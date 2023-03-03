//
//  RoundingTimeClockViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 7/29/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import "RoundingTimeClockViewController.h"

@interface RoundingTimeClockViewController ()

@end

@implementation RoundingTimeClockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Select an Option"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];

 //       cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
    }
    if (indexPath.row == 0)
    {
        cell.textLabel.text = @"None";
//        cell.detailTextLabel.text = @"Only has access to their own timesheet.";
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = @"5 minutes";
//        cell.detailTextLabel.text = @"Has full access except for Payrate and account/subscription.";
    }
    else if (indexPath.row == 2)
    {
        cell.textLabel.text = @"6 minutes";
 //       cell.detailTextLabel.text = @"Has full access except for account/subscription.";
    }
    else if (indexPath.row == 3)
    {
        cell.textLabel.text = @"15 minutes";
    }
    
    if ([_selectedOptionIndex intValue] == indexPath.row)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
   // UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    int row = (int) indexPath.row;
    [_delegate roundingOptionWasSelected:row];
//    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doCancelClick:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
