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


#import "NAUserDataStorer.h"

@implementation NAUserDataStorer


#pragma mark -
#pragma mark NSObject


- (id) init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate)
                                                     name: UIApplicationWillTerminateNotification
                                                   object: nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationWillTerminateNotification
                                                  object: nil];
}

#pragma mark -
#pragma mark Singleton


+ (instancetype) gUserDataStorer
{
    static NAUserDataStorer * _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self new];
    });
    return _sharedInstance;
}


#pragma mark - public own methods


- (void) storeData:(id)data forKey:(NSString*) key
{
    [self storeData: data
             forKey: key
          forceSync: NO
   notificationName: nil];
}

- (void) storeData:(id)data forKey:(NSString*) key forceSync: (BOOL) forceSync
{
    [self storeData:data forKey:key forceSync:forceSync notificationName:nil];
}


- (void) storeData:(id)data forKey:(NSString*) key forceSync: (BOOL) forceSync notificationName: (NSString *) notificationName
{
    @synchronized(self)
    {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
        
        if (forceSync)
        {
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        if (notificationName)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
        }
    }
}

- (id) getUserDataForKey:(NSString*) key
{
    @synchronized(self)
    {
        return [[NSUserDefaults standardUserDefaults] objectForKey:key];
    }
}

- (void) removeUserDataForKey:(NSString*) key
{
    @synchronized(self)
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

#pragma mark - OBSERVER

- (void) applicationWillTerminate
{
    @synchronized(self)
    {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
