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


#import "NADeviceList+Weatherstation.h"


@interface NADeviceList (WeatherstationIntern)

-(NSDictionary *)moduleWithId: (NSString*) moduleId;


@end

@implementation NADeviceList (Weatherstation)

#pragma mark - private own methods

-(NSDictionary *)moduleWithId: (NSString*) moduleId
{
    for (NSDictionary *module in [self moduleList]) {
        if ([module isKindOfClass:[NSDictionary class]]) {
            NSString *moduleIdIt = [module valueForKey:@"_id"];
            if ([moduleIdIt isKindOfClass:[NSString class]] && [moduleIdIt isEqualToString:moduleId]) {
                return module;
            }
        }
    }
    return nil;
}

-(NSDictionary*)deviceWithId: (NSString*) deviceId
{
    NSArray *filteredDeviceList = [[self deviceList] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"_id=%@",deviceId]];
    NSDictionary* device = filteredDeviceList.count>0?filteredDeviceList[0]:nil;
    return device;
}

-(NSDictionary *)outdoorModule
{
    return [self moduleWithId:[self outdoorModuleId]];
}

-(NSDictionary *) rainGaugeModule
{
    return [self moduleWithId:[self rainGaugeModuleId]];
}


#pragma mark - public own methods


-(NSString *)rainGaugeModuleId
{
    NSArray *rainGaugeModules = [[NADeviceList gDeviceList] deviceModulesByType: NAAPIModule3];
    
    if(rainGaugeModules != nil && rainGaugeModules.count > 0)
    {
        return [rainGaugeModules objectAtIndex: 0];
    }
    
    return nil;
}

-(NSString *)outdoorModuleId
{
    NSArray *outdoorModules = [[NADeviceList gDeviceList] deviceModulesByType: NAAPIModule1];
    
    if(outdoorModules != nil && outdoorModules.count > 0)
    {
        return [outdoorModules objectAtIndex: 0];
    }
    
    return nil;
}

