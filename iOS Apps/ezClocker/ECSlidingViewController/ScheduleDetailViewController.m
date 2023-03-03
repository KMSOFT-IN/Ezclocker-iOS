//
//  ScheduleDetailViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 1/19/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import "ScheduleDetailViewController.h"
#import "commonLib.h"
#import "Mixpanel.h"
#import "MetricsLogWebService.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "SharedUICode.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "LocationsWebService.h"
#import "NSNumber+Extensions.h"


#import "user.h"

@implementation ScheduleDetailViewController

int EMPLOYEELIST_TAG = 1;
int START_DATETIME_TAG = 2;
int END_DATETIME_TAG = 3;
int ALL_LOCATIONS_LIST_TAG = 4;
int ASSIGNED_LOCATIONS_LIST_TAG = 5;

int CREATE_SCHEDULE = 1;
int UPDATE_SCHEDULE = 2;

NSString *selectedLocationId;

- (IBAction)doScheduleSave:(id)sender {
    //check values to make sure end date is after start date
    NSDate *startDateValue = [formatterTime12 dateFromString:_startTimeField.text];
    NSDate *endDateValue = [formatterTime12 dateFromString:_endTimeField.text];
    if ([startDateValue compare:endDateValue] == NSOrderedDescending) {
        //show error
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"End Time is Before Start Time. Please Fix!"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        
    }
    else{
        /*     if (self.selectedSchedule == nil)
         [self callCreateSchedule];
         else
         [self callUpdateSchedule];
         */
        [self startSpinnerWithMessage:@"Saving, please wait..."];
        int mode = CREATE_SCHEDULE;
        NSNumber* schedId;
        //if we have a customer ID then this is an edit not create
        if ((self.selectedSchedule != nil) )
        {
            mode = UPDATE_SCHEDULE;
            schedId = [self.selectedSchedule valueForKey:@"scheduleId"];
        }
        //if we do not have an id then this is the default customer so need to call the change-customer API which will create a customer Id for us and convert any time entries with customer id of null to customer id
        //       else if ((_customerDetails) && ([_customerDetails count] > 0))
        //           mode = CHANGE_CUSTOMER;
        [self callScheduleAPI:mode scheduleId:schedId withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
            [self stopSpinner];
            if (aErrorCode != 0) {
                [SharedUICode messageBox:nil message:@"There was an issue saving the schedule information. Please try again later" withCompletion:^{
                    return;
                }];
                
            }
            [self.delegate scheduleDetailViewControllerDidFinish:self];
            
        }];
        
    }
}

- (IBAction)doScheduleCancel:(id)sender {
    [self.delegate scheduleDetailViewControllerDidFinish:self];
}


- (IBAction)doEmployeeBtnClick:(id)sender {
    //if there is only one employee don't bother showing the picker
    if ([employeeList count] > 1) {
        [self showEmployeePicker];
    }
    
}



-(void) viewWillAppear:(BOOL)animated{
    selectedLocationId = @"-1";
    
    _mainView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _startTimeField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
    _endTimeField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
    _employeeNameField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
    _locationField.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
    
    [_scrollView setScrollEnabled:YES];
    //   [_scrollView setContentSize:CGSizeMake(320, 650)];
    _scrollView.delaysContentTouches = NO;
    
    //if there is data that was passed through selectedSchedule (e.g. master/detail view) then use it
    if (self.selectedSchedule != nil){
        _employeeNameField.text = [self.selectedSchedule valueForKey:@"employeeName"];
        //        [_employeeButton setTitle:[self.selectedSchedule valueForKey:@"employeeName"] forState:UIControlStateNormal];
        NSString *locID = @"";
        NSNumber *locIdFromServer = [self.selectedSchedule valueForKey:@"locationId"];
        if (![NSNumber isNilOrNull:locIdFromServer])
            locID = [[self.selectedSchedule valueForKey:@"locationId"] stringValue];
        NSString *locName;
        _locationField.text = @"";
        //if we have the full location list then find the location
        if ([locationList count] > 0)
        {
            for (NSDictionary *locObj in locationList)
            {
                locName = [locObj valueForKey:locID];
                if (locName != nil)
                {
                    _locationField.text = locName ;
                    break;
                }
            }
            
        }
        
        NSString *startDateTime = [NSString stringWithFormat:@"%@  %@", [self.selectedSchedule valueForKey:@"startDate"], [self.selectedSchedule valueForKey:@"startTime"]];
        _startTimeField.text = startDateTime;
        
        NSString *endDateTime = [NSString stringWithFormat:@"%@  %@", [self.selectedSchedule valueForKey:@"endDate"], [self.selectedSchedule valueForKey:@"endTime"]];
        _endTimeField.text = endDateTime;
        
        NSString *notes = [self.selectedSchedule valueForKey:@"notes"];
        if ([NSString isNilOrEmpty:notes])
            notes = @"";
        _notesTextView.text = notes;
        
        
    }
    else{
        NSDate *today = [NSDate date];
        NSString *todayDate = [formatterDate stringFromDate: today];
        _startTimeField.text = [NSString stringWithFormat:@"%@  %@", todayDate, @"9:00AM"];;
        _endTimeField.text = [NSString stringWithFormat:@"%@  %@", todayDate, @"5:00PM"];;
        
        if ([employeeList count] == 1)
            _employeeNameField.text = [employeeList objectAtIndex:0];
        else
            _employeeNameField.text = @"";
        
        
        _locationField.text = @"";
        
    }
    
}

