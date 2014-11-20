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

#import "NAOAuthUser.h"
#import "NAOAuth2Client.h"
#import "NAErrorCode.h"


NSString * const NAUserAPITokenUrl = @"https://api.netatmo.net/oauth2/token";

NSString * const NAUserAPILoginDidSucceedNotification   = @"NAUserAPILoginDidSucceedNotification";
NSString * const NAUserAPILoginDidFailNotification      = @"NAUserAPILoginDidFailNotification";
NSString * const NAUserAPIUserNeedsToLogInNotification  = @"NAUserAPIUserNeedsToLogInNotification";

@interface NAOAuthUser ()

@property (nonatomic, readwrite, assign) NAOAuthUserState state;

@property (nonatomic, readwrite, strong) NSString * userId;
@property (nonatomic, readwrite, strong) NSString * userSecret;

@end

@implementation NAOAuthUser

- (id)init
{
    self = [super init];
    if (self)
    {
        _state = NAOAuthUserStateAuthorizationNoneNoPwd;
    }
    
    return self;
}

- (NSString *)serviceProviderIdentifier
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Keychain" ofType:@"plist"]];
  
    NSString * identifier = [dictionary objectForKey:@"identifier"];
  
    return identifier;
}

#pragma mark - MANAGE STATE MACHINE

-(void) initializeState
{
    if (_userId == nil || _userSecret == nil)
    {
        if(self.credential.accessToken && [self.credential isExpired] == NO)
        {
            //nothing to do, just finished
            _state = NAOAuthUserStateAccessGranted;
        }
        else
        {
            if (self.credential.refreshToken)
            {
                //need oauth request with grant_type = refresh_token
                _state = NAOAuthUserStateAuthorizationGranted;
            }
            else
            {
                _state = NAOAuthUserStateAuthorizationNoneNoPwd;
            }
        }
    }
    else
    {
        //need oauth request with grant_type = password
        _state = NAOAuthUserStateAuthorizationNoneKnownPwd;
    }
}

-(void) processStateMachineWithDelegate:(id<NAOAuthLoginDelegate>) delegate
{
    switch (_state)
    {
        case NAOAuthUserStateAuthorizationNoneNoPwd:
        {
            NSLog(@"NAOAuthUserStateAuthorizationNoneNoPwd");
            [delegate oAuth:self didFailedLogInWithError:NtmoAPIErrorCodeUserNeedToLogIn];
        }
            break;
        case NAOAuthUserStateAuthorizationNoneKnownPwd:
        {
            NSLog(@"NAOAuthUserStateAuthorizationNoneKnownPwd");
            [self requestRefreshTokenWithDelegate:delegate];
        }
            break;
        case NAOAuthUserStateAuthorizationGranted:
        {
            NSLog(@"NAOAuthUserStateAuthorizationGranted");
            [self requestAccessTokenWithDelegate:delegate];
        }
            break;
        case NAOAuthUserStateAccessGranted:
        {
            NSLog(@"NAOAuthUserStateAccessGranted");
            NSLog(@"accessToken %@", _credential.accessToken);
            [delegate oAuth:self didSucceedLogInWithCredential:_credential];
        }
        default:
            break;
    }
}

#pragma mark - LOG IN

- (void) authentificateWithId:(NSString *)anId secret:(NSString *)aSecret withDelegate:(id<NAOAuthLoginDelegate>)delegate
{
    self.userId         = anId;
    self.userSecret     = aSecret;
    
    [self initializeState];
    [self processStateMachineWithDelegate:delegate];
}


- (void) authentificateWithDelegate:(id<NAOAuthLoginDelegate>)delegate
{
    [self authentificateWithId:nil secret:nil withDelegate:delegate];
}

#pragma mark - REQUESTS

- (void) requestRefreshTokenWithDelegate:(id<NAOAuthLoginDelegate>) delegate
{
    [_oauth authenticateUsingOAuthWithURLString:NAUserAPITokenUrl
                                       username:_userId
                                       password:_userSecret
                                          scope:NAClientScope
                                        success:^(AFOAuthCredential *credential) {
                                            [self handleSuccessResponse:credential withDelegate:delegate];
                                        }
                                        failure:^(NSError *error) {
                                            [self handleFailureResponse:error withDelegate:delegate];
                                        }];
    
    
}


- (void) requestAccessTokenWithDelegate:(id<NAOAuthLoginDelegate>) delegate
{
    [_oauth authenticateUsingOAuthWithURLString:NAUserAPITokenUrl
                                   refreshToken:_credential.refreshToken
                                        success:^(AFOAuthCredential *credential) {
                                            [self handleSuccessResponse:credential withDelegate:delegate];
                                        } failure:^(NSError *error) {
                                            [self handleFailureResponse:error withDelegate:delegate];
                                        }];    
}

#pragma mark - HANDLE RESPONSE

- (void) handleSuccessResponse: (AFOAuthCredential*) credential withDelegate:(id<NAOAuthLoginDelegate>) delegate
{
    NSLog(@"I have a token!\n refreshToken %@ \n accessToken %@ \n expired %d", credential.refreshToken, credential.accessToken, [credential isExpired]);
    _credential = credential;
    [self storeCredential];
    [delegate oAuth:self didSucceedLogInWithCredential:_credential];
}

- (void) handleFailureResponse: (NSError*) error withDelegate:(id<NAOAuthLoginDelegate>) delegate
{
    NSLog(@"Error %@", error);
    
    NtmoAPIErrorCode errorCode = [NAErrorCode NAErrorCodeFromNSError:error];
    
    
    switch (errorCode) {
        case NtmoAPIErrorCodeInvalidRefreshToken:
            NSLog(@"NtmoAPIErrorCodeInvalidRefreshToken");
            [self resetCredential];
            [self requestRefreshTokenWithDelegate:delegate];
            return;
        case NtmoAPIErrorCodeInvalidAccessToken:
            NSLog(@"NtmoAPIErrorCodeInvalidAccessToken");
            [self requestAccessTokenWithDelegate:delegate];
            return;
        case NtmoAPIErrorCodeAccessTokenExpired:
            NSLog(@"NtmoAPIErrorCodeAccessTokenExpired");
            [self requestAccessTokenWithDelegate:delegate];
            return;
        case NtmoAPIErrorCodeOauthInvalidGrant:
            NSLog(@"NtmoAPIErrorCodeOauthInvalidGrant");
            [self resetCredential];
            break;
            
        default:
            break;
    }

    [delegate oAuth:self didFailedLogInWithError:errorCode];
}

#pragma mark - NOTIFICATION NAMES

- (NSString *)loginDidSucceedNotificationName
{
    return NAUserAPILoginDidSucceedNotification;
}

- (NSString *)loginDidFailNotificationName
{
    return NAUserAPILoginDidFailNotification;
}

- (NSString *)userNeedsToLogInNotificationName
{
    return NAUserAPIUserNeedsToLogInNotification;
}


@end