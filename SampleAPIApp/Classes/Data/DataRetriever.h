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



#import <Foundation/Foundation.h>

#import "Reachability.h"
#import "DistantDataHandler.h"

#import "NAUserDataStorer.h"


#define DR_TIMER_TICK_MAX       60




@protocol DataRetrieverDelegate

- (void)dataDidUpdateForDevice: (NSString *)deviceId;
- (void)dataDidFail;

@end


typedef enum
{
    DataRetrieverModeLocal,
    DataRetrieverModeStreaming,
    DataRetrieverModeDistant
} DataRetrieverMode;



@interface DataRetriever : NSObject<DataHandlerDelegate>
{
    id<DataRetrieverDelegate> _delegate;
    
    NSCalendar *_calendar;
    
    DataRetrieverMode _mode;
    
    DistantDataHandler *_distantDataHandler;
        
    NSTimer *_timer;
    int _timerTick;
    
    int _numberOfTickSinceLastReceivedData;
}

- (id)initWithDelegate: (id<DataRetrieverDelegate>)delegate;

- (void)start;
- (void)stop;

@property (nonatomic, readwrite, assign)    id<DataRetrieverDelegate> delegate;
@property (nonatomic, readonly, assign)     DataRetrieverMode mode;

@end
