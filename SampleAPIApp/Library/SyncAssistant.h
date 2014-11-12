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


#import "NAAPI.h"
#import "NAUser.h"
#import "NADeviceList.h"
#import "NAUserDataStorer.h"
#import "AppliCommonPrivate.h"
#import "NAUserDataKeys.h"

#import "NetatmoDefines.h"

typedef enum {
    SyncDeviceTypeWeatherStationOnly,
    SyncDeviceTypeAll
}SyncDeviceType;

@protocol SyncAssistantDelegate
@required
-(void) syncDidComplete;
-(void) syncDidFail:(NtmoAPIErrorCode)error;

@end

@interface SyncAssistant : NSObject <NAAPIRequestDelegate>

+(SyncAssistant*) syncAssistantLaunchedWithDelegate:(id<SyncAssistantDelegate>) delegate
                                      forDeviceType:(SyncDeviceType)deviceType
                                      withShouldUserSync:(BOOL) shouldUserSync;

- (id)initWithDelegate: (id<SyncAssistantDelegate>)delegate forDeviceType:(SyncDeviceType)deviceType withShouldUserSync:(BOOL) shouldUserSync;

- (void)sync;

- (void) cancelOnGoingSync;

@end
