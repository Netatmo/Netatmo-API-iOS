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

#import "NAArchivedData.h"

#import "NAUserDataStorer.h"
#import "NetatmoDefines.h"

@implementation NAArchivedData

#pragma mark - NSObject

-(void)dealloc
{
    NTA_RELEASE_SAFELY(_storerKey);
    NTA_RELEASE_SAFELY(_data);
    [super dealloc];
}

#pragma mark - own methods

-(id)initWithStorerKey:(NSString *)key
{
    self = [super init];
    if (nil != self) {
        _data = nil;
        _storerKey = [key copy];
    }
    return self;
}


-(NSDictionary *) data
{
    @synchronized(self) {
        if (_data == nil) {
            NSData *archivedData = [[NAUserDataStorer gUserDataStorer] getUserDataForKey:_storerKey];
            if (nil != archivedData) {
                _data = [[NSKeyedUnarchiver unarchiveObjectWithData:archivedData] retain];
            }
        }
    }
    [self logRead:_data];
    return _data;
        
}

-(void) setData:(NSDictionary *)data
{
    @synchronized(self) {
        NTA_RELEASE_SAFELY(_data);
        _data = [data copy];
        [self logWrite:_data];
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:_data];
        [[NAUserDataStorer gUserDataStorer] storeData:archivedData forKey:_storerKey];
    }
}

- (void)unsetData
{
    @synchronized(self) {
        NTA_RELEASE_SAFELY(_data);
        [[NAUserDataStorer gUserDataStorer] removeUserDataForKey:_storerKey];
    }
}

- (void) synchronizeData
{
    [self setData:[[self.data copy] autorelease]];
}

-(void)logRead:(NSDictionary *)dataRead 
{
    //"Abstract class" -> the users should overwrite it to get a log before read
}

-(void)logWrite:(NSDictionary *)dataToWrite 
{
    //"Abstract class" -> the users should overwrite it to get a log before write
}

@end
