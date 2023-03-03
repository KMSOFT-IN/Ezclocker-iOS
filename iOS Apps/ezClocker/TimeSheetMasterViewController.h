//
//  TimeSheetMasterViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "user.h"
#import "UIViewControllerEx.h"
#import "CommonLib.h"
#import "DateRangeViewController.h"

#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif

/*typedef enum {
    Feedback_None = -1,
    EnjoyingEzClokcer_dlg = 0,
    CanYouRateUs_dlg = 1,
    GiveUsFeedback_dlg = 2,
} RatingDialogType;
 */

@interface TimeSheetMasterViewController : UIViewControllerEx <NSURLConnectionDataDelegate, UITableViewDelegate, UIActionSheetDelegate, WWCalendarTimeSelectorProtocol>{
    UserClass *user;
    NSNumber *employeeID;
    NSMutableData *data;
    NSString *currentDay;
    NSTimeInterval lastTimeUpdated;
//    BOOL editFlag;
    NSDateFormatter *formatterDateTime12, *formatterISO8601DateTime, *dateFormatterEEEMMMdd;
    UIBarButtonItem *actionButton, *addButton;
    UINavigationController *timeSheetNavigationController;
    UINavigationController *navDatePickerController;
    DateRangeViewController *fromToDatePicker;
    RatingDialogType ratingDialogType;
    UIViewController* popoverContent;
    float totalPay;
}

typedef enum {
	FromDateActive = 0,
	ToDateActive = 1,
} DateRangeMode;



extern NSString *const ADD_TIME_ENTRY;
extern NSString *const EMAIL_TIME_SHEET;

- (IBAction)revealMenu:(id)sender;
- (IBAction)doSetDateRange:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *TimeEntryTableView;
@property (weak, nonatomic) IBOutlet UIButton *changeDateBtn;
@property (nonatomic, retain) NSMutableDictionary *timeEntryItems;
@property (weak, nonatomic) IBOutlet UIButton *selectDateButton1;
@property (weak, nonatomic) IBOutlet UILabel *TotalHoursLabel;
@property (weak, nonatomic) IBOutlet UIView *selectedDateView;
@property (nonatomic, retain) NSNumber *employeeID;
@property (nonatomic, copy) NSMutableArray *jobCodes;
@property (nonatomic, copy) NSMutableDictionary *primaryJobCode;
//@property (strong, nonatomic) TimeSheetDetailViewController *timeSheetDetailViewController;
@property (weak, nonatomic) IBOutlet UIView *selectDateView;
@property (nonatomic, retain) NSString *employeeName;
@property (nonatomic, retain) NSString *employeeEmail;
@property (nonatomic, assign) BOOL fromCustomerDetail;
@property (nonatomic, assign) UINavigationController* previousNavigation;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuBarItem;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *backbutton;
//@property (weak, nonatomic) IBOutlet UIButton *backInsideButton;
@end
