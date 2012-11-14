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

#import "NAUser.h"
#import "NAAPI.h"
#import "NAUserDataStorer.h"

@interface NAUser (local)
@property (nonatomic, readwrite, assign) NSDictionary *data;
@end

@implementation NAUser

#pragma mark -
#pragma mark Singleton

static NAUser *_gUser = nil;

+ (NAUser*) globalUser
{
    @synchronized(self)
    {
        if (_gUser == nil) {
            _gUser = [[super allocWithZone:NULL] initWithStorerKey:kUDUser];
        } 
    }
    
    return _gUser;
}

//should not be called as should only be accessed via gDeviceList
+ (id)allocWithZone:(NSZone *)zone {
    return [[self globalUser] retain];
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

#pragma mark - own private


-(void)logRead:(NSDictionary *)dataRead
{
}


#pragma mark - own public

-(NSString *)userId
{
    return [self.data valueForKey:@"_id"];    
}


-(BOOL) isLoggedIn
{
    return (nil != self.userId);
}

-(void) setValue:(NSDictionary*) dataDict
{
    self.data = dataDict;  //this will trigger a notification
}

-(void) reset
{
    [self setValue:nil];
}

@end
