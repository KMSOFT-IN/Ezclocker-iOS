//
//  EmployeeClockViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "UIViewControllerEx.h"
#import "CommonLib.h"

#import "user.h"
#import "ClockWebServices.h"
#import "BreakViewController.h"

//#import <iAd/iAd.h>

#ifdef PERSONAL_VERSION

#import "GADBannerView.h"

#endif

@class GADBannerView, GADRequest;

typedef enum {
    All_Synced = 0,
    ClockIn_Not_Synced = 1,
    ClockOut_Not_Synced = 2,
    Both_Not_Synced = 3
} OfflineMode;


//@interface FirstViewController : UIViewController <NSURLConnectionDataDelegate, CLLocationManagerDelegate, UITableViewDelegate, checkClockStatusWebServicesDelegate>
#ifdef PERSONAL_VERSION

//@interface EmployeeClockViewController : UIViewControllerEx <NSURLConnectionDataDelegate, UITableViewDelegate, UIAlertViewDelegate, ADBannerViewDelegate, GADBannerViewDelegate, UITextFieldDelegate>
@interface EmployeeClockViewController : UIViewControllerEx <NSURLConnectionDataDelegate, UITableViewDelegate, UIAlertViewDelegate, GADBannerViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, BreakViewControllerDelegate>

#else
// EmployeeClockViewController : UIViewController <NSURLConnectionDataDelegate, UITableViewDelegate, UIAlertViewDelegate, UITextFieldDelegate>
@interface EmployeeClockViewController : UIViewControllerEx <NSURLConnectionDataDelegate, UITableViewDelegate, UIActionSheetDelegate,clockWebServicesDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, BreakViewControllerDelegate>


#endif
{
    NSMutableData *data;
    int apiCallType;
    int currentClockMode;
    NSDate *lastClockInTime;
    NSDate *lastBreakInTime;
    NSString *strLastClockInTime;
    NSString *strLastClockOutTime;
    NSString *strLastBreakInTime;
    NSString *strLastBreakOutTime;
    NSString *timeEntryNotes;
    NSDate *lastClockOutTime;
    NSDateFormatter *formatterTime, *formatterISO8601DateTime, *formatterDateTime12hr;
    CLLocationManager *myLocationManager;
    int currentDistanceinMiles;
    int offlineMode;
    RatingDialogType ratingDialogType;
    UIToolbar* pickerToolbar;
    UIView* pickerViewDate;
    UIPickerView *pickerViewJobCode;
    NSMutableArray *jobCodesList;
    NSDictionary *selectedJobCode;
    NSNumber *primaryJobCodeId;
    UIViewController* popoverContent;
    bool isActiveBreakIn;
    bool isBreakScreenShowing;
}

typedef enum {
    CheckActiveClock = 0,
    CheckTimeEntryByID = 1,
} apiCallMode;



@property (nonatomic,assign) BOOL bannerIsVisible;

//@property (nonatomic, retain) UIBarButtonItem* settingsButton;


//@property (weak, nonatomic) IBOutlet UILabel *lblDebug;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuBarItem;
//This devDisplayLabel is used to display the word Running Dev Version when running in debug mode
//away for us to know which version we are using
@property (weak, nonatomic) IBOutlet UILabel *devDisplayLabel;
//@property (strong, nonatomic) IBOutlet ADBannerView *bannerView;
//@property (nonatomic, strong) GADBannerView *admobBannerView;
@property (weak, nonatomic) IBOutlet UIView *adBannerContainer;

@property (nonatomic, assign) BOOL fromCustomerDetail;
@property (nonatomic, assign) UINavigationController* previousNavigation;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *backbutton;
//@property (weak, nonatomic) IBOutlet UIButton *backInsideButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (weak, nonatomic) IBOutlet UINavigationBar *topNavigationBar;
- (IBAction)doCockIn:(id)sender;
- (IBAction)doClockOut:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *signalStrengthImageView;
@property (weak, nonatomic) IBOutlet UILabel *signalStrengthLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UIButton *clockInBtn;
- (IBAction)revealMenu:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *clockOutBtn;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UITableView *TimeClockTableView;
-(void) showPasscodeViewController: (BOOL) setPasscode;
//@property (strong, nonatomic) TimeSheetDetailViewController *editActiveClockViewController;
- (IBAction)doJobCodes:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *jobCodeTextField;
@property (weak, nonatomic) IBOutlet UIView *jobCodeView;


@end