-(void) viewDidLoad{
    [self showIOS14DatePicker];
    //setup all the tags so we know which picker to show when a user taps
    _employeeNameField.tag = EMPLOYEELIST_TAG;
    _startTimeField.tag = START_DATETIME_TAG;
    _endTimeField.tag = END_DATETIME_TAG;
    
    if (assignedLocationList == nil)
        assignedLocationList = [[NSMutableArray alloc] init];
    
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
    [formatterTime12 setDateFormat:@"MM/dd/yyyy h:mma"];
    
    popoverContent = [[UIViewController alloc] init];
    [self setFramePicker];
    
    theDatePicker.hidden = NO;
    NSDate *date = [NSDate date];
    theDatePicker.date = date;
    
    //ge the list of employees so we can show them in the employee view picker
    UserClass *user = [UserClass getInstance];
    employeeList = [[NSMutableArray alloc] initWithArray:[user.employeeNameIDList allValues]];
    locationList = [[NSMutableArray alloc] init];
    for (NSDictionary *loc in user.locationNameAddressList)
    {
        NSDictionary *locObj = [[NSMutableDictionary alloc] init];
        NSString *locName = [loc valueForKey:@"name"];
        NSString *locID = [[loc valueForKey:@"id"] stringValue];
        [locObj setValue:locName forKey:locID];
        [locationList addObject:locObj];
    }
    
    
    
    //if we haven't loaded all the locations then go a head and fetch from server
    if ([user.locationNameAddressList count] == 0)
        [self getAllLocations];
    
}

-(void) showIOS14DatePicker {
    [_startTimeView setHidden:YES];
    [_startTimeField setHidden:NO];
    
    [_endTimeView setHidden:YES];
    [_endTimeField setHidden:NO];
    
    //    if (@available(iOS 14, *)) {
    //        [_startTimeView setHidden:NO];
    //        [_startTimeField setHidden:YES];
    //
    //        [_endTimeView setHidden:NO];
    //        [_endTimeField setHidden:YES];
    //
    //         NSDate *date = [NSDate date];
    //        _startDatePicker.date = date;
    //        _endDatePicker.date = date;
    //
    //        _startDatePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    //        [_startDatePicker addTarget:self action:@selector(handleClockInDatePicker) forControlEvents:UIControlEventValueChanged];
    //
    //        _endDatePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    //        [_endDatePicker addTarget:self action:@selector(handleClockOutDatePicker) forControlEvents:UIControlEventValueChanged];
    //    }
}

-(void)handleClockInDatePicker
{
    _startTimeField.text = [formatterTime12 stringFromDate:_startDatePicker.date];
}

