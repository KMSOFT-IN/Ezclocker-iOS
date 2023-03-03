//
//  AddTimeEntryViewController.m
//  TCS Mobile
//
//  Created by Raya Khashab on 11/10/12.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "AddTimeEntryViewController.h"
#import "user.h"
#import "CommonLib.h"
#import "Mixpanel.h"
#import "MetricsLogWebService.h"
#import "DataManager.h"
#import "SharedUICode.h"
#import "debugdefines.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "NSDictionary+Extensions.h"


@interface AddTimeEntryViewController ()
@end

@implementation AddTimeEntryViewController
@synthesize clockInLabel;
@synthesize clockOutLabel;
@synthesize delegate = _delegate;
@synthesize employeeID;

int CLOCK_IN_TAG = 1;
int CLOCK_OUT_TAG = 2;
int JOB_CODE_TAG = 3;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self showIOS14DatePicker];

    _reasonTextView.delegate = self;
    
    _clockInField.tag = CLOCK_IN_TAG;
    _clockOutField.tag = CLOCK_OUT_TAG;
    _jobCodeField.tag = JOB_CODE_TAG;
    
    _clockInField.delegate = self;
    _clockOutField.delegate = self;
    _jobCodeField.delegate = self;
    
    _reasonTextView.text = @"";
    CALayer *imageLayer = _reasonTextView.layer;
    [imageLayer setCornerRadius:10];
    [imageLayer setBorderWidth:2.1];
    imageLayer.borderColor=[[UIColor lightGrayColor] CGColor];

    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboardAction)];
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:flexSpace, doneDateBarBtn, nil];
    
    keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    keyboardToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [keyboardToolbar sizeToFit];
    
    
    [keyboardToolbar setItems:itemArray animated:YES];
    
//if we are running the personal app then we want the label to say notes not reason for add
#ifdef PERSONAL_VERSION
    _notesLabel.text = @"Notes";
#endif
    
    [_reasonTextView setInputAccessoryView:keyboardToolbar];
    
    if ( IDIOM == IPAD) {
        /* do something specifically for iPad. */
        [self registerForKeyboardNotifications];
    } else {
        /* do something specifically for iPhone or iPod touch. */
    }
    
    clockInTime = @"";
    clockOutTime = @"";
    TextFieldMode = 1;
    
    popoverContent = [[UIViewController alloc] init];
}
- (void)viewDidAppear:(BOOL)animated {
    [self setFramePicker];
    theDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
    theDatePicker.hidden = NO;
    NSDate *date = [NSDate date];
    theDatePicker.date = date;
    

}
- (void)setFramePicker {
    CGFloat kbHeight = [NSUserDefaults.standardUserDefaults floatForKey:keyboardHeight];
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = self.view.frame.size.height;//screenSize.height;
    
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
        
        pickerView = [[UIView alloc] initWithFrame:CGRectMake(0, Y - tabbarHeight, self.view.frame.size.width, kbHeight)];
    } else {
        pickerView = [[UIView alloc] initWithFrame:CGRectMake(0, Y, self.view.frame.size.width, kbHeight)];
    }
    
    [pickerView setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    
    //if we are running the iPhone then we start at 44 because of the toolbar
    CGRect pickerFrame;
    pickerFrame = CGRectMake(0, 44,  screenSize.width, kbHeight - 44);
    theDatePicker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
    [theDatePicker addTarget:self action:@selector(onDatePickerValueChanged) forControlEvents:UIControlEventValueChanged];
    
    pickerViewJobCode = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerViewJobCode.dataSource = self;
    pickerViewJobCode.delegate = self;
}
- (void)viewDidUnload
{
    [self setClockInLabel:nil];
    [self setClockOutLabel:nil];
    theDatePicker = nil;
    pickerToolbar = nil;
    pickerView = nil;

    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) viewWillAppear:(BOOL)animated{
   // [_clockInButton setTitle:@"" forState:UIControlStateNormal];
   // [_clockOutButton setTitle:@"" forState:UIControlStateNormal];

    
    _mainView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    
    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    [_scrollView setScrollEnabled:YES];
    [_scrollView setContentSize:CGSizeMake(320, 650)];
    _scrollView.delaysContentTouches = NO;
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];

    [self removeKeyboard];
    
   // UserClass *user = [UserClass getInstance];
    _jobCodeViewHeight.constant = 50;
    if ([_jobCodes count] == 0) {
        _jobCodeView.hidden = TRUE;
        _jobCodeViewHeight.constant = 0;
    }
    //default to the primary job code if we have one
    if (![NSDictionary isNilOrNull:_primaryJobCode])
    {
        _jobCodeField.text = [_primaryJobCode valueForKey:@"name"];
        selectedJobCode = _primaryJobCode;
    }

}
// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}


// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets;
    contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, _clockOutField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:_reasonTextView.frame animated:YES];
        
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
}


-(void)removeKeyboard{
 //   [_clockInTextField resignFirstResponder];
 //   [_clockOutTextField resignFirstResponder];
}

-(void)dismissKeyboardAction{
    [_reasonTextView resignFirstResponder];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)onDatePickerValueChanged
{
//    if (TextFieldMode == CLOCK_IN_TAG)
//        _clockInField.text = [theDatePicker.date toLongDateTimeString];
//    else
//        _clockOutField.text = [theDatePicker.date toLongDateTimeString];
}

- (IBAction)doTimeEntryCancel:(id)sender {
    [self.delegate addTimeEntryViewControllerDidFinish:self];
}


#pragma mark - Create New Time Entry

-(void) callCreateTimeEntryWebService{
    DataManager* manager = [DataManager sharedManager];
    if ([manager isBusy]) {
        [SharedUICode displayServerIsBusy];
        return;
    }

    NSDate *clockInDateTime = [_clockInField.text toLongDateTime];
    NSDate* clockOutDateTime = [_clockOutField.text toLongDateTime];
    if (nil == clockInDateTime) {
        clockOutDateTime = clockInDateTime;
    }
   
    [self startSpinnerWithMessage:@"Connecting to the server..."];

    NSNumber *selectedJobCodeId = [selectedJobCode valueForKey:@"id"];

    [manager sendNewTimeEntryToServer:clockInDateTime clockOut:clockOutDateTime notes:_reasonTextView.text jobCodeId: selectedJobCodeId withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
        [CommonLib logEvent:@"Add time entry"];
        [self stopSpinner];
        switch (errorCode) {
            case DATAMANAGER_BUSY: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:DATAMANAGER_BUSY description:@"DATAMANAGER_BUSY" error:error];
                [SharedUICode displayServerIsBusy];
                break;
            }
            case SERVICE_UNAVAILABLE_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_UNAVAILABLE_ERROR description:@"SERVICE_UNAVAILABLE_ERROR" error:error];
                [SharedUICode displayServiceUnavailableErrorWithMsg:@"NOTE: You can continue to add time entries and we will save to the server later." withCompletion:^{
                    [DataManager postDataWasModifiedNotification];
                    [self.delegate addTimeEntryViewControllerDidFinish:self];
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
                if ([CommonLib isProduction])
                {
//                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
//                    UserClass *user = [UserClass getInstance];
//                    [mixpanel track:@"Add Time Entry" properties:@{ @"email": user.userEmail}];
                }
                [self.delegate addTimeEntryViewControllerDidFinish:self];
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

- (void) saveTimeEntry: (NSString*) clockInValue ClockOut: (NSString*) clockOutValue
{
    BOOL isEmpty = [NSString isNilOrEmpty:clockInValue];

    if (isEmpty) {
        UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"To use this feature you need to enter a clock in and out value. Please enter a clock In Time"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
        [alert addAction:defaultAction];
                
        [self presentViewController:alert animated:YES completion:nil];

        // UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"To use this feature you need to enter a clock in and out value. Please enter a clock In Time" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
               // [alert show];
            
        }
        else{
            isEmpty = [NSString isNilOrEmpty:clockOutValue];
            if (isEmpty) {
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"ERROR"
                                                 message:@"To use this feature you need to enter a clock in and out value. Please enter a clock out Time"
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:defaultAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];

                 //   UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"To use this feature you need to enter a clock in and out value. Please enter a clock out Time" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                 //   [alert show];
                
                }
    //only force non personal accounts to enter a reason for the add
 /*   #ifndef PERSONAL_VERSION

            else if ([_reasonTextView.text length] == 0) {
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"ERROR"
                                                 message:@"Please enter a reason in the Notes box for the add"
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:defaultAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];

                  //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a reason in the Notes box for the add" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                 //   [alert show];
                
                }
    #endif
  */
            else{
                    [self callCreateTimeEntryWebService];
                }
        }
}

- (IBAction)doTimeEntrySave:(id)sender {
    NSString *clockInValue = _clockInField.text;
    NSString *clockOutValue = _clockOutField.text;
    NSDate *clockInDateTime = [_clockInField.text toLongDateTime];
    NSDate* clockOutDateTime = [_clockOutField.text toLongDateTime];
 
    if((![NSDate isNilOrNull:clockOutDateTime]) && (([clockInDateTime compare: clockOutDateTime] == NSOrderedDescending) || ([clockInDateTime compare: clockOutDateTime] == NSOrderedSame)))// if start is later or equal in time than end
    {

        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Warning!"
                                     message:@"The clock out value should be later than the clock in value."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        UIAlertAction* saveAction = [UIAlertAction actionWithTitle:@"Save Anyway!" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                    [self saveTimeEntry:clockInValue ClockOut:clockOutValue];

                }];
        
        [alert addAction:saveAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    }
    else{
         [self saveTimeEntry:clockInValue ClockOut:clockOutValue];
    }
}

/*
-(void)touchesBegan:(NSSet*)trigger withEvent:(UIEvent*)event{
    UITouch *touch = [trigger anyObject];
    
    if((touch.view.tag == 1) || (touch.view.tag == 2)){
//        CGRect pickerFrame = CGRectMake(0,245,kbHeight,216);
        CGRect pickerFrame = CGRectMake(0,100,100,100);
        pickDate = [[UIDatePicker alloc]initWithFrame:pickerFrame];
        
        [pickDate addTarget:self action:@selector(dateSelected:)forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:pickDate];
        
        if (touch.view.tag == 1){
            TextFieldMode = 1;
            if (![clockInLabel.text isEqualToString:@""])
                pickDate.date = [clockInLabel.text toLongDateTime];
        }
        else {
            TextFieldMode = 2;
            if (![clockOutLabel.text isEqualToString:@""])
                pickDate.date = [clockOutLabel.text toLongDateTime];
        }
    }
}
 */
-(void)dateSelected:(id)sender{
    
    if (TextFieldMode == 1)
        _clockInField.text = [[sender date] toLongDateTimeString];
        //[_clockInButton setTitle:[[sender date] toLongDateTimeString] forState:UIControlStateNormal];

    else {
        _clockOutField.text = [[sender date] toLongDateTimeString];
       // [_clockOutButton setTitle:[[sender date] toLongDateTimeString] forState:UIControlStateNormal];

    }
}


-(BOOL)closeDatePicker:(id)sender{
//    [pickerViewDate dismissWithClickedButtonIndex:0 animated:YES];
    [theDatePicker removeFromSuperview];
    [pickerView removeFromSuperview];

    return YES;
}

-(IBAction)DatePickerDoneClick{
    UITextField *curField;
    if (TextFieldMode == CLOCK_IN_TAG)
        curField = _clockInField;
    else
        curField= _clockOutField;
    curField.text = [theDatePicker.date toLongDateTimeString];
   // [curButton setTitle:[theDatePicker.date toLongDateTimeString] forState:UIControlStateNormal];
    
    [self closeDatePicker:self];
}

-(IBAction)DatePickerCancelClick{
    [self closeDatePicker:self];
}


-(void) showDatePicker: (UITextField*) textField{
    
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    pickerToolbar.barStyle=UIBarStyleBlackOpaque;

    [pickerToolbar sizeToFit];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(DatePickerCancelClick)];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 80, 20.0f)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    if (textField.tag == CLOCK_IN_TAG)
        titleLabel.text = @"Clock In";
    else
        titleLabel.text = @"Clock Out";
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(DatePickerDoneClick)];

    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:cancelBtn, flexSpace, titleButton, flexSpace, doneDateBarBtn, nil];
    
    [pickerToolbar setItems:itemArray animated:YES];
    
    UITextField *curField;
    if (textField.tag == CLOCK_IN_TAG)
    {
        curField = _clockInField;
        TextFieldMode = CLOCK_IN_TAG;
    }
    else
    {
        curField = _clockOutField;
        TextFieldMode = CLOCK_OUT_TAG;
    }
    
    BOOL isEmpty = [NSString isNilOrEmpty:curField.text];
    
    if (! isEmpty)
        theDatePicker.date = [curField.text toLongDateTime];
    else
    curField.text = [theDatePicker.date toLongDateTimeString];
    
    if (@available(iOS 13.4, *)) {
        [theDatePicker setPreferredDatePickerStyle:UIDatePickerStyleWheels];
    } else {
        // Fallback on earlier versions
    }
    
    theDatePicker.frame = CGRectMake(0, theDatePicker.frame.origin.y, UIScreen.mainScreen.bounds.size.width, theDatePicker.frame.size.height);
    [pickerView addSubview:pickerToolbar];
    [pickerView addSubview:theDatePicker];
    [self.view addSubview:pickerView];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // We are now showing the UIPickerViewer instead
    
    // Close the keypad if it is showing
    [self.view.superview endEditing:YES];
    
    if (textField.tag == JOB_CODE_TAG)
        [self showJobCodesPicker];
    else
        [self showDatePicker: textField];
    return  NO;
}

