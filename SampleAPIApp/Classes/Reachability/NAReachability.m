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

#import "NAReachability.h"
#import "Reachability.h"

#import "NetatmoDefines.h"


@implementation NAReachability

@synthesize apiReachability = _apiReachability;
@synthesize wifiReachability = _wifiReachability;


#pragma mark -
#pragma mark Singleton

static NAReachability *_gNAReachability = nil;


+ (NAReachability *)gNAReachability
{
    @synchronized(self)
    {
        if (_gNAReachability == nil) {
            _gNAReachability = [[super allocWithZone:NULL] init];
        }
    }
    
    return _gNAReachability;
}


- (id)init
{
    self = [super init];
    
    if(self)
    {
        _apiReachability = [[Reachability reachabilityForInternetConnection] retain];
        [_apiReachability startNotifier];
        
        _wifiReachability = [[Reachability reachabilityForLocalWiFi] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_apiReachability stopNotifier];
    
    NTA_RELEASE_SAFELY(_wifiReachability);
    NTA_RELEASE_SAFELY(_apiReachability);
    
    [super dealloc];
}

//should not be called as should only be accessed via gDeviceList
+ (id)allocWithZone:(NSZone *)zone {
    return [[self gNAReachability] retain];
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






-(BOOL) isApiReachable
{
    NetworkStatus networkStatus = [_apiReachability currentReachabilityStatus];
    
    switch (networkStatus)
    {
        case NotReachable:
        {
            return NO;
        }
        case ReachableViaWWAN:
        case ReachableViaWiFi:
        default:
        {
            return YES;
        }
    }
}


@end
