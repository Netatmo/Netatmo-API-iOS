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



#ifndef weatherstation_NAMeasure_h
#define weatherstation_NAMeasure_h

#import <Foundation/Foundation.h>


typedef struct {
    long int timestamp;
    CGFloat value;
} NAMeasure;


typedef enum {
    NAMeasureTypeTemperature,
    NAMeasureTypeHumidity,
    NAMeasureTypePressure,
    NAMeasureTypeCO2,
    NAMeasureTypeTemperatureMin,
    NAMeasureTypeTemperatureMax,
    NAMeasureTypeNoise,
    
    NAMeasureTypeUnknown = -1,
} NAMeasureType;

NSString *stringForMeasureType(NAMeasureType type);

#endif
