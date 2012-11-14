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


#import "NADeviceList.h"
#import "NAUserDataStorer.h"
#import "AppliCommonPrivate.h"

@interface NADeviceList ()
@property (nonatomic, readonly) NSArray *deviceList;
@property (nonatomic, readonly) NSArray *moduleList;
@property (nonatomic, readonly) NSDictionary *currentDevice;
@property (nonatomic, readonly) NSDictionary *currentModule;

@end

@implementation NADeviceList

#pragma mark -
#pragma mark Singleton

static NADeviceList *_gDeviceList = nil;

+ (NADeviceList*) gDeviceList
{
    @synchronized(self)
    {
        if (_gDeviceList == nil) {
            _gDeviceList = [[super allocWithZone:NULL] initWithStorerKey:kUDDeviceList];
            
        }
    }
    
    return _gDeviceList;
}

//should not be called as should only be accessed via gDeviceList
+ (id)allocWithZone:(NSZone *)zone {
    return [[self gDeviceList] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}



#pragma mark -
#pragma mark NSObject

#pragma mark - own private methods

/*private*/
-(void)setCurrentDeviceId:(NSString*) deviceId
{
    [[NAUserDataStorer gUserDataStorer] storeData:deviceId forKey:kUDCurrentDevice];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(NSDictionary *)currentDevice
{
    if (nil != self.deviceList && [self.deviceList isKindOfClass:[NSArray class]]){ //should always be
        for (NSDictionary *device in self.deviceList) {
            if ([self.currentDeviceId isEqualToString:[device valueForKey:@"_id"]]){
                return device;
            }
        }
    }
    return nil;
}

-(void)logRead:(NSDictionary *)dataRead
{
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

-(NSDictionary *)currentModule
{
    for (NSDictionary *module in self.moduleList) {
        if ([module isKindOfClass:[NSDictionary class]]) {
            NSString *moduleId = [module valueForKey:@"_id"];
            if (moduleId && [moduleId isEqualToString:self.currentModuleId]) {
                return module;
            }
        }
    }
    return nil;
}

#pragma mark - accessor methods

-(NSArray*) getDeviceIdList
{
    NSMutableArray *result = [NSMutableArray array];
    NSString *deviceId = nil;
    if ([self.deviceList isKindOfClass:[NSArray class]]){ //should always be
        for (NSDictionary *device in self.deviceList) {
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
    if (nil != deviceId) {
        BOOL deviceOwned = NO;
        NSArray *ownedDeviceIdList = [self getDeviceIdList];
        for (NSString *ownedId in ownedDeviceIdList) {
            if ([ownedId isEqualToString:deviceId]) {
                deviceOwned = YES;
                break;
            }
        }     
        if (deviceOwned) {
            return deviceId;
        }
    }
    
    return nil;
}

-(NSString *)currentDeviceName
{
    return [self.currentDevice valueForKey:NAAPIDeviceStationName];
}



-(NSArray *)modulesIdList
{
    return [self.currentDevice valueForKey:@"modules"];
}

-(NSString *)currentModuleId
{
    //Temp
    if (self.modulesIdList && self.modulesIdList.count > 0) {
        return [self.modulesIdList objectAtIndex:0];        
    } else {
        return nil;
    }
}


-(BOOL) hasAValidDevice
{
    if (nil != self.currentDevice && [self.currentDevice isKindOfClass:[NSDictionary class]]){
        NSDictionary *place = [self.currentDevice valueForKey: @"place"];
        if ([place isKindOfClass:[NSDictionary class]]) {
            return YES;
        }
    }
    
    return NO;
}


- (NSTimeZone *)currentDeviceTimeZone
{
    return [NSTimeZone timeZoneWithName: [[[self currentDevice] valueForKey: @"place"] valueForKey: @"timezone"]];
}

- (NSString *)nameForDevice: (NSString *)deviceId
{
    NSDictionary *device = nil;
    
    for(NSDictionary *deviceInfo in self.deviceList)
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
    
    for(NSDictionary *deviceInfo in self.deviceList)
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


- (NSString *)deviceModuleByType: (NSString *)type
{
    for(NSString *moduleId in self.modulesIdList)
    {
        if([[self typeForModule: moduleId] isEqualToString: type])
            return moduleId;
    }
           
    return self.currentDeviceId;
}

- (BOOL)currentDeviceHasModule: (NSString *)moduleId
{
    for(NSString *currentDeviceModule in self.modulesIdList)
    {
        if([moduleId isEqualToString: currentDeviceModule])
            return YES;
    }
    
    return NO;
}

-(void) setValue:(NSDictionary*) value
{
    self.data = value; //this will trigger notification
    
    if (nil == self.currentDevice && nil != self.data) {
        NSArray *deviceIdList = [self getDeviceIdList];
        if (deviceIdList && [deviceIdList count] > 0) {
            [self setCurrentDeviceId:[deviceIdList objectAtIndex:0]];  //will trigger a notif
        }
    }
}

-(void) reset
{
    [self setValue:nil];
}


@end
