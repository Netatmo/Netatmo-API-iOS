//
// Copyright 2011-2012 Netatmo
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


#import "NAAPI.h"


#import "TTURLRequest+NtmoAPI.h"

#import "NetatmoDefines.h"
#import "NAOAuthUser.h"
#import "AppliCommonPrivate.h"
#import "NAReachability.h"

NSString *const  kNAAPIErrorDomain = @"NAAPIErrorDomain";

NSString *const NAAPINotReachableNotification = @"NAAPINotReachableNotification";
NSString *const NAAPIIsReachableNotification = @"NAAPIIsReachableNotification";


NSString *const kWSUrl = @"http://api.netatmo.net/";

@interface NAAPI (local)

-(void) updateReachability:(Reachability*)curReach;

@end

@implementation NAAPI

@synthesize oAuthHandler=_oAuth;

#pragma mark - class methods

+ (NtmoAPIErrorCode) getErrorCodeFromResponse:(TTURLJSONResponse *)response
{
    
    if ([response.rootObject isKindOfClass:[NSDictionary class]]) {
        id errorValue = [response.rootObject valueForKey:@"error"];
        if (errorValue != nil) {
            TTDASSERT([errorValue isKindOfClass:[NSDictionary class]]);
            NTAPRINT(@"ERROR: %@", [errorValue valueForKey:@"message"]);
            NTAPRINT(@"Ntmo Error in json: %@", [errorValue valueForKey:@"message"]);
            id code = [errorValue valueForKey:@"code"];
            if (code != nil) return [(NSString*)code intValue];
        } else {
            id statusValue = [response.rootObject valueForKey:@"status"];
            TTDASSERT([statusValue isKindOfClass:[NSString class]]);
            if ([statusValue compare:@"ok" options:NSCaseInsensitiveSearch] == NSOrderedSame){
                NTAPRINT(@"Success response %@", response.description);
                
                return NtmoAPIErrorCodeSuccess;
            }
        }
    }
        
    return NtmoAPIErrorCodeUnknown;
    
}

+(NSString *) stringFromErrorCode:(NtmoAPIErrorCode) errCode
{
    switch (errCode) {
        case NtmoAPIErrorCodeEmailAlreadyExists:
            return @"Email already exits";
        case NtmoAPIErrorCodeSuccess:
        default:
            return @"";            
    }
    
}


+(NSString*) urlForMethod:(NSString*) method
{
    return [kWSUrl stringByAppendingFormat:@"%@/%@",@"api",method];    
}

+(id) bodyFromOkResponse: (TTURLJSONResponse *) response
{
    TTDASSERT([response.rootObject isKindOfClass:[NSDictionary class]]);
    
    id statusValue = [response.rootObject valueForKey:@"status"];
    TTDASSERT([statusValue isKindOfClass:[NSString class]]);
    TTDASSERT([statusValue isEqualToString:@"ok"]);
    
    id body = [response.rootObject valueForKey:@"body"];
    NTAPRINT(@"body is from class %@", NSStringFromClass([body class]));
    
    return body;
}

+(BOOL) loginFailNotification:(NSNotification*) aNotification 
              isCausedByError:(NtmoAPIErrorCode) errorCode
{
    if (nil != [aNotification userInfo]) {
        if ([aNotification.userInfo isKindOfClass:[NSDictionary class]]) {
            NSError *error = [aNotification.userInfo valueForKey:kLoginErrorUserInfoField];
            if ([error isKindOfClass:[NSError class]] 
                && [error.domain isEqualToString:kNAAPIErrorDomain]
                && error.code == errorCode) {
                return YES;
            }
        } 
    }
    return NO;
}

#pragma mark - NSObject

- (id)init
{
    self = [super init];
    if (self) 
    {
        _state = NAAPIStateNotAuthentified;
        _pendingRequests = [[NSMutableArray alloc] init];
                
        [self updateReachability: [NAReachability gNAReachability].apiReachability];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
    }
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:kReachabilityChangedNotification 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:[_oAuth loginSuccessNotificationName] 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:[_oAuth loginFailureNotificationName] 
                                                  object:nil];
    TT_RELEASE_SAFELY(_oAuth);
    TT_RELEASE_SAFELY(_pendingRequests);
    [super dealloc];
}