-(void)handleClockOutDatePicker
{
    _endTimeField.text = [formatterTime12 stringFromDate:_endDatePicker.date];
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
    pickerViewEmployeeName.tag = EMPLOYEELIST_TAG;
    
    _employeeNameField.delegate = self;
    _startTimeField.delegate = self;
    _endTimeField.delegate = self;
    _locationField.delegate =  self;
    
    pickerViewLocations = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerViewLocations.dataSource = self;
    pickerViewLocations.delegate = self;
    pickerViewLocations.tag = ALL_LOCATIONS_LIST_TAG;
    
}
- (void)LocationsServiceCallDidFinish:(LocationsWebService *)controller ErrorCode: (int) errorValue;
{
    [self stopSpinner];
    UserClass *user = [UserClass getInstance];
    for (NSDictionary *loc in user.locationNameAddressList)
    {
        NSDictionary *locObj = [[NSMutableDictionary alloc] init];
        NSString *locName = [loc valueForKey:@"name"];
        NSString *locID = [[loc valueForKey:@"id"] stringValue];
        [locObj setValue:locName forKey:locID];
        [locationList addObject:locObj];
    }
    //if a selectedSchedule was passed then we are doing an edit and we only had the ID so lookup the name so we can display it
    if (self.selectedSchedule)
    {
        NSString *locID = @"";
        NSNumber *locIdFromServer = [self.selectedSchedule valueForKey:@"locationId"];
        if (![NSNumber isNilOrNull:locIdFromServer])
            locID = [[self.selectedSchedule valueForKey:@"locationId"] stringValue];

        NSString *locName;
        //if we have the full location list then find the location
        if ([locationList count] > 0)
        {
            for (NSDictionary *locObj in locationList)
            {
                locName = [locObj valueForKey:locID];
                if (locName != nil)
                {
                    _locationField.text = locName;
                    break;
                }
            }
            
        }
        
    }
    
}
-(void) getAllLocations
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    LocationsWebService *locationWebService = [[LocationsWebService alloc] init];
    locationWebService.delegate = self;
    [locationWebService fetchAllLocations];
}

- (void)viewDidUnload
{
    
    theDatePicker = nil;
    pickerToolbar = nil;
    pickerViewDate = nil;
    
    [super viewDidUnload];
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

-(BOOL)closeLocationsPicker:(id)sender{
    [pickerViewLocations removeFromSuperview];
    [pickerViewDate removeFromSuperview];
    [theDatePicker removeFromSuperview];
    return YES;
}

-(IBAction)DatePickerDoneClick{
    
    if (theDatePicker.tag == START_DATETIME_TAG)
        _startTimeField.text = [formatterTime12 stringFromDate:theDatePicker.date];
    else
        _endTimeField.text = [formatterTime12 stringFromDate:theDatePicker.date];
    
    [self closeDatePicker:self];
}

-(IBAction)DatePickerCancelClick{
    [self closeDatePicker:self];
}

-(IBAction)EmployeePickerDoneClick{
    NSInteger row = [pickerViewEmployeeName selectedRowInComponent:0];
    
    // [_employeeButton setTitle:[employeeList objectAtIndex:row] forState:UIControlStateNormal];
    _employeeNameField.text = [employeeList objectAtIndex:row];
    
    //reset the assigned locations list because we picked an employee and that list might not be his
    [assignedLocationList removeAllObjects];
    
    [self closeEmployeePicker:self];
}


-(void)setLocationText {
    NSInteger row = [pickerViewLocations selectedRowInComponent:0];
    //if the user selected the last row it's the display All Locations choice then reload the view to show all locations
    if ((pickerViewLocations.tag == ASSIGNED_LOCATIONS_LIST_TAG) && ( row == [pickerViewLocations numberOfRowsInComponent:0] - 1))
    {
        pickerViewLocations.tag = ALL_LOCATIONS_LIST_TAG;
        locationPickerViewtitle.text = @"All Locations";
        [assignedLocationList removeAllObjects];
        [pickerViewLocations reloadAllComponents];
        [pickerViewLocations selectRow:0 inComponent:0 animated:YES];
        
    }
    else
    {
        NSDictionary *locObj;
        if (pickerViewLocations.tag == ASSIGNED_LOCATIONS_LIST_TAG)
            locObj = [assignedLocationList objectAtIndex:row];
        else
            locObj = [locationList objectAtIndex:row];
        NSString *locName = [[locObj allValues] objectAtIndex:0];
        selectedLocationId = [[locObj allKeys] objectAtIndex:0];
        _locationField.text = locName ;
    }
}

-(IBAction)LocationPickerDoneClick{
    [self setLocationText];
    
    NSInteger row = [pickerViewLocations selectedRowInComponent:0];
    //if the user selected the last row it's the display All Locations choice then reload the view to show all locations
    if ((pickerViewLocations.tag == ASSIGNED_LOCATIONS_LIST_TAG) && ( row == [pickerViewLocations numberOfRowsInComponent:0] - 1))
    {
    }
    else
    {
        //if we are running the iPhone version then there is a done button and we need to close the window while the iPAD version you can tap out of the window to close it
#ifndef IPAD_VERSION
        [self closeLocationsPicker:self];
#endif
    }
}

-(IBAction)EmployeePickerCancelClick{
    [self closeEmployeePicker:self];
}

-(IBAction)LocationPickerCancelClick{
    [self closeLocationsPicker:self];
}

-(void) showDatePicker: (UITextField*) textField{
    [self closeEmployeePicker:self];
    [self closeLocationsPicker:self];
    
    
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
    if (textField.tag == START_DATETIME_TAG)
        curField = _startTimeField;
    else
        curField = _endTimeField;
    
    BOOL isEmpty = !(curField.text && curField.text.length > 0);
    
    if (!isEmpty)
        theDatePicker.date = [formatterTime12 dateFromString:curField.text];
    else
        curField.text = [formatterTime12 stringFromDate:theDatePicker.date];

    theDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
    
    
    //to figure out which date picker belongs to which text field
    if (textField.tag == START_DATETIME_TAG)
        theDatePicker.tag = START_DATETIME_TAG;
    else
        theDatePicker.tag = END_DATETIME_TAG;
    
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

/*- (NSDate *)getTodayDateAt:(NSDate*) selectedDate hour: (NSInteger)hour minute:(NSInteger)minute {
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:selectedDate];
    components.hour = hour;
    components.minute = minute;
    return [calendar dateFromComponents:components];
}
*/
-(void)onDatePickerValueChanged
{
    if (theDatePicker.tag == START_DATETIME_TAG)
    {
        _startTimeField.text = [formatterTime12 stringFromDate:theDatePicker.date];
    }
    else
        _endTimeField.text = [formatterTime12 stringFromDate:theDatePicker.date];;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView.tag == EMPLOYEELIST_TAG)
    {
        NSInteger row = [pickerViewEmployeeName selectedRowInComponent:0];
        
        _employeeNameField.text = [employeeList objectAtIndex:row];
        
        //reset the assigned locations list because we picked an employee and that list might not be his
        [assignedLocationList removeAllObjects];
    }
    else
    {
        [self setLocationText];
    }
}
-(void) showEmployeePicker{
    
    [theDatePicker removeFromSuperview];
    [pickerViewLocations removeFromSuperview];
    
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

-(void) showLocationPicker{
    
    [theDatePicker removeFromSuperview];
    [pickerViewEmployeeName removeFromSuperview];
    
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    pickerToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [pickerToolbar sizeToFit];
    
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(LocationPickerCancelClick)];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    locationPickerViewtitle = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 150, 20.0f)];
    [locationPickerViewtitle setBackgroundColor:[UIColor clearColor]];
    [locationPickerViewtitle setTextColor:[UIColor whiteColor]];
    locationPickerViewtitle.textAlignment = NSTextAlignmentCenter;
    if (pickerViewLocations.tag == ASSIGNED_LOCATIONS_LIST_TAG)
        locationPickerViewtitle.text = @"Assigned Locations";
    else
        locationPickerViewtitle.text = @"All Locations";
    
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:locationPickerViewtitle];
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(LocationPickerDoneClick)];
    
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:cancelBtn, flexSpace, titleButton, flexSpace, doneDateBarBtn, nil];
    
    [pickerToolbar setItems:itemArray animated:YES];
    
    [pickerToolbar removeFromSuperview];
    [pickerViewLocations removeFromSuperview];
    
    
    //    }
    
    
