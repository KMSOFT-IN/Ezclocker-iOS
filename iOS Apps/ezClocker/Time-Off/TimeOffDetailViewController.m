//
//  TimeOffDetailViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 1/29/23.
//  Copyright (c) ezNova Technologies LLC. All rights reserved.
//

#import "TimeOffDetailViewController.h"
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

@implementation TimeOffDetailViewController

int REQ_EMPLOYEELIST_TAG = 1;
int REQ_START_DATETIME_TAG = 2;
int REQ_END_DATETIME_TAG = 3;
int REQ_TYPE_TAG = 4;
int REQ_DATE_HOURS_TAG = 5;

int ADD_TIMEOFF = 1;
int UPDATE_TIMEOFF = 2;




-(void) viewWillAppear:(BOOL)animated{
    
    _mainView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _denyBtn.titleLabel.textColor = [UIColor redColor];
    _approveBtn.titleLabel.textColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
    
    [_scrollView setScrollEnabled:YES];
    //   [_scrollView setContentSize:CGSizeMake(320, 650)];
    _scrollView.delaysContentTouches = NO;
    
    //if there is data that was passed through selectedSchedule (e.g. master/detail view) then use it
    if (self.selectedTimeOff != nil){
        self.navigationItem.rightBarButtonItem = nil;
        UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
        titleLabel.text = @"View Time Off";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [customView addSubview:titleLabel];
        self.navigationItem.titleView = customView;

        //hide the All day switch since the user can't change it.
        _allDaySwitch.enabled = NO;
        _employeeNameField.text = [self.selectedTimeOff valueForKey:@"employeeName"];
        _employeeNameField.enabled = NO;
//        _reqTypeField.text = [self.selectedTimeOff valueForKey:@"requestType"];
        NSString *reqType = [self.selectedTimeOff valueForKey:@"requestType"];
        reqType = [reqType stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        _reqTypeField.text = reqType;
        _reqTypeField.enabled = NO;
        _hoursLabel.text = @"Total Hours";
        _hoursPerDayField.enabled = NO;
        _notesTextView.editable = NO;
        NSNumber *totalHours = [self.selectedTimeOff valueForKey:@"totalHours"];
        _hoursPerDayField.text = [totalHours stringValue];
        NSNumber *allDay = [self.selectedTimeOff valueForKey:@"allDay"];
        NSString *startDateTime;
        NSString *endDateTime;
        if ([allDay intValue] == 1)
        {
            startDateTime = [self.selectedTimeOff valueForKey:@"reqStartDate"];
            endDateTime = [self.selectedTimeOff valueForKey:@"reqEndDate"];
        }
        else
        {
            [_allDaySwitch setOn: NO];
            startDateTime = [self.selectedTimeOff valueForKey:@"reqStartDateTime"];
            endDateTime = [self.selectedTimeOff valueForKey:@"reqEndDateTime"];
        }
        _startTimeField.text = startDateTime;
        _startTimeField.enabled = NO;
        
        _endTimeField.text = endDateTime;
        _endTimeField.enabled = NO;
        
        NSString *notes = [self.selectedTimeOff valueForKey:@"notesString"];
        if ([NSString isNilOrEmpty:notes])
            notes = @"";
        _notesTextView.text = notes;
        _notesTextView.editable = NO;
        
        NSString *requestStatus = [self.selectedTimeOff valueForKey:@"requestStatus"];
        _statusLabel.text = requestStatus;
        UserClass *user = [UserClass getInstance];
        if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
        {
            if ([requestStatus isEqualToString:@"PENDING"])
            {
                _BtnsView.hidden = FALSE;
                _middleBtn.hidden = TRUE;
            }
            else if ([requestStatus isEqualToString:@"APPROVED"])
            {
                _statusLabel.textColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
                [_middleBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                [_middleBtn setTitle:@"DENY" forState:UIControlStateNormal];
                _approveBtn.hidden = TRUE;
                _denyBtn.hidden = TRUE;
            }
            else if ([requestStatus isEqualToString:@"DENIED"])
            {
                _statusLabel.textColor = [UIColor redColor];
                [_middleBtn setTitleColor:UIColorFromRGB(GREEN_CLOCKEDIN_COLOR) forState:UIControlStateNormal];
                [_middleBtn setTitle:@"APPROVE" forState:UIControlStateNormal];
                _approveBtn.hidden = TRUE;
                _denyBtn.hidden = TRUE;
            }

        }
        else
        {
            _employeeView.hidden = YES;
            if ([requestStatus isEqualToString:@"PENDING"])
            {
                _approveBtn.hidden = TRUE;
                _denyBtn.hidden = TRUE;
                [_middleBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                [_middleBtn setTitle:@"CANCEL" forState:UIControlStateNormal];
            }
            else
            {
                _BtnsView.hidden = TRUE;
                if ([requestStatus isEqualToString:@"DENIED"])
                    _statusLabel.textColor = [UIColor redColor];
                else if ([requestStatus isEqualToString:@"APPROVED"])
                {
                    _statusLabel.textColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
                    [_middleBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                    [_middleBtn setTitle:@"CANCEL" forState:UIControlStateNormal];
                }
                
            }

        }
        
    }
    //we are doing an add time entry operation
    else{
        //hide the approve/deny buttons
        _BtnsView.hidden = YES;
        UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
        titleLabel.text = @"Add Time Off";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [customView addSubview:titleLabel];
        self.navigationItem.titleView = customView;

        //if are the employee then we don't need to show the pick an employee field.
        UserClass *user = [UserClass getInstance];
        //hide the employee selection view if we are only an employee
        if (!([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)))
            _employeeView.hidden = YES;
        _startTimeField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
        _endTimeField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
        _employeeNameField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
        _reqTypeField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
        _hoursPerDayField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
        NSDate *today = [NSDate date];
        NSString *todayDate = [formatterDate stringFromDate: today];
        _startTimeField.text = [NSString stringWithFormat:@"%@", todayDate];
        _endTimeField.text = [NSString stringWithFormat:@"%@", todayDate];
//        _startTimeField.text = [NSString stringWithFormat:@"%@  %@", todayDate, @"9:00AM"];;
//        _endTimeField.text = [NSString stringWithFormat:@"%@  %@", todayDate, @"5:00PM"];;

        if ([employeeList count] == 1)
            _employeeNameField.text = [employeeList objectAtIndex:0];
        else
            _employeeNameField.text = @"";
        
        _reqTypeField.text = @"";
        _statusView.hidden = YES;
      //  _statusLabel.text = @"PENDING";
        
    }
    
}

-(void) viewDidLoad{
    [self showIOS14DatePicker];
    //setup all the tags so we know which picker to show when a user taps
    _employeeNameField.tag = REQ_EMPLOYEELIST_TAG;
    _reqTypeField.tag = REQ_TYPE_TAG;
    _startTimeField.tag = REQ_START_DATETIME_TAG;
    _endTimeField.tag = REQ_END_DATETIME_TAG;
    _hoursPerDayField.tag = REQ_DATE_HOURS_TAG;
    
    requestTypeList = @[@"PAID PTO",@"PAID SICK",@"UNPAID TIME OFF",@"PAID HOLIDAY"];
    
    serverRequestTypeList = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                @"PAID_PTO", @"PAID PTO",
                                @"PAID_SICK", @"PAID SICK",
                                @"UNPAID_TIME_OFF", @"UNPAID TIME OFF",
                                @"PAID_HOLIDAY", @"PAID HOLIDAY",
                                 nil];
    

    
    UITableView* TV = [[UITableView alloc] init];
    UIColor* separatorColor = [TV separatorColor];
    _separatorLbl1.textColor = separatorColor;
    _separatorLbl2.textColor = separatorColor;
    _separatorLbl3.textColor = separatorColor;
    _separatorLbl4.textColor = separatorColor;
    _separatorLbl5.textColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    
    CALayer *imageLayer = _notesTextView.layer;
    [imageLayer setCornerRadius:10];
    [imageLayer setBorderWidth:2.1];
    imageLayer.borderColor=[[UIColor lightGrayColor] CGColor];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboardAction)];
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:flexSpace, doneDateBarBtn, nil];
    
    keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    keyboardToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [keyboardToolbar sizeToFit];
    
    
    [keyboardToolbar setItems:itemArray animated:YES];
    
    
    [_notesTextView setInputAccessoryView:keyboardToolbar];
    
    
    [self registerForKeyboardNotifications];
    
    _notesTextView.delegate = self;
    
    formatterISO8601DateTime = [[NSDateFormatter alloc] init];
    [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    formatterDate = [[NSDateFormatter alloc] init];
    [formatterDate setDateFormat:@"MM/dd/yyyy"];
    
    formatterTime12 = [[NSDateFormatter alloc] init];
    [formatterTime12 setDateFormat:@"h:mma"];
    
    formatterDateTime12 = [[NSDateFormatter alloc] init];
    [formatterDateTime12 setDateFormat:@"MM/dd/yyyy h:mma"];
    
    popoverContent = [[UIViewController alloc] init];
    [self setFramePicker];
    
    theDatePicker.hidden = NO;
    NSDate *date = [NSDate date];
    theDatePicker.date = date;
    
    //ge the list of employees so we can show them in the employee view picker
    UserClass *user = [UserClass getInstance];
    employeeList = [[NSMutableArray alloc] initWithArray:[user.employeeNameIDList allValues]];
    
    
 
}

-(void) showIOS14DatePicker {
    [_startTimeView setHidden:YES];
    [_startTimeField setHidden:NO];
    
    [_endTimeView setHidden:YES];
    [_endTimeField setHidden:NO];
    
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
        theDatePicker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
    } else {
        pickerFrame = CGRectMake(0, 44, self.view.frame.size.width, kbHeight - 44);
        theDatePicker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
    }
    
    [theDatePicker addTarget:self action:@selector(onDatePickerValueChanged) forControlEvents:UIControlEventValueChanged];
    
    pickerViewEmployeeName = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerViewEmployeeName.dataSource = self;
    pickerViewEmployeeName.delegate = self;
    pickerViewEmployeeName.tag = REQ_EMPLOYEELIST_TAG;
    
    pickerViewRequestTypes = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerViewRequestTypes.dataSource = self;
    pickerViewRequestTypes.delegate = self;
    pickerViewRequestTypes.tag = REQ_TYPE_TAG;
    
    _employeeNameField.delegate = self;
    _startTimeField.delegate = self;
    _endTimeField.delegate = self;
    _reqTypeField.delegate = self;
    _hoursPerDayField.delegate = self;
    
}

