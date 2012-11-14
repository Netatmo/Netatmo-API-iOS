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
#import "DataHandlerDelegate.h"

#import "NAMeasure.h"



#define kDeviceMeasuresDeviceId         @"kDeviceMeasuresDeviceId"
#define kDeviceMeasuresTimestamp        @"kDeviceMeasuresTimestamp"
#define kDeviceMeasuresDataHandlerType  @"kDeviceMeasuresDataHandlerType"


#define kDataHandlerTypeDefault         @"kDataHandlerTypeDefault"
#define kDataHandlerTypeDistant         @"kDataHandlerTypeDistant"


@interface DataHandler : NSObject
{
    BOOL _enabled;
    NSString *_type;
    
    id<DataHandlerDelegate> _delegate;
    
    int _nextUpdateTimerTick;
    
    int _refreshInterval;
    
    int _retryMax;
    int _retryNumber;
    int _retryInterval;
}


- (id)initWithDelegate: (id<DataHandlerDelegate>)delegate;

- (void)start;
- (void)stop;
- (void)reset;

- (void)hookDeviceById: (NSString *)deviceId;

- (NSDictionary *)parseMeasures: (id)measureArray
                       userInfo: (NSDictionary *)userInfo;

+ (NSDictionary *)getMeasuresForDeviceId: (NSString *)deviceId;
+ (void)setValue: (id)value 
         forType: (NAMeasureType)type 
    inDictionary: (NSMutableDictionary *) dictionary;
+ (id)valueForType: (NAMeasureType)type 
      inDictionary: (NSDictionary *) dictionary;
+(NSDate*) dateForMeasureDict:(NSDictionary*) measureDict;
+(NSString*) dataHandlerTypeForMeasureDict:(NSDictionary*) measureDict;


@property (nonatomic, readonly, assign)     BOOL enabled;
@property (nonatomic, readonly, retain)     NSString *type;

@property (nonatomic, readwrite, assign)    id<DataHandlerDelegate> delegate;

@property (nonatomic, readwrite, assign)    int nextUpdateTimerTick;

@property (nonatomic, readonly, assign)    int refreshInterval;

@property (nonatomic, readonly, assign)    int retryMax;
@property (nonatomic, readonly, assign)    int retryNumber;
@property (nonatomic, readonly, assign)    int retryInterval;


@end
