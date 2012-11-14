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


#import "DataRetriever.h"
#import "NetatmoDefines.h"

#import "AppliCommonPrivate.h"
#import "NADeviceList.h"
#import "NAUser.h"

#import "NAReachability.h"





@interface DataRetriever ()

- (void)reachabilityChanged: (NSNotification *)notification;

- (void)switchToLocalDataMode;
- (void)switchToDistantDataMode;

- (void)update;
- (void)updateDistant;

- (int)computeNextTimerTick: (int)interval;

- (void)updateData: (NSDictionary *)measures;

@end


@implementation DataRetriever

@synthesize delegate = _delegate;

@synthesize mode = _mode;



- (id)initWithDelegate: (id<DataRetrieverDelegate>)delegate
{
    self = [super init];
    
    if(self)
    {
        self.delegate = delegate;
        
        _calendar = [[NSCalendar currentCalendar] retain];
        [_calendar setTimeZone: [[NADeviceList gDeviceList] currentDeviceTimeZone]];
        
        _distantDataHandler = [[DistantDataHandler alloc] initWithDelegate: self];
            
        [self switchToLocalDataMode];
    }
    
    return self;
}


- (void)dealloc
{
    [_distantDataHandler setDelegate: nil];
    NTA_RELEASE_SAFELY(_distantDataHandler);
    
    NTA_RELEASE_SAFELY( _calendar);
    
    self.delegate = nil;
    
    [super dealloc];
}

- (void)reachabilityChanged: (NSNotification *)notification
{
    Reachability *currentReach = [notification.userInfo valueForKey:kReachabilityNotificationUserInfoReach];
    
    switch ([currentReach currentReachabilityStatus]) {
        case NotReachable:
        {
            /* this has been commented for the dashboard no network indicator to work (it *looks like* it is useless anyway, with streaming off)
            [self stop];
             */
            break;
        }
        case ReachableViaWiFi:
        case ReachableViaWWAN:
        {
            //Restart
            [self stop];
            [self start];
            break;
        }
     }
}

- (void)start
{
    [_distantDataHandler start];
    
    // Start a timer that will schedule updates
    // In this version, it will only fire once
    if(_timer == nil)
    {
        _timer = [[NSTimer scheduledTimerWithTimeInterval: 1 
                                                   target: self 
                                                 selector: @selector(update) 
                                                 userInfo: nil 
                                                  repeats: YES] retain];
    }
    _timerTick = 0;
    
    _numberOfTickSinceLastReceivedData = 0;
}

- (void)stop
{
    [_timer invalidate];
    NTA_RELEASE_SAFELY(_timer);
    
    [self switchToLocalDataMode];
}


- (void)update
{
    _numberOfTickSinceLastReceivedData++;
    
    if(_distantDataHandler.enabled)
        [self updateDistant];
    
    if(!_distantDataHandler.enabled)
        [self stop];
    
    if(_timerTick < DR_TIMER_TICK_MAX)
        _timerTick++;
    else
        _timerTick = 0;
}


- (void)updateDistant
{
    if(_distantDataHandler.nextUpdateTimerTick != _timerTick)
        return;
    
    if(_mode == DataRetrieverModeDistant)
    {
        // Start retrieving data for the indoor module
        [_distantDataHandler hookDeviceById: [[NADeviceList gDeviceList] currentDeviceId]];
        
        
        // Start retrieving data for the outdoor module
        [_distantDataHandler hookModuleById: [[NADeviceList gDeviceList] currentModuleId]
                             fromDeviceById:[[NADeviceList gDeviceList] currentDeviceId]];

        _distantDataHandler.nextUpdateTimerTick = [self computeNextTimerTick: _distantDataHandler.refreshInterval];
    }
    else if(_distantDataHandler.retryNumber < _distantDataHandler.retryMax)
    {
        [_distantDataHandler hookDeviceById: [[NADeviceList gDeviceList] currentDeviceId]];
        [_distantDataHandler hookModuleById: [[NADeviceList gDeviceList] currentModuleId]
                             fromDeviceById:[[NADeviceList gDeviceList] currentDeviceId]];
        
        _distantDataHandler.nextUpdateTimerTick = [self computeNextTimerTick: _distantDataHandler.retryInterval];
    }
    else
    {
        // we do not reset when retryNumber == 0 as we still want to wait for a possible incoming response
        [_distantDataHandler reset];
        _distantDataHandler.nextUpdateTimerTick = [self computeNextTimerTick: (_distantDataHandler.refreshInterval - _distantDataHandler.retryInterval)];
    }
}


- (int)computeNextTimerTick: (int)interval
{
    if(interval < 0)
        return -1;
    return ((_timerTick + interval) % DR_TIMER_TICK_MAX);
}


