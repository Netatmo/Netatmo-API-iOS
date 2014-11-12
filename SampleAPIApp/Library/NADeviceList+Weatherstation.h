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


#import "NetatmoDefines.h"
#import "AppliCommonPrivate.h"
#import "DataRetriever.h"

#import "NAAPI.h"
#import "NADeviceList.h"
#import "NAUser.h"

@interface NADeviceList (Weatherstation)

//always refering to current device
-(NSString *)outdoorModuleId;
-(NSString *)rainGaugeModuleId;

- (void) parseMeasuresForDashboardDataWithSuccessCompletion:(void (^)(NSString *, NSDictionary *))successCompletion
                                          failureCompletion:(void (^)(NSError *))failureCompletion;
- (BOOL)stationDataMoreRecentThan:(CGFloat) threshold;

- (BOOL)stationDataReliable;
- (BOOL)isDataReliableForModule: (NSString *)moduleId;


@end
