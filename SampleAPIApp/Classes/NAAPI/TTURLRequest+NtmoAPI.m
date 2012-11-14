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

#import "TTURLRequest+NtmoAPI.h"

#import "NetatmoDefines.h"



@implementation TTURLRequest (NtmoAPI)

+(TTURLRequest*) postMonoPartWithURL:(NSString*)URL delegate:(id<TTURLRequestDelegate>)delegate
{
    TTURLRequest *request = [TTURLRequest requestWithURL:URL delegate:delegate];
    request.httpMethod = @"POST";
    request.multiPartForm = NO;
    [request setTimeoutInterval:NARequestTimeoutValue];
    
    return request;
}


+(TTURLRequest*) postMonoPartWithURL:(NSString*)URL delegate:(id<TTURLRequestDelegate>)delegate 
                    compulsoryParams:(NSDictionary*) compulsory 
                 withFirstParamValue:(NSString *)firstValue
                              params:(va_list) paramsList
{
    
    TTURLRequest *request = [self postMonoPartWithURL:URL delegate:delegate];
    
    NSMutableDictionary *params = request.parameters;
    
    if(compulsory != nil){
        [params addEntriesFromDictionary:compulsory];
    }
    
    for (NSString *value = firstValue; value != nil; value = va_arg(paramsList, NSString*)){
        [params setObject:value forKey:va_arg(paramsList, NSString*)];
    }
    
    NTAPRINT(@"prepared request : %@ with params :%@", request, params);
    
    return request;
}

+(TTURLRequest*) postMonoPartWithURL:(NSString*)URL delegate:(id<TTURLRequestDelegate>)delegate 
                 paramsValuesAndKeys:(NSString *)firstValue, ... 
{
    va_list args;
    va_start(args, firstValue);
    
    TTURLRequest *request = [TTURLRequest postMonoPartWithURL:URL delegate:delegate compulsoryParams:nil withFirstParamValue:firstValue params:args];
    va_end(args);
    
    return request;
}

+(TTURLRequest*) getMonoPartWithURL:(NSString*)URL delegate:(id<TTURLRequestDelegate>)delegate
{
    TTURLRequest *request = [TTURLRequest requestWithURL:URL delegate:delegate];
    request.httpMethod = @"GET";
    request.multiPartForm = NO;
    [request setTimeoutInterval:NARequestTimeoutValue];
    
    return request;
}

#pragma mark - local

- (NSString*)stringByUrlEncodingString:(NSString*) input {
    CFStringRef cfUrlEncodedString = 
    CFURLCreateStringByAddingPercentEscapes(NULL,
                                            (CFStringRef)input, (CFStringRef)@" ",
                                            (CFStringRef)@"!#$%&'()*+,/:;=?@[]",
                                            kCFStringEncodingUTF8);
    
    NSString *urlEncoded = [NSString stringWithString:(NSString *)cfUrlEncodedString];
    CFRelease(cfUrlEncodedString);
    return urlEncoded;
}


#pragma mark - override

- (NSData *)generateNonMultipartPostBody {
    NSMutableArray *paramsArray = [NSMutableArray array];
    for (id key in [_parameters keyEnumerator]) {
        NSString *value = [_parameters valueForKey:key];
        if ([key isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
            value = [self stringByUrlEncodingString:value];
            value = [value stringByReplacingOccurrencesOfString:@" " withString:@"+"];
            [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", 
                                    key, 
                                    value]];
        }
    }
    NSString *stringBody = [paramsArray componentsJoinedByString:@"&"];
    return [stringBody dataUsingEncoding:NSUTF8StringEncoding];
}

@end
