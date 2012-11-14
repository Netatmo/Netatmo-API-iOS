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


#import "NAOAuth.h"

#import "NetatmoDefines.h"

#import "TTURLRequest+NtmoAPI.h"

#import "AppliCommonPrivate.h"
#import "NAUserDataStorer.h"

const NSString* const kLoginErrorUserInfoField = @"LoginErrorUserInfoField";


@implementation NAOAuth

#pragma mark - NSObject

- (id)init
{
    self = [super init];
    if (self) {
        _accessToken = nil;
        _refreshToken = nil;
    }
    
    return self;
}

- (void)dealloc
{
    NTA_RELEASE_SAFELY(_backupAccessToken);
    NTA_RELEASE_SAFELY(_backupRefreshToken);
    
    NTA_RELEASE_SAFELY(_accessToken);
    NTA_RELEASE_SAFELY(_refreshToken);
    [super dealloc];
}

#pragma mark -


@synthesize accessToken=_accessToken;

-(NSString*) refreshToken
{
    if(_refreshToken == nil){
        //get access token from mass storage
        _refreshToken = [[NAUserDataStorer gUserDataStorer] getUserDataForKey:kUDRefreshToken];
        if(nil != _refreshToken){
            if ([_refreshToken length] <= 0) {
                _refreshToken = nil;
            } else {
                [_refreshToken retain];
            }
        }
    }
    
    return _refreshToken;
}

+ (NtmoAPIErrorCode) getErrorCodeFromOAuthResponse:(TTURLJSONResponse *)response
{
    if([response.rootObject isKindOfClass:[NSDictionary class]]){
        id errorValue = [response.rootObject valueForKey:@"error"];
        if (errorValue != nil && [errorValue isKindOfClass:[NSString class]]) {
            NTAPRINT(@"OAuth ERROR: %@", errorValue);
            if ([@"invalid_grant" compare:errorValue] == NSOrderedSame){
                return NtmoAPIErrorCodeOauthInvalidGrant;            
            } else {
                return NtmoAPIErrorCodeOauthOther;
            }
        } else {
            return NtmoAPIErrorCodeSuccess;
        }        
    }
    
    return NtmoAPIErrorCodeUnknown;
    
}

- (void) notifyAccessTokenExpired
{
    NTA_RELEASE_SAFELY(_accessToken);
}

-(void) storeRefreshToken
{
    if (_refreshToken != nil) 
    {
        [[NAUserDataStorer gUserDataStorer] storeData:_refreshToken forKey:kUDRefreshToken];
    }
}

-(void) resetRefreshToken
{
    [_refreshToken release];
    _refreshToken = nil;
    [[NAUserDataStorer gUserDataStorer] removeUserDataForKey:kUDRefreshToken];
}

-(void) parseTokenFromOAuthResponse:(TTURLJSONResponse *)response 
{
    TTDASSERT([response.rootObject isKindOfClass:[NSDictionary class]]);
    id accessToken = [response.rootObject valueForKey:@"access_token"];
    if(accessToken != nil && [accessToken isKindOfClass:[NSString class]]){
        [_accessToken release];
        _accessToken = [accessToken retain];
    }
    id refreshToken = [response.rootObject valueForKey:@"refresh_token"];
    if(refreshToken != nil && [refreshToken isKindOfClass:[NSString class]]){
        [_refreshToken release];
        _refreshToken = [refreshToken retain];
    }
}


- (void) parseTokenResponse:(TTURLJSONResponse *)response
{
    [self parseTokenFromOAuthResponse:response];
    [self storeRefreshToken];
}

#pragma mark - dummy

- (void) login
{
    NTAERROR(@"Dummy login: should instantiate NAOAuthUser");
}

-(void)loginWithId:(NSString *)anId secret:(NSString *)aSecret
{
    NTAERROR(@"Dummy login: should instantiate NAOAuthUser");    
}


- (NSString*) loginStartNotificationName
{
    return @"DummyNotification";    
}

- (NSString*) loginSuccessNotificationName
{
    return @"DummyNotification";
}
- (NSString*) loginFailureNotificationName
{
    return @"DummyNotification";
}

#pragma mark - static methods


+(NSString*) getAccessTokenFromResponse: (TTURLJSONResponse*) response
{
    
    if([response.rootObject isKindOfClass:[NSDictionary class]]){
        id accessTokenObj = [response.rootObject valueForKey:@"access_token"];
        if(accessTokenObj != nil && [accessTokenObj isKindOfClass:[NSString class]]){
            NTAPRINT(@"Parsed access token = %@", accessTokenObj);
            return accessTokenObj;
        }
    }
    
    return nil;
}






@end