-(void) showIOS14DatePicker {
    [_clockInView setHidden:YES];
    [_clockInField setHidden:NO];
    [_clockOutView setHidden:YES];
    [_clockOutField setHidden:NO];
    
//    if (@available(iOS 14, *)) {
//        [_clockInView setHidden:NO];
//        [_clockInField setHidden:YES];
//
//        [_clockOutView setHidden:NO];
//        [_clockOutField setHidden:YES];
//
//         NSDate *date = [NSDate date];
//        _datePickerView.date = date;
//        _clockOutDatePicker.date = date;
//
//        _datePickerView.preferredDatePickerStyle = UIDatePickerStyleCompact;
//        [_datePickerView addTarget:self action:@selector(handleClockInDatePicker) forControlEvents:UIControlEventValueChanged];
//
//        _clockOutDatePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
//        [_clockOutDatePicker addTarget:self action:@selector(handleClockOutDatePicker) forControlEvents:UIControlEventValueChanged];
//
//    }
}

-(void)handleClockInDatePicker
{
    _clockInField.text = [[_datePickerView date] toLongDateTimeString];
}

-(void)handleClockOutDatePicker
{
    _clockOutField.text = [[_clockOutDatePicker date] toLongDateTimeString];
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
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(jobCodePickerDoneClick)];
    
    
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
    
    
#ifdef IPAD_VERSION
    
    [pickerViewDate addSubview:pickerViewJobCode];
    popoverContent.view = pickerViewDate;
    popoverContent.modalPresentationStyle = UIModalPresentationPopover;
    popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
    //popoverContent.popoverPresentationController.sourceView = _scrollView;
    popoverContent.popoverPresentationController.sourceRect = _jobCodeField.superview.frame;
    [self presentViewController:popoverContent animated:YES completion:nil];
