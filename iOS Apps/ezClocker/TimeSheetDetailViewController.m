//
//  TimeSheetDetailViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "TimeSheetDetailViewController.h"
#import "user.h"
#import <QuartzCore/QuartzCore.h>
#import "CommonLib.h"
#import "EZAnnotation.h"
#import "TimeEntryHistoryViewController.h"
#import "MapViewController.h"
#import "CheckClockStatusWebService.h"
#import "DataManager.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "TimeEntry+Extensions.h"
#import "debugdefines.h"
#import "TimeEntry.h"
#import "TimeEntry+CoreDataProperties.h"
#import "ClockInfo.h"
#import "ClockInfo+CoreDataProperties.h"
#import "SharedUICode.h"
#import "ClockInfo+Extensions.h"
#import "MetricsLogWebService.h"
#import "NSNumber+Extensions.h"
#import "JobCodeListViewController.h"


@interface TimeSheetDetailViewController () {
}

//@property (nonatomic, copy) NSString* description;
//@property (nonatomic, copy) NSDate* clockInDateValue;
//@property (nonatomic, copy) NSDate* clockOutDateValue;
@property (nonatomic, retain, readonly) TimeEntry* timeEntry;


@end

@implementation TimeSheetDetailViewController

@synthesize description, clockInDateValue, clockOutDateValue;
@synthesize reasonTextView;

@synthesize delegate = _delegate;
@synthesize selectedMode, employeeName;

int TEXTFIELD_CLOCK_IN_TAG = 1;
int TEXTFIELD_CLOCK_OUT_TAG = 2;
int TEXTFIELD_JOBCODE_TAG = 3;

static TimeSheetDetailViewController* __controller = nil;

+ (TimeSheetDetailViewController*)showDetail:(id<TimeSheetDetailViewControllerDelegate>)delegate {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    __controller = [storyboard instantiateViewControllerWithIdentifier:@"TimeSheetDetail2ViewController"];    __controller.delegate = delegate;
    return __controller;
}

+ (TimeSheetDetailViewController*)controller {
    return __controller;
}

+ (void)releaseController {
    if (nil != __controller) {
        [__controller releaseAll];
        __controller = nil;
    }
}

+ (void)popAndReleaseDetail {
    TimeSheetDetailViewController* controller = [TimeSheetDetailViewController controller];
    if (nil != controller) {
        controller.delegate = nil;
        [controller.navigationController popToRootViewControllerAnimated:FALSE];
        [TimeSheetDetailViewController releaseController];
    }
}


- (void)releaseAll {
    self.delegate = nil;
    self.scrollView = nil;
    self.reasonTextView = nil;
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)dealloc {
    [self releaseAll];
}

- (TimeEntry*)timeEntry {
    if (nil == _timeEntryObjectID) {
        return nil;
    }
    DataManager* manager = [DataManager sharedManager];
    NSError* error = nil;
    TimeEntry* result = (TimeEntry*)[manager existingObjectByID:_timeEntryObjectID error:&error];
    if (nil != error) {
        return nil;
    }
    return result;
}
- (NSString*)clockInDateTime {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return @"";
    }
    return __timeEntry.clockIn ? [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString] : @"";
}

- (NSString*)clockOutDateTime {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return @"";
    }
    return __timeEntry.clockOut ? [__timeEntry.clockOut.dateTimeEntry toLongDateTimeString] : @"";
}
#define CLLocationZero CLLocationCoordinate2DMake(0.0, 0.0)

- (CLLocationCoordinate2D)clockInLocation {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return CLLocationZero;
    }
    return __timeEntry.clockIn ? __timeEntry.clockIn.location : CLLocationZero;
}

- (NSNumber*) clockInAccuracy {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return 0;
    }
    return __timeEntry.clockIn ? __timeEntry.clockIn.accuracy : 0;
}


- (CLLocationCoordinate2D)clockOutLocation {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return CLLocationZero;
    }
    return __timeEntry.clockOut ? __timeEntry.clockOut.location : CLLocationZero;
}

- (NSNumber*) clockOutAccuracy {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return 0;
    }
    return __timeEntry.clockOut ? __timeEntry.clockOut.accuracy : 0;
}


- (NSString*)clockInGpsDataStatus {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return @"";
    }
    return __timeEntry.clockIn ? __timeEntry.clockIn.gpsDataStatus : @"";
}

- (NSString*)clockOutGpsDataStatus {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return @"";
    }
    return __timeEntry.clockOut ? __timeEntry.clockOut.gpsDataStatus : @"";
}

- (NSString*)notes {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return @"";
    }
    return [NSString trim:__timeEntry.notes];
}

