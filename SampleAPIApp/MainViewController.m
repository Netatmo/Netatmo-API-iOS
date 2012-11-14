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


#import "MainViewController.h"

#import "LoginViewController.h"

#import "NAUser.h"
#import "NADeviceList.h"
#import "AppliCommonPrivate.h"



#define SECTION_INDEX_INDOOR                            0
#define MEASURE_INDEX_INDOOR_TEMPERATURE                0
#define MEASURE_INDEX_INDOOR_MIN_TEMPERATURE            1
#define MEASURE_INDEX_INDOOR_MAX_TEMPERATURE            2
#define MEASURE_INDEX_INDOOR_HUMIDITY                   3
#define MEASURE_INDEX_INDOOR_PRESSURE                   4
#define MEASURE_INDEX_INDOOR_CO2                        5
#define MEASURE_INDEX_INDOOR_NOISE                      6

#define SECTION_INDEX_OUTDOOR                           1
#define MEASURE_INDEX_OUTDOOR_TEMPERATURE               0
#define MEASURE_INDEX_OUTDOOR_MIN_TEMPERATURE           1
#define MEASURE_INDEX_OUTDOOR_MAX_TEMPERATURE           2
#define MEASURE_INDEX_OUTDOOR_HUMIDITY                  3

#define DATA_OUTDATED_ABSOLUTE_THRESHOLD                (4.0f * 3600.0f)
#define OUTDOOR_DATA_OUTDATED_RELATIVE_THRESHOLD        600.0f


@interface MainViewController ()

- (void) retrieveData;
- (void) refreshIndoorData;
- (void) refreshOutdoorData;

- (void)unsetIndoorData;
- (void)unsetOutdoorData;

- (void)alertWithMessage: (NSString *)message;

@end

@implementation MainViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle: style];
    
    if(self)
    {
        self.tableView.allowsSelection = NO;
        
        
        // This will retrieve data from the server and alert the ui
        // It is started later in code
        _netatmoDataRetriever = [[DataRetriever alloc] initWithDelegate:self];
        
        
        // Graphics
        _titleOutdoorTemperature = [[UILabel alloc] init];
        _titleOutdoorMinTemperature = [[UILabel alloc] init];
        _titleOutdoorMaxTemperature = [[UILabel alloc] init];
        _titleOutdoorHumidity = [[UILabel alloc] init];
        
        _titleIndoorTemperature = [[UILabel alloc] init];
        _titleIndoorMinTemperature = [[UILabel alloc] init];
        _titleIndoorMaxTemperature = [[UILabel alloc] init];
        _titleIndoorHumidity = [[UILabel alloc] init];
        _titleIndoorPressure = [[UILabel alloc] init];
        _titleIndoorCO2 = [[UILabel alloc] init];
        _titleIndoorNoise = [[UILabel alloc] init];
        
        _valueOutdoorTemperature = [[UILabel alloc] init];
        _valueOutdoorMinTemperature = [[UILabel alloc] init];
        _valueOutdoorMaxTemperature = [[UILabel alloc] init];
        _valueOutdoorHumidity = [[UILabel alloc] init];
        
        _valueIndoorTemperature = [[UILabel alloc] init];
        _valueIndoorMinTemperature = [[UILabel alloc] init];
        _valueIndoorMaxTemperature = [[UILabel alloc] init];
        _valueIndoorHumidity = [[UILabel alloc] init];
        _valueIndoorPressure = [[UILabel alloc] init];
        _valueIndoorCO2 = [[UILabel alloc] init];
        _valueIndoorNoise = [[UILabel alloc] init];
        
        
        [_titleOutdoorTemperature setText: @"Temperature"];
        [_titleOutdoorMinTemperature setText: @"Min. temperature"];
        [_titleOutdoorMaxTemperature setText: @"Max. temperature"];
        [_titleOutdoorHumidity setText: @"Humidity"];
        
        [_titleIndoorTemperature setText: @"Temperature"];
        [_titleIndoorMinTemperature setText: @"Min. temperature"];
        [_titleIndoorMaxTemperature setText: @"Max. temperature"];
        [_titleIndoorHumidity setText: @"Humidity"];
        [_titleIndoorPressure setText: @"Pressure"];
        [_titleIndoorCO2 setText: @"CO2"];
        [_titleIndoorNoise setText: @"Noise"];
        
        
        
        [self unsetIndoorData];
        [self unsetOutdoorData];
    }
    
    return self;
}

