//
// Copyright 2014 Netatmo
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
#import "AFNetworking.h"
#import "NAOAuthUser.h"
#import "NAHTTPRequestOperationSaver.h"
#import "NAJSONResponseSerializer.h"
#import "NAJSONRequestSerializer.h"
#import "NAReachability.h"
#import "AFNetworkActivityLogger.h"


NSString * const kWSUrl      = @"https://api.netatmo.net/";

static NAAPI * sSharedUserInstance = nil;

@interface NAAPI ()

@property (nonatomic, readwrite, strong) AFHTTPRequestOperationManager * manager;

@property (nonatomic, readwrite, assign) NAAPIState state;

@property (nonatomic, readwrite, strong) NAOAuth * oAuth;

@property (nonatomic, readwrite, strong) NSMutableArray * pendingOperations;
@property (nonatomic, readwrite, strong) NSMutableArray * onGoingOperations;

@property (nonatomic, readwrite, assign) NSTimeInterval privateTimeServerOffset;

@end

@implementation NAAPI

#pragma mark -
#pragma mark Singleton


+ (instancetype)gUserAPI
{
    @synchronized(self)
    {
        if (sSharedUserInstance == nil)
        {
            sSharedUserInstance = [self new];
            
            sSharedUserInstance.oAuth = [NAOAuthUser new];
        }
        return sSharedUserInstance;
    }
}

#pragma mark - NSObject

- (instancetype)init
{
    if (self = [super init])
    {
        self.privateTimeServerOffset = INFINITY;
        
        self.state = NAAPIStateNotAuthentified;
        
        self.manager = [AFHTTPRequestOperationManager manager];
        
        self.manager.requestSerializer = [NAJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        self.manager.responseSerializer = [NAJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        
        self.pendingOperations = [NSMutableArray new];
        self.onGoingOperations = [NSMutableArray new];
        
#if AF_LOGGER_ENABLE
        [[AFNetworkActivityLogger sharedLogger] setLevel:AF_LOGGER_LEVEL];
        [[AFNetworkActivityLogger sharedLogger] startLogging];
#endif
    }
    
    return self;
}

-(void)dealloc
{
    [self.manager.reachabilityManager stopMonitoring];
    
#if AF_LOGGER_ENABLE
    [[AFNetworkActivityLogger sharedLogger] stopLogging];
#endif
}


#pragma mark - LOGIN

- (void) loginWithId:(NSString*)anId secret:(NSString*)aSecret
{
    
    NSLog(@"[NAAPI loginWithId:secret:]");
    
    
    switch (self.state) {
            
        case NAAPIStateAuthentified:
            NSLog(@"already authentified but we want to have a new access token");
            [self.oAuth resetAccessToken];
        case NAAPIStateNotAuthentified:
            self.state = NAAPIStateReauthenticating;
            
            if ([[NAReachability gNAReachability] isApiReachable])
            {
                [self.oAuth authentificateWithId:anId secret:aSecret withDelegate:self];
            }
            else
            {
                [self oAuth:self.oAuth didFailedLogInWithError:NtmoAPIErrorCodeNoDataConnection];
            }
            
            break;
        case NAAPIStateReauthenticating:
            NSLog(@"Login ignored as we are already authenticating");
            break;
        default:
            break;
    }
    
}

- (void) login
{
    
    // Do not force login if we know it will failed.
    // That permits not to refuse real login trying in multi queue situations.
    
    if (self.oAuth.credential)
    {
        [self loginWithId:nil secret:nil];
    }
    else
    {
        [self oAuth:self.oAuth didFailedLogInWithError:NtmoAPIErrorCodeUserNeedToLogIn];
    }
}

- (void)logout
{
    NSLog(@"[NAAPI Logout]");
    
    self.state = NAAPIStateNotAuthentified;
    [self.oAuth resetCredential];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:self.oAuth.userNeedsToLogInNotificationName object:self];
}

- (BOOL) isLoggedIn
{
    return (self.state == NAAPIStateAuthentified);
}

- (BOOL) hasAccountRelated
{
    // To know if there is an account even not connected.
    return (self.oAuth.credential.refreshToken != nil);
}

- (void) forceRefreshAuth
{
    NSLog(@"[NAAPI]: forceRefreshAuth");
    if (self.state != NAAPIStateReauthenticating)
    {
        [self.oAuth resetAccessToken];
        [self login];
    }
}

#pragma mark - TIME SERVER

- (void) setPrivateTimeServerOffset:(NSTimeInterval)privateTimeServerOffset
{
    if (_privateTimeServerOffset != privateTimeServerOffset)
    {
        _privateTimeServerOffset = privateTimeServerOffset;
    }
}

- (NSDate *)timeServer
{
    return (self.privateTimeServerOffset == INFINITY) ? nil : [NSDate dateWithTimeIntervalSinceNow: self.privateTimeServerOffset];
}

#pragma mark - OAUTH LOGIN DELEGATE


- (void) oAuth:(NAOAuth *)oAuth didSucceedLogInWithCredential:(AFOAuthCredential*)credential
{
    NSLog(@"[NAAPI oAuth:didSucceedLogInWithCredential:]");
    
    self.state = NAAPIStateAuthentified;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:self.oAuth.loginDidSucceedNotificationName object:self];
    
    [self sendPendingOperations];
    
}

