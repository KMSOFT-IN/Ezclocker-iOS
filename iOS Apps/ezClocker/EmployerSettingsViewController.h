//
//  EmployerSettingsViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 8/31/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"
#import "EmployerAutoBreaksTableViewController.h"
#import "EarlyClockInTableViewController.h"
#import "RoundingTimeClockViewController.h"
#import "ScheduleStartDaysViewController.h"
#import "LoginViewController.h"

@interface EmployerSettingsViewController : UITableViewControllerEx <UIPickerViewDataSource, UIPickerViewDelegate, EmployerAutoBreaksViewControllerDelegate, EarlyClockInTableViewDelegate, RoundingTimeClockDelegate, ScheduleStartDayDelegate, LoginViewControllerDelegate>
{
    int selectedStartDate;
}
@property (weak, nonatomic) IBOutlet UITableViewCell *requireGPSCellView;
@property (weak, nonatomic) IBOutlet UILabel *weeklyOnOffLabel;
@property (weak, nonatomic) IBOutlet UILabel *overtimeDetailLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *roundingCellView;
@property (weak, nonatomic) IBOutlet UITableViewCell *overtimeCellView;
@property (weak, nonatomic) IBOutlet UITableViewCell *restrictEarlyClockInCellView;
@property (weak, nonatomic) IBOutlet UITableViewCell *autoBreakCellView;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *employerEmail;
- (IBAction)revealMenu:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *allowPushNotificationsSwitch;
- (IBAction)pushNotificationSwitchChanged:(id)sender;
- (IBAction)allowEmployeesEditSwitchChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *requireGPSSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *allowEditSwitch;
- (IBAction)doSave:(id)sender;
- (IBAction)doSwitchChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;
@property (weak, nonatomic) IBOutlet UISwitch *allowCoworkersScheduleSwtich;
- (IBAction)doDeleteAccount:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UILabel *isAutoBreakOn;
@property (weak, nonatomic) IBOutlet UISwitch *allowBreaksSwitch;
@property (weak, nonatomic) IBOutlet UILabel *scheduleStartDayLabel;
@property (weak, nonatomic) IBOutlet UILabel *earlyClockInLabel;
@property (weak, nonatomic) IBOutlet UILabel *roundingTimeClockLabel;
@property (strong, nonatomic) IBOutlet UITableView *settingsTableView;

@end