- (NSNumber*) jobCodeId {
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        return 0;
    }
    return __timeEntry.jobCodeId ? __timeEntry.jobCodeId : 0;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.title = NSLocalizedString(@"Edit Time Entry", @"Edit Time Entry");
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
    @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
 //   jobCodesList = [[NSMutableArray alloc] initWithArray: user.jobCodesList];
    _jobCodeField.delegate = self;
    
    //put a borde on the text field
    reasonTextView.text = @"";
    CALayer *imageLayer = reasonTextView.layer;
    [imageLayer setCornerRadius:10];
    [imageLayer setBorderWidth:2.1];
    imageLayer.borderColor=[[UIColor lightGrayColor] CGColor];
    
    _clockInField.tag = TEXTFIELD_CLOCK_IN_TAG;
    _clockOutField.tag = TEXTFIELD_CLOCK_OUT_TAG;
    _jobCodeField.tag = TEXTFIELD_JOBCODE_TAG;

    _clockInField.delegate = self;
    _clockOutField.delegate = self;
    
    _mapHistoryTable.layer.borderWidth = 0.5;
    _mapHistoryTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    _mapHistoryTable.delegate = self;
    _mapHistoryTable.dataSource = self;
    
    UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveButtonAction)];
    
    self.navigationItem.rightBarButtonItem = saveButton;

    
    formatterDateTime12 = [[NSDateFormatter alloc] init];
    [formatterDateTime12 setLocale: [[NSLocale alloc]
                                     initWithLocaleIdentifier:@"en_US"]];
    
  //  [formatterDateTime12 setTimeZone:[NSTimeZone localTimeZone]];
    
//#ifndef PERSONAL_VERSION
//    [formatterDateTime12 setDateFormat:@"MM/dd/yyyy h:mm:ss a"];
//#else
//    [formatterDateTime12 setDateFormat:@"MM/dd/yyyy h:mm a"];
//#endif
    
    [formatterDateTime12 setDateFormat:kLongDateTimeFormat];
    
    //formatterDateTime = [[NSDateFormatter alloc] init];
    //[formatterDateTime setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
    formatterISO8601DateTime = [[NSDateFormatter alloc] init];
    [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
//    [self registerForKeyboardNotifications];
    
    TextFieldMode = 1;
    [self setFramePicker];
    theDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
    theDatePicker.hidden = NO;
    NSDate *date = [NSDate date];
    theDatePicker.date = date;
    
#ifdef PERSONAL_VERSION
    _reasonLabel.text = @"Notes";
#endif
    
    reasonTextView.delegate = (id) self;
    
    keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    keyboardToolbar.barStyle=UIBarStyleBlackOpaque;
    [keyboardToolbar sizeToFit];
    
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 200, 20.0f)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    titleLabel.text = @"Enter reason for change";
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];

    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(keyBoardDoneClick)];
    
    
   
    NSArray *itemArray = [[NSArray alloc] initWithObjects:titleButton, flexSpace, doneDateBarBtn, nil];
    

    
    [keyboardToolbar setItems:itemArray animated:YES];

    [reasonTextView setInputAccessoryView:keyboardToolbar];
    
}
- (void)setFramePicker {
    CGFloat kbHeight = [NSUserDefaults.standardUserDefaults floatForKey:keyboardHeight];
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = screenSize.height;
    
    CGFloat safeAreaTopHeight = 0;
    CGFloat safeAreaBottomHeight = 0;
    if (@available(iOS 11, *)) {
        // safe area constraints already set
        safeAreaTopHeight = UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
        safeAreaBottomHeight = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    } else {
        safeAreaTopHeight = self.view.safeAreaInsets.top;
        safeAreaBottomHeight = self.view.safeAreaInsets.bottom;
    }
    
    CGFloat Y = screenHeight - (kbHeight + safeAreaBottomHeight + safeAreaTopHeight);
    if (self.tabBarController != nil) {
        CGFloat tabbarHeight = self.tabBarController.tabBar.frame.size.height;
        
        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, Y - tabbarHeight, self.view.frame.size.width, kbHeight)];
    } else {
        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, Y, self.view.frame.size.width, kbHeight)];
    }
    
    [pickerViewDate setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    
    //if we are running the iPhone then we start at 44 because of the toolbar
    CGRect pickerFrame;
//    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//    {
//        pickerFrame = CGRectMake(0, 44, screenSize.width, 250);
//        theDatePicker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
//    } else {
        pickerFrame = CGRectMake(0, 44,  screenSize.width, kbHeight - 44);
        theDatePicker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
//    }
    
    [theDatePicker addTarget:self action:@selector(onDatePickerValueChanged) forControlEvents:UIControlEventValueChanged];
    
  //  pickerViewJobCode = [[UIPickerView alloc] initWithFrame:pickerFrame];
  //  pickerViewJobCode.dataSource = self;
   // pickerViewJobCode.delegate = self;
}

- (void)viewDidUnload
{
    [self setReasonTextView:nil];
    pickerViewDate = nil;
    theDatePicker = nil;
    pickerToolbar = nil;
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) viewWillDisappear:(BOOL)animated{
    [self.view endEditing:YES];
    
    [self closeDatePicker];
    [self removeKeyboard];
    if ([self.view isFirstResponder]) {
        [self.view resignFirstResponder];
    }
    [super viewWillDisappear:animated];
}

