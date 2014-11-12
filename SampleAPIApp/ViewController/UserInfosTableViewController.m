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

#import "UserInfosTableViewController.h"

#define INDEX_COUNTRY_CODE          0
#define INDEX_UNIT_SYSTEM           1
#define INDEX_WIND_UNIT_SYSTEM      2
#define INDEX_PRESSURE_UNIT_SYSTEM  3

@interface UserInfosTableViewController ()

@property (nonatomic, strong, readwrite) NSString *titleCountryCode;
@property (nonatomic, strong, readwrite) NSString *titleUnitSystem;
@property (nonatomic, strong, readwrite) NSString *titleWindUnitSystem;
@property (nonatomic, strong, readwrite) NSString *titlePressureUnitSystem;

@property (nonatomic, strong, readwrite) NSString *cellIdentifier;

@end

@implementation UserInfosTableViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.cellIdentifier = @"MainViewCustomCell";
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MainViewCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:self.cellIdentifier];
    
    self.tableView.rowHeight = 44;
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    // Graphics
    self.titleCountryCode =         @"Country code";
    self.titleUnitSystem =          @"Unit system";
    self.titleWindUnitSystem =      @"Wind unit system";
    self.titlePressureUnitSystem =  @"Pressure unit system";
    
    [self.tableView reloadData];
}

- (NSInteger)tableView: (UITableView *)tableView
 numberOfRowsInSection: (NSInteger)section
{
    return 4;
}

- (MainTableViewCell *)tableView: (UITableView *)tableView
           cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    MainTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:self.cellIdentifier
                                                                   forIndexPath:indexPath];
    cell.userInteractionEnabled = NO;
    
    if (indexPath.row == INDEX_COUNTRY_CODE) {
        cell.title.text = self.titleCountryCode;
        cell.value.text = [[NAUser globalUser] countryCode];
    }
    else if (indexPath.row == INDEX_UNIT_SYSTEM)
    {
        cell.title.text = self.titleUnitSystem;
        if ([[NAUser globalUser] unitSystem] == NAAPIUnitMetric) {
            cell.value.text = @"Metric system";
        }
        else {
            cell.value.text = @"US units";
        }
    }
    else if (indexPath.row == INDEX_WIND_UNIT_SYSTEM) {
        cell.title.text = self.titleWindUnitSystem;
        if ([[NAUser globalUser] windUnitSystem] == NAAPIUnitWindKmh) {
            cell.value.text = @"Km/h";
        }
        else {
            cell.value.text = @"Mph";
        }
    }
    else {
        cell.title.text = self.titlePressureUnitSystem;
        if ([[NAUser globalUser] pressureUnitSystem] == NAAPIUnitPressureMbar) {
            cell.value.text = @"Mbar";
        }
        else {
            cell.value.text = @"Mercury";
        }
    }
    
    return cell;
}

@end
