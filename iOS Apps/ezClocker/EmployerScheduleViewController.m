//
//  EmployerScheduleViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 1/3/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import "EmployerScheduleViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "CommonLib.h"
#import "user.h"
#import "SharedUICode.h"
#import "MetricsLogWebService.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "threaddefines.h"
#import "ScheduleDetailViewController.h"
#import "EmployerScheduleTableViewCell.h"

@implementation EmployerScheduleViewController

int GET_ALL_SCHEDULES = 1;
int PUBLISH_SCHEDULES = 2;
int DELETE_SCHEDULE = 3;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddClick:)];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditClick:)];
    // self.navigationItem.rightBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:editButton, addButton, nil];

    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];

    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    self.slidingViewController.underRightViewController = nil;
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    showErrorMessage = true;
    
  //  [self callGetEmployeeSchedule];
    [self callGetAllSchedules];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.title = NSLocalizedString(@"Schedules", @"Schedules");
        
        formatterISO8601DateTime = [[NSDateFormatter alloc] init];
        [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        
        formatterISO8601Date = [[NSDateFormatter alloc] init];
        [formatterISO8601Date setDateFormat:@"yyyy-MM-dd"];
        [formatterISO8601Date setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        
        formatterLocalDate = [[NSDateFormatter alloc] init];
        [formatterLocalDate setDateFormat:@"yyyy-MM-dd"];
        [formatterLocalDate setTimeZone:[NSTimeZone localTimeZone]];

        
        formatterTime12 = [[NSDateFormatter alloc] init];
        [formatterTime12 setDateFormat:@"MM/dd/yyyy h:mm a"];

        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _scheduleTable.allowsSelectionDuringEditing = YES;
    _scheduleTable.allowsMultipleSelectionDuringEditing = NO;

    scheduleList = [[NSMutableArray alloc] initWithCapacity:0];
    
    deletedScheduleListIds = [[NSMutableArray alloc] initWithCapacity:0];

    //init starting date with today's date
    startingDate = [[NSDate alloc] init];
    todayDate = startingDate;
    
    _scheduleTable.tableFooterView = [UIView new];
    

    popoverContent = [[UIViewController alloc] init];
    [self setFramePicker];
    
    theDatePicker.datePickerMode = UIDatePickerModeDate;
    theDatePicker.hidden = NO;
    
    theDatePicker.backgroundColor = [UIColor whiteColor];

    formatterDate = [[NSDateFormatter alloc] init];
    [formatterDate setLocale: [[NSLocale alloc]
                               initWithLocaleIdentifier:@"en_US"]];
    [formatterDate setDateFormat:@"MM/dd/yyyy"];

    //selectDateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //selectDateButton.frame = CGRectMake(0, 0, 150.0f, 35.0f);
    NSString *todayDateSr = [formatterDate stringFromDate:startingDate];
    [_selectDateButton setTitle:todayDateSr forState:UIControlStateNormal];

   // [selectDateButton.titleLabel setFont:[UIFont fontWithName:@"System-Bold" size:30.0]];
    //selectDateButton.titleLabel.font = [UIFont systemFontOfSize:24];

    [_selectDateButton addTarget:self action:@selector(doChangeDate) forControlEvents:UIControlEventTouchUpInside];
    
    [_selectDateArrowBtn addTarget:self action:@selector(doChangeDate) forControlEvents:UIControlEventTouchUpInside];

}
- (void)setFramePicker {
    
     CGFloat kbHeight = [NSUserDefaults.standardUserDefaults floatForKey:keyboardHeight];
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
 //   CGFloat screenHeight = screenSize.height;
    
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
    
//    CGFloat Y = screenHeight - (kbHeight + safeAreaBottomHeight + safeAreaTopHeight);
      CGFloat Y = self.view.frame.size.height -  kbHeight ;
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
        pickerFrame = CGRectMake(0, 0, 350, 250);
        theDatePicker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
    } else {
        pickerFrame = CGRectMake(0, 44,  screenSize.width, kbHeight - 44);
        theDatePicker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
    }
    
}

- (IBAction)onEditClick:(id)sender {
    [self setEditState];
}
- (void)setEditButtons {
    if (_scheduleTable.editing) {
        [_scheduleTable setEditing:NO animated:TRUE];
    }
    
    [self __setEditButtons];
}