-(NSDictionary *) findSelectedJobCode
{
    NSNumber* selectedJobCodeId = [self jobCodeId];
    NSNumber* __jobCodeId;
    for (NSDictionary* jobCode in _jobCodes )
    {
        __jobCodeId = [jobCode valueForKey:@"id"];
        if (__jobCodeId && [NSNumber isEquals:__jobCodeId dest:selectedJobCodeId])
        {
            selectedJobCode = [NSDictionary dictionaryWithDictionary:jobCode];
            break;
        }
    }
    return selectedJobCode;
}
-(void) viewWillAppear:(BOOL)animated{
    reasonTextView.text = [self notes];
    
    [self findSelectedJobCode];
    NSString *jobCodeDisplayValue = [selectedJobCode valueForKey:@"name"];

    if (![NSString isNilOrEmpty:jobCodeDisplayValue])
        _jobCodeField.text = jobCodeDisplayValue;
    
    self.clockOutDateValue = [formatterDateTime12 dateFromString:self.clockOutDateTime];
    
    _clockInField.text = self.clockInDateTime;
    _clockOutField.text = self.clockOutDateTime;

    [_scrollView setScrollEnabled:YES];
   // [_scrollView setContentSize:CGSizeMake(320, 500)];
    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    self.view.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);

    
    if ((_editClockMode == ACTIVE_CLOCKIN) ||  (_editClockMode == ACTIVE_CLOCKOUT)) {
        //if we are editing an Active Clockin then re-arange the controls
        //don't show the map and history table and move the delete button
//        [_mapHistoryTable removeFromSuperview];
//        [_deleteButton removeFromSuperview];
        
        
        [_mapHistoryTable setHidden:YES];
         [_deleteButton setHidden:YES];
        //make the container the same collor as the scrollview so it blends in
        _viewContainer.backgroundColor = _scrollView.backgroundColor;
        _midViewContainer.backgroundColor = _scrollView.backgroundColor;
        
       // [_viewContainer addSubview:_deleteButton];
        if (_editClockMode == ACTIVE_CLOCKIN)
        {
            _clockInField.enabled = YES;
            _clockInLabel.enabled = YES;
            _clockOutField.enabled = NO;
            _clockOutField.textColor = [UIColor lightGrayColor];
            _clockOutLabel.enabled = NO;
        }
        else{
            _clockInField.enabled = NO;
            _clockInField.textColor = [UIColor lightGrayColor];
            _clockInLabel.enabled = NO;
            _clockOutField.enabled = YES;
            _clockOutLabel.enabled = YES;
            
        }
        if ([_clockOutField.text length] == 0)
            //don't let them delete if there is no clock out
            _deleteButton.hidden = YES;
        else
            _deleteButton.hidden = NO;

    }
    //else we are coming from the time sheet master controller
    else{
#ifndef PERSONAL_VERSION
        //topViewController I deleted when I moved to iPad
       // [_topViewController removeFromSuperview];
//        [_midViewContainer removeFromSuperview];
    //      _midViewContainer.hidden = YES;
        _mapTableTopConstraint.constant = 16;
        _mapTableViewHeight.constant = 120;
        
#else
        //if we are coming from the personal app don't show them the map or history views - not supported in the personal app
        //move the delete button up to where the mapHistoryTable was
        
//        CGRect  deleteViewFrame = _deleteBtnView.frame;
//        CGRect mapHistoryTableFrame = _mapHistoryTable.frame;
//        deleteViewFrame = CGRectMake( deleteViewFrame.origin.x, mapHistoryTableFrame.origin.y, deleteViewFrame.size.width, deleteViewFrame.size.height );
//
//        _deleteBtnView.frame = deleteViewFrame;
//        [_mapHistoryTable removeFromSuperview];
        _mapTableViewHeight.constant = 0;
        _deleteButton.titleLabel.font = [UIFont systemFontOfSize:17];
        //make the container the same collor as the scrollview so it blends in
        _viewContainer.backgroundColor = _scrollView.backgroundColor;
        _midViewContainer.backgroundColor = _scrollView.backgroundColor;

#endif
    }
    

    _jobCodeViewHeight.constant = 50;
    if ([_jobCodes count] == 0) {
        _jobCodeView.hidden = TRUE;
        _jobCodeViewHeight.constant = 0;
    }
    
    

    [self closeDatePicker];
    
    [self removeKeyboard];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWasShown:)
//                                                 name:UIKeyboardDidShowNotification object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWillBeHidden:)
//                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
//- (void)keyboardWasShown:(NSNotification*)aNotification
//{
//    NSDictionary* info = [aNotification userInfo];
//    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
//    UIEdgeInsets contentInsets;
//    //if we are coming from the main clockin/out screen
//    if ((_editClockMode == ACTIVE_CLOCKIN) ||  (_editClockMode == ACTIVE_CLOCKOUT))
//        contentInsets = UIEdgeInsetsMake(65.0, 0.0, kbSize.height, 0.0);
//    else
//        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
//
//
//    _scrollView.contentInset = contentInsets;
//    _scrollView.scrollIndicatorInsets = contentInsets;
//
//    // If active text field is hidden by keyboard, scroll it so it's visible
//    // Your app might not need or want this behavior.
//    CGRect aRect = self.view.frame;
//    aRect.size.height -= kbSize.height;
//    if (!CGRectContainsPoint(aRect, _mapHistoryTable.frame.origin) ) {
//        [self.scrollView scrollRectToVisible:reasonTextView.frame animated:YES];
//
//    }
//}

