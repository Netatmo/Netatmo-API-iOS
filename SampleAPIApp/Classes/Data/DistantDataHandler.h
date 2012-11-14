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

#import "DataHandler.h"
#import "DataHandlerDelegate.h"

#import "NAAPI.h"


#define DDH_REFRESH_INTERVAL               -1

// No retry (as three20 handles it for us)
#define DDH_RETRY_MAX                       1   
#define DDH_RETRY_INTERVAL                 -1



#define DDH_DAY_SCALE_DATA_NUMBER           2
#define DDH_MAX_SCALE_DATA_NUMBER           5


@interface DistantDataHandler : DataHandler<NAAPIRequestDelegate>
{
    NSMutableArray *_maxScaleDataArray;
    NSMutableArray *_dayScaleDataArray;
}

- (void)hookModuleById: (NSString *)moduleId fromDeviceById: (NSString *)deviceId;

@end
