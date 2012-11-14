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


#import "DistantDataHandler.h"
#import "NAMeasure.h"

#import "AppliCommonPrivate.h"



#define kRequestUserInfoDeviceId        @"kRequestUserInfoDeviceId"

#define kRequestUserInfoScaleType       @"kRequestUserInfoScaleType"
#define kRequestUserInfoScaleTypeDay    @"kRequestUserInfoScaleTypeDay"
#define kRequestUserInfoScaleTypeMax    @"kRequestUserInfoScaleTypeMax"

@interface DistantDataHandler ()

+ (BOOL)checkResponseBody: (id)responseBody 
                  forType: (NSString *)type;
+ (NSMutableDictionary *)parseMaxScaleMeasures: (id)measureArray;
+ (NSMutableDictionary *)parseDayScaleMeasures: (id)measureArray;

- (void)requestDidSucceed;
- (void)requestDidFailWithError: (NSError *)error;

@end


@implementation DistantDataHandler


static const int _dashBoardMaxScaleData[DDH_MAX_SCALE_DATA_NUMBER] = 
{
    NAMeasureTypeTemperature,
    NAMeasureTypeHumidity,
    NAMeasureTypePressure,
    NAMeasureTypeCO2,
    NAMeasureTypeNoise
};

static const int _dashBoardDayScaleData[DDH_DAY_SCALE_DATA_NUMBER] = 
{
    NAMeasureTypeTemperatureMin,
    NAMeasureTypeTemperatureMax,
};





#pragma mark - DataHandler lifecycle

