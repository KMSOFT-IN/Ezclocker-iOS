//
//  TimeSheetDetailViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import <MapKit/MapKit.h>
#import "CommonLib.h"
#import "CheckClockStatusWebService.h"
#import "TimeEntry.h"
#import "JobCodeListViewController.h"
#import "TPKeyboardAvoidingScrollView.h"

#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif

@class TimeSheetDetailViewController;


@protocol TimeSheetDetailViewControllerDelegate
- (void)saveTimeEntryDidFinish:(TimeSheetDetailViewController *)controller;
@end

@interface TimeSheetDetailViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UITextFieldDelegate, MKMapViewDelegate, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource,UITextViewDelegate, checkClockStatusWebServicesDelegate, UIPickerViewDelegate, UIPickerViewDataSource, JobCodeListViewDelegate>{
    UIDatePicker *pickDate;
    CGPoint originalCenter;
    CGSize scrollViewCGSize;
    int TextFieldMode;
    UIDatePicker *theDatePicker;
    UIToolbar* pickerToolbar;
    UIToolbar* keyboardToolbar;
    UIView* pickerViewDate;
    UIButton *deleteDateButton;
    BOOL deleteTimeEntry;
//    UIViewController* popoverContent;
    NSDateFormatter *formatterDateTime12, *formatterISO8601DateTime;
    UIPickerView *pickerViewJobCode;
    NSMutableArray *jobCodesList;
    NSDictionary *selectedJobCode;
}
@property (weak, nonatomic) IBOutlet UIView *topViewController;
@property (weak, nonatomic) IBOutlet UILabel *timeEntryLabel;



@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *tpKeyboard;
@property (nonatomic, copy) NSManagedObjectID* timeEntryObjectID;


@property (weak, nonatomic) IBOutlet UILabel *clockInLabel;
@property (weak, nonatomic) IBOutlet UILabel *clockOutLabel;
@property (weak, nonatomic) IBOutlet UILabel *reasonLabel;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
- (IBAction)doDeleteTimeEntry:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *midViewContainer;
@property (strong, nonatomic) IBOutlet UITableView *mapHistoryTable;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapTableTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapTableViewHeight;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIView *viewContainer;
@property (retain, nonatomic) IBOutlet UITextView *reasonTextView;
@property (weak, nonatomic) IBOutlet UITextField *clockInField;
@property (weak, nonatomic) IBOutlet UITextField *jobCodeField;

@property (weak, nonatomic) IBOutlet UITextField *clockOutField;
@property (weak, nonatomic) IBOutlet UIView *deleteBtnView;
@property (assign, nonatomic) IBOutlet id <TimeSheetDetailViewControllerDelegate> delegate;


@property (nonatomic, assign) ClockMode selectedMode;
@property (nonatomic, copy) NSString *employeeName;
@property (nonatomic, copy) NSNumber *employeeId;
@property (nonatomic, copy) NSNumber *jobCodeId;

//this will tell us if we are in an active clode mode or not
@property (nonatomic, assign) int editClockMode;

@property (nonatomic, copy) NSString* description;
@property (nonatomic, copy) NSDate* clockInDateValue;
@property (weak, nonatomic) IBOutlet UIView *jobCodeView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *jobCodeViewHeight;
@property (nonatomic, copy) NSDate* clockOutDateValue;
@property (nonatomic, copy) NSMutableArray *jobCodes;
+ (TimeSheetDetailViewController*)showDetail:(id<TimeSheetDetailViewControllerDelegate>)delegate;
+ (TimeSheetDetailViewController*)controller;
+ (void)releaseController;
+ (void)popAndReleaseDetail;


@end
