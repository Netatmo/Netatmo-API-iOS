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


#import "MainTableViewController.h"

#define STATION_NAME                                0
#define STATION_NAME_COUNT                          1

#define MAIN_STATION                                1
#define MAIN_STATION_MEASURES_COUNT                 7
#define MEASURE_INDEX_MAIN_STATION_TEMPERATURE      0
#define MEASURE_INDEX_MAIN_STATION_MIN_TEMPERATURE  1
#define MEASURE_INDEX_MAIN_STATION_MAX_TEMPERATURE  2
#define MEASURE_INDEX_MAIN_STATION_HUMIDITY         3
#define MEASURE_INDEX_MAIN_STATION_PRESSURE         4
#define MEASURE_INDEX_MAIN_STATION_CO2              5
#define MEASURE_INDEX_MAIN_STATION_NOISE            6

#define INDOOR_MESURES_COUNT                        5
#define MEASURE_INDEX_INDOOR_TEMPERATURE            0
#define MEASURE_INDEX_INDOOR_MIN_TEMPERATURE        1
#define MEASURE_INDEX_INDOOR_MAX_TEMPERATURE        2
#define MEASURE_INDEX_INDOOR_HUMIDITY               3
#define MEASURE_INDEX_INDOOR_CO2                    4

#define OUTDOOR_MEASURES_COUNT                      4
#define MEASURE_INDEX_OUTDOOR_TEMPERATURE           0
#define MEASURE_INDEX_OUTDOOR_MIN_TEMPERATURE       1
#define MEASURE_INDEX_OUTDOOR_MAX_TEMPERATURE       2
#define MEASURE_INDEX_OUTDOOR_HUMIDITY              3

#define PLUVIO_MEASURES_COUNT                       2
#define MEASURE_INDEX_PLUVIO_RAIN_SUM1              0
#define MEASURE_INDEX_PLUVIO_RAIN_SUM24             1

#define ANEMO_MEASURES_COUNT                       2
#define MEASURE_INDEX_ANEMO_WIND_ANGLE             0
#define MEASURE_INDEX_ANEMO_WIND_STRENGTH          1


@interface MainTableViewController ()

@property (nonatomic, strong, readwrite) NSString *titleTemperature;
@property (nonatomic, strong, readwrite) NSString *titleMinTemperature;
@property (nonatomic, strong, readwrite) NSString *titleMaxTemperature;
@property (nonatomic, strong, readwrite) NSString *titleHumidity;
@property (nonatomic, strong, readwrite) NSString *titlePressure;
@property (nonatomic, strong, readwrite) NSString *titleCO2;
@property (nonatomic, strong, readwrite) NSString *titleNoise;

@property (nonatomic, strong, readwrite) NSString *titlePluvioSumRain1;
@property (nonatomic, strong, readwrite) NSString *titlePluvioSumRain24;

@property (nonatomic, strong, readwrite) NSString *titleAnemoWindAngle;
@property (nonatomic, strong, readwrite) NSString *titleAnemoWindStrength;

@property (nonatomic, strong, readwrite) NSString *indoorModuleType;
@property (nonatomic, strong, readwrite) NSString *outdoorModuleType;
@property (nonatomic, strong, readwrite) NSString *pluvioModuleType;
@property (nonatomic, strong, readwrite) NSString *anemoModuleType;

@property (nonatomic, strong, readwrite) NSString *cellIdentifier;

@property (nonatomic, assign, readwrite) BOOL showAlert;

@end