// Called when the UIKeyboardWillHideNotification is sent
//- (void)keyboardWillBeHidden:(NSNotification*)aNotification
//{
//    //check the 2 lines
//  //  [_scrollView setContentOffset:CGPointMake(0,0) animated:YES];
//    [self.scrollView scrollRectToVisible:_clockInField.frame animated:YES];
//
//    //UIEdgeInsets contentInsets = UIEdgeInsetsZero;
//    //_scrollView.contentInset = contentInsets;
//    //_scrollView.scrollIndicatorInsets = contentInsets;
//}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Close the keypad if it is showing
    [self.view.superview endEditing:YES];
    
    if (textField.tag == TEXTFIELD_JOBCODE_TAG)
        [self showJobCodesPicker];
    else{
        
    @try{
        if (textField.tag == TEXTFIELD_CLOCK_OUT_TAG)
        {
        
        //if the user is trying to set the clock out but it's an active clock in then it will mess up the data so ask them to clock out first then come back here and edit it
        if (_editClockMode == EDIT_ACTIVE_CLOCK)
        {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"This is part of an active clock in. Please clock out first using the clock out button then modify."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

        //    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"This is part of an active clock in. Please clock out first using the clock out button then modify." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //    [alert show];
            
        }
        
        else
            [self showDatePicker: textField];
        }
        else
           [self showDatePicker: textField];
    }@catch (NSException *theException) {
#ifndef RELEASE
        NSLog(@"%@ doClockOutBtnClick check error!", [theException name]);
#endif
        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from TimeSheetDetailViewController.doClockOutBtnClick error= %@", theException.reason]];
        
    }
    }

    
    // Return no so that no cursor is shown in the text box
    return  NO;

}

#pragma mark - updating a time entry

-(void) callModifyTimeEntryWebService{
    //NSString *currentDateTime = self.getCurrentDateTime;
    deleteTimeEntry = FALSE;
    self.description = [NSString trim:reasonTextView.text]; //@"change time entry";

    NSString *partialTimeEntryVal = @"NO";
    NSString *clockInValue = _clockInField.text;
    self.clockInDateValue = [formatterDateTime12 dateFromString:_clockInField.text];
    if (!([clockInValue rangeOfString:@"12:00 AM"].location == NSNotFound)) 
        partialTimeEntryVal = @"StartDateClipped";

    //self.clockOutDateValue = [formatterDateTime12 dateFromString:_clockOutField.text];
    NSString *clockOutValue = _clockOutField.text;
    self.clockOutDateValue = [formatterDateTime12 dateFromString:_clockOutField.text];
    if (!([clockOutValue rangeOfString:@"12:00 AM"].location == NSNotFound))
        partialTimeEntryVal = @"EndDateClipped";

    
    DataManager* manager = [DataManager sharedManager];
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        [SharedUICode messageBox:nil message:@"There was an issue with the Time Entry." withCompletion:^{
            return;
        }];
    }
    
    NSString *selectedJobCodeId = [selectedJobCode valueForKey:@"id"];
    
    [manager modifyTimeEntryOnServer:__timeEntry clockIn:self.clockInDateValue clockOut:self.clockOutDateValue notes:self.description jobCodeId: selectedJobCodeId partialTimeEntry: partialTimeEntryVal withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {

        [self stopSpinner];
        
        if (nil != results) { // If we had changed the date of the time entry that means it was moved so we need to check to see if the _timeEntryObjectID is different and update
            TimeEntry* timeEntry = [results objectForKey:ktimeEntryKey];
            NSManagedObjectID *obj1 = self.timeEntryObjectID;
            NSManagedObjectID *obj2 = timeEntry.objectID;
            if ((nil != timeEntry) && ![obj1 isEqual:obj2])
            {
                self.timeEntryObjectID = timeEntry.objectID;
            }
//            if (nil != timeEntry && ![self.timeEntryObjectID isEquals:timeEntry.objectID]) {
//                self.timeEntryObjectID = timeEntry.objectID;
//            }
        }

        switch (errorCode) {
            case DATAMANAGER_BUSY: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:DATAMANAGER_BUSY description:@"DATAMANAGER_BUSY" error:error];
                [SharedUICode displayServerIsBusy];
                break;
            }
            case SERVICE_UNAVAILABLE_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_UNAVAILABLE_ERROR description:@"SERVICE_UNAVAILABLE_ERROR" error:error];
                [SharedUICode displayServiceUnavailableErrorWithMsg:@"NOTE: You can continue to modify time entries and we will save to the server later." withCompletion:^{
                    [DataManager postDataWasModifiedNotification];
                    [self.delegate saveTimeEntryDidFinish:self];
                }];
                break;
            }
            case SERVICE_ERRORCODE_UNKNOWN_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_UNKNOWN_ERROR description:@"SERVICE_ERRORCODE_UNKNOWN_ERROR" error:error];
                [SharedUICode checkResultsMessageAndDisplayError:resultMessage error:error];