-(BOOL)closeDatePicker:(id)sender{
    [theDatePicker removeFromSuperview];
    [pickerViewDate removeFromSuperview];
    return YES;
}

-(BOOL)closeEmployeePicker:(id)sender{
    [pickerViewEmployeeName removeFromSuperview];
    [pickerViewDate removeFromSuperview];
    return YES;
}

-(BOOL)closeRequestTypesPicker:(id)sender{
    [pickerViewRequestTypes removeFromSuperview];
    [pickerViewDate removeFromSuperview];
    [theDatePicker removeFromSuperview];
    return YES;
}

-(IBAction)DatePickerDoneClick{
    NSString *datePicked;
    if ([_allDaySwitch isOn])
        datePicked = [formatterDate stringFromDate:theDatePicker.date];
   else
   {
       if (theDatePicker.tag == REQ_DATE_HOURS_TAG)
           datePicked = [formatterDate stringFromDate:theDatePicker.date];
       else
           datePicked = [formatterTime12 stringFromDate:theDatePicker.date];
   }

        
    if (theDatePicker.tag == REQ_START_DATETIME_TAG)
        _startTimeField.text = datePicked;
    else if (theDatePicker.tag == REQ_END_DATETIME_TAG)
        _endTimeField.text = datePicked;
    else
        _hoursPerDayField.text = datePicked;
    
    
    [self closeDatePicker:self];
  
}