@implementation MainTableViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor whiteColor];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self
                            action:@selector(retrieveData)
                  forControlEvents:UIControlEventValueChanged];
    
    self.cellIdentifier = @"MainViewCustomCell";
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MainViewCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:self.cellIdentifier];
    
    self.indoorModuleType =     @"NAModule4";
    self.outdoorModuleType =    @"NAModule1";
    self.pluvioModuleType = @"NAModule3";
    self.anemoModuleType = @"NAModule2";
    
    // Graphics
    self.titleTemperature =     @"Temperature";
    self.titleMinTemperature =  @"Min. temperature";
    self.titleMaxTemperature =  @"Max. temperature";
    self.titleHumidity =        @"Humidity";
    self.titlePressure =        @"Pressure";
    self.titleCO2 =             @"CO2";
    self.titleNoise =           @"Noise";
    
    self.titlePluvioSumRain1 =  @"Rain last hour";
    self.titlePluvioSumRain24 = @"Rain today";

    self.titleAnemoWindAngle =    @"Wind angle";
    self.titleAnemoWindStrength = @"Wind strength";

    self.tableView.rowHeight = 44;
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    if (![[NAAPI gUserAPI] hasAccountRelated]) {
        [self showLoginViewController:NO];
    }
    else {
        [[DataRetriever gDataRetriever] setDelegate:self];
        self.showAlert = YES;
        [self retrieveData];
        [self.tableView reloadData];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) appDidEnterBackground
{
    [self.refreshControl endRefreshing];
}


- (IBAction)logoutButtonListener:(id)sender
{
    [self logout];
}

- (IBAction)userInfosButtonListener:(id)sender
{
    [self performSegueWithIdentifier:@"MainToUserInfosViewController" sender:self];
}


#pragma mark - private methods

- (void) retrieveData
{
    self.showAlert = YES;
    [[DataRetriever gDataRetriever] start];
}


- (void) logout
{
    [self.refreshControl endRefreshing];
    [[DataRetriever gDataRetriever] cancelOnGoingSync];
    [[NAUser globalUser] deleteAllUserData];
    [self showLoginViewController:YES];
}


- (void) showLoginViewController: (BOOL) animated
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UITabBarController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [self presentViewController:loginViewController animated:animated completion:nil];
}


#pragma mark - DataRetreiverDelegate

- (void)dataDidUpdateForDevice: (NSString *)deviceId
{
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (void)dataDidFail:(NtmoAPIErrorCode)error
{
    [self.refreshControl endRefreshing];
    
    if (error == NtmoAPIErrorCodeUserNeedToLogIn)
    {
        [self logout];
    }
    else if (error == NtmoAPIErrorCodeDeviceNotFound && self.showAlert)
    {
        [self alertuser:@"No device associated to this account"];
    }
    else if (error == NtmoAPIErrorCodeNoDataConnection && self.showAlert)
    {
        [self alertuser:@"No internet connection"];
    }
    else if (self.showAlert)
    {
        [self alertuser:@"Sync failed"];
    }
}

- (void) alertuser : (NSString *) title
{
    self.showAlert = NO;
    [[[UIAlertView alloc] initWithTitle: @""
                                message: title
                               delegate: nil
                      cancelButtonTitle: @"OK"
                      otherButtonTitles: nil] show];
}


#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"MainToStationViewController" sender:self];
}

- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
    return [[[NADeviceList gDeviceList] modulesIdList] count] + 2;
}

- (NSString *)tableView: (UITableView *)tableView
titleForHeaderInSection: (NSInteger)section
{
    if (section == STATION_NAME)
    {
        return @"Station";
    }
    
    
    if (section == MAIN_STATION)
    {
        return @"Main Station";
    }
    
    NSString *deviceId = [[[NADeviceList gDeviceList] modulesIdList]objectAtIndex:(section - 2)];
    NSString *nameForModule = [[NADeviceList gDeviceList] nameForModule:deviceId];
    
    if (nameForModule == nil)
    {
        nameForModule = @"";
    }
    
    nameForModule = [@" - " stringByAppendingString:nameForModule];
    
    if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.indoorModuleType])
    {
        return [@"Indoor Module" stringByAppendingString:nameForModule];
    }
    else if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.outdoorModuleType])
    {
        return [@"Outdoor Module" stringByAppendingString:nameForModule];
    }
    else if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.pluvioModuleType])
    {
        return [@"Pluvio Module" stringByAppendingString:nameForModule];
    }
    else if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.anemoModuleType])
    {
        return [@"Anémo Module" stringByAppendingString:nameForModule];
    }
    
    return nameForModule;
}

