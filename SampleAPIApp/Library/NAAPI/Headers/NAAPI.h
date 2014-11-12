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

/*
 * This is the only .h file which need to be include to use the NAAPI.
 */

#import "NAOAuth.h"
#import "NAErrorCode.h"
#import "AppliCommonPublic.h"


typedef enum {
    NAAPIStateNotAuthentified,
    NAAPIStateReauthenticating,
    NAAPIStateAuthentified
} NAAPIState;

/**
 The protocol to implement in order to receive response from the NAAPI.
 */
@protocol NAAPIRequestDelegate <NSObject>

@required
-(void) apiRequestDidSucceedWithBody:(id)responseBody userInfo:(NSDictionary*) userInfo;
-(void) apiRequestDidFailWithError:(NtmoAPIErrorCode)error userInfo:(NSDictionary*) userInfo;

@end

/**
 The protocol to conform to in order to listen to login events.
 */
@protocol NAAPILogInObserverProtocol <NSObject>

@required
- (void) apiDidLogInSuccess:    (NSNotification*)notification;
- (void) apiDidLogInFailure:    (NSNotification*)notification;
- (void) userNeedToLogIn:       (NSNotification*)notification;

@end

/**
 NAAPI to send request to Netatmo servers.
 */
@interface NAAPI : NSObject <NAOAuthLoginDelegate>

@property (nonatomic, readonly, strong) NAOAuth * oAuth;

@property (nonatomic, readonly, strong) NSDate * timeServer;

/**
 Creates and returns the shared instance of NAAPI for OAuthUser.
 @return the shared instance using OAuthUser.
 */
+ (instancetype) gUserAPI;

 /**
 Sends a request to the server for method 'method' and will responds to delegate 'aDelegate'. It uses the parameters 'parameters' and identifies the request with the informations in the dictionary 'userInfo'.
 @param method the server side method as a string.
 @param aDelegate a delegate
 @param parameters parameters for the http request.
 @param userInfo a dictionary to identify the request in the call back.
 */
- (void) sendApiRequestWithMethod: (NSString*)method
                         delegate: (id<NAAPIRequestDelegate>) aDelegate
                       parameters: (NSDictionary*) parameters
                         userInfo: (NSDictionary*) userInfo;

/**
 Cancels all the pending requests fired by the delegate 'delegate'.
 @param delegate The delegate whose requests has to be canceled.
 */
- (void) cancelPendingRequestsWithDelegate:(id<NAAPIRequestDelegate>) delegate;

/**
 Cancels all the requests, pending and already sent to the server, fired by the delegate 'delegate'.
 @param delegate The delegate whose requests has to be canceled.
 */
- (void) cancelRequestsWithDelegate:(id<NAAPIRequestDelegate>) delegate;

/**
 Tries to loggin using the id 'anId' and the secret 'aSecret'.
 
 If already authentificated, it will request a new access token anyway.
 @param anId The id.
 @param aSecret The secret.
 */
- (void) loginWithId:(NSString*)anId secret:(NSString*)aSecret;

/**
 Tries to loggin using neither id or secret. Will try using requesting access token using the refresh token if there is one.
 */
- (void) login;

/**
 Logs out the current user, deleting credentials and personnal informations.
 */
- (void) logout;

/**
 Check if the user is logged in that means if current state is authentified.
 @return If YES, the user is logged in.
 */
- (BOOL) isLoggedIn;

/**
 Check if there is an account related to the app. That means if there is an refresh token saved.
 @return If YES, the user has a refresh token.
 */
- (BOOL) hasAccountRelated;

/**
 Forces correspoding oAuth to renew access token even if it is still valid (this is to get a new period of validity)  
 */
- (void) forceRefreshAuth;

/**
 To register to the login notifications. 
 @param observer The observer that will listen to login notifications.
 @warning Be sure to invoke unregisterLogInNotifications: before observer is deallocated.
 */
- (void) registerLogInNotifications:(id<NAAPILogInObserverProtocol>)observer;

/**
 To unregister to the login notifications. 
 @param observer The observer that will no longer listen to login notifications.
 */
- (void) unregisterLogInNotifications:(id<NAAPILogInObserverProtocol>)observer;

@end