- (void)__setEditButtons {
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:UIBarButtonItemStylePlain target:self action:@selector(revealMenu:)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddClick:)];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditClick:)];
    // self.navigationItem.rightBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:editButton, addButton, nil];
    
}

- (void)setCancelButtonForSwipDelete {
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelClick:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    // self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.rightBarButtonItems = nil;
    
}
static BOOL __cancelling = FALSE;
- (void)onCancelClick:(id)sender {
    __cancelling = TRUE;
    @try {
        [self __cancelEditing];
    }
    @finally {
        __cancelling = FALSE;
    }
}

- (void)__cancelEditing {
    [self setEditButtons];
}

- (void)cancelEditing {
    if (nil == self.navigationItem.leftBarButtonItem) {
        return;
    }
    [self __cancelEditing];
}

- (void)setEditState {
    if (nil == self.navigationItem.leftBarButtonItem) {
        return;
    }
    if (self.editing) { // Not editing go into edit mode
        [_scheduleTable setEditing:NO animated:YES];
        //        [self __cancelEditing];
        return;
    }
    
    //    [self beforeEditingBegins];
    [_scheduleTable setEditing:YES animated:YES];
    
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelClick:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.navigationItem.rightBarButtonItems = nil;
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    UIView *view = [cancelButton valueForKey:@"view"];
    
    [SharedUICode yesNoCancel:nil message:@"Delete Shift.  Are you sure?" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing" rootControl:view withCompletion:^(YesNoCancelResult Result) {
        switch (Result) {
            case resultYes: {
                [self deleteScheduleAtIndexPath:indexPath];
                break;
            }
            case resultNo:
                break;
            default: {
                [self onCancelClick:self];
                break;
            }
        }
    }];
    
}

- (void)deleteScheduleAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *selectedSchedule = [scheduleList objectAtIndex:indexPath.section];
    NSArray *dayShifts = [selectedSchedule valueForKey:@"scheduleTimes"];
    NSMutableDictionary *dayShiftSelected = [dayShifts objectAtIndex:indexPath.row];
 //   NSNumber *schID = [dayShiftSelected valueForKey:@"scheduleId"];
    [_scheduleTable setEditing:NO animated: YES];
    [self onCancelClick:self];
    //    editFlag = NO;
    //    [self callDeleteLocation: locID];
    
//    [self startSpinnerWithMessage:@"Deleting, please wait..."];
    
    [self callScheduleAPI:DELETE_SCHEDULE selectedSchedule:dayShiftSelected withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
   
 /*  [self callScheduleAPI:DELETE_SCHEDULE withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
          [self stopSpinner];
          if (aErrorCode != 0) {
              [SharedUICode messageBox:nil message:@"There was an issue publishing the schedule information. Please try again later" withCompletion:^{
                  return;
              }];
              
          }
  */
        else{
            
            _publishButton.enabled = true;
            
            //add the deleted schedule id to the list so we can publish it
            NSNumber *delScheduleId = [dayShiftSelected valueForKey:@"scheduleId"];
            [deletedScheduleListIds addObject:delScheduleId];

            [_scheduleTable beginUpdates];
            if ([dayShifts count] > 1)
            {
                // Section is not yet empty, so delete only the current row.
                [[[scheduleList objectAtIndex:indexPath.section] valueForKey:@"scheduleTimes"] removeObjectAtIndex: indexPath.row];
                [_scheduleTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
            }
            else
            {
                // Section is now completely empty, so delete the entire section.
                [scheduleList removeObjectAtIndex:indexPath.section];
                if ([scheduleList count] > 0)
                    [_scheduleTable deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                         withRowAnimation:UITableViewRowAnimationFade];
                else
                    [_scheduleTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                              withRowAnimation:UITableViewRowAnimationFade];
            }

            [_scheduleTable endUpdates];
        }
    }];
    
}


