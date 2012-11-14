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


#import "Three20/Three20.h"

#import "AppliCommonPublic.h"
#import "extThree20JSON/extThree20JSON.h"

#import "NetatmoDefines.h"

#define kLoginDidChangeNotification     @"UserLoginDidChangeNotification"



////////////////////////////////////////////////////////////////////////
/////////////// Provide your client id and secret //////////////////////
////////////////////////////////////////////////////////////////////////
#define CLIENT_ID           @""
#define CLIENT_SECRET       @""
////////////////////////////////////////////////////////////////////////

extern NSString* const kLoginErrorUserInfoField;

@interface NAOAuth : NSObject <TTURLRequestDelegate>
{
@private
    NSString *_accessToken;
    NSString *_refreshToken;
    
    NSString *_backupAccessToken;
    NSString *_backupRefreshToken;
}

@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSString *refreshToken;


- (void) notifyAccessTokenExpired;

//only derived classes should call these
- (void) resetRefreshToken;
- (void) parseTokenResponse:(TTURLJSONResponse *)response;


//should not be called - class intended to be 'abstract'
- (void) login;
- (void) loginWithId:(NSString*)anId secret:(NSString*)aSecret;
- (NSString*) loginStartNotificationName;
- (NSString*) loginSuccessNotificationName;
- (NSString*) loginFailureNotificationName;


+ (NtmoAPIErrorCode) getErrorCodeFromOAuthResponse:(TTURLJSONResponse *)response;
+ (NSString*) getAccessTokenFromResponse: (TTURLJSONResponse*) response;


+(TTURLRequest*) requestForDeviceLoginWithDeviceId:(NSString*)deviceId deviceSecret:(NSString*)aDeviceSecret delegate:(id<TTURLRequestDelegate>) aDelegate;

@end