//[self showDatePicker];
                break;
            }
            case SERVICE_ERRORCODE_SUCCESSFUL: {
                [DataManager postDataWasModifiedNotification];
                [self updateUserClockInClockOut];
                [self.delegate saveTimeEntryDidFinish:self];
                break;
            }
            default: {
#ifndef RELEASE
                DEBUG_MSG
                NSLog(@"Unhandled errorCode: %ld %@ %@", (long)errorCode, msg, error.localizedDescription);
#endif
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:UNKNOWN_ERROR description:@"UNKNOWN_ERROR" error:error];
                break;
            }
        }
    }];


}

- (void)updateUserClockInClockOut {
    if ((_editClockMode == ACTIVE_CLOCKIN) || (_editClockMode == ACTIVE_CLOCKOUT))
    {
        UserClass *user = [UserClass getInstance];
        if ([_clockOutField.text length] > 0)
            user.lastClockIn = _clockInField.text;
//        if ([_clockOutButton.titleLabel.text length] > 0)
        if (self.clockOutDateValue != nil)
            user.lastClockOut = _clockOutField.text;

    }
}

#pragma mark - deleting a time entry

-(void) callDeleteTimeEntryWebService{

    //NSString *currentDateTime = self.getCurrentDateTime;
    DataManager* manager = [DataManager sharedManager];
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        [SharedUICode messageBox:nil message:@"There was an issue with the Time Entry." withCompletion:^{
            return;
        }];
        return;
    }
    [manager removeTimeEntryFromServer:__timeEntry withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
        [self stopSpinner];

        switch (errorCode) {
            case DATAMANAGER_BUSY: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:DATAMANAGER_BUSY description:@"DATAMANAGER_BUSY" error:error];
                [SharedUICode displayServerIsBusy];
                break;
            }
            case SERVICE_UNAVAILABLE_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_UNAVAILABLE_ERROR description:@"SERVICE_UNAVAILABLE_ERROR" error:error];
                [SharedUICode displayServiceUnavailableErrorWithMsg:@"NOTE: You can continue to delete time entries and we will save to the server later." withCompletion:^{
                    [DataManager postDataWasModifiedNotification];
                    [self updateUserClockInClockOut];
                    [self closeDatePicker];
                    [self.delegate saveTimeEntryDidFinish:self];
                }];
                break;
            }
            case SERVICE_ERRORCODE_UNKNOWN_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_UNKNOWN_ERROR description:@"SERVICE_ERRORCODE_UNKNOWN_ERROR" error:error];
                [SharedUICode checkResultsMessageAndDisplayError:resultMessage error:error];
                break;
            }
            case SERVICE_ERRORCODE_SUCCESSFUL: {
                [DataManager postDataWasModifiedNotification];
                [self updateUserClockInClockOut];
                UserClass *user = [UserClass getInstance];
                NSInteger timeEntryID = [__timeEntry.timeEntryID integerValue];
                if ((user.activeTimeEntryId && timeEntryID == [user.activeTimeEntryId integerValue]) && timeEntryID > 0)
                {
                    user.activeTimeEntryId = nil; // set it to nil so that it will use most recent from database but check clock status may return it as well so it will be set again
                    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:user.activeTimeEntryId forKey:kactiveTimeEntryIDKey];
                    [defaults synchronize];
                }
                [self closeDatePicker];
                self.timeEntryObjectID = nil;
                [self.delegate saveTimeEntryDidFinish:self];
                break;
            }
            default: {
#ifndef RELEASE
                DEBUG_MSG
                NSLog(@"Unhandled errorCode: %ld %@", (long)errorCode, msg);
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:UNKNOWN_ERROR description:@"UNKNOWN_ERROR" error:error];
#endif
                break;
            }
        }
    }];

}

-(void)onDatePickerValueChanged
{
//    if (TextFieldMode == TEXTFIELD_CLOCK_IN_TAG)
//        _clockInField.text = [theDatePicker.date toLongDateTimeString];
//    else
//        _clockOutField.text = [theDatePicker.date toLongDateTimeString];
}