-(void) callDeleteSchedule:(NSNumber*)schID withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    NSString *request_body;
    UserClass *user = [UserClass getInstance];
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    
    //httpPostString = [NSString stringWithFormat:@"%@schedules/%@", SERVER_URL, schID];
    httpPostString = [NSString stringWithFormat:@"%@api/v1/schedules/%@", SERVER_URL, schID];
    //Implement request_body for send request here authToken and clock DateTime set into the body.
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];

    request_body = [NSString
                    stringWithFormat:@"authToken=%@",
                    [user.authToken  stringByAddingPercentEncodingWithAllowedCharacters: set]
                    ];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    urlRequest.timeoutInterval = TIME_OUT_REQUEST;
    
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"DELETE"];
    
    //set request body into HTTPBody.
  //  [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:curEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    [urlRequest setValue:curAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    
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
                MAINTHREAD_BLOCK_START()
                completion(errorCode, resultMessage, results, aError);
                THREAD_BLOCK_END()
                return;
                //                }
            }];
        }
    }];
    [dataTask resume];
    //    [self stopSpinner];
    
}


-(BOOL)closeDatePicker:(id)sender{
#ifdef IPAD_VERSION
    [pickerViewDate removeFromSuperview];
    [self dismissViewControllerAnimated:NO completion:nil];
    return YES;
#else
    [pickerViewDate removeFromSuperview];
    return YES;
#endif

}

-(IBAction)DatePickerDoneClick{
    startingDate = theDatePicker.date;
    NSString *selectedDate = [formatterDate stringFromDate:theDatePicker.date];
    [_selectDateButton setTitle:selectedDate forState:UIControlStateNormal];
    
    [self closeDatePicker:self];
    
   // [self callGetEmployeeSchedule];
    [self callGetAllSchedules];
    
}



-(IBAction)DatePickerCancelClick{
    [self closeDatePicker:self];
}


-(void) updateCurrentSelectedDate:(NSDate*)newDate{
    startingDate = newDate;
    [_selectDateButton setTitle:[formatterDate stringFromDate:startingDate] forState:UIControlStateNormal];

    
}

- (IBAction)doNextDateClick:(id)sender {
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.day = 7;
    NSDate *newDate = [[NSCalendar currentCalendar]dateByAddingComponents:dateComponents
                                                                   toDate: startingDate
                                                                  options:0];
    [self updateCurrentSelectedDate:newDate];
    
   // [self callGetEmployeeSchedule];
    [self callGetAllSchedules];

}

- (IBAction)doPrevDateClick:(id)sender {
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.day = -7;
    NSDate *newDate = [[NSCalendar currentCalendar]dateByAddingComponents:dateComponents
                                                                   toDate: startingDate options:0];
    [self updateCurrentSelectedDate:newDate];
    
  //  [self callGetEmployeeSchedule];
    [self callGetAllSchedules];

}

- (IBAction)revealMenu:(id)sender {
    if ([_publishButton isEnabled])
    {
        UIAlertController * alert = [UIAlertController
                                      alertControllerWithTitle:@"Alert"
                                      message:@"Do you want to publish before leaving this screen?."
                                      preferredStyle:UIAlertControllerStyleAlert];
         
         UIAlertAction* NoAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
             
                    [self.slidingViewController anchorTopViewTo:ECRight];
                 
                }];
                 
         [alert addAction:NoAction];

  //       [self presentViewController:alert animated:YES completion:nil];
        
        UIAlertAction* publishAction = [UIAlertAction actionWithTitle:@"Publish" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
             
                [self doPublish];
                 
                }];
                 
         [alert addAction:publishAction];

         [self presentViewController:alert animated:YES completion:nil];


    }
    else
    {
        [self.slidingViewController anchorTopViewTo:ECRight];
    }
}

//- (IBAction)doPickDateBtnClick:(id)sender {
//    [self showDatePicker];
//}

- (IBAction)doChangeDate{
    [self showDatePicker];
}

//- (IBAction)doChangeDateBtnClick:(id)sender {
//    [self showDatePicker];
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([scheduleList count] == 0){
        return 1;
    }
    else {
        
        return [scheduleList count];
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34.f;
}