-(void)dealloc
{
    NTA_RELEASE_SAFELY(_titleIndoorNoise);
    NTA_RELEASE_SAFELY(_titleIndoorCO2);
    NTA_RELEASE_SAFELY(_titleIndoorPressure);
    NTA_RELEASE_SAFELY(_titleIndoorHumidity);
    NTA_RELEASE_SAFELY(_titleIndoorMaxTemperature);
    NTA_RELEASE_SAFELY(_titleIndoorMinTemperature);
    NTA_RELEASE_SAFELY(_titleIndoorTemperature);
    
    NTA_RELEASE_SAFELY(_titleOutdoorHumidity);
    NTA_RELEASE_SAFELY(_titleOutdoorMaxTemperature);
    NTA_RELEASE_SAFELY(_titleOutdoorMinTemperature);
    NTA_RELEASE_SAFELY(_titleOutdoorTemperature);
    
    NTA_RELEASE_SAFELY(_valueIndoorNoise);
    NTA_RELEASE_SAFELY(_valueIndoorCO2);
    NTA_RELEASE_SAFELY(_valueIndoorPressure);
    NTA_RELEASE_SAFELY(_valueIndoorHumidity);
    NTA_RELEASE_SAFELY(_valueIndoorMaxTemperature);
    NTA_RELEASE_SAFELY(_valueIndoorMinTemperature);
    NTA_RELEASE_SAFELY(_valueIndoorTemperature);
    
    NTA_RELEASE_SAFELY(_valueOutdoorHumidity);
    NTA_RELEASE_SAFELY(_valueOutdoorMaxTemperature);
    NTA_RELEASE_SAFELY(_valueOutdoorMinTemperature);
    NTA_RELEASE_SAFELY(_valueOutdoorTemperature);
    
    NTA_RELEASE_SAFELY(_netatmoDataRetriever);
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Measures";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[NAUser globalUser] isLoggedIn])
    {
        if ([[NADeviceList gDeviceList] hasAValidDevice])
        {
            [self retrieveData];
            
        }
        else
        {
            [self alertWithMessage: @"You should install your station with the Netatmo app first"];
        }
    }
    else
    {
        // Launch LoginViewController if user could not be authenticated
        LoginViewController *loginVC = [[LoginViewController alloc] initWithNibName: nil bundle: nil];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: loginVC];
        [loginVC release];
        
        [self presentModalViewController: navigationController animated:YES];
        [navigationController release];
    }
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - private methods

- (void) retrieveData
{
    // start (or restart) the data retriever
    [_netatmoDataRetriever stop];
    [_netatmoDataRetriever start];
}

-(void) refreshIndoorData
{
    NSDictionary *indoorMeasures = [DataHandler getMeasuresForDeviceId: [[NADeviceList gDeviceList] currentDeviceId]];
    
    if(indoorMeasures)
    {
        NSNumber *temperature = [indoorMeasures valueForKey: NAAPITemperature];
        NSNumber *humidity = [indoorMeasures valueForKey: NAAPIHumidity];
        NSNumber *minTemperature = [indoorMeasures valueForKey: NAAPIMinTemp];
        NSNumber *maxTemperature = [indoorMeasures valueForKey: NAAPIMaxTemp];
        NSNumber *co2 = [indoorMeasures valueForKey: NAAPICo2];
        NSNumber *pressure = [indoorMeasures valueForKey: NAAPIPressure];
        NSNumber *noise = [indoorMeasures valueForKey: NAAPINoise];
        
        
        [_valueIndoorTemperature setText: [[NSString stringWithFormat: @"%.1f", temperature.floatValue] stringByAppendingString: @" °C"]];
        [_valueIndoorMinTemperature setText: [[NSString stringWithFormat: @"%.1f", minTemperature.floatValue] stringByAppendingString: @" °C"]];
        [_valueIndoorMaxTemperature setText: [[NSString stringWithFormat: @"%.1f", maxTemperature.floatValue] stringByAppendingString: @" °C"]];
        [_valueIndoorHumidity setText: [[NSString stringWithFormat: @"%.0f", humidity.floatValue] stringByAppendingString: @" %"]];
        [_valueIndoorPressure setText: [[NSString stringWithFormat: @"%.0f", pressure.floatValue] stringByAppendingString: @" mbar"]];
        [_valueIndoorCO2 setText: [[NSString stringWithFormat: @"%.0f", co2.floatValue] stringByAppendingString: @" ppm"]];
        [_valueIndoorNoise setText: [[NSString stringWithFormat: @"%.0f", noise.floatValue] stringByAppendingString: @" dB"]];
    }
    else
    {
        [self unsetIndoorData];
    }
}

