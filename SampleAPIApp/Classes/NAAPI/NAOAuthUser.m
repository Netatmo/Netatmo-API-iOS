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

#import "NAOAuthUser.h"
#import "NAAPI.h"
#import "AppliCommonPublic.h"
#import "NetatmoDefines.h"

#import "TTURLRequest+NtmoAPI.h"

#import "AppliCommonPrivate.h"

#define kLoginDidStartNotification      @"UserLoginDidStartNotification"
#define kLoginDidSucceedNotification    @"UserLoginDidSucceedNotification"
#define kLoginDidFailNotification       @"UserLoginDidFailNotification"

@interface NAOAuthUser ()
@property (nonatomic, readonly) BOOL hasValidScope;
@end

@implementation NAOAuthUser

NSString *_email = nil;
NSString *_pwd = nil;

#pragma mark - NSObject

- (id)init
{
    self = [super init];
    if (self) {
        _state = NAOAuthUserStateAuthorizationNoneNoPwd;
        _scope = CLIENT_SCOPE;
    }
    
    return self;
}

- (void)dealloc
{
    NTA_RELEASE_SAFELY(_scope);
    NTA_RELEASE_SAFELY(_email);
    NTA_RELEASE_SAFELY(_pwd);
    [super dealloc];
}

#pragma mark -


-(BOOL)hasValidScope
{
    if ([_scope isKindOfClass:[NSString class]]) {
        if ([_scope isEqualToString:NAAPIScopeReadStation]) {
            return YES;
        }
        if ([_scope rangeOfString:NAAPIScopeReadTherm].location != NSNotFound ||
            [_scope rangeOfString:NAAPIScopeWriteTherm].location != NSNotFound) {
            return YES;
        }
    }
    
    return NO;
}


NSString *const kUserTokenUrl = @"https://api.netatmo.net/oauth2/token";


-(void) determineInitialState
{
    if(self.accessToken == nil){
        if (_email == nil || _pwd == nil) {
            if (self.refreshToken == nil) {
                _state = NAOAuthUserStateAuthorizationNoneNoPwd;
                
            } else {
                //need oauth request with grant_type = refresh_token
                _state = NAOAuthUserStateAuthorizationGranted;
            }
        } else {
            //need oauth request with grant_type = password
            _state = NAOAuthUserStateAuthorizationNoneKnownPwd;
        }
    } else {
        //nothing to do, just finished
        _state = NAOAuthUserStateAccessGranted;
    }
    
}

-(void) iterateStateMachine
{
    switch (_state) {
        case NAOAuthUserStateAuthorizationNoneNoPwd:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoginDidFailNotification object:self];
        }
            break;
        case NAOAuthUserStateAuthorizationNoneKnownPwd:
        {
            // authenticate to the server
            // and wait for access token and refresh token            
            TTURLRequest *request = [TTURLRequest postMonoPartWithURL:kUserTokenUrl delegate:self 
                                                  paramsValuesAndKeys:
                                     CLIENT_ID, @"client_id",
                                     CLIENT_SECRET, @"client_secret",
                                     @"password", @"grant_type",
                                     _email, @"username",
                                     _pwd, @"password",
                                     nil];
            
            if ([self hasValidScope]) {
                [request.parameters setValue:_scope forKey:@"scope"];
            }
            
            request.response = [[[TTURLJSONResponse alloc] init] autorelease];
            [request setCachePolicy:TTURLRequestCachePolicyNoCache];
            [request setTimeoutInterval:NARequestTimeoutValue];

            
            _state = NAOAuthUserStateAccessAndAuthRequested;
            [_email release];
            [_pwd release];
            _email = nil;
            _pwd = nil;
            [request send];
        }
            break;
        case NAOAuthUserStateAuthorizationGranted:
        {
            TTURLRequest *request = [TTURLRequest postMonoPartWithURL:kUserTokenUrl delegate:self 
                                                  paramsValuesAndKeys:
                                     CLIENT_ID, @"client_id",
                                     CLIENT_SECRET, @"client_secret",
                                     @"refresh_token", @"grant_type",
                                     self.refreshToken, @"refresh_token",
                                     nil];
            request.response = [[[TTURLJSONResponse alloc] init] autorelease];
            [request setTimeoutInterval:NARequestTimeoutValue];
            [request setCachePolicy:TTURLRequestCachePolicyNoCache];

            
            _state = NAOAuthUserStateAccessRequested;
            [request send];
        }
            break;
        case NAOAuthUserStateAccessRequested:
            //Shouldn't be here
            NTAPRINT(@"Error: launched login in bad state = %d", _state);
            break;
        case NAOAuthUserStateAccessGranted:
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoginDidSucceedNotification object:self];
        default:
            break;
    }
}

