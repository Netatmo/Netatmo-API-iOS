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


#import "NAHTTPRequestOperationSaver.h"

@implementation NAHTTPRequestOperationSaver


+ (NAHTTPRequestOperationSaver*) operationSaverForMethod: (NSString*) method
                                              parameters: (NSDictionary*)parameters
                                                userInfo: (NSDictionary*)userInfo
                                                delegate: (id<NAAPIRequestDelegate>) delegate
{
    
    NAHTTPRequestOperationSaver * operationSaver = [NAHTTPRequestOperationSaver new];
    
    operationSaver.method = method;
    operationSaver.parameters = parameters;
    operationSaver.delegate = delegate;
    operationSaver.userInfo = userInfo;
    
    return operationSaver;
    
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"method %@ parameters %@", self.method, self.parameters];
}

@end