- (void)unsetIndoorData
{
    [_valueIndoorTemperature setText: @" °C"];
    [_valueIndoorMinTemperature setText: @" °C"];
    [_valueIndoorMaxTemperature setText: @" °C"];
    [_valueIndoorHumidity setText: @" %"];
    [_valueIndoorPressure setText: @" mbar"];
    [_valueIndoorCO2 setText: @" ppm"];
    [_valueIndoorNoise setText: @" dB"];
}

- (void)unsetOutdoorData
{
    [_valueOutdoorTemperature setText: @" °C"];
    [_valueOutdoorMinTemperature setText: @" °C"];
    [_valueOutdoorMaxTemperature setText: @" °C"];
    [_valueOutdoorHumidity setText: @" %"];
}

- (void)alertWithMessage: (NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: nil
                                                    message: message
                                                   delegate: nil
                                          cancelButtonTitle: @"OK"
                                          otherButtonTitles: nil];
    [alert show];
    [alert release];
}

-(void) refreshOutdoorData
{
    NSDictionary *outdoorMeasures = [DataHandler getMeasuresForDeviceId:[[NADeviceList gDeviceList] currentModuleId]];
    
    if(outdoorMeasures)
    {
        NSNumber *temperature = [outdoorMeasures valueForKey: NAAPITemperature];
        NSNumber *humidity = [outdoorMeasures valueForKey: NAAPIHumidity];
        NSNumber *minTemperature = [outdoorMeasures valueForKey: NAAPIMinTemp];
        NSNumber *maxTemperature = [outdoorMeasures valueForKey: NAAPIMaxTemp];
        
        [_valueOutdoorTemperature setText: [[NSString stringWithFormat: @"%.1f", temperature.floatValue] stringByAppendingString: @" °C"]];
        [_valueOutdoorMinTemperature setText: [[NSString stringWithFormat: @"%.1f", minTemperature.floatValue] stringByAppendingString: @" °C"]];
        [_valueOutdoorMaxTemperature setText: [[NSString stringWithFormat: @"%.1f", maxTemperature.floatValue] stringByAppendingString: @" °C"]];
        [_valueOutdoorHumidity setText: [[NSString stringWithFormat: @"%.0f", humidity.floatValue] stringByAppendingString: @" %"]];
    }
    else
    {
        [self unsetOutdoorData];
    }
}

#pragma mark - DataRetrieverDelegate

-(void)dataDidUpdateForDevice:(NSString *)deviceId
{
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Check data validity.                                                                                   //
    //  *Station data is valid if indoor data is less than 4 hours old                                        //
    //  *Outdoor data is valid if it is less than 4 hours old and less than 10 minutes away from indoor data  //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    BOOL recentOutdoor = NO, recentIndoor = NO;
    NSDate *currentDate = [NSDate date];
    
    NSDictionary *indoorMeasures = [DataHandler getMeasuresForDeviceId:[[NADeviceList gDeviceList] currentDeviceId]];
    NSDate *indoorMeasuresDate = [DataHandler dateForMeasureDict: indoorMeasures];
    
    NSDictionary *outdoorMeasures = [DataHandler getMeasuresForDeviceId:[[NADeviceList gDeviceList] currentModuleId]];
    NSDate *outdoorMeasuresDate = [DataHandler dateForMeasureDict: outdoorMeasures];
    
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate: indoorMeasuresDate];
    if(timeInterval < DATA_OUTDATED_ABSOLUTE_THRESHOLD && timeInterval > -DATA_OUTDATED_ABSOLUTE_THRESHOLD)
    {
        recentIndoor = YES;
    }
    
    NSTimeInterval relativeTimeInterval = 0;
    
    timeInterval = [currentDate timeIntervalSinceDate: outdoorMeasuresDate];
    if(timeInterval < DATA_OUTDATED_ABSOLUTE_THRESHOLD && timeInterval > -DATA_OUTDATED_ABSOLUTE_THRESHOLD)
    {
        relativeTimeInterval = [outdoorMeasuresDate timeIntervalSinceDate: indoorMeasuresDate];
        if(relativeTimeInterval <= OUTDOOR_DATA_OUTDATED_RELATIVE_THRESHOLD && relativeTimeInterval >= -OUTDOOR_DATA_OUTDATED_RELATIVE_THRESHOLD)
        {
            recentOutdoor = YES;
        }
    }
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Only update the concerned device                                                                       //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    if([deviceId isEqualToString: [[NADeviceList gDeviceList] currentDeviceId]])
    {
        if(recentIndoor)
        {
            [self refreshIndoorData];
        }
        else
        {
            [self unsetIndoorData];
            [self alertWithMessage: @"No recent data for the station"];
        }
    }
    else if([[NADeviceList gDeviceList] currentDeviceHasModule: deviceId])
    {
        if(recentOutdoor)
        {
            [self refreshOutdoorData];
        }
        else
        {
            [self unsetOutdoorData];
            
            if(recentIndoor)
            {
                [self alertWithMessage: @"No recent data for the outdoor module"];
            }
        }
    }
    
    [self.view setNeedsDisplay];
}

