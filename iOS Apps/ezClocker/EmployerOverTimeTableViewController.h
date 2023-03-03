//
//  EmployerOverTimeTableViewController.h
//  ezClocker
//
//  Created by Logileap on 03/09/20.
//  Copyright © 2020 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol EmployerOverTimeTableViewControllerDelegate <NSObject>
- (void)weeklyOverTime:(BOOL)overtime weeklyOverTimeHour:(NSNumber*)hour dailyOvertime:(BOOL)dailyOvertime dailyOvertimeHour: (NSNumber*) dailyHour;
@end


@interface EmployerOverTimeTableViewController : UITableViewController

@property (nonatomic, assign) BOOL CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS;
@property (nonatomic, assign) BOOL CALCULATE_DAILY_OVERTIME_IN_TIME_SHEET_EXPORTS;
@property (nonatomic, assign) NSNumber *CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS;
@property (nonatomic, assign) NSNumber *CALCULATE_DAILY_OVERTIME_AFTER_HOURS;

@property (weak, nonatomic) IBOutlet UITableViewCell *noteTableViewCell;
@property (weak, nonatomic) IBOutlet UISwitch *overtimeSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *weeklyOvertimeHoursCellView;
@property (weak, nonatomic) IBOutlet UITextField *hourTextField;

@property (weak, nonatomic) IBOutlet UILabel *overtimeNoteLabel;
@property (nonatomic, weak) id <EmployerOverTimeTableViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITableViewCell *dailyOvertimeSwitchCellView;
- (IBAction)dailyOvertimeSwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *dailyOvertimeSwitch;

@property (weak, nonatomic) IBOutlet UITableViewCell *dailyOvertimeHoursViewCell;
@property (weak, nonatomic) IBOutlet UITextField *dailyOvertimeHoursField;


- (IBAction)switchChanged:(UISwitch *)sender;

@end

NS_ASSUME_NONNULL_END
