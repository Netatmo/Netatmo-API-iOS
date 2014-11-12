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


#import "NAOAuth.h"
#import "NAAPIConfig.h"

extern NSString * const kWSUrl;

@implementation NAOAuth

@synthesize credential = _credential;
@synthesize oauth = _oauth;

- (id)init
{
    if (self = [super init])
    {
        _oauth = [[NAOAuth2Client alloc] initWithBaseURL:[NSURL URLWithString:kWSUrl] clientID:NAClientId secret:NAClientSecret];
    }
    
    return self;
}

#pragma mark - MANAGE CREDENTIAL


- (NSString*) serviceProviderIdentifier
{
    NSAssert(NO, @"Subclass should implement serviceProviderIdentifier method");
    return _oauth.serviceProviderIdentifier;
}

- (AFOAuthCredential *)credential
{
    if(_credential == nil)
    {
        _credential = [AFOAuthCredential retrieveCredentialWithIdentifier:self.serviceProviderIdentifier];
    }
    NSLog(@"[NAOAuth]: getCredential %@", _credential);
    return _credential;
}


- (void) resetCredential
{
    NSLog(@"[NAOAuth]: resetCredential %@", [self credential]);
    _credential = nil;
    
    if ([AFOAuthCredential deleteCredentialWithIdentifier:self.serviceProviderIdentifier])
    {
        NSLog(@"[NAOAuth]: delete credential successfully");
    }
    else
    {
        NSLog(@"[NAOAuth]: delete credential failed");
    }
}

- (void) storeCredential
{
    NSLog(@"[NAOAuth]: try to store credential %@", _credential);
    // Persistent store credential.
    
    id securityAccessibility = nil;
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 43000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
    if( &kSecAttrAccessibleAlways != NULL )
        securityAccessibility = (__bridge id)(kSecAttrAccessibleAlways);
#endif
    
    if ([AFOAuthCredential storeCredential:_credential withIdentifier:self.serviceProviderIdentifier withAccessibility:securityAccessibility])
    {
        NSLog(@"[NAOAuth]: store credential successfully");
    }
    else
    {
        NSLog(@"[NAOAuth]: store credential failed");
    }
    
    
    AFOAuthCredential * credtential = [AFOAuthCredential retrieveCredentialWithIdentifier:self.serviceProviderIdentifier];
    NSLog(@"[NAOAuth]: credential saved %@", credtential);
}

- (void) resetAccessToken
{
    NSLog(@"[NAOAuth]: resetAccessToken %@", [self credential]);
    [self credential];
    
    if ([AFOAuthCredential deleteCredentialWithIdentifier:self.serviceProviderIdentifier])
    {
        NSLog(@"[NAOAuth]: delete credential successfully");
    }
    else
    {
        NSLog(@"[NAOAuth]: delete credential failed");
    }
    AFOAuthCredential * credential = [AFOAuthCredential credentialWithOAuthToken:nil tokenType:nil response:nil];
    [credential setRefreshToken:_credential.refreshToken expiration:[NSDate date]];
    _credential = credential;
    [self storeCredential];
}

#pragma mark - FOR NON-API LOGIN

- (NSString *)accessToken
{
    return self.credential.accessToken;
}


#pragma mark - LOG IN

- (void) authentificateWithDelegate:(id<NAOAuthLoginDelegate>)delegate
{
    NSAssert(NO, @"Subclass should implement login method");
}

- (void) authentificateWithId:(NSString *)anId secret:(NSString *)aSecret withDelegate:(id<NAOAuthLoginDelegate>)delegate
{
    NSAssert(NO, @"Subclass should implement loginWithId:secret: method");
}

#pragma mark - NOTIFICATION NAMES

- (NSString *)loginDidSucceedNotificationName
{
    NSAssert(YES, @"Super class should implement method loginDidSucceedNotificationName");
    return nil;
}

- (NSString *)loginDidFailNotificationName
{
    NSAssert(YES, @"Super class should implement method loginDidFailNotificationName");
    return nil;
}

- (NSString *)userNeedsToLogInNotificationName
{
    NSAssert(YES, @"Super class should implement method userNeedsToLogInNotificationName");
    return nil;
}

@end
