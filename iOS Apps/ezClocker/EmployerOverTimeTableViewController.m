//
//  EmployerOverTimeTableViewController.m
//  ezClocker
//
//  Created by Logileap on 03/09/20.
//  Copyright © 2020 ezNova Technologies LLC. All rights reserved.
//

#import "EmployerOverTimeTableViewController.h"

@interface EmployerOverTimeTableViewController ()

{
    BOOL isOn;
}

@end

@implementation EmployerOverTimeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Overtime Options"];

    isOn = self.CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS;
    if (isOn)
    {
        [self.overtimeSwitch setOn:isOn];
        _weeklyOvertimeHoursCellView.contentView.alpha = 1.0f;
        _weeklyOvertimeHoursCellView.userInteractionEnabled = YES;
        _dailyOvertimeSwitchCellView.contentView.alpha = 1.0f;
        _dailyOvertimeSwitchCellView.userInteractionEnabled = YES;
    }
    else
    {
        _weeklyOvertimeHoursCellView.contentView.alpha = 0.2;
        _weeklyOvertimeHoursCellView.userInteractionEnabled = NO;
        self.CALCULATE_DAILY_OVERTIME_IN_TIME_SHEET_EXPORTS = false;
        _dailyOvertimeSwitchCellView.contentView.alpha = 0.2;
        _dailyOvertimeSwitchCellView.userInteractionEnabled = NO;
    }

    BOOL dailyIsOn = self.CALCULATE_DAILY_OVERTIME_IN_TIME_SHEET_EXPORTS;
    if (dailyIsOn)
    {
        [_dailyOvertimeSwitch setOn:dailyIsOn];
        _dailyOvertimeHoursViewCell.contentView.alpha = 1.0f;
        _dailyOvertimeHoursViewCell.userInteractionEnabled = YES;
    }
    else
    {
        _dailyOvertimeHoursViewCell.contentView.alpha = 0.2;
        _dailyOvertimeHoursViewCell.userInteractionEnabled = NO;
    }
     self.hourTextField.text = [_CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS stringValue];
    self.dailyOvertimeHoursField.text = [_CALCULATE_DAILY_OVERTIME_AFTER_HOURS stringValue];

    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(onCancelClick)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(onDoneClick)];
    self.navigationItem.rightBarButtonItem = doneButton;

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        return 85;
    else
        return UITableViewAutomaticDimension;
}

/*- (IBAction)saveButonClicked:(UIBarButtonItem *)sender {
    NSString *hourText = self.hourTextField.text;
    if ([hourText isEqualToString:@""]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"EZClocker" message:@"Please enter hour" delegate:nil cancelButtonTitle:@"CANCEL" otherButtonTitles:@"OK", nil];
             [alert show];
    } else {
        NSNumber *val = @([hourText intValue]);
        [self.delegate weeklyOverTime:isOn weeklyOverTimeHour:val];
        [self.navigationController popViewControllerAnimated:NO];
    }
}
*/
- (IBAction)switchChanged:(UISwitch *)sender {
    isOn = sender.isOn;
    if (isOn)
    {
        _weeklyOvertimeHoursCellView.contentView.alpha = 1.0f;
        _weeklyOvertimeHoursCellView.userInteractionEnabled = YES;
        _dailyOvertimeSwitchCellView.contentView.alpha = 1.0f;
        _dailyOvertimeSwitchCellView.userInteractionEnabled = YES;
        
    }
    else
    {
        _weeklyOvertimeHoursCellView.contentView.alpha = 0.2;
        _weeklyOvertimeHoursCellView.userInteractionEnabled = NO;
         _dailyOvertimeSwitchCellView.contentView.alpha = 0.2;
        _dailyOvertimeSwitchCellView.userInteractionEnabled = NO;    }
}

/*- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  if (self.isMovingFromParentViewController) {
    // Do your stuff here
    BOOL weeklyIsOn = [self.overtimeSwitch isOn];
    BOOL dailyIsON = [self.dailyOvertimeSwitch isOn];
    NSString *hourText = self.hourTextField.text;
    NSString *dailyHourText = self.dailyOvertimeHoursField.text;
    NSNumber *val = @([hourText intValue]);
    NSNumber *dailyHourVal = @([dailyHourText intValue]);
      [self.delegate weeklyOverTime:weeklyIsOn weeklyOverTimeHour:val dailyOvertime:dailyIsON dailyOvertimeHour:dailyHourVal];
  }
}
 */

- (IBAction)dailyOvertimeSwitchChanged:(UISwitch *)sender {
    isOn = sender.isOn;
    if (isOn)
    {
        _dailyOvertimeHoursViewCell.contentView.alpha = 1.0f;
        _dailyOvertimeHoursViewCell.userInteractionEnabled = YES;
    }
    else
    {
        _dailyOvertimeHoursViewCell.contentView.alpha = 0.2;
        _dailyOvertimeHoursViewCell.userInteractionEnabled = NO;
    }
}

-(void) onDoneClick{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterNoStyle;
    
    BOOL weeklyIsOn = [self.overtimeSwitch isOn];
    BOOL dailyIsON = [self.dailyOvertimeSwitch isOn];
    NSString *hourText = self.hourTextField.text;
    NSString *dailyHourText = self.dailyOvertimeHoursField.text;
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    NSNumber *val = [f numberFromString: hourText];
    NSNumber *dailyHourVal = [f numberFromString: dailyHourText];
    
    [self.delegate weeklyOverTime:weeklyIsOn weeklyOverTimeHour:val dailyOvertime:dailyIsON dailyOvertimeHour:dailyHourVal];

}

-(void) onCancelClick{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