#pragma mark -
#pragma mark Singleton

static NAAPI *_gUserAPI = nil;

+ (NAAPI*) gUserAPI
{
    @synchronized(self)
    {
        if (_gUserAPI == nil) {
            _gUserAPI = [[super allocWithZone:NULL] init];
            
            _gUserAPI->_oAuth = [[NAOAuthUser alloc] init];
        }
    }
    return _gUserAPI;
}

//should not be called - this means default is user
+ (id)allocWithZone:(NSZone *)zone {
    return [[self gUserAPI] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}


#pragma mark - own methods

NSString *const kRetriesDoneUserInfo = @"RetriesDoneUserInfoKey";
NSString *const kNAAPIUserInfoTopic = @"NAAPI user info";



+(TTUserInfo*) userInfoForRequestWithDelegate:(id<NAAPIRequestDelegate>) aDelegate
                                               retryNb:(NSInteger) nbOfRetriesDone
{
    NSMutableDictionary *addDictionary = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:nbOfRetriesDone] 
                                                                            forKey:kRetriesDoneUserInfo];
    return [TTUserInfo topic:kNAAPIUserInfoTopic 
                                          strongRef:addDictionary 
                                            weakRef:aDelegate];
     
}

+(id<NAAPIRequestDelegate>) getDelegateFromAPIRequestUserInfo:(TTUserInfo*) userInfo
{
    return userInfo.weakRef;
}

+(NSDictionary*) getDictionaryFromAPIRequestUserInfo:(TTUserInfo*) userInfo
{
    return userInfo.strongRef;
}

+(NSInteger) getNbOfRetriesFromAPIRequestUserInfo:(TTUserInfo*) userInfo
{
    return [[userInfo.strongRef valueForKey:kRetriesDoneUserInfo] integerValue];
}

+(void) incrementNbOfRetriesFromAPIRequestUserInfo:(TTUserInfo*) userInfo
{
    NSInteger oldValue = [[userInfo.strongRef valueForKey:kRetriesDoneUserInfo] integerValue];
    NSNumber *incrementedValue = [NSNumber numberWithInt:oldValue + 1];
    [userInfo.strongRef setValue:incrementedValue forKey:kRetriesDoneUserInfo];
}

-(void) sendApiRequest:(TTURLRequest*) request
              delegate:(id<NAAPIRequestDelegate>) aDelegate
{
    NSString *accessToken = [_oAuth accessToken];
    
    NSDictionary *compParam = nil;
    
    if (nil == accessToken) {
        if (NAAPIStateAuthentified == _state) {
            _state = NAAPIStateNotAuthentified;            
        }
        //We add this for permanent caching issues
        //Perm caching is based on md5 of url requests. For http POST
        //parameters the url string is formed by enumerating the parameters dictionary 
        //(ignoring access_token parameter). When there are not the exact same keys
        //the order of enumerations is not the same, so we add a dummy access_token key
        compParam = [NSDictionary dictionaryWithObject:@"ignored" forKey:@"access_token"];
    } else {
        compParam = [NSDictionary dictionaryWithObject:accessToken forKey:@"access_token"];
    }
    
    [request.parameters addEntriesFromDictionary:compParam];
    
    TTUserInfo *apiUserInfo = [NAAPI userInfoForRequestWithDelegate:aDelegate retryNb:0];
    if (request.userInfo && [request.userInfo isKindOfClass:[NSDictionary class]]
        && [apiUserInfo.strongRef isKindOfClass:[NSDictionary class]]){
        [apiUserInfo.strongRef addEntriesFromDictionary:request.userInfo];
        request.userInfo = apiUserInfo;
    } else {
        request.userInfo = apiUserInfo;
    }
        
    request.response = [[[TTURLJSONResponse alloc] init] autorelease];
    [request.delegates addObject:self];
    
    switch(_state){
        case NAAPIStateNoDataConnection:
            if (NA_CACHE_EXPIRATION_NO_CACHE != request.cacheExpirationAge) {                  
                //it may be cached so try (don't mind if there is not any access token v)
                [request setCacheExpirationAge:TT_CACHE_EXPIRATION_AGE_NEVER];
                BOOL foundInCache = [request send];
                if (foundInCache) {
                    break;
                } else {
                    [request cancel];
                }
            }

            NSDictionary *dictUserInfo = [NAAPI getDictionaryFromAPIRequestUserInfo:request.userInfo]; 
            [aDelegate apiRequestDidFailWithError:NtmoAPIErrorCodeNoDataConnection 
                                            userInfo:dictUserInfo];
            break;
        case NAAPIStateReauthenticating:
            [_pendingRequests addObject:request];
            break;
            
        case NAAPIStateNotAuthentified:
            [_pendingRequests addObject:request];
            [self login];
            break;
            
            
        case NAAPIStateAuthentified:
            [request send];
            break;
    }
    
}


