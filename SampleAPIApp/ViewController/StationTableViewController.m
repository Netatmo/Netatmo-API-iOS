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


#import "StationTableViewController.h"

@interface StationTableViewController ()

@property (nonatomic, strong, readwrite) NSString *cellIdentifier;

@end

@implementation StationTableViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.cellIdentifier = @"StationViewCustomCell";
    
    [self.tableView registerNib:[UINib nibWithNibName:@"StationViewCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:self.cellIdentifier];
    
    self.tableView.rowHeight = 44;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *deviceId = [[[NADeviceList gDeviceList] getDeviceIdList] objectAtIndex:indexPath.row];
    [[NADeviceList gDeviceList] changeCurrentDeviceIfIdExists:deviceId];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView: (UITableView *)tableView
 numberOfRowsInSection: (NSInteger)section
{
    return [[[NADeviceList gDeviceList] getDeviceIdList] count];
}


- (StationTableViewCell *)tableView: (UITableView *)tableView
              cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    StationTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:self.cellIdentifier
                                                                      forIndexPath:indexPath];
    NSString *deviceId = [[[NADeviceList gDeviceList] getDeviceIdList] objectAtIndex:indexPath.row];
    cell.title.text = [[NADeviceList gDeviceList] nameForDevice:deviceId];
    
    return cell;
}
@end