- (void) oAuth:(NAOAuth *)oAuth didFailedLogInWithError:(NtmoAPIErrorCode)error
{
    NSLog(@"[NAAPI oAuth:didFailedLogInWithError:] error %@", [NAErrorCode NAErrorCodeDescription:error]);
    
    self.state = NAAPIStateNotAuthentified;
    
    switch (error) {
        case NtmoAPIErrorCodeUserNeedToLogIn:
        case NtmoAPIErrorCodeBadPassword:
        case NtmoAPIErrorCodeOauthInvalidGrant:
        case NtmoAPIErrorCodeNoDataConnection:
            [[NSNotificationCenter defaultCenter] postNotificationName:self.oAuth.loginDidFailNotificationName object:self userInfo:@{@"error":[NSNumber numberWithInt:error]}];
            break;
            
        default:
            NSLog(@"[NAAPI oAuth:didFailedLogInWithError:] new error");
            [[NSNotificationCenter defaultCenter] postNotificationName:self.oAuth.loginDidFailNotificationName object:self userInfo:@{@"error":[NSNumber numberWithInt:error]}];
            break;
    }
    
    [self cancelAndNotifyFailurePendingOperationsWithError:error];
}

#pragma mark - LOG IN NOTIFICATIONS OBSERVER


- (void)registerLogInNotifications:(id<NAAPILogInObserverProtocol>)observer
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(apiDidLogInSuccess:) name:self.oAuth.loginDidSucceedNotificationName object:self];
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(apiDidLogInFailure:) name:self.oAuth.loginDidFailNotificationName object:self];
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(userNeedToLogIn:) name:self.oAuth.userNeedsToLogInNotificationName object:self];
}

- (void)unregisterLogInNotifications:(id<NAAPILogInObserverProtocol>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:self.oAuth.loginDidSucceedNotificationName object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:self.oAuth.loginDidFailNotificationName object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:self.oAuth.userNeedsToLogInNotificationName object:self];
}

#pragma mark - REQUEST

- (void) sendApiRequestWithMethod: (NSString*)method
                         delegate: (id<NAAPIRequestDelegate>) aDelegate
                       parameters: (NSDictionary*) parameters
                         userInfo: (NSDictionary*) userInfo
{
    NAHTTPRequestOperationSaver * operationSaver = [NAHTTPRequestOperationSaver operationSaverForMethod: method
                                                                                             parameters: parameters
                                                                                               userInfo: userInfo
                                                                                               delegate: aDelegate];
    
    
    switch(self.state)
    {
        case NAAPIStateReauthenticating:
        {
            @synchronized(self.pendingOperations)
            {
                [self.pendingOperations addObject:operationSaver];
            }
            break;
        }
        case NAAPIStateNotAuthentified:
        {
            @synchronized(self.pendingOperations)
            {
                [self.pendingOperations addObject:operationSaver];
            }
            [self login];
            break;
        }
        case NAAPIStateAuthentified:
            
            [self fireOperation:operationSaver];
            break;
    }
}