+(TTURLRequest*) apiRequestWithMethod:(NSString *)method
                   cacheExpirationAge:(NSTimeInterval) expirationAge
                          addUserInfo:(NSDictionary *)userInfoDict
                  withFirstParamValue:(NSString*) firstValue 
                               params:(va_list) paramsList
{
    
    NSString *url = [NAAPI urlForMethod:method];
    TTURLRequest *request = [TTURLRequest postMonoPartWithURL:url 
                                                     delegate:nil 
                                             compulsoryParams:nil 
                                          withFirstParamValue:firstValue 
                                                       params:paramsList];
    
    request.userInfo = [NSMutableDictionary dictionaryWithDictionary:userInfoDict];
    
    
    if (expirationAge == NA_CACHE_EXPIRATION_NO_CACHE) {
        [request setCachePolicy:TTURLRequestCachePolicyNoCache];
    } else {
        [request setCachePolicy:TTURLRequestCachePolicyLocal];
        [request setCacheExpirationAge:expirationAge];
    }
    [request setCacheExpirationAge:expirationAge];
    [request setTimeoutInterval:NARequestTimeoutValue];
    
    return request;
}

+(TTURLRequest*) apiRequestWithMethod:(NSString *)method
                   cacheExpirationAge:(NSTimeInterval) expirationAge
                          addUserInfo:(NSDictionary *)userInfoDict 
                  paramsValuesAndKeys:(NSString *)firstValue, ...
{
    va_list args;
    va_start(args, firstValue);
    
    TTURLRequest *request = [NAAPI apiRequestWithMethod:method 
                                     cacheExpirationAge:expirationAge 
                                            addUserInfo:userInfoDict 
                                    withFirstParamValue:firstValue 
                                                 params:args];
    
    va_end(args);
    
    return request;
}



-(void) sendApiRequestWithMethod:(NSString *)method
                        delegate:(id<NAAPIRequestDelegate>) aDelegate
              cacheExpirationAge:(NSTimeInterval) expirationAge
                     addUserInfo:(NSDictionary *)userInfoDict 
             paramsValuesAndKeys:(NSString *)firstValue, ... 
{
    va_list args;
    va_start(args, firstValue);
    
    TTURLRequest *request = [NAAPI apiRequestWithMethod:method 
                                     cacheExpirationAge:expirationAge 
                                            addUserInfo:userInfoDict 
                                    withFirstParamValue:firstValue 
                                                 params:args];
    
    va_end(args);
    
    [self sendApiRequest:request delegate:aDelegate];    
}


-(TTURLRequest*) requestFromRespondedRequest:(TTURLRequest*) aRequest
{
    aRequest.response = [[[TTURLJSONResponse alloc] init] autorelease];
    [NAAPI incrementNbOfRetriesFromAPIRequestUserInfo:aRequest.userInfo];
    return aRequest;
}

-(void) notifyAPINotReachable
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NAAPINotReachableNotification 
                                                        object:self];
}

-(void) notifyAPIIsReachable
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NAAPIIsReachableNotification 
                                                        object:self];
}

-(void) cancelPendingRequestsWithDelegate:(id<NAAPIRequestDelegate>) delegate
{
    NSMutableArray *requestsToCancel = nil; 
    
    for (TTURLRequest *request in _pendingRequests) {
        id<NAAPIRequestDelegate> requestDelegate = [NAAPI getDelegateFromAPIRequestUserInfo:request.userInfo];
        
        if (delegate == requestDelegate) {
            if (!requestsToCancel) {
                requestsToCancel = [NSMutableArray array];
            }
            [requestsToCancel addObject:request];
        }
    }
    
    for (TTURLRequest* request in requestsToCancel) {
        [_pendingRequests removeObject:request];
    }
}