//because we are overridng the color of the section header we'll also need to set the Header text
//because by using this method it will override whatever is in titleForHeaderInSection method
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *tempView=[[UIView alloc]initWithFrame:CGRectMake(0,200,300,244)];
    tempView.backgroundColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR);
    //  UILabel *tempLabel = [[UILabel alloc] init];
    UILabel *tempLabel=[[UILabel alloc]initWithFrame:CGRectMake(15,0,300,36)];
    tempLabel.backgroundColor=[UIColor clearColor];
    tempLabel.textColor = [UIColor whiteColor];
    tempLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0f];
    tempLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    
    if ([scheduleList count] > 0)
    {
        NSDictionary *dayShiftList;
        dayShiftList = [scheduleList objectAtIndex:section];
        tempLabel.text = [dayShiftList valueForKey:@"scheduleDate"];
    }
    else {
        tempLabel.text =  @"No schedule available";
    }
    
    [tempView addSubview:tempLabel];
    
    return tempView;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if ([scheduleList count] > 0)
    {
        // Return the number of rows in the section.
        NSDictionary *daySchedule;
        daySchedule = [scheduleList objectAtIndex:section];
        NSArray *dayShifts = [daySchedule valueForKey:@"scheduleTimes"];
        int tmp = (int)[dayShifts count];
        return tmp;
    }
    else {
        return 0;
    }
    
}


/*- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
 //   static NSString *CellIdentifier = @"Cell";
    
    UILabel *lblStatus;
  //  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    static NSString *CellIdentifier = @"EmployerScheduleCell";
    EmployerScheduleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSDictionary *daySchedule;
    daySchedule = [scheduleList objectAtIndex:indexPath.section];
    NSArray *dayShifts = [daySchedule valueForKey:@"scheduleTimes"];
    NSDictionary *dayShift = [dayShifts objectAtIndex:indexPath.row];
    NSString *employeeName = [dayShift valueForKey:@"employeeName"];
    NSString *locationName = [dayShift valueForKey:@"locationName"];
    NSString *empNameAndLocation = @"";
    if (![NSString isNilOrEmpty:locationName])
    {
        empNameAndLocation = [NSString stringWithFormat:@"%@ (%@)", employeeName, locationName];
       // cell.detailTextLabel.text = locationName;
        cell.locationNameLabel.text = locationName;
    }
    else
        empNameAndLocation = employeeName;
    
    cell.empNameLabel.text = employeeName;
    
    cell.shiftTimeLabel.text = [dayShift valueForKey:@"shiftStartEndTime"];
    
    lblStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 140, 20)];
    lblStatus.backgroundColor = [UIColor clearColor];
    [lblStatus setTag:101];
    lblStatus.textAlignment = NSTextAlignmentRight;
 //   cell.accessoryView = lblStatus;
    lblStatus.text = [dayShift valueForKey:@"shiftStartEndTime"];
    lblStatus.font = [lblStatus.font fontWithSize:16];
    //cell.detailTextLabel.text = [dayShift valueForKey:@"shiftStartEndTime"];
    
    
    return cell;
}
*/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UILabel *lblStatus;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
         cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
     }


    NSDictionary *daySchedule;
    daySchedule = [scheduleList objectAtIndex:indexPath.section];
    NSArray *dayShifts = [daySchedule valueForKey:@"scheduleTimes"];
    NSDictionary *dayShift = [dayShifts objectAtIndex:indexPath.row];
    NSString *employeeName = [dayShift valueForKey:@"employeeName"];
    NSString *locationName = [dayShift valueForKey:@"locationName"];
    if ([NSString isNilOrEmpty:locationName])
        locationName = @"";
    cell.textLabel.text = employeeName;
    cell.detailTextLabel.text = locationName;
    lblStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 140, 20)];
    lblStatus.backgroundColor = [UIColor clearColor];
    [lblStatus setTag:101];
    lblStatus.textAlignment = NSTextAlignmentRight;
    cell.accessoryView = lblStatus;
    lblStatus.text = [dayShift valueForKey:@"shiftStartEndTime"];
    lblStatus.font = [lblStatus.font fontWithSize:16];
    
    return cell;
}
 
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [cell textLabel].font =  [[cell textLabel].font fontWithSize: 20];//setFont:[UIFont systemFontOfSize:20.0]];
    [cell detailTextLabel].font = [[cell detailTextLabel].font fontWithSize:16];//[UIFont systemFontOfSize:16.0]];
    cell.detailTextLabel.textColor = UIColorFromRGB(NAVY_WEBSITE_COLOR);
    
    
    //[UIColor colorWithRed:81.0/255.0 green:102.0/255.0 blue:145.0/255.0 alpha:1.0];
 }

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

