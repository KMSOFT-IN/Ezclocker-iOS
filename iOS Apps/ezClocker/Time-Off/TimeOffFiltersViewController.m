//
//  TimeOffFiltersViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 02/26/23.
//  Copyright (c) ezNova Technologies LLC. All rights reserved.
//

#import "TimeOffFiltersViewController.h"
#import "commonLib.h"
#import "MetricsLogWebService.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "SharedUICode.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "NSNumber+Extensions.h"


#import "user.h"

@implementation TimeOffFiltersViewController

int FILTER_EMPLOYEELIST_TAG = 1;
int FILTER_DATETIME_TAG = 2;

-(NSString*) getEmployeeName: (NSNumber*) employeeId
{
    NSString *empName = @"";
    UserClass *user = [UserClass getInstance];
    for (NSDictionary *empObj in user.employeeList) {
        NSNumber *temp = empObj[@"ID"];
        if ([NSNumber isEquals:temp dest:employeeId])
        {
//        if ([temp isEqualToString:employeeId]) {
            empName = empObj[@"Name"];
            break;
        }
    }
    return empName;
}


-(void) viewWillAppear:(BOOL)animated{
    
    _mainView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    
    [_scrollView setScrollEnabled:YES];
    _scrollView.delaysContentTouches = NO;
    
         //if are the employee then we don't need to show the pick an employee field.
        UserClass *user = [UserClass getInstance];
        //show the employee name if we are signed in as the employee and do not let them change it
        if (!([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)))
        {
            _employeeNameField.text = user.employeeName;
            _employeeNameField.enabled = NO;
        }
        else
        {
            _employeeNameField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
            if ([employeeList count] == 1)
                _employeeNameField.text = [employeeList objectAtIndex:0];
            else
                _employeeNameField.text = @"";

        }
        _startTimeField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);

        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy"];
        NSString *yearString = [formatter stringFromDate:[NSDate date]];
    
        _startTimeField.text = yearString;
    
    
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}


-(void) viewDidLoad{
    [self showIOS14DatePicker];
    //setup all the tags so we know which picker to show when a user taps
    _employeeNameField.tag = FILTER_EMPLOYEELIST_TAG;
    _startTimeField.tag = FILTER_DATETIME_TAG;

    requestTypeList = @[@"2023",@"2024",@"2025",@"2026"];
    
    UITableView* TV = [[UITableView alloc] init];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboardAction)];
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:flexSpace, doneDateBarBtn, nil];
    
    keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    keyboardToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [keyboardToolbar sizeToFit];
    
    
    [keyboardToolbar setItems:itemArray animated:YES];
    
        
    
    [self registerForKeyboardNotifications];
    
    popoverContent = [[UIViewController alloc] init];
    [self setFramePicker];
    
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Time Off Filters";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;
    
    
    //ge the list of employees so we can show them in the employee view picker
    UserClass *user = [UserClass getInstance];
    employeeList = [[NSMutableArray alloc] initWithArray:[user.employeeNameIDList allValues]];
    //add all as the first choice
    [employeeList insertObject:@"All" atIndex:0];
    


 
}

-(void) showIOS14DatePicker {
    [_startTimeView setHidden:YES];
    [_startTimeField setHidden:NO];

 }


- (void)setFramePicker {
    CGFloat kbHeight = [NSUserDefaults.standardUserDefaults floatForKey:keyboardHeight];
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
    
    CGFloat Y = self.view.frame.size.height -  (kbHeight + safeAreaBottomHeight + safeAreaTopHeight);
    if (self.tabBarController != nil) {
        CGFloat tabbarHeight = self.tabBarController.tabBar.frame.size.height;
        
        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, Y - tabbarHeight, self.view.frame.size.width, kbHeight)];
    } else {
        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, Y, self.view.frame.size.width, kbHeight)];
    }
    
    [pickerViewDate setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    
    //if we are running the iPhone then we start at 44 because of the toolbar
    CGRect pickerFrame;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        //        pickerFrame = CGRectMake(0, 44, 0, 0);
        pickerFrame = CGRectMake(0, 0, 350, 250);
    } else {
        pickerFrame = CGRectMake(0, 44, self.view.frame.size.width, kbHeight - 44);
    }
        
    pickerViewEmployeeName = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerViewEmployeeName.dataSource = self;
    pickerViewEmployeeName.delegate = self;
    pickerViewEmployeeName.tag = FILTER_EMPLOYEELIST_TAG;
    
    pickerViewRequestTypes = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerViewRequestTypes.dataSource = self;
    pickerViewRequestTypes.delegate = self;
    pickerViewRequestTypes.tag = FILTER_DATETIME_TAG;
    
    _employeeNameField.delegate = self;
    _startTimeField.delegate = self;
    
}

-(BOOL)closeEmployeePicker:(id)sender{
    [pickerViewEmployeeName removeFromSuperview];
    [pickerViewDate removeFromSuperview];
    return YES;
}

-(BOOL)closeRequestTypesPicker:(id)sender{
    [pickerViewRequestTypes removeFromSuperview];
    [pickerViewDate removeFromSuperview];
    return YES;
}

-(IBAction)RequestTypesPickerDoneClick{
    NSInteger row = [pickerViewRequestTypes selectedRowInComponent:0];
    
    _startTimeField.text = [requestTypeList objectAtIndex:row];
    
    [self closeRequestTypesPicker:self];
}


-(IBAction)EmployeePickerDoneClick{
    NSInteger row = [pickerViewEmployeeName selectedRowInComponent:0];
    
    // [_employeeButton setTitle:[employeeList objectAtIndex:row] forState:UIControlStateNormal];
    _employeeNameField.text = [employeeList objectAtIndex:row];
    
    [self closeEmployeePicker:self];
}