-(void)dataDidFail
{
    [self alertWithMessage: @"Failed to retrieve data"];
}




////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                GRAPHICS                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
	return 2;
}

- (NSString *)tableView: (UITableView *)tableView
titleForHeaderInSection: (NSInteger)section
{
    if(section == SECTION_INDEX_INDOOR)
        return @"Indoor";
    
    if(section == SECTION_INDEX_OUTDOOR)
        return @"Outdoor";
    
    return @"";
}

- (NSInteger)tableView: (UITableView *)tableView
 numberOfRowsInSection: (NSInteger)section
{
    if(section == SECTION_INDEX_INDOOR)
        return 7;
    
    if(section == SECTION_INDEX_OUTDOOR)
        return 4;
    
    return 0;
}

- (UITableViewCell *)tableView: (UITableView *)tableView
         cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UILabel *title = nil;
    UILabel *value = nil;
    
    CGFloat cellMarginLeft = 20.0f;
    CGFloat cellMarginRight = 20.0f;
    
    
    
    if(indexPath.section == SECTION_INDEX_OUTDOOR)
    {
        if(indexPath.row == MEASURE_INDEX_OUTDOOR_TEMPERATURE)
        {
            title = _titleOutdoorTemperature;
            value = _valueOutdoorTemperature;
        }
        else if(indexPath.row == MEASURE_INDEX_OUTDOOR_MIN_TEMPERATURE)
        {
            title = _titleOutdoorMinTemperature;
            value = _valueOutdoorMinTemperature;
        }
        else if(indexPath.row == MEASURE_INDEX_OUTDOOR_MAX_TEMPERATURE)
        {
            title = _titleOutdoorMaxTemperature;
            value = _valueOutdoorMaxTemperature;
        }
        else if(indexPath.row == MEASURE_INDEX_OUTDOOR_HUMIDITY)
        {
            title = _titleOutdoorHumidity;
            value = _valueOutdoorHumidity;
        }
    }
    else if(indexPath.section == SECTION_INDEX_INDOOR)
    {
        if(indexPath.row == MEASURE_INDEX_INDOOR_TEMPERATURE)
        {
            title = _titleIndoorTemperature;
            value = _valueIndoorTemperature;
        }
        else if(indexPath.row == MEASURE_INDEX_INDOOR_MIN_TEMPERATURE)
        {
            title = _titleIndoorMinTemperature;
            value = _valueIndoorMinTemperature;
        }
        else if(indexPath.row == MEASURE_INDEX_INDOOR_MAX_TEMPERATURE)
        {
            title = _titleIndoorMaxTemperature;
            value = _valueIndoorMaxTemperature;
        }
        else if(indexPath.row == MEASURE_INDEX_INDOOR_HUMIDITY)
        {
            title = _titleIndoorHumidity;
            value = _valueIndoorHumidity;
        }
        else if(indexPath.row == MEASURE_INDEX_INDOOR_PRESSURE)
        {
            title = _titleIndoorPressure;
            value = _valueIndoorPressure;
        }
        else if(indexPath.row == MEASURE_INDEX_INDOOR_CO2)
        {
            title = _titleIndoorCO2;
            value = _valueIndoorCO2;
        }
        else if(indexPath.row == MEASURE_INDEX_INDOOR_NOISE)
        {
            title = _titleIndoorNoise;
            value = _valueIndoorNoise;
        }
    }
    [title setBackgroundColor: [UIColor clearColor]];
    [value setBackgroundColor: [UIColor clearColor]];
    [value setTextColor: [UIColor grayColor]];
    
    UITableViewCell *cell = [[[UITableViewCell alloc] init] autorelease];
    
    [value sizeToFit];
    [value setTextAlignment: UITextAlignmentRight];
    CGRect valueFrame = cell.frame;
    valueFrame.size.width /= 2.0f;
    valueFrame.size.width -= cellMarginRight;
    valueFrame.origin.x = cell.frame.size.width / 2.0f;
    [value setFrame: valueFrame];
    [cell addSubview: value];
    
    [title sizeToFit];
    [title setTextAlignment: UITextAlignmentLeft];
    CGRect titleFrame = cell.frame;
    titleFrame.size.width /= 2.0f;
    titleFrame.size.width -= cellMarginLeft;
    titleFrame.origin.x = cellMarginLeft;
    [title setFrame: titleFrame];
    [cell addSubview: title];
    
    return cell;
}

@end
