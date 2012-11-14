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



#import "NAUserDataStorer.h"

static NSString * const kUserDataPathName = @"NAUserData";

/* shared keys*/

NSString * const kUDCurrentDevice   = @"UDCurrentDeviceKey";
NSString * const kUDDeviceList      = @"UDDeviceListKey";
NSString * const kUDDeviceMeasures  = @"kUDDeviceMeasures";
NSString * const kUDUser            = @"UDUserKey";
NSString * const kUDLastCacheWipeDate = @"UDCacheWipeDateKey";




/*notification Name*/
NSString * const NAUDCurrentDeviceNotification = @"NAUDCurrentDeviceNotificationName";
NSString * const NAUDDeviceListNotification = @"NAUDDeviceListNotificationName";
NSString * const NAUDUserNotification = @"NAUDUserNotificationName";

NSString * const kUDRefreshToken    = @"UDRefreshToken";


@interface NAUserDataStorer ()
-(NSString*) notificationForkey:(NSString*) key;
@end

@implementation NAUserDataStorer


#pragma mark -
#pragma mark NSObject

//kind of lazy initialization
- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark -
#pragma mark Singleton

static NAUserDataStorer *_gUserDataStorer = nil;

+ (NAUserDataStorer*) gUserDataStorer
{
    @synchronized(self)
    {
        if (_gUserDataStorer == nil) {
            _gUserDataStorer = [[super allocWithZone:NULL] init];
            [[NSNotificationCenter defaultCenter] addObserver:[NSUserDefaults standardUserDefaults] 
                                                     selector:@selector(synchronize) 
                                                         name:UIApplicationWillTerminateNotification 
                                                       object:nil];
        }
    }
    
    return _gUserDataStorer;
}

//should not be called as should only be accessed via gDeviceList
+ (id)allocWithZone:(NSZone *)zone {
    return [[self gUserDataStorer] retain];
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


#pragma mark - private own methods

-(NSString *)notificationForkey:(NSString *)key
{
    if (kUDDeviceList == key) {
        return NAUDDeviceListNotification;
    } else if (kUDCurrentDevice == key){
        return NAUDCurrentDeviceNotification;
    } else if (kUDUser == key){
        return NAUDUserNotification;
    }else {
        //no notification for the others
        return nil;
    }
}

-(BOOL) shouldForceSynchronizeAfterWriteForKey:(NSString *)key
{
    if (kUDCurrentDevice == key || kUDDeviceList == key || kUDUser == key) {
        return YES;
    } 
    
    return NO;
}

#pragma mark - public own methods


-(void) storeData:(id)data forKey:(NSString*) key 
{
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
        
    NSString *notificationName = [self notificationForkey:key];
    if (nil != notificationName) {
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
    }
    
    if ([self shouldForceSynchronizeAfterWriteForKey:key]) {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(id) getUserDataForKey:(NSString*) key 
{
    return [[NSUserDefaults standardUserDefaults]  objectForKey:key];
}

-(void) removeUserDataForKey:(NSString*) key 
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];   
}

@end