-(void) saveButtonAction
{
    NSDate *clockInDateTime = [_clockInField.text toLongDateTime];
    NSDate* clockOutDateTime = [_clockOutField.text toLongDateTime];
     
    if( (![NSDate isNilOrNull:clockOutDateTime]) && (([clockInDateTime compare: clockOutDateTime] == NSOrderedDescending) || ([clockInDateTime compare: clockOutDateTime] == NSOrderedSame)))// if start is later or equal in time than end
    {
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"The clock out value must be later than the clock in value."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    else{
        DataManager* manager = [DataManager sharedManager];
        if ([manager isBusy]) {
            [SharedUICode displayServerIsBusy];
            return;
        }
        //    NSDate *clockPickerDate = [pickDate date];
    
        //only force non personal accounts to enter a reason for the edit
#ifndef PERSONAL_VERSION
        NSString *strResult = reasonTextView.text;
        strResult = [strResult stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (strResult.length == 0) {
            UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Required Field"
                                     message:@"Please enter a reason in the Notes box for the change"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
            [alert addAction:defaultAction];
        
            [self presentViewController:alert animated:YES completion:nil];


            //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a reason in the Notes box for the change" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];

        }
        else {
                [self startSpinnerWithMessage:@"Saving, please wait..."];
                [self callModifyTimeEntryWebService];
        }
#else
        [self startSpinnerWithMessage:@"Saving, please wait..."];
        [self callModifyTimeEntryWebService];
#endif
    
        [self removeKeyboard];
    }
}


-(void)dateSelected:(id)sender{
    if (TextFieldMode == TEXTFIELD_CLOCK_IN_TAG)
        _clockInField.text = [formatterDateTime12 stringFromDate:[sender date]];
      //  [_clockInButton setTitle:[formatterDateTime12 stringFromDate:[sender date]] forState:UIControlStateNormal];
    else {
        _clockOutField.text = [formatterDateTime12 stringFromDate:[sender date]];
       // [_clockOutButton setTitle:[formatterDateTime12 stringFromDate:[sender date]] forState:UIControlStateNormal];
        self.clockOutDateValue = [sender date];
    }
 }


-(void)removeKeyboard{
    //   self.view.center = originalCenter;
    if ([reasonTextView isFirstResponder]) {
        [reasonTextView resignFirstResponder];
    }
}

- (IBAction)doClockInEditingBegin:(id)sender {
 //   self.view.center = CGPointMake(originalCenter.x, originalCenter.y - 100);

}

-(void)closeDatePicker{
    [pickerViewDate removeFromSuperview];
}

-(IBAction)DatePickerDoneClick{
    UITextField *curField;
    if (TextFieldMode == TEXTFIELD_CLOCK_IN_TAG)
        curField = _clockInField;
    else
    {
        curField = _clockOutField;
        self.clockOutDateValue = theDatePicker.date;
    }

    curField.text = [formatterDateTime12 stringFromDate:theDatePicker.date];
   // [curButton setTitle:[formatterDateTime12 stringFromDate:theDatePicker.date] forState:UIControlStateNormal];

    
    [self closeDatePicker];
    
}
-(IBAction)keyBoardDoneClick{
    [_tpKeyboard setContentSize:CGSizeZero];
    [_tpKeyboard setContentOffset:CGPointZero animated:YES];
    [reasonTextView resignFirstResponder];
}

-(IBAction)DatePickerCancelClick{
    [self closeDatePicker];
}

-(void) showDatePicker: (UITextField*) textField{

    [self removeKeyboard];
    bool canEdit = true;
    //disableTimeEntryEditing is an option that employers can set to prevent their employees from editing time sheets. Check if the user is an employer then he/she can edit else check to see if that option is set for employees.
   
    @try{
#ifndef PERSONAL_VERSION
    UserClass *user = [UserClass getInstance];
      
  //  if ([user.userType isEqualToString:@"employer"])
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)) //((user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"])))
        canEdit = true;
    else
        canEdit = !(user.disableTimeEntryEditing);

#endif
    
    }@catch (NSException *theException) {
#ifndef RELEASE
        NSLog(@"%@ disableTimeEntryEditing check error!", [theException name]);
#endif
        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from TimeSheetDetailViewController.showDatePicker checking canEdit= %@", theException.reason]];


        }
    
        @try{
    if (!canEdit)
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Alert"
                                     message:@"Your Employer Has Turned Off The Edit Feature. You Can Only Add Notes"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your Employer Has Turned Off The Edit Feature. You Can Only Add Notes" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];

    }
    else{
        
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    pickerToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [pickerToolbar sizeToFit];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(DatePickerCancelClick)];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 80, 20.0f)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    if (textField.tag == TEXTFIELD_CLOCK_IN_TAG)
    {
        titleLabel.text = @"Clock In";
        TextFieldMode = TEXTFIELD_CLOCK_IN_TAG;
    }
    else
    {
        titleLabel.text = @"Clock Out";
        TextFieldMode = TEXTFIELD_CLOCK_OUT_TAG;
    }
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(DatePickerDoneClick)];
    
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:cancelBtn, flexSpace, titleButton, flexSpace, doneDateBarBtn, nil];
    
    [pickerToolbar setItems:itemArray animated:YES];

    UITextField *curField;
    if (textField.tag == TEXTFIELD_CLOCK_IN_TAG)
        curField = _clockInField;
    else
        curField = _clockOutField;
