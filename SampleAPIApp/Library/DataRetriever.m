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


#import "DataRetriever.h"


#define kDeviceMeasuresTimestamp                @"kDeviceMeasuresTimestamp"

@interface DataRetriever ()

- (void)updateDataForModuleId:(NSString*) moduleId withMeasures:(NSDictionary *)measures;
- (void)setData:(NSDictionary*)dictionary forDeviceId:(NSString *)deviceId;
- (NSDictionary*)dataForDeviceId:(NSString *)deviceId;


@property (nonatomic, readwrite, strong) SyncAssistant* syncAssistantDeviceMeasures;
@property (nonatomic, readwrite, strong) NSCalendar *calendar;
@property (nonatomic, readwrite, strong) NSMutableDictionary *deviceData;

// clue for improper use (produces compile time error)
+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

- (instancetype)initUniqueInstance;

@end


@implementation DataRetriever


- (instancetype)initUniqueInstance
{
    self = [super init];
    
    if(self)
    {
        self.deviceData = [NSMutableDictionary new];
        self.calendar = [NSCalendar currentCalendar];
        [self.calendar setTimeZone: [[NADeviceList gDeviceList] currentDeviceTimeZone]];
        
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(cancelOnGoingSync)
                                                     name: UIApplicationDidEnterBackgroundNotification
                                                   object: nil];
    }
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationDidEnterBackgroundNotification
                                                  object: nil];
}

#pragma mark -
#pragma mark Singleton

+ (instancetype) gDataRetriever
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

#pragma mark -

- (void)start
{
    if ( self.syncAssistantDeviceMeasures == nil ) /* skip run it twice */
    {
        self.syncAssistantDeviceMeasures = [[SyncAssistant alloc] initWithDelegate:self
                                                                     forDeviceType:SyncDeviceTypeWeatherStationOnly
                                                                withShouldUserSync:YES];
        [self.syncAssistantDeviceMeasures sync];
    }
}

/* SyncAssistant callback */
-(void) syncDidComplete {

    [self updateDistant];
    self.syncAssistantDeviceMeasures = nil;
}
/* SyncAssistant callback */
-(void) syncDidFail:(NtmoAPIErrorCode)error {

    self.syncAssistantDeviceMeasures = nil;
    [self.delegate dataDidFail:error];
}

- (void)updateDistant
{
    [[NADeviceList gDeviceList] parseMeasuresForDashboardDataWithSuccessCompletion:
    ^(NSString *moduleId, NSDictionary *measures)
    {
        /*
         first receive distant data so min temp, max temp are updated
         then start streaming and do not forget to schedule it on next tick
         */
        
        [self updateDataForModuleId:moduleId withMeasures: measures];
    }
                                                                 failureCompletion:
     ^(NSError *error)
    {
        [self.delegate dataDidFail:[NAErrorCode NAErrorCodeFromNSError:error]];
    }];
}


