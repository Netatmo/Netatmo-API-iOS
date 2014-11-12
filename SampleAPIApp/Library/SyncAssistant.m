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


#import "SyncAssistant.h"

@interface SyncAssistant ()

@property (nonatomic, readwrite, weak) id<SyncAssistantDelegate> delegate;
@property (nonatomic, readwrite, assign) BOOL shouldUserSync;
@property (nonatomic, readwrite, assign) BOOL syncedDeviceList;
@property (nonatomic, readwrite, assign) BOOL syncedUserData;
@property (nonatomic, readwrite, assign) SyncDeviceType deviceType;

@end

@implementation SyncAssistant

#pragma mark - NSObject

-(id)init
{
    self = [super init];
    if (self) {
        self.syncedUserData = NO;
        self.syncedDeviceList = NO;
    }
    return self;
}

#pragma mark - NSCopying Protocol

- (instancetype) copyWithZone:(NSZone *)zone
{
    SyncAssistant *copy = [[[self class] allocWithZone:zone] init];
    
    if (copy)
    {
        copy->_syncedUserData = _syncedUserData;
        copy->_syncedDeviceList = _syncedDeviceList;
        copy->_shouldUserSync = _shouldUserSync;
    }
    
    return copy;
}

#pragma mark - public own methods


+(SyncAssistant *)syncAssistantLaunchedWithDelegate:(id<SyncAssistantDelegate>)delegate
                                      forDeviceType:(SyncDeviceType)deviceType
                                 withShouldUserSync:(BOOL) shoudUserSync
{

    
    SyncAssistant *syncer = [[SyncAssistant alloc]
                             initWithDelegate:delegate
                             forDeviceType:deviceType
                             withShouldUserSync:shoudUserSync];

    [syncer syncUser];

    [syncer syncDevice];
    
    return syncer;
}


- (id)initWithDelegate: (id<SyncAssistantDelegate>)delegate
         forDeviceType:(SyncDeviceType)deviceType
        withShouldUserSync:(BOOL) shouldUserSync
{
    self = [super init];
    if (self) {
        
        self.shouldUserSync = shouldUserSync;
        
        if ( self.shouldUserSync )
            self.syncedUserData = NO;
        else
            self.syncedUserData = YES;
        
        
        self.syncedDeviceList = NO;
        
        self.delegate = delegate;
        self.deviceType = deviceType;
    }
    return self;
}


#pragma mark - private own methods

static NSString* kSyncUserInfoKey = @"SyncUserInfoKey";

static NSString* kDeviceListSyncUserInfo = @"DeviceListSyncUserInfo";
static NSString* kUserSyncUserInfo = @"UserSyncUserInfo";

- (void)sync
{
    [self syncUser];
    [self syncDevice];
}

-(void) syncDevice
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:kDeviceListSyncUserInfo
                                                         forKey:kSyncUserInfoKey];
    switch (self.deviceType) {
        case SyncDeviceTypeWeatherStationOnly:
            [[NAAPI gUserAPI] sendApiRequestWithMethod:@"devicelist"
                                              delegate:self
                                            parameters:@{NAAPIAppType : NAAPIAppTypeStation}
                                              userInfo:userInfo];
            break;
        case SyncDeviceTypeAll:
            [[NAAPI gUserAPI] sendApiRequestWithMethod:@"devicelist"
                                              delegate:self
                                            parameters:@{NAAPIAppType : NAAPIAppTypeAll}
                                              userInfo:userInfo];
            break;
    }
    
}

-(void) syncUser
{
    if ( !self.shouldUserSync )
        return;
    
    NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  kUserSyncUserInfo,
                                  kSyncUserInfoKey,
                                  nil];
    
    [[NAAPI gUserAPI] sendApiRequestWithMethod:@"getuser"
                                      delegate:self
                                    parameters:nil
                                      userInfo:userInfoDict];
}

- (void) cancelOnGoingSync
{
    [[NAAPI gUserAPI] cancelRequestsWithDelegate:self];
}


#pragma mark NAAPIRequestDelegate

-(void)apiRequestDidSucceedWithBody:(id)responseBody userInfo:(NSDictionary *)ourUserInfo
{ 
    if (responseBody){
        NSString *type = [ourUserInfo valueForKey:kSyncUserInfoKey];
        if ([type isEqualToString:kDeviceListSyncUserInfo]) {
            [[NADeviceList gDeviceList] setValue:responseBody]; //this will trigger notification(s)
            self.syncedDeviceList = YES;
        } else if ([type isEqualToString:kUserSyncUserInfo]) {
            [[NAUser globalUser] setValue:responseBody];
            self.syncedUserData = YES;
        }
    }
    
    if (self.syncedUserData && self.syncedDeviceList) {
        [self.delegate syncDidComplete];
    }
    
}

-(void)apiRequestDidFailWithError:(NtmoAPIErrorCode)error userInfo:(NSDictionary *)ourUserInfo
{
    //Do not update
    
    NSString *type = [ourUserInfo valueForKey:kSyncUserInfoKey];
    if ([type isEqualToString:kDeviceListSyncUserInfo]) {
        if (NtmoAPIErrorCodeDeviceNotFound == error) {
            //this means that we haven't associated a device to this user yet, but
            //we can consider that sync is successful
            self.syncedDeviceList = YES;
            
            //however, this means that if the user owns a device, it will be erased
            //(as it has been dissociated)
            [[NADeviceList gDeviceList] setValue:nil];
            
            if (self.syncedUserData && self.syncedDeviceList) {
                [self.delegate syncDidComplete];
            }
            return;
        }
    }
    
    [self.delegate syncDidFail:error];
}
@end
