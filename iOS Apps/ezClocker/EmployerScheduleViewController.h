//
//  EmployerScheduleViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 1/3/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScheduleDetailViewController.h"
#import "UIViewControllerEx.h"


@interface EmployerScheduleViewController : UIViewControllerEx <UITableViewDelegate,NSURLConnectionDataDelegate>{
    
    NSMutableData *data;
    NSDate *startingDate;
    UIDatePicker *theDatePicker;
    NSDate *todayDate;
    NSDateFormatter *formatterISO8601DateTime, *formatterISO8601Date, *formatterLocalDate;
    bool showErrorMessage;
    NSMutableArray *scheduleList;
    NSMutableArray *deletedScheduleListIds;
    NSDateFormatter *formatterDate, *formatterLongDate, *formatterTime12;
    UIView* pickerViewDate;
    UIToolbar* pickerToolbar;
    UIBarButtonItem *addButton;
    UIBarButtonItem* cancelButton;
    UIViewController* popoverContent;
    UINavigationController *scheduleNavigationController;
}
@property (weak, nonatomic) IBOutlet UIButton *selectDateArrowBtn;
- (IBAction)doNextDateClick:(id)sender;
- (IBAction)doPrevDateClick:(id)sender;
- (IBAction)revealMenu:(id)sender;
//- (IBAction)doPickDateBtnClick:(id)sender;
- (IBAction)doPublishClick:(id)sender;

//- (IBAction)doChangeDateBtnClick:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *weekOfLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectDateButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *publishButton;
@property (weak, nonatomic) IBOutlet UITableView *scheduleTable;
@property (weak, nonatomic) IBOutlet UIView *selectedDateView;
@property (strong, nonatomic) ScheduleDetailViewController *scheduleDetailViewController;




@end