- (NSInteger)tableView: (UITableView *)tableView
 numberOfRowsInSection: (NSInteger)section
{
    
    if (section == STATION_NAME)
    {
        return STATION_NAME_COUNT;
    }
    
    if (section == MAIN_STATION)
    {
        return MAIN_STATION_MEASURES_COUNT;
    }
    
    NSString *deviceId = [[[NADeviceList gDeviceList] modulesIdList]objectAtIndex:(section - 2)];
    
    if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.indoorModuleType])
    {
        return INDOOR_MESURES_COUNT;
    }
    else if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.outdoorModuleType])
    {
        return OUTDOOR_MEASURES_COUNT;
    }
    else if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.pluvioModuleType])
    {
        return PLUVIO_MEASURES_COUNT;
    }
    else if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.anemoModuleType])
    {
        return ANEMO_MEASURES_COUNT;
    }

    return 0;
}

- (MainTableViewCell *)tableView: (UITableView *)tableView
           cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    MainTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:self.cellIdentifier
                                                                   forIndexPath:indexPath];
    cell.userInteractionEnabled = NO;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (indexPath.section == STATION_NAME)
    {
        NSString *nameForStation = [[NADeviceList gDeviceList] currentDeviceName];
        if (nameForStation == nil)
        {
            nameForStation = @"--";
        }
        cell.title.text = nameForStation;
        cell.value.text = @"";
        cell.userInteractionEnabled = YES;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.section == MAIN_STATION)
    {
        
        NSDictionary *data = [[DataRetriever gDataRetriever] getMeasuresForDeviceId:[[NADeviceList gDeviceList] currentDeviceId]];
        
        BOOL stationDataReliable = [[DataRetriever gDataRetriever] stationDataReliable];
        if(indexPath.row == MEASURE_INDEX_MAIN_STATION_TEMPERATURE)
        {
            cell.title.text = self.titleTemperature;
            if ([[DataRetriever valueForType:NAMeasureTypeTemperature inDictionary:data] isKindOfClass:[NSNumber class]] && stationDataReliable)
            {
                cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeTemperature inDictionary:data]];
                cell.value.text = [cell.value.text stringByAppendingString:@"°C"];
            }
            else
            {
                cell.value.text = @"--";
            }
        }
        else if(indexPath.row == MEASURE_INDEX_MAIN_STATION_MIN_TEMPERATURE)
        {
            cell.title.text = self.titleMinTemperature;
            cell.value.text = @"%f", [DataRetriever valueForType:NAMeasureTypeTemperatureMin inDictionary:data];
            if ([[DataRetriever valueForType:NAMeasureTypeTemperatureMin inDictionary:data] isKindOfClass:[NSNumber class]] && stationDataReliable)
            {
                cell.value.text = [[NSString alloc] initWithFormat:@"%@",[DataRetriever valueForType:NAMeasureTypeTemperatureMin inDictionary:data]];
                cell.value.text = [cell.value.text stringByAppendingString:@"°C"];
            }
            else
            {
                cell.value.text = @"--";
            }
        }
        else if(indexPath.row == MEASURE_INDEX_MAIN_STATION_MAX_TEMPERATURE)
        {
            cell.title.text = self.titleMaxTemperature;
            if ([[DataRetriever valueForType:NAMeasureTypeTemperatureMax inDictionary:data] isKindOfClass:[NSNumber class]] && stationDataReliable)
            {
                cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeTemperatureMax inDictionary:data]];
                cell.value.text = [cell.value.text stringByAppendingString:@"°C"];
            }
            else
            {
                cell.value.text = @"--";
            }
        }
        else if(indexPath.row == MEASURE_INDEX_MAIN_STATION_HUMIDITY)
        {
            cell.title.text = self.titleHumidity;
            if ([[DataRetriever valueForType:NAMeasureTypeHumidity inDictionary:data] isKindOfClass:[NSNumber class]] && stationDataReliable)
            {
                cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeHumidity inDictionary:data]];
                cell.value.text = [cell.value.text stringByAppendingString:@"%"];
            }
            else
            {
                cell.value.text = @"--";
            }
        }
        else if(indexPath.row == MEASURE_INDEX_MAIN_STATION_PRESSURE)
        {
            cell.title.text = self.titlePressure;
            if ([[DataRetriever valueForType:NAMeasureTypePressure inDictionary:data] isKindOfClass:[NSNumber class]] && stationDataReliable)
            {
                cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypePressure inDictionary:data]];
                cell.value.text = [cell.value.text stringByAppendingString:@"mb"];
            }
            else
            {
                cell.value.text = @"--";
            }
        }
        else if(indexPath.row == MEASURE_INDEX_MAIN_STATION_CO2)
        {
            cell.title.text = self.titleCO2;
            if ([[DataRetriever valueForType:NAMeasureTypeCO2 inDictionary:data] isKindOfClass:[NSNumber class]] && stationDataReliable)
            {
                cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeCO2 inDictionary:data]];
                cell.value.text = [cell.value.text stringByAppendingString:@"ppm"];
            }
            else
            {
                cell.value.text = @"--";
            }
        }
        else if(indexPath.row == MEASURE_INDEX_MAIN_STATION_NOISE)
        {
            cell.title.text = self.titleNoise;
            if ([[DataRetriever valueForType:NAMeasureTypeNoise inDictionary:data] isKindOfClass:[NSNumber class]] && stationDataReliable)
            {
                cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeNoise inDictionary:data]];
                cell.value.text = [cell.value.text stringByAppendingString:@"dB"];
            }
            else
            {
                cell.value.text = @"--";
            }
        }
        
    }
    else
    {
        NSString *deviceId = [[[NADeviceList gDeviceList] modulesIdList] objectAtIndex:(indexPath.section - 2)];
        NSDictionary *data = [[DataRetriever gDataRetriever] getMeasuresForDeviceId:deviceId];
        BOOL dataReliableForModule = [[DataRetriever gDataRetriever] isDataReliableForModule:deviceId];
        
        if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.indoorModuleType])
        {
            if (indexPath.row == MEASURE_INDEX_INDOOR_TEMPERATURE)
            {
                cell.title.text = self.titleTemperature;
                if ([[DataRetriever valueForType:NAMeasureTypeTemperature inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeTemperature inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"°C"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
            else if (indexPath.row == MEASURE_INDEX_INDOOR_MIN_TEMPERATURE)
            {
                cell.title.text = self.titleMinTemperature;
                if ([[DataRetriever valueForType:NAMeasureTypeTemperatureMin inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeTemperatureMin inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"°C"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
            else if (indexPath.row == MEASURE_INDEX_INDOOR_MAX_TEMPERATURE)
            {
                cell.title.text = self.titleMaxTemperature;
                if ([[DataRetriever valueForType:NAMeasureTypeTemperatureMax inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeTemperatureMax inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"°C"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
            else if (indexPath.row == MEASURE_INDEX_INDOOR_HUMIDITY)
            {
                cell.title.text = self.titleHumidity;
                if ([[DataRetriever valueForType:NAMeasureTypeHumidity inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeHumidity inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"%"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
            else if (indexPath.row == MEASURE_INDEX_INDOOR_CO2)
            {
                cell.title.text = self.titleCO2;
                if ([[DataRetriever valueForType:NAMeasureTypeCO2 inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeCO2 inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"ppm"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
        }
        else if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.outdoorModuleType])
        {
            if (indexPath.row == MEASURE_INDEX_OUTDOOR_TEMPERATURE)
            {
                cell.title.text = self.titleTemperature;
                if ([[DataRetriever valueForType:NAMeasureTypeTemperature inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeTemperature inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"°C"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
            else if (indexPath.row == MEASURE_INDEX_OUTDOOR_MIN_TEMPERATURE)
            {
                cell.title.text = self.titleMinTemperature;
                if ([[DataRetriever valueForType:NAMeasureTypeTemperatureMin inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeTemperatureMin inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"°C"];
                }
                else {
                    cell.value.text = @"--";
                }
            }
            else if (indexPath.row == MEASURE_INDEX_OUTDOOR_MAX_TEMPERATURE)
            {
                cell.title.text = self.titleMaxTemperature;
                if ([[DataRetriever valueForType:NAMeasureTypeTemperatureMax inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeTemperatureMax inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"°C"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
            else if (indexPath.row == MEASURE_INDEX_OUTDOOR_HUMIDITY)
            {
                cell.title.text = self.titleHumidity;
                if ([[DataRetriever valueForType:NAMeasureTypeHumidity inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeHumidity inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"%"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
        }
        else if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.pluvioModuleType])
        {
            if (indexPath.row == MEASURE_INDEX_PLUVIO_RAIN_SUM1)
            {
                cell.title.text = self.titlePluvioSumRain1;
                if ([[DataRetriever valueForType:NAMeasureTypeRainPerHour inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeRainPerHour inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"mm"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
            else if (indexPath.row == MEASURE_INDEX_PLUVIO_RAIN_SUM24)
            {
                cell.title.text = self.titlePluvioSumRain24;
                if ([[DataRetriever valueForType:NAMeasureTypeRainDay inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeRainDay inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"mm"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
        }
        else if ([[[NADeviceList gDeviceList] typeForModule:deviceId] isEqual:self.anemoModuleType])
        {
            if (indexPath.row == MEASURE_INDEX_ANEMO_WIND_ANGLE)
            {
                cell.title.text = self.titleAnemoWindAngle;
                if ([[DataRetriever valueForType:NAMeasureTypeWindAngle inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    float angle = [[DataRetriever valueForType:NAMeasureTypeWindAngle inDictionary:data] floatValue];
                    NSString *direction = [NSString new];
                    if ((angle > -11.25 && angle <= 11.25) || (angle > 348.75 && angle <= 371.25))
                    {
                        direction = [direction stringByAppendingString:@"N"];
                    }
                    else if (angle > 11.25 && angle <= 33.75)
                    {
                        direction = [direction stringByAppendingString:@"NNE"];
                    }
                    else if (angle > 33.75 && angle <= 56.25)
                    {
                        direction = [direction stringByAppendingString:@"NE"];
                    }
                    else if (angle > 56.25 && angle <= 78.75)
                    {
                        direction = [direction stringByAppendingString:@"ENE"];
                    }
                    else if (angle > 78.75 && angle <= 101.25)
                    {
                        direction = [direction stringByAppendingString:@"E"];
                    }
                    else if (angle > 101.25 && angle <= 123.75)
                    {
                        direction = [direction stringByAppendingString:@"ESE"];
                    }
                    else if (angle > 123.75 && angle <= 146.25)
                    {
                        direction = [direction stringByAppendingString:@"SE"];
                    }
                    else if (angle > 146.25 && angle <= 168.75)
                    {
                        direction = [direction stringByAppendingString:@"SSE"];
                    }
                    else if (angle > 168.75 && angle <= 191.25)
                    {
                        direction = [direction stringByAppendingString:@"S"];
                    }
                    else if (angle > 191.25 && angle <= 213.75)
                    {
                        direction = [direction stringByAppendingString:@"SSW"];
                    }
                    else if (angle > 213.75 && angle <= 236.25)
                    {
                        direction = [direction stringByAppendingString:@"SW"];
                    }
                    else if (angle > 236.25 && angle <= 258.75)
                    {
                        direction = [direction stringByAppendingString:@"WSW"];
                    }
                    else if (angle > 258.75 && angle <= 281.25)
                    {
                        direction = [direction stringByAppendingString:@"W"];
                    }
                    else if (angle > 281.25 && angle <= 303.75)
                    {
                        direction = [direction stringByAppendingString:@"WNW"];
                    }
                    else if (angle > 303.75 && angle <= 326.25)
                    {
                        direction = [direction stringByAppendingString:@"NW"];
                    }
                    else if (angle > 326.25 && angle <= 348.75)
                    {
                        direction = [direction stringByAppendingString:@"NNW"];
                    }
                    cell.value.text = direction;
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
            else if (indexPath.row == MEASURE_INDEX_ANEMO_WIND_STRENGTH)
            {
                cell.title.text = self.titleAnemoWindStrength;
                if ([[DataRetriever valueForType:NAMeasureTypeWindStrength inDictionary:data] isKindOfClass:[NSNumber class]] && dataReliableForModule)
                {
                    cell.value.text = [[NSString alloc] initWithFormat:@"%@", [DataRetriever valueForType:NAMeasureTypeWindStrength inDictionary:data]];
                    cell.value.text = [cell.value.text stringByAppendingString:@"km/h"];
                }
                else
                {
                    cell.value.text = @"--";
                }
            }
        }
    }

    
    return cell;
}

@end