- (void) sendPendingOperations
{
    for (NAHTTPRequestOperationSaver * operationSaver in [self.pendingOperations copy])
    {
        [self fireOperation:operationSaver];
    }
}

- (void) fireOperation: (NAHTTPRequestOperationSaver*) operationSaver
{
    @synchronized(self.pendingOperations)
    {
        [self.pendingOperations removeObject:operationSaver];
    }
    
    if ([[NAReachability gNAReachability] isApiReachable])
    {
        
        AFHTTPRequestOperation * operation = [self operationFromOperationSaver:operationSaver];
        
        operationSaver.operation = operation;
        
        @synchronized(self.onGoingOperations)
        {
            [self.onGoingOperations addObject:operationSaver];
        }
        
        NSLog(@"[NAAPI] fire operation: %@ at %@", operationSaver, operation.request.URL);
        
        [operation start];
    }
    else
    {
        // Save some time if we already know there's gonna be a time out.
        [operationSaver.delegate apiRequestDidFailWithError:NtmoAPIErrorCodeNoDataConnection userInfo:operationSaver.userInfo];
    }
    
}

-(void) cancelPendingRequestsWithDelegate:(id<NAAPIRequestDelegate>) delegate
{
    for (NAHTTPRequestOperationSaver * operationSaver in [self.pendingOperations copy])
    {
        if (operationSaver.delegate == delegate)
        {
            @synchronized(self.pendingOperations)
            {
                [self.pendingOperations removeObject:operationSaver];
            }
        }
    }
}

-(void) cancelRequestsWithDelegate:(id<NAAPIRequestDelegate>) delegate
{
    [self cancelPendingRequestsWithDelegate:delegate];
    
    for (NAHTTPRequestOperationSaver * operationSaver in [self.onGoingOperations copy])
    {
        if (operationSaver.delegate == delegate)
        {
            [operationSaver.operation cancel];
            
            @synchronized(self.onGoingOperations)
            {
                [self.onGoingOperations removeObject:operationSaver];
            }
        }
    }
}



- (void) cancelAndNotifyFailurePendingOperationsWithError:(NtmoAPIErrorCode)code
{
    
    for (NAHTTPRequestOperationSaver * operationSaver in [self.pendingOperations copy])
    {
        [operationSaver.delegate apiRequestDidFailWithError:code
                                                   userInfo:operationSaver.userInfo];
        @synchronized(self.pendingOperations)
        {
            [self.pendingOperations removeObject:operationSaver];
        }
    }
}

#pragma mark - GENERATE OPERATION


- (NSString*) URLStringForMethod:(NSString*) method
{
    return [kWSUrl stringByAppendingFormat:@"%@/%@",@"api",method];
}



- (AFHTTPRequestOperation*) operationFromOperationSaver: (NAHTTPRequestOperationSaver*) operationSaver
{
    __block NAHTTPRequestOperationSaver * operationSaverBlock = operationSaver;
    AFHTTPRequestOperation * operation = [self operationForMethod:operationSaver.method
                                                       parameters:operationSaver.parameters
                                                          success:^(AFHTTPRequestOperation *operation, id responseObject)
                                          {
                                              [self handleSuccessOperation:operation
                                                            responseObject:responseObject
                                                              withDelegate:operationSaverBlock.delegate
                                                                  userInfo:operationSaverBlock.userInfo];
                                          }
                                                          failure:^(AFHTTPRequestOperation *operation, NSError *error)
                                          {
                                              [self handleFailureOperation:operation
                                                                     error:error
                                                              withDelegate:operationSaverBlock.delegate
                                                                  userInfo:operationSaverBlock.userInfo];
                                          }];
    
    return operation;
    
}

