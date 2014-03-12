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
#import "extThree20JSON/extThree20JSON.h"
#import "Reachability.h"

#import "AppliCommonPublic.h"
#import "NAOAuth.h"

#define NA_CACHE_EXPIRATION_NO_CACHE 0

extern NSString *const kNAAPIErrorDomain;

extern NSString *const NAAPINotReachableNotification;
extern NSString *const NAAPIIsReachableNotification;

typedef enum {
    NAAPIStateNoDataConnection,
    NAAPIStateNotAuthentified,
    NAAPIStateReauthenticating,
    NAAPIStateAuthentified
} NAAPIState;

@protocol NAAPIRequestDelegate <NSObject>

@required
-(void) apiRequestDidSucceedWithBody:(id)responseBody userInfo:(NSDictionary*) ourUserInfo;
-(void) apiRequestDidFailWithError:(NtmoAPIErrorCode)error userInfo:(NSDictionary*) ourUserInfo;

@end



@interface NAAPI : NSObject <TTURLRequestDelegate>
{
    @private
    NAAPIState _state;
    
    NAOAuth *_oAuth;
    
    NSMutableArray *_pendingRequests;
}

+ (id<NAAPIRequestDelegate>) getDelegateFromAPIRequestUserInfo:(NSDictionary*) userInfo;
+ (NSDictionary*) getDictionaryFromAPIRequestUserInfo:(TTUserInfo*) userInfo;
+ (NtmoAPIErrorCode) getErrorCodeFromResponse:(TTURLJSONResponse *)response;
+ (NSString *) stringFromErrorCode:(NtmoAPIErrorCode) errCode;

+(BOOL) loginFailNotification:(NSNotification*) aNotification 
              isCausedByError:(NtmoAPIErrorCode) errorCode;

+(id) bodyFromOkResponse: (TTURLJSONResponse *) response;

+(NSString*) urlForMethod:(NSString*) method;

+ (NAAPI*) gUserAPI: (NSString*) scope;

+(TTURLRequest*) apiRequestWithMethod:(NSString *)method
                   cacheExpirationAge:(NSTimeInterval) expirationAge
                          addUserInfo:(NSDictionary *)userInfoDict 
                  paramsValuesAndKeys:(NSString *)firstValue, ... NS_REQUIRES_NIL_TERMINATION;

-(void) sendApiRequest:(TTURLRequest*) request
              delegate:(id<NAAPIRequestDelegate>) aDelegate;

-(void) sendApiRequestWithMethod:(NSString *)method
                        delegate:(id<NAAPIRequestDelegate>) aDelegate
              cacheExpirationAge:(NSTimeInterval) expirationAge
                     addUserInfo: (NSDictionary*) userInfoDict
             paramsValuesAndKeys:(NSString *)firstValue, ... NS_REQUIRES_NIL_TERMINATION;

/*Cancel unsend requests only (they haven't been sent to Three20 Network core )*/
-(void) cancelPendingRequestsWithDelegate:(id<NAAPIRequestDelegate>) delegate;

-(void) cancelRequestsWithDelegate:(id<NAAPIRequestDelegate>) delegate;

- (void) login;
- (void) loginWithId:(NSString*)anId secret:(NSString*)aSecret;

@property (nonatomic, readonly) NAOAuth *oAuthHandler;

@end