#else
    [pickerView addSubview:pickerToolbar];
    [pickerView addSubview:pickerViewJobCode];
    [self.view addSubview:pickerView];
#endif
*/
    
 UINavigationController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"jobCodeList"];
   JobCodeListViewController * controller = viewController.viewControllers.firstObject;
   controller.delegate = self;
   controller.jobCodes = _jobCodes;
   [self presentViewController:viewController animated:YES completion:nil];

    
}

- (void)searchJobCode:(NSDictionary *)jobCodeObj {
    _jobCodeField.text = [jobCodeObj valueForKey:@"name"];
    selectedJobCode = jobCodeObj;
}

-(IBAction)jobCodePickerDoneClick{
    NSInteger row = [pickerViewJobCode selectedRowInComponent:0];
    
    // [_employeeButton setTitle:[employeeList objectAtIndex:row] forState:UIControlStateNormal];
    NSDictionary *jobCodeObj = [_jobCodes objectAtIndex:row];
    _jobCodeField.text = [jobCodeObj valueForKey:@"name"];
    selectedJobCode = [_jobCodes objectAtIndex:row];
    
    [self closeJobCodePicker:self];
    
  //  [self assignSelectedJobCode ];
}

-(BOOL)closeJobCodePicker:(id)sender{
    [pickerViewJobCode removeFromSuperview];
    [pickerView removeFromSuperview];
    return YES;
}

-(IBAction)EmployeePickerCancelClick{
    [self closeJobCodePicker:self];
}

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

/*- (IBAction)doClockInBtnClick:(id)sender {
    TextFieldMode = 1;
    [self showDatePicker];

}
- (IBAction)clockOutBtnClick:(id)sender {
    TextFieldMode = 2;
    [self showDatePicker];

}
 */
@end