- (void)updateDataForModuleId:(NSString*) moduleId withMeasures:(NSDictionary *)newMeasures
{
    if(newMeasures == nil)
    {
        NTAWARNING(@"ERROR: nil measures");
        return;
    }
    
    
    ////// Check if current device data has already been stored
    NSDictionary *currentDevice = [self dataForDeviceId:moduleId];
    
    BOOL cacheIsEmptyForDevice  = ( currentDevice == nil) ;
    BOOL isDataNewer = NO;
    NSNumber *newDeviceMeasuresTimestamp = [newMeasures valueForKey: kDeviceMeasuresTimestamp];
    NSNumber *oldDeviceMeasuresTimestamp = [currentDevice valueForKey: kDeviceMeasuresTimestamp];

    if (![newDeviceMeasuresTimestamp isKindOfClass:[NSNumber class]])
    {
        isDataNewer = NO;
    }
    else if (![oldDeviceMeasuresTimestamp isKindOfClass:[NSNumber class]])
    {
        isDataNewer = YES;
    }
    else
    {
        isDataNewer = [oldDeviceMeasuresTimestamp compare:newDeviceMeasuresTimestamp] == NSOrderedAscending;
    }
    
        
    NTAPRINT(@"Data stored for timestamp:%@ ,isDataIsNewer:%d , cacheIsEmptyForDevice:%d, mac:%@"
             , [newMeasures valueForKey: kDeviceMeasuresTimestamp]
             , isDataNewer
             , cacheIsEmptyForDevice
             , moduleId
             );
    
    ///// Store data
    if(cacheIsEmptyForDevice)
    {
        [self setData:newMeasures forDeviceId:moduleId];
    }
    else if(isDataNewer)
    {

        NSMutableDictionary *currentDeviceMutableCopy = [currentDevice mutableCopy];
        
        
        /*
         erase min temperature and max temperature values from last stored data if they do not match the current day
         thus if we are receiving data from server, they will be rewritten anyway
         and if we are receiving data from streaming, there won't be invalid data
         */
        NSDateComponents *dateComponents = [self.calendar components: NSCalendarUnitDay
                                                            fromDate: [NSDate dateWithTimeIntervalSince1970: [((NSNumber *)[currentDeviceMutableCopy valueForKey: kDeviceMeasuresTimestamp]) longValue]]
                                                              toDate: [NSDate dateWithTimeIntervalSince1970: [((NSNumber *)[newMeasures valueForKey: kDeviceMeasuresTimestamp]) longValue]]
                                                             options: 0];
        

        if([dateComponents day] >= 1)
        {
            [currentDeviceMutableCopy removeObjectForKey: NAAPIMinTemp];
            [currentDeviceMutableCopy removeObjectForKey: NAAPIMaxTemp];
            /*We won't do the same thing for particles;;; we really need to have some data for it to be displayed correctly*/
        }
        
        
        

        NSArray *keys = [newMeasures allKeys];
        for(id key in keys)
        {
            [currentDeviceMutableCopy setObject: [newMeasures objectForKey: key]
                                         forKey: key];
        }
        

        [self setData:currentDeviceMutableCopy forDeviceId:moduleId];
    }
    
    [self.delegate dataDidUpdateForDevice: moduleId];
    
}


- (void) cancelOnGoingSync
{
    if (self.syncAssistantDeviceMeasures) {
        [self.syncAssistantDeviceMeasures cancelOnGoingSync];
    }
    self.syncAssistantDeviceMeasures = nil;
}


#pragma mark - Measures dashboard cache handling

-(NSDictionary *)getMeasuresForDeviceId: (NSString *)deviceId
{
    return [self dataForDeviceId:deviceId];
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
        default:
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
        default:
            //Not supposed to be in data handler dictionaries
            break;
    }
    
    if(value == nil || [value isKindOfClass: [NSString class]])
        return nil;
    
    return value;
}

+(void) setDateTimestamp:(NSNumber*)dateTimestamp forMeasureDict:(NSDictionary*) measureDict
{
    [measureDict setValue:dateTimestamp forKey:kDeviceMeasuresTimestamp];
}

-(void)setData:(NSDictionary*)dictionary forDeviceId:(NSString *)deviceId
{
    if (![deviceId isKindOfClass:[NSString class]] || ![dictionary isKindOfClass:[NSDictionary class]])
    {
        return;
    }
    
    [self.deviceData setValue:dictionary forKey:deviceId];
}

-(NSDictionary*)dataForDeviceId:(NSString *)deviceId
{
    if (![deviceId isKindOfClass:[NSString class]])
    {
        return nil;
    }
    
    return [self.deviceData valueForKey:deviceId];
}

- (BOOL)stationDataReliable
{
    BOOL deviceListReliable = [[NADeviceList gDeviceList] stationDataReliable];
    
    NSDictionary *stationMeasures = [self getMeasuresForDeviceId: [[NADeviceList gDeviceList] currentDeviceId]];
    return (deviceListReliable && [stationMeasures isKindOfClass:[NSDictionary class]]);
}

- (BOOL)isDataReliableForModule: (NSString *)moduleId
{
    BOOL deviceListReliable = [[NADeviceList gDeviceList] isDataReliableForModule:moduleId];
    
    NSDictionary *moduleMeasures = [self getMeasuresForDeviceId: moduleId];
    return (deviceListReliable && [moduleMeasures isKindOfClass:[NSDictionary class]]);
}


@end
