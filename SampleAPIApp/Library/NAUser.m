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


#import "NAUser.h"

@interface NAUser ()

-(NSDictionary *)administrative;
-(NSString *) mail;

@end

@implementation NAUser

#pragma mark -
#pragma mark Singleton

- (instancetype)initUniqueInstance
{
    self = [super initWithStorerKey:kUDUser];
    
    return self;
}

+ (instancetype) globalUser
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

#pragma mark - own private

-(NSDictionary *)administrative
{
    return [self.data valueForKey:@"administrative"];
}

-(NSString *) mail
{
    return [self.data valueForKey:@"mail"];
}


#pragma mark - own public

-(void) setValue:(NSDictionary*) dataDict
{
    self.data = dataDict;  //this will trigger a notification
}

-(NSString *)userId
{
    if ([self.data isKindOfClass:[NSDictionary class]]) {
        return [self.data valueForKey:@"_id"];
    }
    return nil;
}


-(BOOL) isLoggedIn
{
    return (nil != [self userId]);
}


-(NSString *)countryCode
{
    NSString *storedCountryCode = [[self administrative] valueForKey:@"country"];
    if (nil != storedCountryCode) {
        return storedCountryCode;
    } else {
        NSString *carrierCountryCode = getCountryCodeFromSim();
        carrierCountryCode = [carrierCountryCode uppercaseString];
        return (carrierCountryCode.length > 0)? carrierCountryCode : nil;
    }
}

-(void) reset
{
    [self setValue:nil];
}

- (int)unitSystem
{
    
    NSNumber *unitSystemValue = [[self administrative] objectForKey: @"unit"];
    if ([unitSystemValue isKindOfClass:[NSNumber class]]) {
        return [unitSystemValue intValue];
    } else {
        return NAAPIUnitMetric;
    }
    
}

- (int)windUnitSystem
{
    
    NSNumber *windUnitValue = [[self administrative] objectForKey: @"windunit"];
    if ([windUnitValue isKindOfClass:[NSNumber class]]) {
        return [windUnitValue intValue];
    } else {
        if (NAAPIUnitUs == [self unitSystem]) {
            return NAAPIUnitWindMph;
        } else {
            return NAAPIUnitWindKmh;
        }
    }
}

- (int)pressureUnitSystem
{
    
    NSNumber *pressureUnitValue = [[self administrative] objectForKey: @"pressureunit"];
    if ([pressureUnitValue isKindOfClass:[NSNumber class]]) {
        return [pressureUnitValue intValue];
    } else {
        if (NAAPIUnitUs == [self unitSystem]) {
            return NAAPIUnitPressureMercury;
        } else {
            return NAAPIUnitPressureMbar;
        }
    }
    
}


-(void)deleteAllUserData
{
    [[NAUser globalUser] reset];
    [[NADeviceList gDeviceList] reset];
    [[NAAPI gUserAPI] logout];
}

@end
