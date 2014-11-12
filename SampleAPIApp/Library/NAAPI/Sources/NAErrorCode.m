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

#import "NAErrorCode.h"

NSString * const kNAAPIErrorDomain = @"NAAPIErrorDomain";

@implementation NAErrorCode

+ (NtmoAPIErrorCode) NAErrorCodeFromNSError:(NSError*)error
{
    
    // Under kNAJSONResponseSerializerResponseBody you might find the body of the error response.
    // If it is an Oauth response you will find @"{ "error" : "the string error" }"
    // If it is a Netatmo error you will find @"{ "error" : { "code" : [error code int] , "message" : "message error" } }"
    // We need to parse it net in order to avoid unexpected crashes.
    
    NSString * responseBody = [error.userInfo objectForKey:kNAJSONResponseSerializerResponseBody];
    
    if (responseBody == nil)
    {
        
        if ([error.domain isEqualToString:kNAAPIErrorDomain])
        {
            return (NtmoAPIErrorCode) error.code;
        }
        
        if ([error.domain isEqualToString:@"NSURLErrorDomain"]) {
            
            switch (error.code)
            {
                case -1018:
                case -1009:
                case -1001:
                case -1005:
                case -1004:
                    return NtmoAPIErrorCodeNoDataConnection;
                    
            }
            
        }
        
        if ([error.domain isEqualToString:@"AFNetworkingErrorDomain"])
        {
            switch (error.code)
            {
                case -1011:
                    return NtmoAPIErrorCodeInvalidAccessToken;
                    
            }
        }
        
        return NtmoAPIErrorCodeUnknown;
    }
    
    NSData *data = [responseBody dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    if ([json isKindOfClass:[NSDictionary class]] == NO)
    {
        return NtmoAPIErrorCodeUnknown;
    }
    
    
    if ([json objectForKey:@"error"] && [[json objectForKey:@"error"] isKindOfClass:[NSString class]])
    {
        
        // Oauth response
        
        if ([[json objectForKey:@"error"] isEqualToString:@"invalid_grant"])
        {
            return NtmoAPIErrorCodeOauthInvalidGrant;
        }
        if ([[json objectForKey:@"error"] isEqualToString:@"invalid_request"])
        {
            return NtmoAPIErrorCodeUnknown;
        }
    }
    
    if ([json objectForKey:@"error"] && [[json objectForKey:@"error"] isKindOfClass:[NSDictionary class]] && [[json objectForKey:@"error"] objectForKey:@"code"])
    {
        // Netatmo error
        
        return [[[json objectForKey:@"error"] objectForKey:@"code"] intValue];
    }
    
    return NtmoAPIErrorCodeUnknown;
}


+ (NtmoAPIErrorCode) NAErrorCodeFromNAAPINotificationsUserInfo:(NSDictionary *)userInfo
{
    return [[userInfo objectForKey:@"error"] intValue];
}

+ (NSError *) NSErrorFromNAErrorCode: (NtmoAPIErrorCode)code
{
    return [NSError errorWithDomain: kNAAPIErrorDomain
                               code: code
                           userInfo: nil];
}


+ (NSString *)NAErrorCodeDescription:(NtmoAPIErrorCode)code
{
    switch (code) {
        case NtmoAPIErrorCodeInvalidAccessToken:
            return @"NtmoAPIErrorCodeInvalidAccessToken";
        case NtmoAPIErrorCodeNoDataConnection:
            return @"NtmoAPIErrorCodeNoDataConnection";
        case NtmoAPIErrorCodeUserNeedToLogIn:
            return @"NtmoAPIErrorCodeUserNeedToLogIn";
        case NtmoAPIErrorCodeInvalidArg:
            return @"NtmoAPIErrorCodeInvalidArg";
        case NtmoAPIErrorCodeAccessTokenExpired:
            return @"NtmoAPIErrorCodeAccessTokenExpired";
        case NtmoAPIErrorCodeAccessTokenMissing:
            return @"NtmoAPIErrorCodeAccessTokenMissing";
        case NtmoAPIErrorCodeAlreadyDeviceOwner:
            return @"NtmoAPIErrorCodeAlreadyDeviceOwner";
        case NtmoAPIErrorCodeApplicationDeactivated:
            return @"NtmoAPIErrorCodeApplicationDeactivated";
        case NtmoAPIErrorCodeApplicationNameAlreadyExists:
            return @"NtmoAPIErrorCodeApplicationNameAlreadyExists";
        case NtmoAPIErrorCodeApplicationNotFound:
            return @"NtmoAPIErrorCodeApplicationNotFound";
        case NtmoAPIErrorCodeBadMgtKey:
            return @"NtmoAPIErrorCodeBadMgtKey";
        case NtmoAPIErrorCodeBadPassword:
            return @"NtmoAPIErrorCodeBadPassword";
        case NtmoAPIErrorCodeDeviceIdAlreadyExists:
            return @"NtmoAPIErrorCodeDeviceIdAlreadyExists";
        case NtmoAPIErrorCodeDeviceNotFound:
            return @"NtmoAPIErrorCodeDeviceNotFound";
        case NtmoAPIErrorCodeDeviceOrSecretNoMatch:
            return @"NtmoAPIErrorCodeDeviceOrSecretNoMatch";
        case NtmoAPIErrorCodeEmailAlreadyExists:
            return @"NtmoAPIErrorCodeEmailAlreadyExists";
        case NtmoAPIErrorCodeForceAssociate:
            return @"NtmoAPIErrorCodeForceAssociate";
        case NtmoAPIErrorCodeInconsistencyError:
            return @"NtmoAPIErrorCodeInconsistencyError";
        case NtmoAPIErrorCodeInternalError:
            return @"NtmoAPIErrorCodeInternalError";
        case NtmoAPIErrorCodeInvalidDate:
            return @"NtmoAPIErrorCodeInvalidDate";
        case NtmoAPIErrorCodeInvalidEmail:
            return @"NtmoAPIErrorCodeInvalidEmail";
        case NtmoAPIErrorCodeInvalidIp:
            return @"NtmoAPIErrorCodeInvalidIp";
        case NtmoAPIErrorCodeInvalidRefreshToken:
            return @"NtmoAPIErrorCodeInvalidRefreshToken";
        case NtmoAPIErrorCodeInvalidTimezone:
            return @"NtmoAPIErrorCodeInvalidTimezone";
        case NtmoAPIErrorCodeIpNotFound:
            return @"NtmoAPIErrorCodeIpNotFound";
        case NtmoAPIErrorCodeMaxUsageReached:
            return @"NtmoAPIErrorCodeMaxUsageReached";
        case NtmoAPIErrorCodeMeasureAlreadyExists:
            return @"NtmoAPIErrorCodeMeasureAlreadyExists";
        case NtmoAPIErrorCodeMgtKeyMissing:
            return @"NtmoAPIErrorCodeMgtKeyMissing";
        case NtmoAPIErrorCodeMissingArgs:
            return @"NtmoAPIErrorCodeMissingArgs";
        case NtmoAPIErrorCodeModuleAlreadyPaired:
            return @"NtmoAPIErrorCodeModuleAlreadyPaired";
        case NtmoAPIErrorCodeNoPlacesInDevice:
            return @"NtmoAPIErrorCodeNoPlacesInDevice";
        case NtmoAPIErrorCodeNotFound:
            return @"NtmoAPIErrorCodeNotFound";
        case NtmoAPIErrorCodeNothingToModify:
            return @"NtmoAPIErrorCodeNothingToModify";
        case NtmoAPIErrorCodeOauthInvalidGrant:
            return @"NtmoAPIErrorCodeOauthInvalidGrant";
        case NtmoAPIErrorCodeOauthOther:
            return @"NtmoAPIErrorCodeOauthOther";
        case NtmoAPIErrorCodeOperationForbidden:
            return @"NtmoAPIErrorCodeOperationForbidden";
        case NtmoAPIErrorCodeSuccess:
            return @"NtmoAPIErrorCodeSuccess";
        case NtmoAPIErrorCodeTooManyUserWithIp:
            return @"NtmoAPIErrorCodeTooManyUserWithIp";
        case NtmoAPIErrorCodeUnableToExecute:
            return @"NtmoAPIErrorCodeUnableToExecute";
        case NtmoAPIErrorCodeUnknown:
            return @"NtmoAPIErrorCodeUnknown";
        case NtmoAPIErrorCodeUserNotFound:
            return @"NtmoAPIErrorCodeUserNotFound";
        default:
            return @"None registered error code";
            
    }
}


@end