//    if (![curTextField.text isEqualToString:@""])
//        theDatePicker.date = [formatterDateTime12 dateFromString:curTextField.text];
//    else
//        curTextField.text = [formatterDateTime12 stringFromDate:theDatePicker.date];
    BOOL isEmpty = !(curField.text && curField.text.length > 0);

    if (!isEmpty)
        theDatePicker.date = [formatterDateTime12 dateFromString:curField.text];
    else
        curField.text = [formatterDateTime12 stringFromDate:theDatePicker.date];
    
        if (@available(iOS 13.4, *)) {
            [theDatePicker setPreferredDatePickerStyle:UIDatePickerStyleWheels];
        } else {
            // Fallback on earlier versions
        }
        
#ifdef IPAD_VERSION
        [pickerViewDate addSubview:pickerToolbar];
        [pickerViewDate addSubview:theDatePicker];
        [self.view addSubview:pickerViewDate];
        
//        [pickerViewDate addSubview:theDatePicker];
//        popoverContent.view = pickerViewDate;
//        popoverContent.modalPresentationStyle = UIModalPresentationPopover;
//        popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
//        popoverContent.popoverPresentationController.sourceView = self.view;
//        popoverContent.popoverPresentationController.sourceRect = curField.superview.frame;
//        [self presentViewController:popoverContent animated:YES completion:nil];
#else
        theDatePicker.frame = CGRectMake(0, theDatePicker.frame.origin.y, UIScreen.mainScreen.bounds.size.width, theDatePicker.frame.size.height);
        
        [pickerViewDate addSubview:pickerToolbar];
        [pickerViewDate addSubview:theDatePicker];
        [self.view addSubview:pickerViewDate];

#endif
        }
        
    }@catch (NSException *theException) {
#ifndef RELEASE
            NSLog(@"%@ showDatePicker check error!", [theException name]);
#endif
            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from showDatePicker TimeSheetDetailViewController= %@", theException.reason]];
        
        }

}
 
- (void)searchJobCode:(NSDictionary *)jobCodeObj {
    _jobCodeField.text = [jobCodeObj valueForKey:@"name"];
    selectedJobCode = jobCodeObj;
}


/*- (IBAction)clockInTouchDown:(id)sender {
    TextFieldMode = 1;
    [self showDatePicker];

}
*/


- (IBAction)doDeleteTimeEntry:(id)sender {
    UserClass *user = [UserClass getInstance];
    bool canDelete = true;
    
   // if ([user.userType isEqualToString:@"employer"])
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)) //((user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"])))
        canDelete = true;
    else
        canDelete = !(user.disableTimeEntryEditing);

    if (!canDelete)
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Alert"
                                     message:@"Your Employer Has Turned Off The Edit Feature. You Can Only Add Notes"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your Employer Has Turned Off The Edit Feature. You Can Only Add Notes" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
        
    }
    else
    {

        //if this is an active clock in do not let them delete it because it will mess up the data

        if (_editClockMode == EDIT_ACTIVE_CLOCK)
        {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Alert"
                                         message:@"This is part of an active clock in. Please clock out using the clock out button then delete it"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

          //  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"This is part of an active clock in. Please clock out using the clock out button then delete it." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
        
        }
        else {
        
            [self confirmDelete];
        }
    }
}

-(void)confirmDelete{
    DataManager* manager = [DataManager sharedManager];
    if ([manager isBusy]) {
        [SharedUICode displayServerIsBusy];
        return;
    }
    [SharedUICode yesNo:@"Confirm Delete" message:@"Tapping DELETE will remove this record from the system permanently." yesBtnTitle:@"DELETE" noBtnTitle:@"Cancel" rootControl: _deleteButton withCompletion:^(YesNoCancelResult Result) {
        switch (Result) {
            case resultYes:
                [self doConfirmedDeleteTimeEntry];
                break;
                
            default:
                break;
        }
    }];
}

-(void)doConfirmedDeleteTimeEntry{
    [self startSpinnerWithMessage:@"Deleting, please wait..."];
    [self callDeleteTimeEntryWebService];
}

//#define MINIMUM_ZOOM 0.014
//#define ANNOTATION_REGION_PAD_FACTOR 3.15
//#define MAX_DEGREES 360


//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        
    return 60.0;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return 2;
    
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    if (indexPath.row == 0)
    {
        cell.textLabel.text = @"View Map";
        cell.imageView.image = [UIImage imageNamed:@"map-marker.png"];
    }
    else
    {
        cell.textLabel.text = @"View History";
        cell.imageView.image = [UIImage imageNamed:@"notepad.png"];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //if View map was selected
    if (indexPath.row == 0)
    {
        //if the employee disabled the GPS tracking
        if ([self.clockInGpsDataStatus isEqualToString:@"DISABLED"])
        {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Alert"
                                         message:@"Unable to view Map. Employee has turned off Location Services on their device. They will need to turn it on for this feature to work"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

           // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Unable to view Map. Employee has turned off Location Services on their device. They will need to turn it on for this feature to work" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
            
        }
        //if we don't have any GPS recording like for an add time entry vs a clock in
        else if ((self.clockInLocation.latitude == 0) && (self.clockOutLocation.latitude == 0))
        {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Alert"
                                         message:@"No GPS information available for this time entry"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

         //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"No GPS information available for this time entry" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
         //   [alert show];
           
        }

        else

            [self showMapView];
    }
    else
        [self showHistoryView];
}