#ifdef IPAD_VERSION
    
    [pickerViewDate addSubview:pickerViewLocations];
    popoverContent.view = pickerViewDate;
    popoverContent.modalPresentationStyle = UIModalPresentationPopover;
    popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
    popoverContent.popoverPresentationController.sourceView = _scrollView;
    popoverContent.popoverPresentationController.sourceRect = _locationField.superview.frame;
    [self presentViewController:popoverContent animated:YES completion:nil];
#else
    [pickerViewDate addSubview:pickerToolbar];
    [pickerViewDate addSubview:pickerViewLocations];
    [self.view addSubview:pickerViewDate];
#endif
    
    
    BOOL isEmpty = [NSString isNilOrEmpty:_locationField.text];
    int pos = 0;
    
    if (!isEmpty)
    {
        int row = 0;
        NSString *locName;
        NSArray *locationDisplayList;
        if ((assignedLocationList) && ([assignedLocationList count] > 0))
            locationDisplayList = assignedLocationList;
        else
            locationDisplayList = locationList;
        
        for (NSDictionary *locObj in locationDisplayList)
        {
            locName = [[locObj allValues] objectAtIndex:0];
            if ([locName isEqualToString:_locationField.text])
                pos = row;
            else
                row++;
        }
        
    }
    //if the employee Name TextField is empty then default it to the first name in the employeeList
    else if ([locationList count] > 0)
    {
        NSDictionary *locObj = [locationList objectAtIndex:0];
        NSString *locName = [[locObj allValues] objectAtIndex:0];
        _locationField.text = locName;
    }
    
    [pickerViewLocations reloadAllComponents];
    [pickerViewLocations selectRow:pos inComponent:0 animated:YES];
    
    
    
}


