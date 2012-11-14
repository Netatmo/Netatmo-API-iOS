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


#import <Foundation/Foundation.h>

/* shared keys - used in several classes*/

extern NSString * const kUDCurrentDevice;
extern NSString * const kUDDeviceList;
extern NSString * const kUDDeviceMeasures;
extern NSString * const kUDUser;
extern NSString * const kUDLastCacheWipeDate;



extern NSString * const NAUDCurrentDeviceNotification;
extern NSString * const NAUDDeviceListNotification;
extern NSString * const NAUDUserNotification;


extern NSString * const kUDRefreshToken;

#define kUserDefaultNullValue   @"-"


@interface NAUserDataStorer : NSObject

+ (NAUserDataStorer*) gUserDataStorer;

-(void) storeData:(id)data forKey:(NSString*) key;
-(id) getUserDataForKey:(NSString*) key;
-(void) removeUserDataForKey:(NSString*) key;

@end