- (id)initWithDelegate:(id<DataHandlerDelegate>)delegate
{
    self = [super initWithDelegate: delegate];
    
    if(self)
    {
        _type = kDataHandlerTypeDistant;
        
        _refreshInterval = DDH_REFRESH_INTERVAL;
        
        _retryMax = DDH_RETRY_MAX;
        _retryNumber = 0;
        _retryInterval = DDH_RETRY_INTERVAL;
        
        
        _maxScaleDataArray = [[NSMutableArray alloc] init];
        _dayScaleDataArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [[NAAPI gUserAPI] cancelRequestsWithDelegate:self];

    NTA_RELEASE_SAFELY(_maxScaleDataArray);
    NTA_RELEASE_SAFELY(_dayScaleDataArray);
    
    [super dealloc];
}





#pragma mark - DataHandler override

- (void)start
{
    NTAPRINT(@"...DistantDataHandler start");

    [super start];
}


- (void)stop
{
    NTAPRINT(@"...DistantDataHandler stop");
    
    [super stop];
}


- (void)hookDeviceById: (NSString *)deviceId
{
    [super hookDeviceById: deviceId];

    [self hookModuleById:nil fromDeviceById:deviceId];
}

- (void)hookModuleById: (NSString *)moduleId fromDeviceById: (NSString *)deviceId
{    
    // Retrieving max scale data (listed in _dashBoardMaxScaleData)
    
    NSMutableDictionary *userInfoScaleMax =[NSMutableDictionary dictionary];
    NSString *uiDeviceId;
    uiDeviceId = (nil != moduleId)? moduleId: deviceId;
    [userInfoScaleMax setValue: uiDeviceId 
                        forKey: kRequestUserInfoDeviceId];
    [userInfoScaleMax setValue: kRequestUserInfoScaleTypeMax 
                        forKey: kRequestUserInfoScaleType];
    
    // get JSON keys for data types
    NSString *maxScaleDataTypeString = @"";
    for(int i = 0 ; i < DDH_MAX_SCALE_DATA_NUMBER ; i++)
    {
        maxScaleDataTypeString = [maxScaleDataTypeString stringByAppendingString: stringForMeasureType(_dashBoardMaxScaleData[i])];
        if(i != DDH_MAX_SCALE_DATA_NUMBER - 1)
            maxScaleDataTypeString = [maxScaleDataTypeString stringByAppendingString: @","];
    }
    
    // format and send request to the server
    // answer will be forwarded by NAAPIRequestDelegate methods
    if (nil != moduleId) {
        [[NAAPI gUserAPI] sendApiRequestWithMethod: @"getmeasure" 
                                          delegate: self
                                cacheExpirationAge: NA_CACHE_EXPIRATION_NO_CACHE
                                       addUserInfo: userInfoScaleMax
                               paramsValuesAndKeys: 
         deviceId, @"device_id",
         moduleId, @"module_id",
         maxScaleDataTypeString, @"type",
         @"max", @"scale",
         @"last", @"date_end",
         nil];

    } else {
        [[NAAPI gUserAPI] sendApiRequestWithMethod: @"getmeasure" 
                                          delegate: self
                                cacheExpirationAge: NA_CACHE_EXPIRATION_NO_CACHE
                                       addUserInfo: userInfoScaleMax
                               paramsValuesAndKeys: 
         deviceId, @"device_id",
         maxScaleDataTypeString, @"type",
         @"max", @"scale",
         @"last", @"date_end",
         nil];

    }
        
    
    
    // Retrieving day scale data (listed in _dashBoardDayScaleData)
    
    NSMutableDictionary *userInfoScaleDay =[NSMutableDictionary dictionary];
    [userInfoScaleDay setValue: uiDeviceId 
                        forKey: kRequestUserInfoDeviceId];
    [userInfoScaleDay setValue: kRequestUserInfoScaleTypeDay
                        forKey: kRequestUserInfoScaleType];
    
    // get JSON keys for data types
    NSString *dayScaleDataTypeString = @"";
    for(int i = 0 ; i < DDH_DAY_SCALE_DATA_NUMBER ; i++)
    {
        dayScaleDataTypeString = [dayScaleDataTypeString stringByAppendingString: stringForMeasureType(_dashBoardDayScaleData[i])];
        if(i != DDH_DAY_SCALE_DATA_NUMBER - 1)
            dayScaleDataTypeString = [dayScaleDataTypeString stringByAppendingString: @","];
    }
    
    // format and send request to the server
    // answer will be forwarded by NAAPIRequestDelegate methods
    if (nil != moduleId) {
        [[NAAPI gUserAPI] sendApiRequestWithMethod: @"getmeasure" 
                                          delegate: self
                                cacheExpirationAge: NA_CACHE_EXPIRATION_NO_CACHE
                                       addUserInfo: userInfoScaleDay
                               paramsValuesAndKeys: 
         deviceId, @"device_id",
         moduleId, @"module_id",
         dayScaleDataTypeString, @"type",
         @"1day", @"scale",
         @"last", @"date_end",
         nil];
    } else {
        [[NAAPI gUserAPI] sendApiRequestWithMethod: @"getmeasure" 
                                          delegate: self
                                cacheExpirationAge: NA_CACHE_EXPIRATION_NO_CACHE
                                       addUserInfo: userInfoScaleDay
                               paramsValuesAndKeys: 
         deviceId, @"device_id",
         dayScaleDataTypeString, @"type",
         @"1day", @"scale",
         @"last", @"date_end",
         nil];
    }
}





- (NSDictionary *)parseMeasures: (id)measureArray
                       userInfo: (NSDictionary *)userInfo
{
    NTAPRINT();
    
    if(![userInfo isKindOfClass: [NSDictionary class]])
    {
        NTAPRINT(@"userInfo is expected to be a NSDictionary object. Abort parsing.");
        return nil;
    }
    NSString *type = [userInfo valueForKey: kRequestUserInfoScaleType];
    NSString *deviceId = [userInfo valueForKey: kRequestUserInfoDeviceId];
    
    if((type == nil) || (deviceId == nil))
    {
        NTAPRINT(@"Unexpected userInfo.");
        return nil; 
    }
    
    NSMutableDictionary *result = nil;
    if([type isEqualToString: kRequestUserInfoScaleTypeDay])
    {
        result = [DistantDataHandler parseDayScaleMeasures: measureArray];
        if (nil == result) {
            result = [NSMutableDictionary dictionary];
        }
        [result setValue: deviceId forKey: kDeviceMeasuresDeviceId];
        
        [_dayScaleDataArray addObject:result];
    }
    else if([type isEqualToString: kRequestUserInfoScaleTypeMax])
    {
        result = [DistantDataHandler parseMaxScaleMeasures: measureArray];
        if (nil == result) {
            result = [NSMutableDictionary dictionary];
        }
        [result setValue: deviceId forKey: kDeviceMeasuresDeviceId];
            
        [_maxScaleDataArray addObject:result];
        
    }
    return result;
}





#pragma mark - DistantDataHandler internal

+ (BOOL)checkResponseBody: (id)responseBody 
                  forType: (NSString *)type
{
    if(![responseBody isKindOfClass: [NSArray class]])
    {
        NTAPRINT(@"Unexpected responseBody.");
        return NO;
    }
    
    if([responseBody count] != 1)
    {
        NTAPRINT(@"Unexpected responseBody size.");
        return NO;
    }    
    
    id data = [responseBody objectAtIndex: 0];
    if(![data isKindOfClass: [NSDictionary class]])
    {
        NTAPRINT(@"Unexpected data.");
        return NO;
    }
    
    NSArray *valueArray = [data valueForKey: @"value"];
    if(![valueArray isKindOfClass: [NSArray class]])
    {
        NTAPRINT(@"Unexpected value object.");
        return NO;
    }
    
    
    if([type isEqualToString: kRequestUserInfoScaleTypeDay])
    {
        if([[valueArray objectAtIndex: 0] count] != DDH_DAY_SCALE_DATA_NUMBER)
        {
            NTAPRINT(@"Unexpected value number (%d).", [[valueArray objectAtIndex: 0] count]);
            return NO;            
        }
    }
    else if([type isEqualToString: kRequestUserInfoScaleTypeMax])
    {
        if([[valueArray objectAtIndex: 0] count] != DDH_MAX_SCALE_DATA_NUMBER)
        {
            NTAPRINT(@"Unexpected value number (%d).", [[valueArray objectAtIndex: 0] count]);
            return NO; 
        }
    }
    else
    {
        NTAPRINT(@"Unknown type.");
        return NO;
    }
    
    return YES;
}


+ (NSMutableDictionary *)parseDayScaleMeasures: (id)measureArray
{
    NTAPRINT();
    
    if(![DistantDataHandler checkResponseBody: measureArray 
                                      forType: kRequestUserInfoScaleTypeDay])
    {
        NTAPRINT(@"Unexpected data. Abort parsing.");
        return nil;
    }
    
    NSArray *values = [[[measureArray objectAtIndex: 0] valueForKey: NAAPIMeteogroupValue] objectAtIndex: 0];
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for(int i = 0 ; i < DDH_DAY_SCALE_DATA_NUMBER ; i++)
    {
        [DataHandler setValue: [values objectAtIndex: i] 
                      forType: _dashBoardDayScaleData[i] 
                 inDictionary: result];
    }
    [result setValue: [[measureArray objectAtIndex: 0] valueForKey: NAAPIMeteogroupDateBegin] 
              forKey: kDeviceMeasuresTimestamp];
    
    return result;
}


+ (NSMutableDictionary *)parseMaxScaleMeasures:(id)measureArray
{
    NTAPRINT();
    
    if(![DistantDataHandler checkResponseBody: measureArray 
                                      forType: kRequestUserInfoScaleTypeMax])
    {
        NTAPRINT(@"Unexpected data. Abort parsing.");
        return nil;
    }
    
    NSArray *values = [[[measureArray objectAtIndex: 0] valueForKey: NAAPIMeteogroupValue] objectAtIndex: 0];
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for(int i = 0 ; i < DDH_MAX_SCALE_DATA_NUMBER ; i++)
    {
        [DataHandler setValue: [values objectAtIndex: i] 
                      forType: _dashBoardMaxScaleData[i] 
                 inDictionary: result];
    }
    [result setValue: [[measureArray objectAtIndex: 0] valueForKey: NAAPIMeteogroupDateBegin] 
              forKey: kDeviceMeasuresTimestamp];
    
    return result;
}


- (void)requestDidSucceed
{
    NSString *deviceId = nil;
    NSMutableDictionary *result = nil, *maxScaleData = nil, *dayScaleData = nil;
    for (int i = 0; i < _maxScaleDataArray.count && nil == result; i++) {
        maxScaleData = [_maxScaleDataArray objectAtIndex:i];
        deviceId = [maxScaleData valueForKey:kDeviceMeasuresDeviceId];
        if (nil != deviceId) {
            for (int j=0; j < _dayScaleDataArray.count; j++) {
                dayScaleData = [_dayScaleDataArray objectAtIndex:j];
                
                if ([dayScaleData valueForKey:kDeviceMeasuresDeviceId] == deviceId) {
                    //Matching day/max scale measures! We can store them
                    result = [[NSMutableDictionary alloc] init];
                    
                    [dayScaleData removeObjectForKey: kDeviceMeasuresTimestamp];
                    [result addEntriesFromDictionary: dayScaleData];
                    [result addEntriesFromDictionary: maxScaleData];
                    
                    //clean
                    
                    [_maxScaleDataArray removeObjectAtIndex:i];
                    [_dayScaleDataArray removeObjectAtIndex:j];
                    
                    //only one hit per call (as it is called after every measures set received)
                    break;
                }
            }
        }
    }
    if (nil != result && [result valueForKey: kDeviceMeasuresTimestamp] != nil) {
        [self.delegate dataHandler: kDataHandlerTypeDistant 
                didReceiveMeasures: result];
    }
    
    [result release];
}


- (void)requestDidFailWithError: (NSError *)error
{
    NSString *deviceId = [error.userInfo valueForKey:kRequestUserInfoDeviceId];
    
    //Cleaning of the array
    NSMutableDictionary *maxScaleData = nil, *dayScaleData = nil;
    if (nil != deviceId) {
        for (int i = 0; i < _maxScaleDataArray.count; i++) {
            maxScaleData = [_maxScaleDataArray objectAtIndex:i];
            if ([maxScaleData valueForKey:kDeviceMeasuresDeviceId] == deviceId) {
                [_maxScaleDataArray removeObjectAtIndex:i];
                i--;
            }
        }
        
        for (int i = 0; i < _dayScaleDataArray.count; i++) {
            dayScaleData = [_dayScaleDataArray objectAtIndex:i];
            if ([dayScaleData valueForKey:kDeviceMeasuresDeviceId] == deviceId) {
                [_dayScaleDataArray removeObjectAtIndex:i];
                i--;
            }
        }
    }
    
    [self.delegate dataHandler: kDataHandlerTypeDistant 
              didFailWithError: error];
}






#pragma mark - NAAPIRequestDelegate


-(void)apiRequestDidSucceedWithBody:(id)responseBody userInfo:(NSDictionary*) ourUserInfo
{
    // parse data from server
    [self parseMeasures: responseBody 
               userInfo: ourUserInfo];
    
    [self requestDidSucceed];
}


-(void)apiRequestDidFailWithError:(NtmoAPIErrorCode)error userInfo:(NSDictionary*) ourUserInfo
{    
    [self requestDidFailWithError: [NSError errorWithDomain: kNAAPIErrorDomain 
                                                       code: error 
                                                   userInfo: ourUserInfo]];
}




@end