- (IBAction)doEmployeeNameTouchDown:(id)sender {
    //if there is only one employee don't bother showing the picker
    if ([employeeList count] > 1) {
        [self showEmployeePicker];
    }
    
}

/*
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            [self stopSpinner];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //error 503 is when tomcat is down
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            //  [alert show];
        }
    }
    
    
    data = [[NSMutableData alloc] init];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataIn
{
    [data appendData:dataIn];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self stopSpinner];
    
    NSError *error = nil;
    
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];
    
    if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from ScheduleDetailViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
        
        if ([resultMessage isEqual:[NSNull null]]){
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"Schedule Creation Failed"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            
            //   alert = [[UIAlertView alloc] initWithTitle:nil message:@"Schedule Creation Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
        else
        {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:resultMessage
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            //    alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            //  [alert show];
        }
    }
    else {
        //log to mixpanel if we are production
        if ([CommonLib isProduction])
        {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            UserClass *user = [UserClass getInstance];
            [mixpanel track:@"Create Schedule" properties:@{ @"email": user.userEmail}];
        }
        
        [self.delegate scheduleDetailViewControllerDidFinish:self];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self stopSpinner];
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"ERROR"
                                 message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    //[alert show];
    
    connection = nil;
    data = nil;
}
 */

-(void) callCreateSchedule{
    [self callCreateScheduleAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            NSError *error = nil;
            
        //    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
            NSString *resultMessage = [aResults valueForKey:@"message"];
            
            if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
                [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from ScheduleDetailViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                
                if ([resultMessage isEqual:[NSNull null]]){
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"ERROR"
                                                 message:@"Schedule Creation Failed"
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:defaultAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                    
                    
                    //   alert = [[UIAlertView alloc] initWithTitle:nil message:@"Schedule Creation Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                }
                else
                {
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"ERROR"
                                                 message:resultMessage
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:defaultAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                    
                    //    alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    //  [alert show];
                }
            }
            else {
                
                [self.delegate scheduleDetailViewControllerDidFinish:self];
            }

        }
    }];
}

