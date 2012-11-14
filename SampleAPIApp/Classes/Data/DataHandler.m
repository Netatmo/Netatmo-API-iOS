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


#import "DataHandler.h"

#import "NetatmoDefines.h"
#import "AppliCommonPrivate.h"
#import "NAUserDataStorer.h"


@implementation DataHandler

@synthesize enabled             = _enabled;
@synthesize type                = _type;

@synthesize delegate            = _delegate;

@synthesize nextUpdateTimerTick = _nextUpdateTimerTick;

@synthesize refreshInterval     = _refreshInterval;

@synthesize retryMax            = _retryMax;
@synthesize retryNumber         = _retryNumber;
@synthesize retryInterval       = _retryInterval;



- (id)initWithDelegate: (id<DataHandlerDelegate>)delegate
{
    self = [super init];
    
    if(self)
    {
        _enabled = NO;
        _type = kDataHandlerTypeDefault;
        
        self.delegate = delegate;
        
        _nextUpdateTimerTick = 0;
        
        _refreshInterval = 0;
        
        _retryMax = 0;
        _retryNumber = 0;
        _retryInterval = 0;
    }
    
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    
    [super dealloc];
}



- (void)start
{
    _enabled = YES;
    [self reset];
}


- (void)stop
{
    _enabled = NO;
}

- (void)reset
{
    _retryNumber = 0;
    _nextUpdateTimerTick = 0;
}


- (void)hookDeviceById: (NSString *)deviceId
{
    _retryNumber++;
}

+ (NSDictionary *)getMeasuresForDeviceId: (NSString *)deviceId
{
    NSDictionary *result = nil;
    
    for(NSDictionary *device in [[NAUserDataStorer gUserDataStorer] getUserDataForKey: kUDDeviceMeasures])
    {
        NSLog(@"device: %@", device);
        if([[device objectForKey: kDeviceMeasuresDeviceId] isEqualToString: deviceId])
        {
            result = device;
        }
    }
    
    return result;
}

+ (void)setValue: (id)value 
         forType: (NAMeasureType)type 
    inDictionary: (NSMutableDictionary *) dictionary
{
    if(dictionary == nil)
        return;
    
    if([value isKindOfClass: [NSNull class]])
    {
        value = kUserDefaultNullValue;
    }
    
    switch(type)
    {
        case NAMeasureTypeTemperature:
        {
            [dictionary setValue: value 
                          forKey: NAAPITemperature];
            break;
        }
            
        case NAMeasureTypeHumidity:
        {
            [dictionary setValue: value 
                          forKey: NAAPIHumidity];
            break;
        }
            
        case NAMeasureTypePressure:
        {
            [dictionary setValue: value 
                          forKey: NAAPIPressure];
            break;
        }
            
        case NAMeasureTypeCO2:
        {
            [dictionary setValue: value 
                          forKey: NAAPICo2];
            break;
        }
            
        case NAMeasureTypeTemperatureMin:
        {
            [dictionary setValue: value 
                          forKey: NAAPIMinTemp];
            break;
        }
            
        case NAMeasureTypeTemperatureMax:
        {
            [dictionary setValue: value 
                          forKey: NAAPIMaxTemp];
            break;
        }
        case NAMeasureTypeNoise:
        {
            [dictionary setValue: value 
                          forKey: NAAPINoise];
            break;
        }
        
        case NAMeasureTypeUnknown:
            break;
    }
}

+ (id)valueForType: (NAMeasureType)type 
      inDictionary: (NSDictionary *) dictionary
{
    if(dictionary == nil)
    return nil;
    
    id value = nil;
    switch(type)
    {
        case NAMeasureTypeTemperature:
        {
            value = [dictionary valueForKey: NAAPITemperature];
            break;
        }
            
        case NAMeasureTypeHumidity:
        {
            value = [dictionary valueForKey: NAAPIHumidity];
            break;
        }
            
        case NAMeasureTypePressure:
        {
            value = [dictionary valueForKey: NAAPIPressure];
            break;
        }
            
        case NAMeasureTypeCO2:
        {
            value = [dictionary valueForKey: NAAPICo2];
            break;
        }
            
        case NAMeasureTypeTemperatureMin:
        {
            value = [dictionary valueForKey: NAAPIMinTemp];
            break;
        }
            
        case NAMeasureTypeTemperatureMax:
        {
            value = [dictionary valueForKey: NAAPIMaxTemp];
            break;
        }
            
        case NAMeasureTypeNoise:
        {
            value = [dictionary valueForKey: NAAPINoise];
            break;
        }
            
        case NAMeasureTypeUnknown:
            break;
    }
    
    if(value == nil || [value isKindOfClass: [NSString class]])
        return nil;
    
    return value;
}

+(NSDate*) dateForMeasureDict:(NSDictionary*) measureDict
{
    NSNumber *timestamp = [measureDict valueForKey:kDeviceMeasuresTimestamp];
    if (nil != timestamp) {
        return [NSDate dateWithTimeIntervalSince1970:[timestamp longValue]];
    }
    
    return nil;
}

+(NSString*) dataHandlerTypeForMeasureDict:(NSDictionary*) measureDict
{
    return [measureDict valueForKey:kDeviceMeasuresDataHandlerType];
}


- (NSDictionary *)parseMeasures: (id)measureArray
                       userInfo: (NSDictionary *)userInfo
{
    NTAPRINT(@"[NOT IMPLEMENTED]");
    return nil;
}



#pragma mark - DEBUG -

- (NSDictionary *)getFakeMeasuresForDevice: (NSString *)deviceId
{
    NSMutableDictionary *measures = [NSMutableDictionary dictionary];
    
    NSNumber *timestamp = [NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]];
    
    NSNumber *temperature = [NSNumber numberWithInt: (int)((((float)rand() / (float)RAND_MAX) * 60.0f) - 20.0f)];
    NSNumber *humidity = [NSNumber numberWithInt: (int)(((float)rand() / (float)RAND_MAX) * 100.0f)];
    NSNumber *noise = [NSNumber numberWithInt: (int)(((float)rand() / (float)RAND_MAX) * 40.0f)];
    
    [measures setObject: deviceId forKey: kDeviceMeasuresDeviceId];
    [measures setObject: timestamp forKey: kDeviceMeasuresTimestamp];
    [measures setObject: temperature forKey: [[NSNumber numberWithInt: 0] stringValue]];
    [measures setObject: humidity forKey: [[NSNumber numberWithInt: 1] stringValue]];
    [measures setObject: noise forKey: [[NSNumber numberWithInt: 7] stringValue]];
    
    return measures;
}



@end