-(IBAction)EmployeePickerCancelClick{
    [self closeEmployeePicker:self];
}

-(IBAction)requestTypesPickerCancelClick{
    [self closeRequestTypesPicker:self];
}



- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView.tag == FILTER_EMPLOYEELIST_TAG)
    {
        NSInteger row = [pickerViewEmployeeName selectedRowInComponent:0];
        
        _employeeNameField.text = [employeeList objectAtIndex:row];
        
    }
    else if (pickerView.tag == FILTER_DATETIME_TAG)
    {
        NSInteger row = [pickerViewRequestTypes selectedRowInComponent:0];
        
        _startTimeField.text = [requestTypeList objectAtIndex:row];

    }

  
}

-(void) showEmployeePicker{
    
    [pickerViewRequestTypes removeFromSuperview];
    
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
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
    BOOL isEmpty = !(_employeeNameField.text && _employeeNameField.text.length > 0);
    
    if (!isEmpty)
    {
        
        for (NSString *name in employeeList)
        {
            if ([name isEqualToString:_employeeNameField.text])
                pos = row;
            else
                row++;
        }
    }
    //if the employee Name TextField is empty then default it to the first name in the employeeList
    else if ([employeeList count] > 0)
        _employeeNameField.text = [employeeList objectAtIndex:0];
    
    [pickerViewEmployeeName selectRow:pos inComponent:0 animated:YES];
    
    
#ifdef IPAD_VERSION
    
    [pickerViewDate addSubview:pickerViewEmployeeName];
    popoverContent.view = pickerViewDate;
    popoverContent.modalPresentationStyle = UIModalPresentationPopover;
    popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
    popoverContent.popoverPresentationController.sourceView = _scrollView;
    popoverContent.popoverPresentationController.sourceRect = _employeeNameField.superview.frame;
    [self presentViewController:popoverContent animated:YES completion:nil];
#else
    [pickerViewDate addSubview:pickerToolbar];
    [pickerViewDate addSubview:pickerViewEmployeeName];
    [self.view addSubview:pickerViewDate];
#endif
    
    
}

-(void) showRequestTypesPicker{
    
    [pickerViewEmployeeName removeFromSuperview];
    
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    pickerToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [pickerToolbar sizeToFit];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(requestTypesPickerCancelClick)];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 80, 20.0f)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(RequestTypesPickerDoneClick)];
    
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:cancelBtn, flexSpace, titleButton, flexSpace, doneDateBarBtn, nil];
    
    [pickerToolbar setItems:itemArray animated:YES];
    
    _startTimeField.text = [requestTypeList objectAtIndex:0];
    
#ifdef IPAD_VERSION
    
    [pickerViewDate addSubview:pickerViewRequestTypes];
    popoverContent.view = pickerViewDate;
    popoverContent.modalPresentationStyle = UIModalPresentationPopover;
    popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
    popoverContent.popoverPresentationController.sourceView = _scrollView;
    popoverContent.popoverPresentationController.sourceRect = _startTimeField.superview.frame;
    [self presentViewController:popoverContent animated:YES completion:nil];
#else
    [pickerViewDate addSubview:pickerToolbar];
    [pickerViewDate addSubview:pickerViewRequestTypes];
    [self.view addSubview:pickerViewDate];
#endif
}

#pragma mark -
#pragma mark Picker Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{

    if (pickerView.tag == FILTER_EMPLOYEELIST_TAG)
        return [employeeList count];
    else
        return [requestTypeList count];

 
}

#pragma mark Picker Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *name = @"";
    if (pickerView.tag == FILTER_EMPLOYEELIST_TAG)
    {
        name = [employeeList objectAtIndex:row];
    }
    else if (pickerView.tag == FILTER_DATETIME_TAG)
    {
        name = [requestTypeList objectAtIndex:row];
    }
    return name;
}


- (IBAction)doSelectEmployeeNameField:(id)sender {
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // We are now showing the UIPickerViewer instead
    
    // Close the keypad if it is showing
    [self.view.superview endEditing:YES];
    
    // Function to show the picker view
    if (textField.tag == FILTER_EMPLOYEELIST_TAG)
    {
        if ([employeeList count] > 1)
            [self showEmployeePicker];
    }
    else if (textField.tag == FILTER_DATETIME_TAG)
    {
        [self showRequestTypesPicker];
    }

  

        return YES;

}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGPoint kbOrigin = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].origin;
    UIEdgeInsets contentInsets;
    
    contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
}


-(void)dismissKeyboardAction{
    
}



- (IBAction)doCancelView:(id)sender {
    [self.delegate timeOffFiltersDidFinish:YES employeeName:nil dateSelected: nil];
}

- (IBAction)doSave:(UIBarButtonItem *)sender {
    
    if (_employeeNameField.text.length == 0)
    {
        [SharedUICode messageBox:nil message:@"Employee field can not be empty. Please tap and select an employee" withCompletion:^{
            return;
        }];
    }
    
    else
    {
        NSDate *startDateTime;
    
        startDateTime = [_startTimeField.text toDefaultDate];

    }
    [self.delegate timeOffFiltersDidFinish:NO employeeName:_employeeNameField.text dateSelected: _startTimeField.text];

}



- (IBAction)doEmployeeFieldClick:(id)sender {
    //if there is only one employee don't bother showing the picker
    if ([employeeList count] > 1) {
        [self showEmployeePicker];
    }
}


- (IBAction)doSelectEmployee:(id)sender {
    //if there is only one employee don't bother showing the picker
    if ([employeeList count] > 1) {
        [self showEmployeePicker];
    }
}



@end