-(void) callCreateScheduleAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    //    showErrorMessage = true;
    
    [self startSpinnerWithMessage:@"Creating Schedule..."];
    NSString *httpPostString;
    NSString *startTime, *endTime;
    UserClass *user = [UserClass getInstance];
    
    NSDate *DateValue = [formatterTime12 dateFromString:_startTimeField.text];
    NSString *shiftDate = [formatterDate stringFromDate:DateValue];
    [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    startTime = [formatterISO8601DateTime stringFromDate:DateValue];
    startTime  = [startTime stringByReplacingOccurrencesOfString:@"+0000" withString:@".000Z"];
    startTime  = [startTime stringByReplacingOccurrencesOfString:@"-0000" withString:@".000Z"];
    
    DateValue = [formatterTime12 dateFromString:_endTimeField.text];
    endTime = [formatterISO8601DateTime stringFromDate:DateValue];
    endTime  = [endTime stringByReplacingOccurrencesOfString:@"+0000" withString:@".000Z"];
    endTime  = [endTime stringByReplacingOccurrencesOfString:@"-0000" withString:@".000Z"];
    
    //    user.authToken = @"f57fd8bf-3b12-4012-b580-9ab0be6e8303";
    NSString *employerID = [user.employerID stringValue];
    NSArray* arrayOfKeys = [user.employeeNameIDList allKeysForObject:_employeeNameField.text];
    
    
    NSString *employeeID = [arrayOfKeys objectAtIndex:0];
    
    NSString *notes = _notesTextView.text;
    
    httpPostString = [NSString stringWithFormat:@"%@schedules", SERVER_URL];
    
    NSString *tmpAuthToken = user.authToken;
    //    tmpAuthToken = @"cfb75f27-abbe-4c98-8319-d410f661d3f5";
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              shiftDate, @"shiftDateString",
                              startTime, @"startDateTimeIso8601",
                              endTime, @"endDateTimeIso8601",
                              employerID, @"employerId",
                              employeeID, @"employeeId",
                              notes, @"notes",
                              selectedLocationId, @"locationId",
                              nil];
    
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:0
                                                         error:&error];
    NSString *JSONString;
    if (!jsonData) {
    } else {
        
        JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    NSData *requestData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    //    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"authToken"];
    [urlRequest setValue:employerID forHTTPHeaderField:@"employerId"];
    [urlRequest setValue:[NSString stringWithFormat:@"%ld", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setHTTPBody: requestData];
    
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

/*
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        //alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        // [alert show];
        
    }
    
    */
}


-(void) callScheduleAPI:(int)flag scheduleId:(NSNumber*) schId withCompletion:(ServerResponseCompletionBlock)completion
{
    if (flag == CREATE_SCHEDULE)
        [self startSpinnerWithMessage:@"Creating Schedule..."];
    else
        [self startSpinnerWithMessage:@"Updating Schedule..."];
    
    NSString *httpPostString;
    NSString *startTime, *endTime;
    UserClass *user = [UserClass getInstance];
    
    NSDate *DateValue = [formatterTime12 dateFromString:_startTimeField.text];
    NSString *shiftDate = [formatterDate stringFromDate:DateValue];
    [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    startTime = [formatterISO8601DateTime stringFromDate:DateValue];
    //   startTime  = [startTime stringByReplacingOccurrencesOfString:@"+0000" withString:@".000Z"];
    startTime  = [startTime stringByReplacingOccurrencesOfString:@"+0000" withString:@"Z"];
    startTime  = [startTime stringByReplacingOccurrencesOfString:@"-0000" withString:@"Z"];
    
    DateValue = [formatterTime12 dateFromString:_endTimeField.text];
    endTime = [formatterISO8601DateTime stringFromDate:DateValue];
    //  endTime  = [endTime stringByReplacingOccurrencesOfString:@"+0000" withString:@".000Z"];
    endTime  = [endTime stringByReplacingOccurrencesOfString:@"+0000" withString:@"Z"];
    
    endTime  = [endTime stringByReplacingOccurrencesOfString:@"-0000" withString:@"Z"];
    
    //    user.authToken = @"f57fd8bf-3b12-4012-b580-9ab0be6e8303";
    NSString *employerID = [user.employerID stringValue];
    NSArray* arrayOfKeys = [user.employeeNameIDList allKeysForObject:_employeeNameField.text];
    
    
    NSString *employeeID = [arrayOfKeys objectAtIndex:0];
    
    NSString *notes = _notesTextView.text;
    
    if ([selectedLocationId integerValue] == -1)
        selectedLocationId = [self.selectedSchedule valueForKey:@"locationId"];
    
    if (flag == CREATE_SCHEDULE)
        httpPostString = [NSString stringWithFormat:@"%@api/v1/schedules", SERVER_URL];
    else
        httpPostString = [NSString stringWithFormat:@"%@api/v1/schedules/%@", SERVER_URL, schId];
    
    NSString *tmpAuthToken = user.authToken;
    //    tmpAuthToken = @"cfb75f27-abbe-4c98-8319-d410f661d3f5";
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              shiftDate, @"pendingShiftDateString",
                              startTime, @"pendingStartDateTimeIso8601",
                              endTime, @"pendingEndDateTimeIso8601",
                              employerID, @"employerId",
                              employeeID, @"employeeId",
                              notes, @"pendingNotes",
                              selectedLocationId, @"pendingLocationId",
                              nil];
    
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:0
                                                         error:&error];
    NSString *JSONString;
    if (!jsonData) {
    } else {
        
        JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    NSData *requestData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (flag == CREATE_SCHEDULE)
        [urlRequest setHTTPMethod:@"POST"];
    else
        [urlRequest setHTTPMethod:@"PUT"];
    
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    //    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:employerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    
    [urlRequest setValue:[NSString stringWithFormat:@"%ld", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setHTTPBody: requestData];
    
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
                
                //[self stopSpinner];
                
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
/*-(void) callUpdateSchedule{
    [self startSpinnerWithMessage:@"Updating Schedule..."];
    
    NSString *httpPostString;
    NSString *startTime, *endTime;
    UserClass *user = [UserClass getInstance];
    
    NSDate *DateValue = [formatterTime12 dateFromString:_startTimeField.text];
    NSString *shiftDate = [formatterDate stringFromDate:DateValue];
    [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    startTime = [formatterISO8601DateTime stringFromDate:DateValue];
    startTime  = [startTime stringByReplacingOccurrencesOfString:@"+0000" withString:@".000Z"];
    startTime  = [startTime stringByReplacingOccurrencesOfString:@"-0000" withString:@".000Z"];
    
    DateValue = [formatterTime12 dateFromString:_endTimeField.text];
    endTime = [formatterISO8601DateTime stringFromDate:DateValue];
    endTime  = [endTime stringByReplacingOccurrencesOfString:@"+0000" withString:@".000Z"];
    endTime  = [endTime stringByReplacingOccurrencesOfString:@"-0000" withString:@".000Z"];
    
    //    user.authToken = @"f57fd8bf-3b12-4012-b580-9ab0be6e8303";
    NSString *employerID = [user.employerID stringValue];
    NSArray* arrayOfKeys = [user.employeeNameIDList allKeysForObject:_employeeNameField.text];
    
    
    NSString *employeeID = [arrayOfKeys objectAtIndex:0];
    
    NSString *notes = _notesTextView.text;
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/schedules/%@", SERVER_URL, [self.selectedSchedule valueForKey:@"scheduleId"]];
    
    if ([selectedLocationId integerValue] == -1)
        selectedLocationId = [self.selectedSchedule valueForKey:@"locationId"];
    
    NSString *tmpAuthToken = user.authToken;
    //    tmpAuthToken = @"cfb75f27-abbe-4c98-8319-d410f661d3f5";
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              shiftDate, @"pendingShiftDateString",
                              startTime, @"pendingStartDateTimeIso8601",
                              endTime, @"pendingEndDateTimeIso8601",
                              employerID, @"employerId",
                              employeeID, @"employeeId",
                              notes, @"pendingNotes",
                              selectedLocationId, @"pendingLocationId",
                              nil];
    
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:0
                                                         error:&error];
    NSString *JSONString;
    if (!jsonData) {
    } else {
        
        JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    NSData *requestData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    
    [urlRequest setHTTPMethod:@"PUT"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"authToken"];
    [urlRequest setValue:employerID forHTTPHeaderField:@"employerId"];
    [urlRequest setValue:[NSString stringWithFormat:@"%ld", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setHTTPBody: requestData];
    
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        // alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        // [alert show];
        
    }
    
    
}

-(void) callScheduleUpdateAPI:(NSNumber*)schedId withCompletion:(ServerResponseCompletionBlock)completion
{
    
    NSString *httpPostString;
    UserClass *user = [UserClass getInstance];
    
    NSString *employerID = [user.employerID stringValue];
    
    NSString *startTime, *endTime;
    
    NSDate *DateValue = [formatterTime12 dateFromString:_startTimeField.text];
    startTime = [formatterISO8601DateTime stringFromDate:DateValue];
    startTime  = [startTime stringByReplacingOccurrencesOfString:@"+0000" withString:@".000Z"];
    startTime  = [startTime stringByReplacingOccurrencesOfString:@"-0000" withString:@".000Z"];
    
    DateValue = [formatterTime12 dateFromString:_endTimeField.text];
    endTime = [formatterISO8601DateTime stringFromDate:DateValue];
    endTime  = [endTime stringByReplacingOccurrencesOfString:@"+0000" withString:@".000Z"];
    endTime  = [endTime stringByReplacingOccurrencesOfString:@"-0000" withString:@".000Z"];
    
    
    
    NSDictionary *jsonDict;
    NSMutableURLRequest *urlRequest;
    
    //   NSString *employeeID = [arrayOfKeys objectAtIndex:0];
    httpPostString = [NSString stringWithFormat:@"%@api/v1/schedules/%@", SERVER_URL, schedId];
    
    urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSMutableArray *scheduleIdsToPublish = [NSMutableArray new];
    
    
    jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                employerID, @"employerId",
                scheduleIdsToPublish, @"entities",
                nil];
    
    
    NSError *error = nil;
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    //set request body into HTTPBody.
    urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [urlRequest setHTTPMethod:@"PUT"];
    
    // urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
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
                
                //[self stopSpinner];
                
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

*/
-(void) callEmployeeAssignedLocationsAPI:(int)operation employeeID: empId withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    NSString *httpPostString;
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/employer/%@/employee/%@/locationMap", SERVER_URL, curEmployerID, empId];
    
    //   /api/v1/employer/{employerId}/employee/{employeeId}/locationMap
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    [request setHTTPMethod:@"GET"];
    
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //    [request setValue:curEmployerID forHTTPHeaderField:@"employerId"];
    //    [request setValue:curAuthToken forHTTPHeaderField:@"authToken"];
    [request setValue:curEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [request setValue:curAuthToken forHTTPHeaderField:@"x-ezclocker-authToken"];
    
    
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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

-(void) getAssignedLocationsForEmployee
{
    UserClass *user = [UserClass getInstance];
    NSArray* arrayOfKeys = [user.employeeNameIDList allKeysForObject:_employeeNameField.text];
    
    if ([arrayOfKeys count] > 0)
    {
        [self startSpinnerWithMessage:@"Refreshing, please wait..."];
        NSString *employeeId = [arrayOfKeys objectAtIndex:0];
        
        [self callEmployeeAssignedLocationsAPI:1 employeeID: employeeId withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
            [self stopSpinner];
            if (aErrorCode != 0) {
                [SharedUICode messageBox:nil message:@"There was an issue in retrieving data from server. Please try again later" withCompletion:^{
                    return;
                }];
                
            }
            
            NSArray *locations = [aResults valueForKey:@"employeeLocationMaps"];
            NSString *locationName = @"";
            NSNumber *assignedLocationId;
            NSNumber *locationId;
            
            [assignedLocationList removeAllObjects];
            if ((locations) && ([locations count] > 0))
            {
                for (NSDictionary *assignedLocation in locations)
                {
                    assignedLocationId = [assignedLocation valueForKey:@"locationId"];
                    for (NSDictionary *loc in locationList)
                    {
                        locationId = [[loc allKeys] objectAtIndex:0];
                        locationName = [[loc allValues] objectAtIndex:0];
                        if (assignedLocationId.intValue == locationId.intValue)
                        {
                            [assignedLocationList addObject:loc];
                            break;
                        }
                    }
                    
                }
                
            }
            if (([assignedLocationList count] > 0) || ([locationList count] > 0))
            {
                if ([assignedLocationList count] > 0)
                {
                    //add All Locations to the end of the pick list
                    NSDictionary *item = [[NSDictionary alloc]
                                          initWithObjectsAndKeys:@"All Locations",@"0",nil];
                    [assignedLocationList addObject:item];
                    pickerViewLocations.tag = ASSIGNED_LOCATIONS_LIST_TAG;
                }
                else
                    pickerViewLocations.tag = ALL_LOCATIONS_LIST_TAG;
                [self showLocationPicker];
            }
            else
            {
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"There are no locations currently setup. Please use the location menu option to add locations"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];
                
                // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"There are no locations currently setup. Please use the location menu option to add locations" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                //  [alert show];
            }
            
        }];
    }
    
    
}

#pragma mark -
#pragma mark Picker Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView.tag == EMPLOYEELIST_TAG)
        return [employeeList count];
    else
    {
        if (pickerView.tag == ASSIGNED_LOCATIONS_LIST_TAG)
            return [assignedLocationList count];
        else
            return [locationList count];
        
        
    }
}

#pragma mark Picker Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *name = @"";
    if (pickerView.tag == EMPLOYEELIST_TAG)
    {
        name = [employeeList objectAtIndex:row];
    }
    else
    {
        if (pickerView.tag == ASSIGNED_LOCATIONS_LIST_TAG)
        {
            NSDictionary *locObj = [assignedLocationList objectAtIndex:row];
            name = [[locObj allValues] objectAtIndex:0];
            
        }
        else{
            NSDictionary *locObj = [locationList objectAtIndex:row];
            name = [[locObj allValues] objectAtIndex:0];
        }
    }
    
    return name;
}
/*
 UserClass *user = [UserClass getInstance];
 return [user.locationNameAddressList count];
 */


