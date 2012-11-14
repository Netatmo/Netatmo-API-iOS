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


#import "SyncAssistant.h"

#import "NAUser.h"
#import "NADeviceList.h"
#import "NAUserDataStorer.h"

@interface SyncAssistant () 
@property (nonatomic, readwrite, assign) id<SyncAssistantDelegate> delegate;
-(void) syncDevice;
-(void) syncUser;
@end

@implementation SyncAssistant

@synthesize delegate=_delegate;

#pragma mark - NSObject

-(id)init
{
    self = [super init];
    if (self) {
        _syncedUserData = NO;
        _syncedDeviceList = NO;
    }
    return self;
}

-(void)dealloc
{
    [[NAAPI gUserAPI] cancelRequestsWithDelegate:self];
    [super dealloc];
}

#pragma mark - public own methods

+(SyncAssistant *)syncAssistantLaunchedWithDelegate:(id<SyncAssistantDelegate>)delegate
{
    SyncAssistant *syncer = [[SyncAssistant alloc] init];
    
    syncer.delegate = delegate;
        
    // sync user preferences
    [syncer syncUser];
    
    // sync user device list
    [syncer syncDevice];
    
    [syncer autorelease];
    
    return syncer;
}

- (id)initWithDelegate: (id<SyncAssistantDelegate>)delegate
{
    self = [super init];
    if (self) {
        _syncedUserData = NO;
        _syncedDeviceList = NO;
        
        _delegate = delegate;
    }
    return self;
}

- (void)sync
{
    [self syncUser];
    [self syncDevice];
}


#pragma mark - private own methods

static NSString* kSyncUserInfoKey = @"SyncUserInfoKey";

static NSString* kDeviceListSyncUserInfo = @"DeviceListSyncUserInfo";
static NSString* kUserSyncUserInfo = @"UserSyncUserInfo";


-(void) syncDevice
{
    [[NAAPI gUserAPI] sendApiRequestWithMethod:@"devicelist"
                                      delegate:self 
                            cacheExpirationAge:NA_CACHE_EXPIRATION_NO_CACHE 
                                   addUserInfo:[NSDictionary dictionaryWithObject:kDeviceListSyncUserInfo 
                                                                           forKey:kSyncUserInfoKey] 
                           paramsValuesAndKeys:nil];
}

-(void) syncUser
{   
    [[NAAPI gUserAPI] sendApiRequestWithMethod:@"getuser" 
                                      delegate:self 
                            cacheExpirationAge:NA_CACHE_EXPIRATION_NO_CACHE 
                                   addUserInfo:[NSDictionary dictionaryWithObject:kUserSyncUserInfo 
                                                                           forKey:kSyncUserInfoKey]  
                           paramsValuesAndKeys:nil];
}


#pragma mark NAAPIRequestDelegate

-(void)apiRequestDidSucceedWithBody:(id)responseBody userInfo:(NSDictionary *)ourUserInfo
{ 
    if (responseBody){
        NSString *type = [ourUserInfo valueForKey:kSyncUserInfoKey];
        if ([type isEqualToString:kDeviceListSyncUserInfo]) {
            [[NADeviceList gDeviceList] setValue:responseBody]; //this will trigger notification(s)
            _syncedDeviceList = YES;
        } else if ([type isEqualToString:kUserSyncUserInfo]) {
            [[NAUser globalUser] setValue:responseBody];
            _syncedUserData = YES;
        }
    }
    
    if (_syncedUserData && _syncedDeviceList) {
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
            _syncedDeviceList = YES;
            
            //however, this means that if the user owns a device, it will be erased
            //(as it has been dissociated)
            [[NADeviceList gDeviceList] setValue:nil];
            
            if (_syncedUserData && _syncedDeviceList) {
                [self.delegate syncDidComplete];
            }
            return;
        }
    }
    
    [self.delegate syncDidFail];
}
@end