-(void) showHistoryView{
    UIStoryboard *storyboard;
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    
    TimeEntryHistoryViewController *historyViewController = [storyboard instantiateViewControllerWithIdentifier:@"TimeEntryHistory"];
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        [SharedUICode messageBox:nil message:@"There was an issue with the Time Entry." withCompletion:^{
            return;
        }];
        return;
    }
    historyViewController.timeEntryID = [__timeEntry.timeEntryID stringValue];
    historyViewController.clockInDateTime = self.clockInDateTime;
    historyViewController.clockOutDateTime = self.clockOutDateTime;
    historyViewController.employeeName = employeeName;
    
    historyViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController pushViewController:historyViewController animated:YES];
}

-(void) showMapView{
    UIStoryboard *storyboard;
  //  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
  //  } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
  //      storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
  //  }
    
    MapViewController *mapViewController = [storyboard instantiateViewControllerWithIdentifier:@"MapView"];
    
    mapViewController.clockInLocation = self.clockInLocation;
    mapViewController.clockOutLocation = self.clockOutLocation;
    mapViewController.clockInAccuracy = self.clockInAccuracy;
    mapViewController.clockOutAccuracy = self.clockOutAccuracy;
    
    mapViewController.employeeName = self.employeeName;
    
    
    mapViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController pushViewController:mapViewController animated:YES];
    
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

- (IBAction)doPersonalAcctDeleteTimeEntry:(id)sender {
}

- (void)checkClockStatusServiceCallDidFinish:(CheckClockStatusWebService *)controller timeEntryRec:(NSDictionary *)timeEntryRec ErrorCode:(int)errorValue {
    
}

-(void) showJobCodesPicker{
    
    
/*    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    pickerToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [pickerToolbar sizeToFit];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(EmployeePickerCancelClick)];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 80, 20.0f)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(EmployeePickerDoneClick)];
    
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:cancelBtn, flexSpace, titleButton, flexSpace, doneDateBarBtn, nil];
    
    [pickerToolbar setItems:itemArray animated:YES];
    int row = 0;
    int pos = 0;
    BOOL isEmpty = !(_jobCodeField.text && _jobCodeField.text.length > 0);
    
    if (!isEmpty)
    {
        NSString *name;
        for (NSDictionary *jobCodeObj in jobCodesList)
        {
            name = [jobCodeObj valueForKey:@"displayValue"];
            if ([name isEqualToString:_jobCodeField.text])
                pos = row;
            else
                row++;
        }
    }
    //if the employee Name TextField is empty then default it to the first name in the employeeList
    
    [pickerViewJobCode selectRow:pos inComponent:0 animated:YES];
    */
    
/*#ifdef IPAD_VERSION
    
    [pickerViewDate addSubview:pickerViewJobCode];
    popoverContent.view = pickerViewDate;
    popoverContent.modalPresentationStyle = UIModalPresentationPopover;
    popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
    //popoverContent.popoverPresentationController.sourceView = _scrollView;
    popoverContent.popoverPresentationController.sourceRect = _jobCodeField.superview.frame;
    [self presentViewController:popoverContent animated:YES completion:nil];
#else
    [pickerViewDate addSubview:pickerToolbar];
    [pickerViewDate addSubview:pickerViewJobCode];
    [self.view addSubview:pickerViewDate];
 */
    UINavigationController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"jobCodeList"];
      JobCodeListViewController * controller = viewController.viewControllers.firstObject;
      controller.delegate = self;
      controller.jobCodes = _jobCodes;
      [self presentViewController:viewController animated:YES completion:nil];

//#endif
    
    
}



/*-(IBAction)EmployeePickerDoneClick{
    NSInteger row = [pickerViewJobCode selectedRowInComponent:0];
    
    // [_employeeButton setTitle:[employeeList objectAtIndex:row] forState:UIControlStateNormal];
    NSDictionary *jobCodeObj = [jobCodesList objectAtIndex:row];
    _jobCodeField.text = [jobCodeObj valueForKey:@"displayValue"];
    selectedJobCode = [jobCodesList objectAtIndex:row];
    
    [self closeEmployeePicker:self];
    
    //  [self assignSelectedJobCode ];
}

-(BOOL)closeEmployeePicker:(id)sender{
    [pickerViewJobCode removeFromSuperview];
    [pickerViewDate removeFromSuperview];
    return YES;
}

-(IBAction)EmployeePickerCancelClick{
    [self closeEmployeePicker:self];
}
 */

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [_jobCodes count];
}

#pragma mark Picker Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSDictionary *jobCodeObj = [_jobCodes objectAtIndex:row];
    NSString *name = [jobCodeObj valueForKey:@"name"];
    
    return name;
}


@end
