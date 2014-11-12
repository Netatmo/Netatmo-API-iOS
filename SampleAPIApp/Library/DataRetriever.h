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


#import "SyncAssistant.h"

#import "NAUserDataStorer.h"
#import "NAUserDataKeys.h"
#import "NAMeasure.h"
#import "NAMultiKeyArchivedData.h"
#import "NetatmoDefines.h"

#import "NADeviceList+Weatherstation.h"
#import "NAUser.h"

#import "NAUserDataKeys.h"


@protocol DataRetrieverDelegate

- (void)dataDidUpdateForDevice: (NSString *)deviceId;
- (void)dataDidFail:(NtmoAPIErrorCode)error;

@end


@interface DataRetriever : NSObject <SyncAssistantDelegate>

+(instancetype) gDataRetriever;

@property (nonatomic, readwrite, weak) id<DataRetrieverDelegate> delegate;

- (void)start;

- (NSDictionary *)getMeasuresForDeviceId: (NSString *)deviceId;
+ (void)setValue: (id)value
         forType: (NAMeasureType)type
    inDictionary: (NSMutableDictionary *) dictionary;
+ (id)valueForType: (NAMeasureType)type
      inDictionary: (NSDictionary *) dictionary;
+(void) setDateTimestamp:(NSNumber*)dateTimestamp forMeasureDict:(NSDictionary*) measureDict;

- (BOOL)stationDataReliable;
- (BOOL)isDataReliableForModule: (NSString *)moduleId;

- (void) cancelOnGoingSync;

@end
