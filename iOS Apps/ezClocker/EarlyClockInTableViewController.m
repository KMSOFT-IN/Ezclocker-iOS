//
//  EarlyClockInTableViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 7/19/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import "EarlyClockInTableViewController.h"

@interface EarlyClockInTableViewController ()

@end

@implementation EarlyClockInTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Select an Option"];

}

//override func layoutSubviews() {
//        super.layoutSubviews()
//        let AccessoryWidth=self.frame.width-self.contentView.frame.width
//}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
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
        cell.textLabel.text = @"No Restriction";
//        cell.detailTextLabel.text = @"Only has access to their own timesheet.";
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = @"At (or after) scheduled time";
        if ([_selectedOptionIndex intValue] == 0)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if (indexPath.row == 2)
    {
        cell.textLabel.text = @"5 minutes before scheduled time";
        if ([_selectedOptionIndex intValue] == 5)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;

    }
    else if (indexPath.row == 3)
    {
        cell.textLabel.text = @"10 minutes before scheduled time";
        if ([_selectedOptionIndex intValue] == 10)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;

    }
    else if (indexPath.row == 4)
    {
        cell.textLabel.text = @"15 minutes before scheduled time";
        if ([_selectedOptionIndex intValue] == 15)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;

    }
    else if (indexPath.row == 5)
    {
        cell.textLabel.text = @"30 minutes before scheduled time";
        if ([_selectedOptionIndex intValue] == 30)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;

    }
    
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    int selectedTime;
    int row = (int) indexPath.row;
    //return how many minutes were selected. return 0 if at time was selected and return -1 if none was selected.
    if (row == 1)
        selectedTime= 0;
    else if (row == 2)
        selectedTime = 5;
    else if (row == 3)
        selectedTime = 10;
    else if (row == 4)
        selectedTime = 15;
    else if (row == 5)
        selectedTime = 30;
    else
        selectedTime = -1;
        
    [_delegate optionWasSelected:selectedTime];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)doCancelBtnClick:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
