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


#import <UIKit/UIKit.h>

#import "DataRetriever.h"


@interface MainViewController : UITableViewController <DataRetrieverDelegate>
{
    DataRetriever *_netatmoDataRetriever;
    
    
    
    UILabel *_titleOutdoorTemperature;
    UILabel *_titleOutdoorMinTemperature;
    UILabel *_titleOutdoorMaxTemperature;
    UILabel *_titleOutdoorHumidity;
    
    UILabel *_titleIndoorTemperature;
    UILabel *_titleIndoorMinTemperature;
    UILabel *_titleIndoorMaxTemperature;
    UILabel *_titleIndoorHumidity;
    UILabel *_titleIndoorPressure;
    UILabel *_titleIndoorCO2;
    UILabel *_titleIndoorNoise;
    
    
    UILabel *_valueOutdoorTemperature;
    UILabel *_valueOutdoorMinTemperature;
    UILabel *_valueOutdoorMaxTemperature;
    UILabel *_valueOutdoorHumidity;
    
    UILabel *_valueIndoorTemperature;
    UILabel *_valueIndoorMinTemperature;
    UILabel *_valueIndoorMaxTemperature;
    UILabel *_valueIndoorHumidity;
    UILabel *_valueIndoorPressure;
    UILabel *_valueIndoorCO2;
    UILabel *_valueIndoorNoise;
}

@end