- (void) parseMeasuresForDashboardDataWithSuccessCompletion:(void (^)(NSString *, NSDictionary *))successCompletion
                                          failureCompletion:(void (^)(NSError *))failureCompletion
{
    NADPRINTMETHODNAME();
    
    if (![[NADeviceList gDeviceList] hasAValidDevice])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NTAPRINT(@" Notify that we do not have any valid device");
            NSError *error = [NSError errorWithDomain:kNAAPIErrorDomain
                                                 code:NtmoAPIErrorCodeDeviceNotFound
                                             userInfo:nil];
            failureCompletion(error);
        });
    }
    
    /* get data from station mac */
    for (NSDictionary *deviceIt in [[NADeviceList gDeviceList] deviceList])
    {
        if (![deviceIt isKindOfClass:[NSDictionary class]])
        {
            continue;
        }
        
        NSString* stationMac = [deviceIt valueForKey:@"_id"];
        
        NTAPRINT( @"stationMac:%@", stationMac );
        
        NSMutableDictionary* dataToCache = [[NSMutableDictionary alloc] init];
        
        NSDictionary* dashboard_data = [deviceIt objectForKey:@"dashboard_data" ];
        if ( dashboard_data != nil )
        {
            NSNumber* time_utc      = [dashboard_data objectForKey:@"time_utc"];
            NSNumber* CO2           = [dashboard_data objectForKey:@"CO2"];
            NSNumber* Humidity      = [dashboard_data objectForKey:@"Humidity"];
            NSNumber* Noise         = [dashboard_data objectForKey:@"Noise"];
            NSNumber* Pressure      = [dashboard_data objectForKey:@"Pressure"];
            NSNumber* Temperature   = [dashboard_data objectForKey:@"Temperature"];
            NSNumber* min_temp      = [dashboard_data objectForKey:@"min_temp"];
            NSNumber* max_temp      = [dashboard_data objectForKey:@"max_temp"];
            
            if ( time_utc != nil && stationMac != nil )
            {
                [DataRetriever setDateTimestamp:time_utc forMeasureDict:dataToCache];
                
                /* tip: enum _dashBoardMaxScaleData and _dashBoardDayScaleData is not in conflict with int values :
                 because this is redeclaration of NAMeasureType !!! */
                
                [DataRetriever setValue: Temperature      forType: NAMeasureTypeTemperature       inDictionary:dataToCache];
                [DataRetriever setValue: Humidity         forType: NAMeasureTypeHumidity          inDictionary:dataToCache];
                [DataRetriever setValue: Pressure         forType: NAMeasureTypePressure          inDictionary:dataToCache];
                [DataRetriever setValue: CO2              forType: NAMeasureTypeCO2               inDictionary:dataToCache];
                [DataRetriever setValue: Noise            forType: NAMeasureTypeNoise             inDictionary:dataToCache];
                
                [DataRetriever setValue: min_temp         forType: NAMeasureTypeTemperatureMin    inDictionary:dataToCache];
                [DataRetriever setValue: max_temp         forType: NAMeasureTypeTemperatureMax    inDictionary:dataToCache];
                
                
                /* Update Application Cache */
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    successCompletion(stationMac, dataToCache);
                });
            }
            
        }
        
    }
    
    
    NSString* moduleTypeInterieur 			= @"NAModule4";
    NSString* moduleTypeExterieur 			= @"NAModule1";
    NSString* moduleTypeExterieurPluvmtr 	= @"NAModule3";
    NSString* moduleTypeExterieurAnemomtr 	= @"NAModule2";

    
    for( NSDictionary *module in [[NADeviceList gDeviceList] moduleList] )
    {
        if (![module isKindOfClass:[NSDictionary class]])
        {
            continue;
        }
        
        NSDictionary* dashboard_data        = [ module objectForKey:@"dashboard_data" ];
        NSString* moduleType                = [ module valueForKey: @"type" ];
        NSString* moduleMac                 = [ module valueForKey: @"_id" ];
        NSNumber* time_utc                  = [ dashboard_data objectForKey:@"time_utc" ];
        
        
        if (   dashboard_data != nil
            && time_utc != nil
            && moduleMac != nil
            && moduleType != nil ) {
            
            NSMutableDictionary* dataToCache    = [[NSMutableDictionary alloc] init] ;
            
            [DataRetriever setDateTimestamp:time_utc forMeasureDict:dataToCache];
            
            NTAPRINT(@"moduleMac:%@, moduleType:%@", moduleMac, moduleType);
            
            
            if ( [moduleTypeInterieur isEqual:moduleType ] ) /* interieur module */
            {
                
                NSNumber* CO2           = [dashboard_data objectForKey:@"CO2"];
                NSNumber* Humidity      = [dashboard_data objectForKey:@"Humidity"];
                NSNumber* Temperature   = [dashboard_data objectForKey:@"Temperature"];
                NSNumber* min_temp      = [dashboard_data objectForKey:@"min_temp"];
                NSNumber* max_temp      = [dashboard_data objectForKey:@"max_temp"];
                
                [DataRetriever setValue: CO2         forType: NAMeasureTypeCO2            inDictionary:dataToCache];
                [DataRetriever setValue: Humidity    forType: NAMeasureTypeHumidity       inDictionary:dataToCache];
                [DataRetriever setValue: Temperature forType: NAMeasureTypeTemperature    inDictionary:dataToCache];
                [DataRetriever setValue: min_temp    forType: NAMeasureTypeTemperatureMin inDictionary:dataToCache];
                [DataRetriever setValue: max_temp    forType: NAMeasureTypeTemperatureMax inDictionary:dataToCache];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCompletion(moduleMac, dataToCache);
                });
            }
            else if ( [moduleTypeExterieur isEqual:moduleType ] ) /* ext module */
            {
                
                NSNumber* Temperature   = [ dashboard_data objectForKey:@"Temperature" ];
                NSNumber* Humidity      = [ dashboard_data objectForKey:@"Humidity" ];
                NSNumber* min_temp      = [ dashboard_data objectForKey:@"min_temp" ];
                NSNumber* max_temp      = [ dashboard_data objectForKey:@"max_temp" ];
                
                
                [DataRetriever setValue: Temperature      forType: NAMeasureTypeTemperature    inDictionary:dataToCache];
                [DataRetriever setValue: Humidity         forType: NAMeasureTypeHumidity       inDictionary:dataToCache];
                [DataRetriever setValue: min_temp         forType: NAMeasureTypeTemperatureMin inDictionary:dataToCache];
                [DataRetriever setValue: max_temp         forType: NAMeasureTypeTemperatureMax inDictionary:dataToCache];
                
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    /* Update Application Cache */
                    successCompletion(moduleMac, dataToCache);
                });
                
            }
            else if ( [moduleTypeExterieurPluvmtr isEqual:moduleType ] ) /* ext module pluvio */
            {
                NSNumber* sumRain1     = [ dashboard_data objectForKey: NAAPISumRain1];
                NSNumber* sumRain24    = [ dashboard_data objectForKey: NAAPISumRain24 ];
                
                [DataRetriever setValue: sumRain1 forType: NAMeasureTypeRainPerHour   inDictionary:dataToCache];
                [DataRetriever setValue: sumRain24 forType: NAMeasureTypeRainDay   inDictionary:dataToCache];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    /* Update Application Cache */
                    successCompletion(moduleMac, dataToCache);
                });
            }
            else if ( [moduleTypeExterieurAnemomtr isEqual:moduleType ] ) /* ext module anemo */
            {
                NSNumber* windAngle = [dashboard_data objectForKey: NAAPIWindAngle];
                NSNumber* windStrength = [dashboard_data objectForKey: NAAPIWindStrength];

                [DataRetriever setValue: windAngle forType: NAMeasureTypeWindAngle inDictionary:dataToCache];
                [DataRetriever setValue: windStrength forType: NAMeasureTypeWindStrength inDictionary:dataToCache];

                dispatch_async(dispatch_get_main_queue(), ^{
                    /* Update Application Cache */
                    successCompletion(moduleMac, dataToCache);
                });
            }
        }
    }
}