-(void) cancelRequestsWithDelegate:(id<NAAPIRequestDelegate>) delegate
{
 
    [self cancelPendingRequestsWithDelegate:delegate];
    
    /*Super important, do also the same with main queue*/
    [[TTURLRequestQueue mainQueue] cancelRequestsWithDelegate:delegate];
}

#pragma mark - Authentication

/*juste un frontend for oAuth*/
- (void) login
{
    switch (_state) {
        case NAAPIStateNoDataConnection:
            [self notifyAPINotReachable];
            break;
        case NAAPIStateAuthentified:
        case NAAPIStateNotAuthentified:
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(loginDidSucceed:) 
                                                         name:[_oAuth loginSuccessNotificationName] 
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(loginDidFail:) 
                                                         name:[_oAuth loginFailureNotificationName] 
                                                       object:nil];

            _state = NAAPIStateReauthenticating;
            [_oAuth login];
            break;
        case NAAPIStateReauthenticating:
            NTAWARNING(@"Login ignored as we are already authenticating");
        default:
            break;
    }
}
- (void) loginWithId:(NSString*)anId secret:(NSString*)aSecret
{
    switch (_state) {
        case NAAPIStateNoDataConnection:
            [self notifyAPINotReachable];
            break;
        case NAAPIStateAuthentified:
        case NAAPIStateNotAuthentified:
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(loginDidSucceed:) 
                                                         name:[_oAuth loginSuccessNotificationName] 
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(loginDidFail:) 
                                                         name:[_oAuth loginFailureNotificationName] 
                                                       object:nil];
            
            _state = NAAPIStateReauthenticating;
            [_oAuth loginWithId:anId secret:aSecret];
            break;
        case NAAPIStateReauthenticating:
            NTAWARNING(@"Login ignored as we are already authenticating");
        default:
            break;
    }
}


#pragma mark reachability

- (void)updateReachability:(Reachability*)curReach
{
    if ([[NAReachability gNAReachability] isApiReachable]) {
        _state = NAAPIStateNotAuthentified;    
    } else {
        //show alert;
        if (NAAPIStateNoDataConnection != _state){
            _state = NAAPIStateNoDataConnection;
            [self notifyAPINotReachable];            
        }        
    }
}

-(void)reachabilityChanged:(NSNotification* )notification
{
    Reachability *curReach = [notification.userInfo valueForKey:kReachabilityNotificationUserInfoReach];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateReachability:curReach];
}

#define MAX_AUTH_RETRIES 2

#pragma mark -

-(void) loginDidSucceed: (NSNotification *) aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:[_oAuth loginSuccessNotificationName] 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:[_oAuth loginFailureNotificationName] 
                                                  object:nil];
    
    _state = NAAPIStateAuthentified;
    NTAPRINT(@"NAAPI state set to NAAPIStateAuthentified");

    
    //send pending requests
    TTURLRequest *request = nil;
    while ([_pendingRequests count] > 0  && nil != (request = [_pendingRequests objectAtIndex:0])){
        [request retain];
        [_pendingRequests removeObjectAtIndex:0];
        NSString *newAccessToken = [_oAuth accessToken];

        NTAPRINT(@"new access token %@", newAccessToken);
        [request.parameters setValue:newAccessToken forKey:@"access_token"];
        NTAPRINT(@"Request before send : %@ with params :%@", request, request.parameters);
        [request send];
        [request release];
    }
    
}

