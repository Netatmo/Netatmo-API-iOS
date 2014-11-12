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


#import "NAReachability.h"
#import "AFNetworkReachabilityManager.h"


@implementation NAReachability

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
        
        _wifiReachability = [self reachabilityForLocalWifi];
        
        _apiReachability = [AFNetworkReachabilityManager sharedManager];
        [_apiReachability startMonitoring];
        
    }
    
    return self;
}

- (void)dealloc
{
    [_apiReachability stopMonitoring];
}

//should not be called as should only be accessed via gDeviceList
+ (id)allocWithZone:(NSZone *)zone
{
    return [self gNAReachability];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(BOOL) isApiReachable
{
    AFNetworkReachabilityStatus networkStatus = [_apiReachability networkReachabilityStatus];
    
    switch (networkStatus)
    {
        case AFNetworkReachabilityStatusNotReachable:
        {
            return NO;
        }
        case AFNetworkReachabilityStatusReachableViaWiFi:
        case AFNetworkReachabilityStatusReachableViaWWAN:
        case AFNetworkReachabilityStatusUnknown:
        default:
        {
            return YES;
        }
    }
}

- (AFNetworkReachabilityManager*) reachabilityForLocalWifi
{
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0.
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    
    return [AFNetworkReachabilityManager managerForAddress:&localWifiAddress];
}


@end
