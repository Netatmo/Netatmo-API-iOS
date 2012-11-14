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

#import "NAArchivedData.h"

@interface NADeviceList : NAArchivedData

@property (nonatomic, readonly) NSString *currentDeviceId;
@property (nonatomic, readonly) NSString *currentDeviceName;


//always refering to current device
@property (nonatomic, readonly) NSArray *modulesIdList;
@property (nonatomic, readonly) NSString *currentModuleId;

+ (NADeviceList*) gDeviceList;

- (NSArray*) getDeviceIdList;
- (BOOL) hasAValidDevice;

- (NSTimeZone *)currentDeviceTimeZone;

- (NSString *)nameForDevice: (NSString *)deviceId;
- (NSString *)nameForMainModule: (NSString *)deviceId;
- (NSString *)nameForModule: (NSString *)moduleId;
- (NSString *)typeForModule: (NSString *)moduleId;

- (NSString *)deviceModuleByType: (NSString *)type;

- (BOOL)currentDeviceHasModule: (NSString *)moduleId;

-(void) setValue:(NSDictionary*) value;
-(void) reset;

@end