-(IBAction)DatePickerCancelClick{
    [self closeDatePicker:self];
}

-(IBAction)EmployeePickerDoneClick{
    NSInteger row = [pickerViewEmployeeName selectedRowInComponent:0];
    
    // [_employeeButton setTitle:[employeeList objectAtIndex:row] forState:UIControlStateNormal];
    _employeeNameField.text = [employeeList objectAtIndex:row];
    
    [self closeEmployeePicker:self];
}

-(IBAction)RequestTypesPickerDoneClick{
    NSInteger row = [pickerViewRequestTypes selectedRowInComponent:0];
    
    _reqTypeField.text = [requestTypeList objectAtIndex:row];
    
    [self closeRequestTypesPicker:self];
}


-(IBAction)EmployeePickerCancelClick{
    [self closeEmployeePicker:self];
}

-(IBAction)requestTypesPickerCancelClick{
    [self closeRequestTypesPicker:self];
}

-(void) showDatePicker: (UITextField*) textField{
    [self closeEmployeePicker:self];
    [self closeRequestTypesPicker:self];
    
    
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    pickerToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [pickerToolbar sizeToFit];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(DatePickerCancelClick)];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 80, 20.0f)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(DatePickerDoneClick)];
    
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:cancelBtn, flexSpace, titleButton, flexSpace, doneDateBarBtn, nil];
    
    [pickerToolbar setItems:itemArray animated:YES];
    
    UITextField *curField;
    if (textField.tag == REQ_START_DATETIME_TAG)
        curField = _startTimeField;
    else if (textField.tag == REQ_END_DATETIME_TAG)
        curField = _endTimeField;
    else
        curField = _hoursPerDayField;
    
    BOOL isEmpty = !(curField.text && curField.text.length > 0);
    
    if (!isEmpty)
    {
        theDatePicker.date = [formatterTime12 dateFromString:curField.text];

    }
    else
        curField.text = [formatterTime12 stringFromDate:theDatePicker.date];

    if ([_allDaySwitch isOn])
        theDatePicker.datePickerMode = UIDatePickerModeDate;
    else if (textField.tag == REQ_DATE_HOURS_TAG)
        theDatePicker.datePickerMode = UIDatePickerModeDate;
    else
        theDatePicker.datePickerMode = UIDatePickerModeTime;
    
    
    //to figure out which date picker belongs to which text field
    if (textField.tag == REQ_START_DATETIME_TAG)
        theDatePicker.tag = REQ_START_DATETIME_TAG;
    else if (textField.tag == REQ_END_DATETIME_TAG)
        theDatePicker.tag = REQ_END_DATETIME_TAG;
    else
        theDatePicker.tag = REQ_DATE_HOURS_TAG;

    if (@available(iOS 13.4, *)) {
        [theDatePicker setPreferredDatePickerStyle:UIDatePickerStyleWheels];
    } else {
        // Fallback on earlier versions
    }
    