//-(void)tableView:willDisplayCellForRow:atIndexPath{
    
//}


-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            //            [self stopSpinner];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //error 503 is when tomcat is down
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            
       //     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       //     [alert show];
            //don't show any more erors for this api call one is enough
            showErrorMessage = false;
        }
    }
    
    
    data = [[NSMutableData alloc] init];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataIn
{
    [data appendData:dataIn];
}

-(int) FindScheduleDate: (NSString *) curSchDate
{
    int idx = -1;
    int row = 0;
    NSString *schDate;
    for (NSMutableDictionary *item in scheduleList) {
        schDate = [item valueForKey:@"scheduleDate"];
        if ([schDate isEqualToString:curSchDate]){
            idx = row;
        }
        else row++;
    }
    return idx;
}


-(void)showDatePicker
{
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    pickerToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [pickerToolbar sizeToFit];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 100, 20.0f)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    titleLabel.text = @"Select Date";
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(DatePickerCancelClick)];
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(DatePickerDoneClick)];
    
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:cancelBtn, flexSpace, titleButton, flexSpace, doneDateBarBtn, nil];
    
    [pickerToolbar setItems:itemArray animated:YES];
    
    if (@available(iOS 13.4, *)) {
        [theDatePicker setPreferredDatePickerStyle:UIDatePickerStyleWheels];
    } else {
        // Fallback on earlier versions
    }
    
#ifdef IPAD_VERSION
    
 /*   [pickerViewDate addSubview:theDatePicker];
    popoverContent.view = pickerViewDate;
    popoverContent.modalPresentationStyle = UIModalPresentationPopover;
    popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
    popoverContent.popoverPresentationController.sourceView = _selectedDateView;
    popoverContent.popoverPresentationController.sourceRect = _selectDateButton.frame;
    [self presentViewController:popoverContent animated:YES completion:nil];
    */
    [pickerViewDate addSubview:theDatePicker];
    UIViewController *V2 = [[UIViewController alloc] init];
    V2.view = pickerViewDate;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:V2];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    V2.preferredContentSize = CGSizeMake(350, 250);
    V2.navigationItem.rightBarButtonItem = doneDateBarBtn;
    V2.navigationItem.leftBarButtonItem = cancelBtn;
    [self presentViewController:navController animated:YES completion:nil];
    navController.view.superview.center = self.view.superview.center;
#else
    theDatePicker.frame = CGRectMake(0, theDatePicker.frame.origin.y, UIScreen.mainScreen.bounds.size.width, theDatePicker.frame.size.height);
    [pickerViewDate addSubview:pickerToolbar];
    [pickerViewDate addSubview:theDatePicker];
    [self.view addSubview:pickerViewDate];
#endif

    
}

- (IBAction)onAddClick:(id)sender {
    ScheduleDetailViewController *addViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ScheduleDetailViewController"];
    
    scheduleNavigationController = [[UINavigationController alloc] initWithRootViewController:addViewController];
    
    
    addViewController.delegate = (id) self;
    addViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:scheduleNavigationController animated:YES completion:nil];
    
}

- (void)scheduleDetailViewControllerDidFinish:(ScheduleDetailViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self callGetAllSchedules];
   // [self callGetEmployeeSchedule];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if (!self.scheduleDetailViewController){
        self.scheduleDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ScheduleDetailViewController"];
        self.scheduleDetailViewController.delegate = (id) self;
    }

    //selectedSchedule is the schedule the user selected
    //scheduleInfo is JSON object we are going to pass to the detail view
    NSDictionary *selectedSchedule = [scheduleList objectAtIndex:indexPath.section];
    NSArray *dayShifts = [selectedSchedule valueForKey:@"scheduleTimes"];
    NSMutableDictionary *dayShiftSelected = [dayShifts objectAtIndex:indexPath.row];
    
    self.scheduleDetailViewController.selectedSchedule = dayShiftSelected;
    
    [self.navigationController pushViewController: self.scheduleDetailViewController animated:YES];
}