- (AFHTTPRequestOperation*) operationForMethod: (NSString*) method
                                    parameters: (NSDictionary*)parameters
                                       success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                       failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSMutableDictionary * mutableParameters = [parameters mutableCopy];
    if (mutableParameters == nil)
    {
        mutableParameters = [NSMutableDictionary new];
    }
    
    NSString * accessToken = [[self.oAuth credential] accessToken];
    if (accessToken)
    {
        [mutableParameters addEntriesFromDictionary:@{@"access_token": accessToken}];
    }
    else
    {
        NSLog(@"access token disapeared");
    }
    
    NSString * URLString = [self URLStringForMethod:method];
    NSMutableURLRequest *request = [[self.manager requestSerializer] requestWithMethod:@"POST"
                                                                             URLString:URLString
                                                                            parameters:mutableParameters
                                                                                 error:nil];
    
    AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:request
                                                                              success:success
                                                                              failure:failure];
    
    return operation;
}


#pragma mark - PARSE RESPONSE


- (NSDictionary *) bodyFromResponseBody: (id)responseBody
{
    if([responseBody isKindOfClass: [NSDictionary class]])
    {
        return [responseBody objectForKey: @"body"];
    }
    
    return nil;
}

- (long) timeServerFromResponseBody: (id)responseBody
{
    if([responseBody isKindOfClass: [NSDictionary class]])
    {
        NSNumber * timeServer = [responseBody objectForKey: @"time_server"];
        if ([timeServer isKindOfClass:[NSNumber class]])
        {
            return [timeServer longValue];
        }
    }
    return -1;
}


#pragma mark - HANDLE RESPONSE

- (void) handleSuccessOperation:(AFHTTPRequestOperation*) operation
                 responseObject: (id) responseObject
                   withDelegate: (id<NAAPIRequestDelegate>) aDelegate
                       userInfo: (NSDictionary*) userInfo
{
    for (NAHTTPRequestOperationSaver * operationSaver in [self.onGoingOperations copy])
        
    {
        if ([operationSaver.operation isEqual:operation])
        {
            @synchronized(self.onGoingOperations)
            {
                [self.onGoingOperations removeObject:operationSaver];
            }
            break;
        }
    }
    
    long timeServer = [self timeServerFromResponseBody:responseObject];
    
    if (0 < timeServer)
    {
        self.privateTimeServerOffset = (NSTimeInterval)timeServer - [[NSDate date] timeIntervalSince1970];
    }
    
    [aDelegate apiRequestDidSucceedWithBody: [self bodyFromResponseBody:responseObject]
                                   userInfo: userInfo];
}

- (void) handleFailureOperation:(AFHTTPRequestOperation*) operation
                          error:(NSError*) error
                   withDelegate: (id<NAAPIRequestDelegate>) aDelegate
                       userInfo: (NSDictionary*) userInfo
{
    NAHTTPRequestOperationSaver * operationSaver;
    
    for (NAHTTPRequestOperationSaver * operationSaverEnum in [self.onGoingOperations copy])
    {
        if ([operationSaverEnum.operation isEqual:operation])
        {
            operationSaver = operationSaverEnum;
            
            @synchronized(self.onGoingOperations)
            {
                [self.onGoingOperations removeObject:operationSaver];
            }
            break;
        }
    }
    
    NtmoAPIErrorCode errorCode = [NAErrorCode NAErrorCodeFromNSError:error];
    
    switch (errorCode) {
            
        case NtmoAPIErrorCodeAccessTokenExpired:
        case NtmoAPIErrorCodeInvalidAccessToken:
        case NtmoAPIErrorCodeAccessTokenMissing:
        {
            operationSaver.operation = nil; // Will be regenerated
            if (operationSaver)
            {
                @synchronized(self.pendingOperations)
                {
                    [self.pendingOperations addObject:operationSaver];
                }
            }
            [self login];
            break;
        }
        default:
        {
            [aDelegate apiRequestDidFailWithError:errorCode userInfo:userInfo];
            break;
        }
    }
    
    
}

@end