#pragma mark - Station/Module Data Reliability Methods

- (BOOL)stationDataMoreRecentThan:(CGFloat) threshold
{
    NSDate *currentDate = [[NADeviceList gDeviceList] currentDateForDataReliability];
    
    NSTimeInterval timeInterval = 0;
    
    NSDictionary *station = [[NADeviceList gDeviceList] currentDevice];
    NSDate *stationMeasuresDate = [NSDate dateWithTimeIntervalSince1970:[station[@"dashboard_data"][@"time_utc"] doubleValue]];
    
    timeInterval = [currentDate timeIntervalSinceDate: stationMeasuresDate];
    if(timeInterval < threshold && timeInterval > -threshold)
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)stationDataReliable
{
    return [[NADeviceList gDeviceList] stationDataMoreRecentThan: NA_DATA_OUTDATED_ABSOLUTE_THRESHOLD];
}

- (BOOL)isDataReliableForModule: (NSString *)moduleId
{
    CGFloat threshold = NA_DATA_OUTDATED_ABSOLUTE_THRESHOLD;
    
    NSDate *currentDate = [[NADeviceList gDeviceList] currentDateForDataReliability];
    
    NSTimeInterval timeInterval = 0;
    
    NSDictionary *module = [[NADeviceList gDeviceList] moduleWithId:moduleId];
    NSDictionary *station = [[NADeviceList gDeviceList] deviceWithId:module[@"main_device"]];
    if (!module) {
        //If we don't find it as a "pure" module, we search in the device list
        //because, in order to be convenient for indoor module search, we need
        //to be able to search for station as a standard "indoor module"
        module = [[NADeviceList gDeviceList] deviceWithId:moduleId];
        station = module;
    }
    NSDate *moduleMeasuresDate = [NSDate dateWithTimeIntervalSince1970:[module[@"dashboard_data"][@"time_utc"] doubleValue]];
    
    NSDate *stationMeasuresDate = [NSDate dateWithTimeIntervalSince1970:[station[@"dashboard_data"][@"time_utc"] doubleValue]];
    
    NSTimeInterval relativeTimeInterval = 0;
    
    timeInterval = [currentDate timeIntervalSinceDate: moduleMeasuresDate];
    if(timeInterval < threshold && timeInterval > -threshold)
    {
        relativeTimeInterval = [moduleMeasuresDate timeIntervalSinceDate: stationMeasuresDate];
        if(relativeTimeInterval <= NA_INDOOR_DATA_OUTDATED_RELATIVE_THRESHOLD && relativeTimeInterval >= -NA_INDOOR_DATA_OUTDATED_RELATIVE_THRESHOLD)
        {
            return YES;
        }
    }
    
    return NO;
}

- (NSDate*) currentDateForDataReliability
{
    //We use the date of the server for the current date in order to be sure
    //we make update decision accurately despite the phone's local date being wrong.
    NSDate *currentDate = nil;
    if ([[NAAPI gUserAPI] respondsToSelector:@selector(timeServer)] && [[NAAPI gUserAPI] timeServer]) {
        currentDate = [[NAAPI gUserAPI] timeServer];
    }
    else
    {
        currentDate = [NSDate date];
    }
    return currentDate;
}

@end
