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


@interface TTURLRequest (NtmoAPI)

+(TTURLRequest*) postMonoPartWithURL:(NSString*)URL delegate:(id<TTURLRequestDelegate>)delegate;

+(TTURLRequest*) postMonoPartWithURL:(NSString*)URL delegate:(id<TTURLRequestDelegate>)delegate 
                    compulsoryParams:(NSDictionary*) compulsory 
                 withFirstParamValue:(NSString *)firstValue
                              params:(va_list) paramsList;

+(TTURLRequest*) postMonoPartWithURL:(NSString*)URL delegate:(id<TTURLRequestDelegate>)delegate 
                 paramsValuesAndKeys:(NSString *)firstValue, ... NS_REQUIRES_NIL_TERMINATION;

+(TTURLRequest*) getMonoPartWithURL:(NSString*)URL delegate:(id<TTURLRequestDelegate>)delegate;
@end