#ifdef IPAD_VERSION
    
    [pickerViewDate addSubview:theDatePicker];
    popoverContent.view = pickerViewDate;
    popoverContent.modalPresentationStyle = UIModalPresentationPopover;
    popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
    popoverContent.popoverPresentationController.sourceView = _scrollView;
    popoverContent.popoverPresentationController.sourceRect = curField.superview.frame;
    [self presentViewController:popoverContent animated:YES completion:nil];
#else
    [pickerViewDate addSubview:pickerToolbar];
    
    theDatePicker.frame = CGRectMake(0, theDatePicker.frame.origin.y, UIScreen.mainScreen.bounds.size.width, theDatePicker.frame.size.height);
    [pickerViewDate addSubview:theDatePicker];
    [self.view addSubview:pickerViewDate];
#endif
    
    
    
}

-(void)onDatePickerValueChanged
{
    NSString *datePicked;
    if ([_allDaySwitch isOn])
        datePicked = [formatterDate stringFromDate:theDatePicker.date];
   else if (theDatePicker.tag == REQ_DATE_HOURS_TAG)
       datePicked = [formatterDate stringFromDate:theDatePicker.date];
   else
       datePicked = [formatterTime12 stringFromDate:theDatePicker.date];

    
    if (theDatePicker.tag == REQ_START_DATETIME_TAG)
    {
        _startTimeField.text = datePicked;
    }
    else if (theDatePicker.tag == REQ_END_DATETIME_TAG)
        _endTimeField.text = datePicked;
    else
        _hoursPerDayField.text = datePicked;

}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView.tag == REQ_EMPLOYEELIST_TAG)
    {
        NSInteger row = [pickerViewEmployeeName selectedRowInComponent:0];
        
        _employeeNameField.text = [employeeList objectAtIndex:row];
        
    }
    else if (pickerView.tag == REQ_TYPE_TAG)
    {
        NSInteger row = [pickerViewRequestTypes selectedRowInComponent:0];
        
        _reqTypeField.text = [requestTypeList objectAtIndex:row];

    }
  
}

-(void) showEmployeePicker{
    
    [theDatePicker removeFromSuperview];
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
    
    [theDatePicker removeFromSuperview];
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
    
    _reqTypeField.text = [requestTypeList objectAtIndex:0];
    
#ifdef IPAD_VERSION
    
    [pickerViewDate addSubview:pickerViewRequestTypes];
    popoverContent.view = pickerViewDate;
    popoverContent.modalPresentationStyle = UIModalPresentationPopover;
    popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
    popoverContent.popoverPresentationController.sourceView = _scrollView;
    popoverContent.popoverPresentationController.sourceRect = _reqTypeField.superview.frame;
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
    if (pickerView.tag == REQ_EMPLOYEELIST_TAG)
        return [employeeList count];
    else
        return [requestTypeList count];
 
}

