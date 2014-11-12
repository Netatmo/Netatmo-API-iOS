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

#import "NADeviceList.h"

#import "NAUserDataStorer.h"
#import "AppliCommonPrivate.h"
#import "NetatmoDefines.h"
#import "NAUserDataKeys.h"

@implementation NADeviceList

#pragma mark -
#pragma mark Singleton

- (instancetype)initUniqueInstance
{
    self = [super initWithStorerKey:kUDDeviceList];
    
    return self;
}

+ (instancetype) gDeviceList
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}


#pragma mark -
#pragma mark NSObject

#pragma mark - own private methods

/*private*/
-(void)setCurrentDeviceId:(NSString*) deviceId
{
    [[NAUserDataStorer gUserDataStorer] storeData:deviceId forKey:kUDCurrentDevice forceSync:YES notificationName:NAUDCurrentDeviceNotification];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL) doesOwnDeviceId:(NSString*) deviceId
{
    if (nil != deviceId) {
        NSArray *ownedDeviceIdList = [self getDeviceIdList];
        for (NSString *ownedId in ownedDeviceIdList) {
            if ([ownedId isEqualToString:deviceId]) {
                return YES;
            }
        }     
    }
    
    return NO;
}

-(BOOL) doesOwnCurrentDeviceId
{
    NSString *deviceId = [[NAUserDataStorer gUserDataStorer] getUserDataForKey:kUDCurrentDevice];
    return [self doesOwnDeviceId:deviceId];
}

-(NSString*) setNewCurrentDeviceIdIfNecessary
{
    if (![self doesOwnCurrentDeviceId] && nil != self.data) {
        NSArray *deviceIdList = [self getDeviceIdList];
        if (deviceIdList && [deviceIdList count] > 0) {
            NSString *newCurrentId = [deviceIdList objectAtIndex:0];
            [self setCurrentDeviceId:newCurrentId];  //will trigger a notif
            return newCurrentId;
        }
    }
    return nil;
}


-(NSDictionary *)currentDevice
{
    NSArray *deviceList = [self deviceList];
    
    if ([deviceList isKindOfClass:[NSArray class]]){ //should always be
        for (NSDictionary *device in deviceList) {
            if ([[self currentDeviceId] isEqualToString:[device valueForKey:@"_id"]]){
                return device;
            }
        }
    }
    return nil;
}


-(void)logWrite:(NSDictionary *)dataToWrite
{
    
}

-(NSArray *)deviceList
{
    return [self.data valueForKey:@"devices"];
}

-(NSArray *)moduleList
{
    return [self.data valueForKey:@"modules"];
}



#pragma mark - accessor methods

-(NSArray*) getDeviceIdList
{
    NSMutableArray *result = [NSMutableArray array];
    NSString *deviceId = nil;
    NSArray *deviceList = [self deviceList];
    if ([deviceList isKindOfClass:[NSArray class]]){ //should always be
        for (NSDictionary *device in deviceList) {
            deviceId = [device valueForKey:@"_id"];
            if (deviceId) {
                [result addObject:deviceId];
            }
        }
        if(result.count > 0){
            return result;
        }
    }
    return nil;
}

-(NSString *)currentDeviceId
{
    NSString *deviceId = [[NAUserDataStorer gUserDataStorer] getUserDataForKey:kUDCurrentDevice];
    if ([self doesOwnDeviceId:deviceId]) {
        return deviceId;
    } else {
        return [self setNewCurrentDeviceIdIfNecessary];
    }
}

-(NSString *)currentDeviceName
{
    return [[self currentDevice] valueForKey:NAAPIDeviceStationName];
}

/*public*/


-(NSArray *)modulesIdList
{
    return [[self currentDevice] valueForKey:@"modules"];
}



-(BOOL) shouldUpgradeCurrentDevice
{
    NSNumber *boolNumber = [[self currentDevice] valueForKey:NAAPIRecordUpgrading];
    return [boolNumber boolValue];
}

-(BOOL) hasAValidDeviceWithPlace
{
    NSDictionary *currentDevice = [self currentDevice];
    if ([currentDevice isKindOfClass:[NSDictionary class]]){
        NSDictionary *place = [currentDevice valueForKey: @"place"];
        if ([place isKindOfClass:[NSDictionary class]]) {
            return YES;
        }
    }
    
    return NO;
}

-(BOOL) hasAValidDevice
{
    return [self hasAValidDeviceWithPlace];
}


- (NSTimeZone *)currentDeviceTimeZone
{
    return [NSTimeZone timeZoneWithName: [[[self currentDevice] valueForKey: @"place"] valueForKey: @"timezone"]];
}