- (void)switchToLocalDataMode
{
    if(_distantDataHandler.enabled)
        [_distantDataHandler stop];
    
    _mode = DataRetrieverModeLocal;
}


- (void)switchToDistantDataMode
{
    _distantDataHandler.nextUpdateTimerTick = [self computeNextTimerTick: _distantDataHandler.refreshInterval];
    _mode = DataRetrieverModeDistant;
    
    if(_distantDataHandler.enabled)
        [_distantDataHandler stop];
}


- (void)updateData: (NSDictionary *)measures
{
    if(measures == nil)
    {
        NTAWARNING(@"ERROR: nil measures");
        return;
    }
    
    NSMutableArray *data = [[[[NAUserDataStorer gUserDataStorer] getUserDataForKey: kUDDeviceMeasures] mutableCopy] autorelease];
    if(data == nil)
    {
        data = [NSMutableArray array];
    }
    
    ////// Check if current device data has already been stored
    NSDictionary *currentDevice = nil;
    NSString *currentDeviceId = [measures objectForKey: kDeviceMeasuresDeviceId];
    for(NSMutableDictionary *device in data)
    {
        if([[device objectForKey: kDeviceMeasuresDeviceId] isEqualToString: currentDeviceId])
        {
            currentDevice = device;
            break;
        }
    }
    
    ///// Store data
    if(currentDevice == nil)
    {
        [data addObject: measures];
        
        [[NAUserDataStorer gUserDataStorer] storeData: data 
                                               forKey: kUDDeviceMeasures];
        
        NTAPRINT(@"Data stored for timestamp: %@", [measures valueForKey: kDeviceMeasuresTimestamp]);
    }
    else if([[currentDevice valueForKey: kDeviceMeasuresTimestamp] compare: [measures valueForKey: kDeviceMeasuresTimestamp]] == NSOrderedAscending)
    {
        NSMutableDictionary *currentDeviceMutableCopy = [currentDevice mutableCopy];
        [data removeObject: currentDevice];
        
        /* 
         erase min temperature and max temperature values from last stored data if they do not match the current day
         thus if we are receiving data from server, they will be rewritten anyway
         and if we are receiving data from streaming, there won't be invalid data
         */
        NSDateComponents *dateComponents = [_calendar components: NSDayCalendarUnit 
                                                        fromDate: [NSDate dateWithTimeIntervalSince1970: [((NSNumber *)[currentDeviceMutableCopy valueForKey: kDeviceMeasuresTimestamp]) longValue]] 
                                                          toDate: [NSDate dateWithTimeIntervalSince1970: [((NSNumber *)[measures valueForKey: kDeviceMeasuresTimestamp]) longValue]] 
                                                         options: 0];
        if([dateComponents day] >= 1)
        {
            [currentDeviceMutableCopy removeObjectForKey: NAAPIMinTemp];
            [currentDeviceMutableCopy removeObjectForKey: NAAPIMaxTemp];
            /*We won't do the same thing for particles;;; we really need to have some data for it to be displayed correctly*/
        }
        
        
        
        
        NSArray *keys = [measures allKeys];
        for(id key in keys)
        {
            [currentDeviceMutableCopy setObject: [measures objectForKey: key] 
                                         forKey: key];
        }
        [data addObject: currentDeviceMutableCopy];
        [currentDeviceMutableCopy release];
        
        
        
        [[NAUserDataStorer gUserDataStorer] storeData: data 
                                               forKey: kUDDeviceMeasures];
        
        NTAPRINT(@"Data stored for timestamp: %@", [measures valueForKey: kDeviceMeasuresTimestamp]);
    }
    
    [self.delegate dataDidUpdateForDevice: currentDeviceId];
}





#pragma mark - DataHandlerDelegate

- (void)dataHandler: (NSString *)type 
 didReceiveMeasures: (NSDictionary *)measures
{
    /*
        first receive distant data so min temp, max temp are updated 
        then start streaming and do not forget to schedule it on next tick
     */
    
    _numberOfTickSinceLastReceivedData = 0;
    
    [measures setValue:type forKey:kDeviceMeasuresDataHandlerType];
    
    if([type isEqualToString: kDataHandlerTypeDistant])
    {
        if(_mode != DataRetrieverModeStreaming)
        {
            [self switchToDistantDataMode];
            [self updateData: measures];
        }
    }
}


- (void)dataHandler: (NSString *)type 
   didFailWithError: (NSError *)error
{
    if([type isEqualToString: kDataHandlerTypeDistant])
    {
        if(_distantDataHandler.enabled)
            [_distantDataHandler stop];
        
        [self.delegate dataDidFail];
    }
}

@end