#pragma mark Picker Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *name = @"";
    if (pickerView.tag == REQ_EMPLOYEELIST_TAG)
    {
        name = [employeeList objectAtIndex:row];
    }
    else if (pickerView.tag == REQ_TYPE_TAG)
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
    if (textField.tag == REQ_EMPLOYEELIST_TAG)
    {
        if ([employeeList count] > 1)
            [self showEmployeePicker];
    }
 //   else if (textField.tag == REQ_TYPE_TAG)
 //   {
 //       [self showRequestTypesPicker];
 //   }
    else if ((textField.tag == REQ_START_DATETIME_TAG) || (textField.tag == REQ_END_DATETIME_TAG) ||
             ((![_allDaySwitch isOn]) && (textField.tag == REQ_DATE_HOURS_TAG)))
        [self showDatePicker: textField];
  
    //if all Day box is checked then we want customers to modify the hours
    if (([_allDaySwitch isOn]) && (textField.tag == REQ_DATE_HOURS_TAG))
        return YES;
    else
        return  NO;
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
    
    if (_noteView.frame.origin.y + _noteView.frame.size.height > kbOrigin.y) {
        if (!CGRectContainsPoint(aRect, _notesTextView.frame.origin) ) {
            //        [self.scrollView scrollRectToVisible:_separatorLbl5.frame animated:YES];
            CGPoint scrollPoint = CGPointMake(0.0, _notesTextView.frame.origin.y + _notesTextView.frame.size.height);
            [_scrollView setContentOffset:scrollPoint animated:YES];
        }
    }
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
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

-(void)dismissKeyboardAction{
    [_notesTextView resignFirstResponder];
    
}