- (NSString *)nameForDevice: (NSString *)deviceId
{
    NSDictionary *device = nil;
    
    for(NSDictionary *deviceInfo in [self deviceList])
    {
        if([[deviceInfo valueForKey: @"_id"] isEqualToString: deviceId])
        {
            device = deviceInfo;
            break;
        }
    }
    
    if(device == nil)
        return nil;
    
    NSString *deviceName = [device valueForKey: NAAPIDeviceStationName];
    
    return deviceName;
}

- (NSString *)nameForMainModule: (NSString *)deviceId
{
    NSDictionary *device = nil;
    
    for(NSDictionary *deviceInfo in [self deviceList])
    {
        if([[deviceInfo valueForKey: @"_id"] isEqualToString: deviceId])
        {
            device = deviceInfo;
            break;
        }
    }
    
    if(device == nil)
        return nil;
    
    return [device valueForKey: NAAPIModuleName];
}

- (NSString *)nameForModule: (NSString *)moduleId
{
    for(NSDictionary *module in [self moduleList])
    {
        if([[module valueForKey: @"_id"] isEqualToString: moduleId])
            return [module valueForKey: NAAPIModuleName];
    }
    
    return nil;
}

- (NSString *)typeForModule: (NSString *)moduleId
{
    for(NSDictionary *module in [self moduleList])
    {
        if([[module valueForKey: @"_id"] isEqualToString: moduleId])
            return [module valueForKey: @"type"];
    }
    
    for(NSString *deviceId in [self getDeviceIdList])
    {
        if([deviceId isEqualToString: moduleId])
            return NAAPIMainDevice;
    }
    
    return nil;
}



- (NSArray *)deviceModulesByType: (NSString *)type
{
    NSMutableArray *result = [NSMutableArray array];
    NTAPRINT(@"%@", [self currentDeviceId]);
    for(NSString *moduleId in [self modulesIdList])
    {
        if([[self typeForModule: moduleId] isEqualToString: type])
            [result addObject: moduleId];
    }
           
    return result;
}

- (BOOL)currentDeviceHasModule: (NSString *)moduleId
{
    for(NSString *currentDeviceModule in [self modulesIdList])
    {
        if([moduleId isEqualToString: currentDeviceModule])
            return YES;
    }
    
    return NO;
}


- (BOOL)currentDeviceCalibratingCO2
{
    NSNumber *flagCalibrating = [[self currentDevice] valueForKey: NAAPICo2StatusCalibrating];
    
    return !(flagCalibrating == nil || flagCalibrating.boolValue == NO);
}


-(BOOL)hasOnlyReadOnlyDevices
{
    for (NSDictionary *device in [self deviceList]){
        if ([device isKindOfClass:[NSDictionary class]]) {
            NSNumber *isReadOnly = [device valueForKey:@"read_only"];
            if ([isReadOnly isKindOfClass:[NSNumber class]]) {
                if (![isReadOnly boolValue]) {
                    return NO;
                }
            } else {
                return NO;
            }
        } 
    }
    return YES;
}

-(void)setHistory:(NADeviceListHistory)history
{
    NSNumber *intNumber = [NSNumber numberWithInt:history];
    [[NAUserDataStorer gUserDataStorer] storeData:intNumber forKey:kUDDeviceListHistory];
}

-(NADeviceListHistory)history
{
    NSNumber *intNumber = [[NAUserDataStorer gUserDataStorer] getUserDataForKey:kUDDeviceListHistory];
    if ([intNumber isKindOfClass:[NSNumber class]]) {
        return [intNumber intValue];
    } else {
        return NADeviceListHistoryNew;
    }
}

-(void) setValue:(NSDictionary*) value
{
    self.data = value; //this will trigger notification
    
    if (nil != value && [self hasAValidDevice]) {
        if ([self hasOnlyReadOnlyDevices]) {
            self.history = NADeviceListHistoryInvitedOnly;
        } else {
            self.history = NADeviceListHistoryOwned;
        }
    }
    [self setNewCurrentDeviceIdIfNecessary];
}

-(void) reset
{
    self.history = NADeviceListHistoryNew;
    [self setValue:nil];
}

-(BOOL)changeCurrentDeviceIfIdExists:(NSString*) newDeviceId
{
    NTAPRINT(@"Changing current device to %@", newDeviceId);
    
    for (NSString *deviceId in [self getDeviceIdList]) {
        if ([deviceId isEqualToString:newDeviceId]){
            [self setCurrentDeviceId:newDeviceId];
            return YES;
        }
    }
    
    return NO;
}

@end