-(void) doPublish
{
        [self callScheduleAPI:PUBLISH_SCHEDULES selectedSchedule:nil  withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
                   [self stopSpinner];
                   if (aErrorCode != 0) {
                       [SharedUICode messageBox:nil message:@"There was an issue publishing the schedule information. Please try again later" withCompletion:^{
                           return;
                       }];
                       
                   }
                   else
                   {
                       //clear out the deleted list because we've published them
                       [deletedScheduleListIds removeAllObjects];
                       [SharedUICode messageBox:nil message:@"Schedules were successfully published!" withCompletion:^{
                           return;
                       }];
                       _publishButton.enabled = false;
                   }
    //               [self.delegate scheduleDetailViewControllerDidFinish:self];
                   
            }];

}
- (IBAction)doPublishClick:(id)sender {

    [self doPublish];
    
}

-(void)callGetAllSchedules
{
    [self callScheduleAPI:GET_ALL_SCHEDULES selectedSchedule:nil withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
            [self stopSpinner];
            if (aErrorCode != 0) {
                [SharedUICode messageBox:nil message:@"There was an error retrieving the data. Please try again later" withCompletion:^{
                           return;
            }];
                       
            }
            else
            {
                [scheduleList removeAllObjects];
                [deletedScheduleListIds removeAllObjects];
                
                NSString *schStartTime;
                NSString *shiftDateString, *shiftLongDateString;
                NSString *schEndTime;
                NSMutableDictionary *newSchedule, *newShift;
                
                 UserClass *user = [UserClass getInstance];
                  
                  NSDateFormatter *formatterDateTime12 = [[NSDateFormatter alloc] init];
                  [formatterDateTime12 setDateFormat:@"h:mma"];
                  
                  NSDateFormatter *formatterDateFromServer = [[NSDateFormatter alloc] init];
                  [formatterDateFromServer setDateFormat:@"MM/dd/yyyy"];
                  
                  formatterLongDate = [[NSDateFormatter alloc] init];
                  //this gives me Monday, Tuesday..etc.
                  [formatterLongDate setDateFormat:@"EEEE, MMM dd, yyyy"];
                  
                  
                  NSArray *schedules = [aResults valueForKey:@"schedules"];
                  NSArray *locations = [aResults valueForKey:@"scheduleLocations"];
                  NSString *shiftTime;
                  NSDate *nextShiftDate;
                  _publishButton.enabled = false;
                  NSString *locationName;
                
                  for (NSDictionary *schedule in schedules){
                      
                    bool isPublished = [[schedule valueForKey:@"published"] boolValue];
                    bool isModified = [[schedule valueForKey:@"modified"] boolValue];
                    bool isDeleted = [[schedule valueForKey:@"deleted"] boolValue];
                    if (!isPublished || isModified || isDeleted)
                        _publishButton.enabled = true;
                    //if they are marked as deleted don't show them but add them to the deleted list so they can be published
                    if (isDeleted)
                    {
                        NSNumber *delSchduleId = [schedule valueForKey:@"id"];
                        [deletedScheduleListIds addObject: delSchduleId];
                    }
                    else
                    {
                      NSNumber *tmpEmployeeID = [schedule valueForKey:@"employeeId"];

                      
                      NSString *employeeName = [user.employeeNameIDList valueForKey:[tmpEmployeeID stringValue]];
                        //if we can't find the employee then that means the schedule belongs to an archived employee and we need to ignore it
                        if (![NSString isNilOrEmpty:employeeName])
                        {
                            NSNumber *scheduleID = [schedule valueForKey:@"id"];
                            NSNumber *locationId = [schedule valueForKey:@"pendingLocationId"];
                      
                            NSString *notes = [schedule valueForKey:@"pendingNotes"];
                      
                            schStartTime = [schedule valueForKey:@"pendingStartDateTimeIso8601"];
                            NSString *startTime  = [schStartTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                      
                            NSDate *DateValue = [formatterISO8601DateTime dateFromString:schStartTime];
                            nextShiftDate = DateValue;
                            startTime = [formatterDateTime12 stringFromDate:DateValue];
                            NSString *startDate = [formatterDateFromServer stringFromDate:DateValue];
                      //               shiftDate = [formatterDate stringFromDate:DateValue];
                      
                            schEndTime = [schedule valueForKey:@"pendingEndDateTimeIso8601"];
                            NSString *endTime  = [schEndTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                      
                            DateValue = [formatterISO8601DateTime dateFromString:schEndTime];
                            endTime = [formatterDateTime12 stringFromDate:DateValue];
                            NSString *endtDate = [formatterDateFromServer stringFromDate:DateValue];
                      
                            shiftDateString = [schedule valueForKey:@"pendingShiftDateString"];
                            DateValue = [formatterDateFromServer dateFromString:shiftDateString];
                            shiftLongDateString = [formatterLongDate stringFromDate:DateValue];
                            NSMutableArray *dayShifts;
                            //check if the date is already in the list
                            int idx = [self FindScheduleDate:shiftLongDateString];
                            //if not found
                            bool scheduleExists = idx != -1;
                            if (!scheduleExists )
                            {
                                newSchedule = [[NSMutableDictionary alloc] init];
                                [newSchedule setValue:shiftDateString forKey:@"shiftDateString"];
                                dayShifts = [[NSMutableArray alloc] initWithCapacity:0];
                                [newSchedule setValue:shiftLongDateString forKey:@"scheduleDate"];

                            }
                            else{
                                newSchedule = [scheduleList objectAtIndex:idx];
                                dayShifts = [newSchedule valueForKey:@"scheduleTimes"];
                            }
            
                      
                        shiftTime = [NSString stringWithFormat:@"%@-%@", startTime, endTime];
                      
                        newShift = [[NSMutableDictionary alloc] init];
                        [newShift setValue:shiftTime forKey:@"shiftStartEndTime"];
                        [newShift setValue: notes forKey:@"notes"];
                        [newShift setValue:employeeName forKey:@"employeeName"];
                        [newShift setValue: tmpEmployeeID forKey: @"employeeId"];
                        [newShift setValue:scheduleID forKey:@"scheduleId"];
                        [newShift setValue:startTime forKey:@"startTime"];
                        [newShift setValue:startDate forKey:@"startDate"];
                        [newShift setValue:endTime forKey:@"endTime"];
                        [newShift setValue:endtDate forKey:@"endDate"];
                        [newShift setValue:[schedule valueForKey:@"pendingEndDateTimeIso8601"] forKey:@"pendingEndDateTimeIso8601"];
                        [newShift setValue: [schedule valueForKey:@"pendingStartDateTimeIso8601"] forKey:@"pendingStartDateTimeIso8601"];
                        [newShift setValue:[schedule valueForKey:@"pendingShiftDateString"] forKey:@"pendingShiftDateString"];
                        [newShift setValue:locationId forKey:@"locationId"];
                            
                            locationName = @"";
                            if ((locations != nil) && [locations count] > 0)
                            {
                                for (NSDictionary *loc in locations)
                                {
                                    NSString *locName = [loc valueForKey:@"name"];
                                    NSNumber *locID = [loc valueForKey:@"id"];
                                    if ([locationId intValue] == [locID intValue])
                                        locationName = locName;

                                }
                            }
                        [newShift setValue:locationName forKey:@"locationName"];
                            
                        [newShift setValue:[schedule valueForKey:@"published"] forKey:@"published"];
                        [newShift setValue: [schedule valueForKey:@"modified"] forKey:@"modified"];
                        [newShift setValue: [schedule valueForKey:@"deleted"] forKey:@"deleted"];
                        [dayShifts addObject:newShift];
                      
                        [newSchedule setValue:dayShifts forKey:@"scheduleTimes"];
                      //[newSchedule setValue:scheduleID forKey:@"id"];
                      
                        if (!scheduleExists )
                        {
                          //sort the list
                            NSDate *shiftDateValue = [formatterDate dateFromString:shiftDateString];
                            int pos = -1;
                            int row = 0;
                            NSString *schDate;
                            for (NSMutableDictionary *item in scheduleList) {
                              schDate = [item valueForKey:@"scheduleDate"];
                              NSDate *schDateValue = [formatterLongDate dateFromString:schDate];
                              if ([shiftDateValue compare:schDateValue] == NSOrderedAscending) {
                                  pos = row;
                                  [scheduleList insertObject:newSchedule atIndex:pos];
                                  break;
                              }
                              else row++;
                            }
                            //if we haven't found any dates that come after the one we have then do an add
                            if (pos == -1)
                                [scheduleList addObject:newSchedule];
                      
                        }
                    }
                      
                  }
                  
                }
              }
        
              [_scheduleTable reloadData];
        
            }];
            
}

-(void) callScheduleAPI:(int)flag selectedSchedule: (NSDictionary*) selSchedule withCompletion:(ServerResponseCompletionBlock)completion
{
    if (flag == PUBLISH_SCHEDULES)
        [self startSpinnerWithMessage:@"Publishing Schedule..."];
    else if (flag == DELETE_SCHEDULE)
        [self startSpinnerWithMessage:@"Deleting, please wait..."];
    else
       [self startSpinnerWithMessage:@"Retrieving Data..."];
    
    NSString *httpPostString;
    UserClass *user = [UserClass getInstance];

    NSString *employerID = [user.employerID stringValue];

    NSDictionary *jsonDict;
    NSMutableURLRequest *urlRequest;
    
 //   NSString *employeeID = [arrayOfKeys objectAtIndex:0];
    if (flag == PUBLISH_SCHEDULES)
    {
        httpPostString = [NSString stringWithFormat:@"%@api/v1/schedules/publish", SERVER_URL];

        urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
        
        NSMutableArray *scheduleIdsToPublish = [NSMutableArray new];

        for (NSDictionary *schedule in scheduleList)
        {
            NSDictionary *scheduleTimes = [schedule valueForKey:@"scheduleTimes"];
            for (NSDictionary *schedule in scheduleTimes)
            {

                bool isPublished = [[schedule valueForKey:@"published"] boolValue];
                bool isModified = [[schedule valueForKey:@"modified"] boolValue];
                bool isDeleted = [[schedule valueForKey:@"deleted"] boolValue];
                if (!isPublished || isModified || isDeleted)
                {
                    NSNumber *scheduleId = [schedule valueForKey:@"scheduleId"];
                    [scheduleIdsToPublish addObject: scheduleId];
                }
            }
        }
                
        for (NSNumber* scheduleId in deletedScheduleListIds)
        {
            [scheduleIdsToPublish addObject:scheduleId];
        }

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


    }
    else if (flag == DELETE_SCHEDULE)
    {
        httpPostString = [NSString stringWithFormat:@"%@api/v1/schedules/%@", SERVER_URL,
                          [selSchedule valueForKey:@"scheduleId"]];
        
        urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
        
        NSString *pendingShiftDateString = [selSchedule valueForKey:@"pendingShiftDateString"];
        NSString *pendingStartDateTimeIso8601 = [selSchedule valueForKey:@"pendingStartDateTimeIso8601"];
        NSString *pendingEndDateTimeIso8601 = [selSchedule valueForKey:@"pendingEndDateTimeIso8601"];
        
        NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  
                                  pendingShiftDateString, @"pendingShiftDateString",
                                  pendingStartDateTimeIso8601, @"pendingStartDateTimeIso8601",
                                  pendingEndDateTimeIso8601, @"pendingEndDateTimeIso8601",
                                  [user.employerID stringValue], @"employerId",
                                  [selSchedule valueForKey:@"employeeId"], @"employeeId",
                                  [selSchedule valueForKey:@"notes"], @"pendingNotes",
                                  [selSchedule valueForKey:@"locationId"], @"pendingLocationId",
                                    @"true", @"deleted",
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

        urlRequest.HTTPBody = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
        [urlRequest setHTTPMethod:@"PUT"];
    }
    else //we are just doing a get all schedules
    {
        NSString *periodStart = [formatterLocalDate stringFromDate:startingDate];
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        NSString *timeZoneId = timeZone.name;
        httpPostString = [NSString stringWithFormat:@"%@api/v1/schedules?dateInWeek=%@&timeZoneId=%@", SERVER_URL, periodStart, timeZoneId];
        
        urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
        
        [urlRequest setHTTPMethod:@"GET"];
    }
    
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


@end
