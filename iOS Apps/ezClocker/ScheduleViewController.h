//
//  ScheduleViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 9/23/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShiftDetailsViewController.h"
#import "UIViewControllerEx.h"

@interface ScheduleViewController : UIViewControllerEx<UITableViewDelegate, NSURLConnectionDataDelegate, UIActionSheetDelegate>{
    NSMutableData *data;
    UIBarButtonItem *actionButton;
    UIDatePicker *theDatePicker;
    UIToolbar* pickerToolbar;
    UIView* pickerViewDate;
    NSDate *startingDate;
    NSDateFormatter *formatterISO8601DateTime, *formatterISO8601Date;
    UIBarButtonItem* cancelButton;
    NSMutableArray *scheduleList;
}
@property (weak, nonatomic) IBOutlet UILabel *nextShiftTopLabel;
@property (strong, nonatomic) ShiftDetailsViewController *shiftDetailsViewController;
@property (weak, nonatomic) IBOutlet UILabel *totalHoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalHoursValue;
@property (weak, nonatomic) IBOutlet UIView *nextShiftView;
@property (weak, nonatomic) IBOutlet UILabel *totalHoursCol;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuBarBtn;
@property (weak, nonatomic) IBOutlet UIButton *selectDateButton;
- (IBAction)myScheduleButtonClicked:(id)sender;
- (IBAction)allScheduleButtonClicked:(id)sender;
- (IBAction)doChangeDate;
- (IBAction)doChangeDateBtnClick:(id)sender;
- (IBAction)doPrevDateClick:(id)sender;
- (IBAction)doNextDateClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *selectDateView;
@property (weak, nonatomic) IBOutlet UIButton *myScheduleButton;

@property (weak, nonatomic) IBOutlet UIButton *allScheduleButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pagerLeadingConstraint;
@property (weak, nonatomic) IBOutlet UIView *pagerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pagerViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *shiftViewHeight;

- (IBAction)revealMenu:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *scheduleTable;
@property (weak, nonatomic) IBOutlet UILabel *shiftDate;
@property (weak, nonatomic) IBOutlet UIView *totalHoursView;
@property (weak, nonatomic) IBOutlet UILabel *nextShiftLabel;

@end
