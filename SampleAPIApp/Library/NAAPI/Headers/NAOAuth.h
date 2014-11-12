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


#import "NAOAuth2Client.h"
#import "AFNetworking.h"
#import "AppliCommonPublic.h"


extern NSString * const NAClientId;
extern NSString * const NAClientSecret;
extern NSString * const NAClientScope;

@protocol NAOAuthLoginDelegate;

@interface NAOAuth : NSObject
{
    @protected
    AFOAuthCredential * _credential;
    AFOAuth2Client * _oauth;
}

@property (nonatomic, readonly, strong) AFOAuthCredential * credential;
@property (nonatomic, readonly, strong) AFOAuth2Client * oauth;

@property (nonatomic, readonly, strong) NSString * serviceProviderIdentifier;

/**
 only derived classes should call these
 */
- (void) resetCredential;
- (void) storeCredential;

- (void) resetAccessToken;

/**
 Intended for non-API login (e.g. my.netatmo.com)
 */
@property (nonatomic, readonly, strong) NSString * accessToken;

/**
 should not be called - class intended to be 'abstract'
 */
- (void) authentificateWithDelegate:(id<NAOAuthLoginDelegate>) delegate;

- (void) authentificateWithId: (NSString*) anId
                       secret: (NSString*) aSecret
                 withDelegate: (id<NAOAuthLoginDelegate>) delegate;

- (NSString*) loginDidSucceedNotificationName;
- (NSString*) loginDidFailNotificationName;
- (NSString*) userNeedsToLogInNotificationName;

@end

@protocol NAOAuthLoginDelegate <NSObject>

- (void) oAuth:(NAOAuth *)oAuth didSucceedLogInWithCredential:(AFOAuthCredential*)credential;
- (void) oAuth:(NAOAuth *)oAuth didFailedLogInWithError:(NtmoAPIErrorCode)error;

@end