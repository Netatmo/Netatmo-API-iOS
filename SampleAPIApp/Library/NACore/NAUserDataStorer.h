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


#define kUserDefaultNullValue   @"-"


@interface NAUserDataStorer : NSObject

+ (instancetype) gUserDataStorer;

/**
 Stores the data in the NSUserDefaults.
 @param data the data to store.
 @param key the key used to store and retrieve the data.
 */
- (void) storeData:(id)data forKey:(NSString*) key;

/**
 Stores the data in the NSUserDefaults.
 @param data the data to store.
 @param key the key used to store and retrieve the data.
 @param forceSync if YES, it forces the NSUserDefaults to synchronized after written the key.
 */
- (void) storeData:(id)data forKey:(NSString*) key forceSync: (BOOL) forceSync;


/**
 Stores the data in the NSUserDefaults.
 @param data the data to store.
 @param key the key used to store and retrieve the data.
 @param forceSync if YES, it forces the NSUserDefaults to synchronized after written the key.
 @param notificationName If not nil post a notification with the given name.
 */
- (void) storeData:(id)data forKey:(NSString*) key forceSync: (BOOL) forceSync notificationName:(NSString *)notificationName;

/**
 Gets the data from the NSUserDefaults.
 @param key the key used to store the data.
 */
- (id) getUserDataForKey:(NSString*) key;

/**
 Removes the data from the NSUserDefaults.
 @param key the key used to store the data.
 */
- (void) removeUserDataForKey:(NSString*) key;


@end