-(void) showLocations{
    //the assigned location list gets reset everytime we pick an employee
    //if employee not selected then show all locations
    BOOL isEmpty = [NSString isNilOrEmpty:_employeeNameField.text];
    if (isEmpty)
    {
        //show all locations
        pickerViewLocations.tag = ALL_LOCATIONS_LIST_TAG;
        
        [self showLocationPicker];
    }
    //if I don't have any assigned location for this employee then fetch from server
    else if ([assignedLocationList count] == 0)
        [self getAssignedLocationsForEmployee];
    else
    {
        //show assigned locations only
        pickerViewLocations.tag = ASSIGNED_LOCATIONS_LIST_TAG;
        [self showLocationPicker];
    }
    
    
}
- (IBAction)doSelectEmployeeNameField:(id)sender {
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // We are now showing the UIPickerViewer instead
    
    // Close the keypad if it is showing
    [self.view.superview endEditing:YES];
    
    // Function to show the picker view
    if (textField.tag == EMPLOYEELIST_TAG)
    {
        if ([employeeList count] > 1)
            [self showEmployeePicker];
    }
    else if ((textField.tag == START_DATETIME_TAG) || (textField.tag == END_DATETIME_TAG))
        [self showDatePicker: textField];
    else
        [self showLocations];
    // Return no so that no cursor is shown in the text box
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


@end
