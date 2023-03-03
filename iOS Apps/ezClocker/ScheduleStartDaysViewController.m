//
//  ScheduleStartDaysViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 7/31/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import "ScheduleStartDaysViewController.h"
#import "CommonLib.h"

@interface ScheduleStartDaysViewController ()

@end

@implementation ScheduleStartDaysViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Select a Day"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];


    }
    
    int row = (int) indexPath.row;
    cell.textLabel.text = [CommonLib getDayOfTheWeek: row];
     
    if ([_selectedOptionIndex intValue] == indexPath.row)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;

    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    int row = (int) indexPath.row;
    [_delegate dayOptionWasSelected:row];
}


- (IBAction)doCancel:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
