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


#import "NAJSONResponseSerializer.h"

@implementation NAJSONResponseSerializer

+ (instancetype)serializer {
    return [self serializerWithReadingOptions:0];
}

+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions {
    NAJSONResponseSerializer *serializer = [[self alloc] init];
    serializer.readingOptions = readingOptions;
    
    return serializer;
}

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    id JSONObject = [super responseObjectForResponse:response data:data error:error]; // may mutate `error`
    
    if (*error != nil)
    {
        NSMutableDictionary *userInfo = [(*error).userInfo mutableCopy];
        NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [userInfo setObject:responseBody forKey:kNAJSONResponseSerializerResponseBody];
        NSError *newError = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:[userInfo copy]];
        (*error) = newError;
    }
    
    return JSONObject;
}

@end
