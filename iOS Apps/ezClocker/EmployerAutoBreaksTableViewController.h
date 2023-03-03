//
//  EmployerAutoBreaksTableViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 7/16/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"
#import "AutoBreakTCViewController.h"

@class EmployerAutoBreaksTableViewController;

NS_ASSUME_NONNULL_BEGIN
@protocol EmployerAutoBreaksViewControllerDelegate
- (void)saveAutoBreaksOptionsDidFinish:(BOOL)autoBreak breakAfterHours:(NSNumber*)hours breakDuration: (NSNumber*) duration;
@end

@interface EmployerAutoBreaksTableViewController : UITableViewControllerEx <AutoBreakTCViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *afterHoursTextField;
@property (weak, nonatomic) IBOutlet UITextField *durationBreakTextField;
@property (nonatomic, weak) id <EmployerAutoBreaksViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL ALLOW_AUTOMATIC_BREAKS;
- (IBAction)SwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UITableViewCell *hoursOptionCellView;
@property (weak, nonatomic) IBOutlet UITableViewCell *durationCellView;
@property (weak, nonatomic) IBOutlet UISwitch *autoBreakSwitch;
@property (nonatomic, assign) NSNumber *AUTO_BREAK_WORK_HOURS_OPTION;
@property (nonatomic, assign) NSNumber *AUTO_BREAK_WORK_MINUTES_OPTION;

@end

NS_ASSUME_NONNULL_END
