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


#import "NAArchivedData.h"

typedef enum{
    NADeviceListHistoryNew,  /*Has never had a device - or been reseted*/
    NADeviceListHistoryInvitedOnly, /*has had devices, bot only as a guest */
    NADeviceListHistoryOwned /*has already owned a deice*/
}NADeviceListHistory;

@interface NADeviceList : NAArchivedData

+ (instancetype) gDeviceList;

- (NSArray *)deviceList;
- (NSArray *)moduleList;
- (NSDictionary *)currentDevice;

- (NSString *)currentDeviceId;
- (NSString *)currentDeviceName;


//always refering to current device
- (NSArray *)modulesIdList;


- (NSArray*) getDeviceIdList;
- (BOOL) hasAValidDeviceWithPlace;
- (BOOL) hasAValidDevice;

- (NSTimeZone *)currentDeviceTimeZone;

- (NSString *)nameForDevice: (NSString *)deviceId;
- (NSString *)nameForModule: (NSString *)moduleId;
- (NSString *)typeForModule: (NSString *)moduleId;

- (NSArray *)deviceModulesByType: (NSString *)type;


-(void) setValue:(NSDictionary*) value;
-(void) reset;


-(BOOL) hasOnlyReadOnlyDevices;


- (BOOL)changeCurrentDeviceIfIdExists: (NSString*) newDeviceId;

@end
