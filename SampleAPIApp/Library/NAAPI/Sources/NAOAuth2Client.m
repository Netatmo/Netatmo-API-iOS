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
#import "NAJSONResponseSerializer.h"


@interface NAOAuth2Client ()
@property (readonly, nonatomic) NSString *clientID;
@property (readwrite, nonatomic) NSString *secret;
@end

@implementation NAOAuth2Client


- (void)authenticateUsingOAuthWithURLString:(NSString *)urlString
                                 parameters:(NSDictionary *)parameters
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure
{
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [mutableParameters setObject:self.clientID forKey:@"client_id"];
    [mutableParameters setValue:self.secret forKey:@"client_secret"];
    parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
    
    self.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    NSMutableURLRequest *mutableRequest = [self.requestSerializer requestWithMethod:@"POST" URLString:urlString parameters:parameters error:nil];
    [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:mutableRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject valueForKey:@"error"]) {
            if (failure) {
                // TODO: Resolve the `error` field into a proper NSError object
                // http://tools.ietf.org/html/rfc6749#section-5.2
                failure(nil);
            }
            
            return;
        }
        
        NSString *refreshToken = [responseObject valueForKey:@"refresh_token"];
        if (refreshToken == nil || [refreshToken isEqual:[NSNull null]]) {
            refreshToken = [parameters valueForKey:@"refresh_token"];
        }
        
        AFOAuthCredential *credential = [AFOAuthCredential credentialWithOAuthToken:[responseObject valueForKey:@"access_token"] tokenType:[responseObject valueForKey:@"token_type"] response:responseObject];
        
        NSDate *expireDate = nil;
        id expiresIn = [responseObject valueForKey:@"expires_in"];
        if (expiresIn != nil && ![expiresIn isEqual:[NSNull null]]) {
            expireDate = [NSDate dateWithTimeIntervalSinceNow:[expiresIn doubleValue]];
        }
        
        [credential setRefreshToken:refreshToken expiration:expireDate];
        
        [self setAuthorizationHeaderWithCredential:credential];
        
        if (success) {
            success(credential);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    
    // Add this line to change default response serializer object. Otherwise method is identical to AFNetworking framework one.
    requestOperation.responseSerializer = [NAJSONResponseSerializer serializer];
    
    [requestOperation start];
}

@end