-(void) callTimeOffAPI:(int) flag Status:(NSString*)status withCompletion:(ServerResponseCompletionBlock)completion
{
 
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    //if flag == Update_timeoff then we are either approving or denying the request
    if (flag == UPDATE_TIMEOFF)
    {
        NSString *reqId =@"0";
        if (self.selectedTimeOff != nil)
        {
            reqId = [_selectedTimeOff valueForKey:@"id"];
        }
        httpPostString = [NSString stringWithFormat:@"%@api/v1/timeoff/%@?target-time-zone-id=%@", SERVER_URL, reqId, timeZoneId];
    }
    //else we are adding a new one
    else
    {
        httpPostString = [NSString stringWithFormat:@"%@api/v1/timeoff/?target-time-zone-id=%@", SERVER_URL, timeZoneId];
    }

    NSDateFormatter *formatterISO8601DateTime = [[NSDateFormatter alloc] init];
    [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];


     
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];

    NSMutableDictionary *dict;
    NSData *jsonData;
    if (flag == UPDATE_TIMEOFF)
    {

        [self.selectedTimeOff setValue:status forKey:@"requestStatus"];
        [urlRequest setHTTPMethod:@"PUT"];
        NSError *error;

        jsonData = [NSJSONSerialization dataWithJSONObject:self.selectedTimeOff
        options:NSJSONWritingPrettyPrinted error:&error];
        
    }
    else
    {

        NSString *employerId = [user.employerID stringValue];
        NSString *employeeId;
        if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
        {
            NSArray* arrayOfKeys = [user.employeeNameIDList allKeysForObject:_employeeNameField.text];
            employeeId = [arrayOfKeys objectAtIndex:0];

        }
        else
        {
            employeeId = [user.userID stringValue];
        }
        NSDate *startDateValue, *endDateValue;
        NSString *allDayStr = @"false";
        NSString *hoursPerDay;
        if ([_allDaySwitch isOn])
        {
            allDayStr = @"true";
            startDateValue = [formatterDate dateFromString:_startTimeField.text];
            endDateValue = [formatterDate dateFromString:_endTimeField.text];
            hoursPerDay = _hoursPerDayField.text;

        }
        else
        {
            NSString *selectedDate = _hoursPerDayField.text;
            NSString *selectedDateTime = [NSString stringWithFormat:@"%@ %@", selectedDate, _startTimeField.text];
            startDateValue = [formatterDateTime12 dateFromString:selectedDateTime];
            selectedDateTime = [NSString stringWithFormat:@"%@ %@", selectedDate, _endTimeField.text];
            endDateValue = [formatterDateTime12 dateFromString:selectedDateTime];
            hoursPerDay = @"0";
        }
        NSString *startDateTimeISO, *endDateTimeISO;

        [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        startDateTimeISO = [formatterISO8601DateTime stringFromDate:startDateValue];
        startDateTimeISO  = [startDateTimeISO stringByReplacingOccurrencesOfString:@"+0000" withString:@"Z"];
        startDateTimeISO  = [startDateTimeISO stringByReplacingOccurrencesOfString:@"-0000" withString:@"Z"];

        endDateTimeISO = [formatterISO8601DateTime stringFromDate:endDateValue];
        endDateTimeISO  = [endDateTimeISO stringByReplacingOccurrencesOfString:@"+0000" withString:@"Z"];
        endDateTimeISO  = [endDateTimeISO stringByReplacingOccurrencesOfString:@"-0000" withString:@"Z"];

        //look up the time off string we need to send back to the server
        NSString *reqType = [serverRequestTypeList valueForKey: _reqTypeField.text];

        NSString *requestedByUserId = [user.realUserId stringValue];
        
        NSDate *today = [NSDate date];
        NSString *todayStr = [formatterISO8601DateTime stringFromDate:today];
        todayStr  = [todayStr stringByReplacingOccurrencesOfString:@"+0000" withString:@"Z"];
        todayStr  = [todayStr stringByReplacingOccurrencesOfString:@"-0000" withString:@"Z"];

   //     NSString *startDateTime = [self.selectedTimeOff valueForKey:@"reqStartDateTime"];
        
  //      NSString *endDateTime = [self.selectedTimeOff valueForKey:@"reqEndDateTime"];

        
        NSString *notes = _notesTextView.text;
        if ([NSString isNilOrEmpty:notes])
            notes = @"";
        
        //if the user that is submitting the request is th eemployer then the status would be approved and not pending.
        if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
        {
            status = @"APPROVED";
        }

        
        dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    employerId, @"employerId",
                                    employeeId, @"employeeId",
                                    allDayStr, @"allDay",
                                    hoursPerDay, @"hoursPerDay",
                                    requestedByUserId, @"requestedByUserId",
                                    todayStr, @"submittedDateTimeIso",
                                    @"2023", @"submittedYear",
                                    startDateTimeISO, @"requestStartDateIso",
                                    endDateTimeISO, @"requestEndDateIso",
                                    status, @"requestStatus",
                                    reqType, @"requestType",
                                    notes, @"notesString",
                                     nil];
        
        [urlRequest setHTTPMethod:@"POST"];
        NSError *error;

        jsonData = [NSJSONSerialization dataWithJSONObject:dict
        options:NSJSONWritingPrettyPrinted error:&error];
        

    }

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    //set request body into HTTPBody.
    urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];



    
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            MAINTHREAD_BLOCK_START()
            completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            MAINTHREAD_BLOCK_START()
            completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        @autoreleasepool {
            [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                
                //                [self stopSpinner];
                
                //               if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                MAINTHREAD_BLOCK_START()
                completion(errorCode, resultMessage, results, aError);
                THREAD_BLOCK_END()
                return;
                //                }
            }];
        }
    }];
    [dataTask resume];
    
}


- (IBAction)doCancelView:(id)sender {
    [self.delegate timeOffDetailViewControllerDidFinish:self];
}