-(void) loginDidFail: (NSNotification *) aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self  
                                                    name:[_oAuth loginSuccessNotificationName] 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:[_oAuth loginFailureNotificationName] 
                                                  object:nil];
    
    _state = NAAPIStateNotAuthentified;
    
    //cancel & notify failure of pending requests
    TTURLRequest *request = nil;
    while ([_pendingRequests count] > 0  && nil != (request = [_pendingRequests objectAtIndex:0])){
        [request retain];
        [_pendingRequests removeObjectAtIndex:0];
        
        id<NAAPIRequestDelegate> delegate = [NAAPI getDelegateFromAPIRequestUserInfo:request.userInfo];
        NSDictionary *userInfo = [NAAPI getDictionaryFromAPIRequestUserInfo:request.userInfo];
        
        if ([aNotification.userInfo isKindOfClass:[NSDictionary class]]){
            NSError *error = [aNotification.userInfo valueForKey:kLoginErrorUserInfoField];
            if ([error isKindOfClass:[NSError class]]) {
                if ([delegate respondsToSelector:@selector(apiRequestDidFailWithError:userInfo:)]){
                    [delegate apiRequestDidFailWithError:error.code
                                                userInfo:userInfo];
                }
            }
        }
        
        [request cancel];
        
        [request release];
    }
}


#pragma mark - TTURLRequestDelegate

-(void)requestDidStartLoad:(TTURLRequest *)request
{
    NADPRINTMETHODNAME();
}

-(void)requestDidFinishLoad:(TTURLRequest *)request
{
    TTURLJSONResponse *response = request.response;
    
    NTAPRINT(@"in state :%d received response: %@", _state, response);    
    
    id<NAAPIRequestDelegate> delegate = [NAAPI getDelegateFromAPIRequestUserInfo:request.userInfo];
    NSDictionary *userInfo = [NAAPI getDictionaryFromAPIRequestUserInfo:request.userInfo];

    
    if ([delegate conformsToProtocol:@protocol(NAAPIRequestDelegate)]){
        NtmoAPIErrorCode errorCode = [NAAPI getErrorCodeFromResponse:response];
        if (NtmoAPIErrorCodeSuccess == errorCode){
            [delegate apiRequestDidSucceedWithBody:[NAAPI bodyFromOkResponse:response] 
                                          userInfo:userInfo];
        } else {
            //probabaly will never be called as we don't get api errors with http success
            [delegate apiRequestDidFailWithError:errorCode 
                                        userInfo:userInfo];
        }
    }
}

-(void)request:(TTURLRequest *)request didFailLoadWithError:(NSError *)error
{
    NTAPRINT(@"in state :%d received error response: %@", _state, error);    
    
    id<NAAPIRequestDelegate> delegate = [NAAPI getDelegateFromAPIRequestUserInfo:request.userInfo];
    NSDictionary *userInfo = [NAAPI getDictionaryFromAPIRequestUserInfo:request.userInfo];

    
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCannotFindHost) {
        //lost internet connection?
        if ([delegate respondsToSelector:@selector(apiRequestDidFailWithError:userInfo:)]){
            [delegate apiRequestDidFailWithError:NtmoAPIErrorCodeNoDataConnection 
                                        userInfo:userInfo];
        }
        return;
    } 
    
    
    NtmoAPIErrorCode errorCode = [NAAPI getErrorCodeFromResponse:request.response];
        switch (errorCode) {
            case NtmoAPIErrorCodeAccessTokenExpired:
            case NtmoAPIErrorCodeInvalidAccessToken:
                _state = NAAPIStateNotAuthentified;
                if ([NAAPI getNbOfRetriesFromAPIRequestUserInfo:request.userInfo] <= MAX_AUTH_RETRIES){
                    //enqueue request at first position for it to be the
                    //first to be retried after login
                    TTURLRequest *resetedRequest = [self requestFromRespondedRequest:request];
                    [_pendingRequests insertObject:resetedRequest atIndex:0];
                    [_oAuth notifyAccessTokenExpired];
                    [self login];
                } else {
                    if ([delegate respondsToSelector:@selector(apiRequestDidFailWithError:userInfo:)]){
                        [delegate apiRequestDidFailWithError:errorCode 
                                                    userInfo:userInfo];
                    }
                }
                break;
            default:
                if ([delegate respondsToSelector:@selector(apiRequestDidFailWithError:userInfo:)]){
                    [delegate apiRequestDidFailWithError:errorCode 
                                                userInfo:userInfo];
                }
                break;
        }
}

-(void)requestDidCancelLoad:(TTURLRequest *)request
{
    NADPRINTMETHODNAME();
}




@end