-(void) loginWithId:(NSString *)anId secret:(NSString *)aSecret
{
    [_email release];
    [_pwd release];
    _email = anId;
    _pwd = aSecret;
    [_email retain];
    [_pwd retain];
    [self determineInitialState];
    [self iterateStateMachine];
}


-(void) login
{
    [self loginWithId:nil secret:nil];
}

- (NSString*) loginStartNotificationName
{
    return kLoginDidStartNotification;
}
- (NSString*) loginSuccessNotificationName
{
    return kLoginDidSucceedNotification;
}
- (NSString*) loginFailureNotificationName
{
    return kLoginDidFailNotification;
}

/*only oAuth specific errors: does not handle http or
 no connection errors*/
-(void) handleOAuthError: (NtmoAPIErrorCode) errorCode
{
    NTAPRINT(@"Error in state @%d", _state);
    NSError *error = [NSError errorWithDomain:kNAAPIErrorDomain code:errorCode userInfo:nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:kLoginErrorUserInfoField];
    if (NAOAuthUserStateAccessRequested == _state
        && NtmoAPIErrorCodeOauthInvalidGrant == errorCode){
        _state = NAOAuthUserStateAuthorizationNoneNoPwd;
        [self resetRefreshToken];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginDidFailNotification 
                                                            object:self
                                                          userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginDidChangeNotification object:self];

    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginDidFailNotification 
                                                            object:self
                                                          userInfo:userInfo];    
    }
    //[self iterateStateMachine];
}



#pragma mark - 
#pragma mark TTUrlRequestDelegate

-(void) requestDidStartLoad:(TTURLRequest *)request
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLoginDidStartNotification object:self];
}

-(void) requestDidFinishLoad:(TTURLRequest *)request
{
    if (_state != NAOAuthUserStateAccessRequested && _state != NAOAuthUserStateAccessAndAuthRequested){
        //Shouldn't be here as we should have requested either access or authorization
        NTAPRINT(@"ERROR OAUTH: Bad state (%d) after request ", _state);
        return;
    }
    
    if([NAOAuth getErrorCodeFromOAuthResponse:request.response] == NtmoAPIErrorCodeSuccess){
        NTAPRINT(@"Login ok !!");
        _state = NAOAuthUserStateAccessGranted;
        [self parseTokenResponse:request.response];
        NTAPRINT(@"OAUTH: Received access token: %@", self.accessToken);
        NTAPRINT(@"OAUTH: Received refresh token: %@", self.refreshToken);
        
        NTAPRINT(@"Sending login succeed notification");
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginDidSucceedNotification object:self];
    } else {
        //just in case: should not happen (http ok and api error)
        [self handleOAuthError: NtmoAPIErrorCodeUnknown];
    }
    
}

-(void)request:(TTURLRequest *)request didFailLoadWithError:(NSError *)error
{
    NTAPRINT(@"Request failed with error %@", error.description);

    if (_state != NAOAuthUserStateAccessRequested && _state != NAOAuthUserStateAccessAndAuthRequested){
        //Shouldn't be here as we should have requested either access or authorization
        TTDERROR(@"ERROR OAUTH: Bad state (%d) after request ", _state);
        return;
    }
    NtmoAPIErrorCode errorCode = [NAOAuth getErrorCodeFromOAuthResponse:request.response];
    if( errorCode != NtmoAPIErrorCodeSuccess){
        [self handleOAuthError:errorCode];        
    } else {
        //this means we do not have a data connection?
        //can this happen?
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginDidFailNotification object:self];//or Error
    }
    
}


@end