- (IBAction)doSave:(UIBarButtonItem *)sender {
    
    if ((_employeeView.hidden != YES) && (_employeeNameField.text.length == 0))
    {
        [SharedUICode messageBox:nil message:@"Employee field can not be empty. Please tap and select an employee" withCompletion:^{
            return;
        }];
    }
    
    else if (_reqTypeField.text.length == 0)
    {
        [SharedUICode messageBox:nil message:@"Request Type field can not be empty. Please tap and select a time off type" withCompletion:^{
                return;
        }];
    }
    else
    {
        NSDate *startDateTime;
        NSDate* endDateTime;
    
        if ([_allDaySwitch isOn])
        {
            startDateTime = [_startTimeField.text toDefaultDate];
            endDateTime = [_endTimeField.text toDefaultDate];
      }
        else
        {
            startDateTime = [_startTimeField.text toLongDateTime];
            endDateTime = [_endTimeField.text toLongDateTime];
        }
     
        if ((![NSDate isNilOrNull:endDateTime]) && ([startDateTime compare: endDateTime] == NSOrderedDescending))
           // if start is later than end (negative) then show an error message
        {
        
            UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"The end date/time value must be later than the start value."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
            [alert addAction:defaultAction];
        
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            [self startSpinnerWithMessage:@"Saving, please wait..."];
    
            [self callTimeOffAPI:ADD_TIMEOFF Status: @"PENDING" withCompletion:^(NSInteger aErrorCode, NSString     * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
                [self stopSpinner];
                if (aErrorCode != 0) {
                    [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                        return;
                    }];
                }
                NSString *resultMessage = [aResults valueForKey:@"message"];
                if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"]))
                {
                        UIAlertController * alert = [UIAlertController
                                                     alertControllerWithTitle:@"ERROR"
                                                     message:@"TimeOff Request Failed"
                                                     preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                        
                        [alert addAction:defaultAction];
                    
                        [self presentViewController:alert animated:YES completion:nil];
                    
                        
                }
                else{
                    [self.delegate timeOffDetailViewControllerDidFinish:self];
                }
            }];
        }
    }
}

- (IBAction)doRequestTypesClick:(id)sender {
    [self showRequestTypesPicker];

}

- (IBAction)doEmployeeFieldClick:(id)sender {
    //if there is only one employee don't bother showing the picker
    if ([employeeList count] > 1) {
        [self showEmployeePicker];
    }
}

- (IBAction)doApproveBtnClick:(id)sender {
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callTimeOffAPI:UPDATE_TIMEOFF Status: @"APPROVED" withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        NSString *resultMessage = [aResults valueForKey:@"message"];
        if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"]))
        {
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"TimeOff Update Failed"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
            
                [self presentViewController:alert animated:YES completion:nil];
            
                
        }
        else{
            [self.delegate timeOffDetailViewControllerDidFinish:self];
        }
    }];
}

- (IBAction)doDenyBtnClick:(id)sender {
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callTimeOffAPI:UPDATE_TIMEOFF Status:@"DENIED" withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            [self.delegate timeOffDetailViewControllerDidFinish:self];
        }
    }];

}
- (IBAction)doSelectEmployee:(id)sender {
    //if there is only one employee don't bother showing the picker
    if ([employeeList count] > 1) {
        [self showEmployeePicker];
    }
}
- (IBAction)doAllDaySwitchChange:(id)sender {
    NSDate *today = [NSDate date];
    NSString *todayDate = [formatterDate stringFromDate: today];
    if (![_allDaySwitch isOn])
    {
        _startTimeField.text = [NSString stringWithFormat:@"%@", @"9:00AM"];
        _endTimeField.text = [NSString stringWithFormat:@"%@", @"5:00PM"];
        //change the hours per day field to be the date field
        _hoursPerDayField.text = [NSString stringWithFormat:@"%@", todayDate];
        _hoursLabel.text = @"Date";
    }
    else
    {
        _startTimeField.text = [NSString stringWithFormat:@"%@", todayDate];
        _endTimeField.text = [NSString stringWithFormat:@"%@", todayDate];
        _hoursPerDayField.text = @"8";
        _hoursPerDayField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
        _hoursLabel.text = @"Hours Per Day";
    }
        
}

-(void) callCancelAPI
{

    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callTimeOffAPI:UPDATE_TIMEOFF Status:@"CANCELED" withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            [self.delegate timeOffDetailViewControllerDidFinish:self];
        }
    }];

}

- (void)doCancelRequest
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Alert"
                                 message:@"Are you sure you want to cancel this request?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

        [self callCancelAPI];
    }];
    
    [alert addAction:defaultAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        [alert dismissViewControllerAnimated:YES completion:nil];
        
    }];
    
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];

    
 }

- (IBAction)doMiddleBtnClick:(UIButton *)sender {
    if ([_middleBtn.titleLabel.text isEqualToString:@"APPROVE"])
        [self doApproveBtnClick:sender];
    else if ([_middleBtn.titleLabel.text isEqualToString:@"DENY"])
        [self doDenyBtnClick:sender];
    else if ([_middleBtn.titleLabel.text isEqualToString:@"CANCEL"])
        [self doCancelRequest];
}

- (IBAction)doChangeHours:(UITextField *)sender {
}
@end
