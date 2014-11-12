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


#import "NAArchivedData.h"
#import "NAUserDataStorer.h"
#import "NAUserDataKeys.h"


@interface NAArchivedData()

@property (nonatomic, readwrite, strong) NSString *storerKey;
@property (atomic, readwrite, strong) NSDictionary *dataUnarchived;

@end

@implementation NAArchivedData

/* automatically synthezised _data generates an error (Maybe NSObject ivar)*/

#pragma mark - own methods

-(id)initWithStorerKey:(NSString *)key
{
    self = [super init];
    if (nil != self) {
        _storerKey = [key copy];
    }
    return self;
}


-(NSDictionary *) data
{
    @synchronized (self)
    {
        if (self.dataUnarchived == nil)
        {
            NSData *archivedData = [[NAUserDataStorer gUserDataStorer] getUserDataForKey:self.storerKey];
            if (nil != archivedData)
            {
                self.dataUnarchived = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
            }
        }
    }
    [self logRead:self.dataUnarchived];
    return self.dataUnarchived;
    
}

-(void) setData:(NSDictionary *)data
{
    @synchronized (self)
    {
        self.dataUnarchived = [data copy];
        
        [self logWrite:self.dataUnarchived];
        
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.dataUnarchived];
        
        if ([self.storerKey isEqualToString:kUDDeviceList])
        {
            [[NAUserDataStorer gUserDataStorer] storeData:archivedData forKey:self.storerKey forceSync:YES notificationName:NAUDDeviceListNotification];
        }
        else if ([self.storerKey isEqualToString:kUDUser])
        {
            [[NAUserDataStorer gUserDataStorer] storeData:archivedData forKey:self.storerKey forceSync:YES notificationName:NAUDUserNotification];
        }
        else
        {
            [[NAUserDataStorer gUserDataStorer] storeData:archivedData forKey:self.storerKey];
        }
    }
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
