//
//  ScheduleViewController.m
//  ezClocke
//
//  Created by Raya Khashab on 9/23/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "ScheduleViewController.h"
#import "CommonLib.h"
#import "user.h"
#import "MetricsLogWebService.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "PushNotificationManager.h"
#import "NSString+Extensions.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "ScheduleTableViewCell.h"
#import "NSDate+Extensions.h"

@interface ScheduleViewController ()
{
    NSMutableArray *employeeList;
}
@end

@implementation ScheduleViewController

NSString *const ACTION_SELECT_DATE = @"Select Date";

bool showErrorMessage = true;
bool allScheduleOpen = NO;

NSDate *todayDate;

NSDateFormatter *formatterDate, *formatterDateYYYYMMDD;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.title = NSLocalizedString(@"Schedule", @"Schedule");
        self.tabBarItem.image = [UIImage imageNamed:@"calendar"];
        
        formatterISO8601DateTime = [[NSDateFormatter alloc] init];
        [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        
        formatterISO8601Date = [[NSDateFormatter alloc] init];
        [formatterISO8601Date setDateFormat:@"yyyy-MM-dd"];
        [formatterISO8601Date setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _scheduleTable.allowsSelectionDuringEditing = YES;
    _scheduleTable.allowsMultipleSelectionDuringEditing = NO;
    // Do any additional setup after loading the view.
/*    pickerViewDate = [[UIActionSheet alloc] initWithTitle:@""
                                                 delegate:nil
                                        cancelButtonTitle:nil
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:nil];
 */
 //   [self.totalHoursCell.contentView.layer setBorderColor:[UIColor blackColor].CGColor];
 //   [self.totalHoursCell.contentView.layer setBorderWidth:1.0f];

    _totalHoursView.backgroundColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR);
    _totalHoursCol.textColor = [UIColor whiteColor];
    self.totalHoursLabel.textColor = [UIColor whiteColor];
    self.totalHoursValue.textColor = [UIColor whiteColor];

    [self setFramePicker];

    theDatePicker.datePickerMode = UIDatePickerModeDate;
    theDatePicker.hidden = NO;
//    NSDate *date = [NSDate date];
//    theDatePicker.date = date;

    
//    theDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0, 44.0, 0.0, 0.0)];
//    theDatePicker.datePickerMode = UIDatePickerModeDate;
//    [UIView appearanceWhenContainedIn:[UITableView class], [UIDatePicker class], nil].backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    
//    [theDatePicker addTarget:self action:nil forControlEvents:UIControlEventValueChanged];
    
    theDatePicker.backgroundColor = [UIColor whiteColor];

    formatterDate = [[NSDateFormatter alloc] init];
    [formatterDate setLocale: [[NSLocale alloc]
                               initWithLocaleIdentifier:@"en_US"]];
    [formatterDate setDateFormat:@"MM/dd/yyyy"];
    
    formatterDateYYYYMMDD = [[NSDateFormatter alloc] init];
    [formatterDateYYYYMMDD setLocale: [[NSLocale alloc]
                               initWithLocaleIdentifier:@"en_US"]];
    [formatterDateYYYYMMDD setDateFormat:@"yyyy-MM-dd"];

    _shiftDate.font = [UIFont boldSystemFontOfSize:24.0f];
    _nextShiftLabel.font = [UIFont boldSystemFontOfSize:24.0f];
    
    scheduleList = [[NSMutableArray alloc] initWithCapacity:0];
    //init starting date with today's date
    startingDate = [[NSDate alloc] init];
    todayDate = startingDate;
    _nextShiftLabel.text = @"";
    _shiftDate.text = @"";

   // _nextShiftCell.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    
    _nextShiftView.backgroundColor = [UIColor orangeColor];
    
    NSString *todayDateSr = [formatterDate stringFromDate:startingDate];
    [_selectDateButton setTitle:todayDateSr forState:UIControlStateNormal];
    _selectDateButton.titleLabel.font = [UIFont systemFontOfSize:20];
   // [selectDateButton.titleLabel setFont:[UIFont fontWithName:@"System-Bold" size:24.0]];
    [_selectDateButton addTarget:self action:@selector(doChangeDate) forControlEvents:UIControlEventTouchUpInside];


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
    
    CGFloat Y = screenHeight - kbHeight;// + safeAreaBottomHeight + safeAreaTopHeight);
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


- (void)viewDidUnload
{
    theDatePicker = nil;
    pickerToolbar = nil;
    pickerViewDate = nil;
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    startingDate = [[NSDate alloc] init];
    todayDate = startingDate;
    NSString *todayDateSr = [formatterDate stringFromDate:startingDate];
    [_selectDateButton setTitle:todayDateSr forState:UIControlStateNormal];

    PushNotificationManager* manager = [PushNotificationManager sharedManager];
    PushNotification* gotoSchedule = manager.gotoSchedule;
    if (gotoSchedule) {
        NSString* message = gotoSchedule.alert;
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Alert" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:^{
            
        }];
    }
 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    allScheduleOpen = NO;
    UserClass *user = [UserClass getInstance];
    if (user.seeCoworkersScheduleAllowed) {
        [self.pagerView setHidden:NO];
        self.pagerViewHeight.constant = 50;
        [self AllEmployeeList];
      //  self.title = @"Schedule";
    } else {
        [self.pagerView setHidden:YES];
        self.pagerViewHeight.constant = 0;
        [self setSchedule];
     //   self.title = @" My Schedule";
        
    }
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];

    
 //   actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonAction)];
    
    
//    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:actionButton, nil];
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    self.slidingViewController.underRightViewController = nil;
    
   // [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
#ifdef IPAD_VERSION
    self.navigationItem.leftBarButtonItems = nil;
#endif

//    if (allScheduleOpen) {
//        [self setAllSchedule];
//    } else {
//        [self setSchedule];
//    }
}
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    UIView *view = [cancelButton valueForKey:@"view"];
    
    [SharedUICode yesNoCancel:nil message:@"Delete Shift.  Are you sure?" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing"  rootControl:view withCompletion:^(YesNoCancelResult Result) {
        switch (Result) {
            case resultYes: {
                [self deleteLocationAtIndexPath:indexPath];
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

- (void)deleteLocationAtIndexPath:(NSIndexPath*)indexPath {
  //  UserClass *user = [UserClass getInstance];
  //  NSMutableDictionary *location =  [user.locationNameAddressList objectAtIndex:indexPath.row];
  //  NSNumber *locID = [location valueForKey:@"id"];
    [_scheduleTable setEditing:NO animated: YES];
    [self onCancelClick:self];
    //    editFlag = NO;
    //    [self callDeleteLocation: locID];
    
    [self startSpinnerWithMessage:@"Deleting, please wait..."];
    
   /* [self callDeleteLocation:locID withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        else{
            [user.locationNameAddressList removeObjectAtIndex:indexPath.row];
            // Delete the row from the data source
            [_scheduleTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
    */
}

- (void)setEditButtons {
    if (_scheduleTable.editing) {
        [self setEditing:NO animated:TRUE];
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
        [self setEditing:NO animated:YES];
        //        [self __cancelEditing];
        return;
    }
    
    //    [self beforeEditingBegins];
    [self setEditing:YES animated:YES];
    
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelClick:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.navigationItem.rightBarButtonItems = nil;
    
}


- (IBAction)onEditClick:(id)sender {
    [self setEditState];
}

-(void)DatePickerView
{
    //set the date picker to the starting date which is equal to the select date button text
    theDatePicker.date = startingDate;
    
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
    navController.view.superview.center = self.view.center;
#else
    theDatePicker.frame = CGRectMake(0, theDatePicker.frame.origin.y, UIScreen.mainScreen.bounds.size.width, theDatePicker.frame.size.height);
    [pickerViewDate addSubview:pickerToolbar];
    [pickerViewDate addSubview:theDatePicker];
    [self.view addSubview:pickerViewDate];
#endif
}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([scheduleList count] == 0) {
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
        int tmp = (int) [dayShifts count];
        return tmp;
    }
    else {
        return 0;
    }
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSDictionary *daySchedule;
    daySchedule = [scheduleList objectAtIndex:indexPath.section];
    NSArray *dayShifts = [daySchedule valueForKey:@"scheduleTimes"];
    NSDictionary *dayShiftInfo = [dayShifts objectAtIndex:indexPath.row];
    NSNumber *shiftLocId = [dayShiftInfo valueForKey:@"shiftLocId"];
    NSString *shiftNotes = [dayShiftInfo valueForKey:@"notes"];
    if ([NSString isNilOrEmpty:shiftNotes])
        shiftNotes = @"";


    if (!self.shiftDetailsViewController){
        self.shiftDetailsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ShiftDetails"];

        self.shiftDetailsViewController.delegate = (id) self;
    }
    // ...
    // Pass the selected object to the new view controller.

    self.shiftDetailsViewController.shiftLocId = shiftLocId;
    
    self.shiftDetailsViewController.shiftNotes = shiftNotes;
    
    [self.navigationController pushViewController:self.shiftDetailsViewController animated:YES];
    
    
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserClass *user = [UserClass getInstance];
    if([user.userType isEqualToString:TEAM_USER_TYPE])
        return nil;
    else
        return indexPath;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ScheduleTableViewCell";
    ScheduleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//    }
    
    NSDictionary *daySchedule;
    daySchedule = [scheduleList objectAtIndex:indexPath.section];
    NSArray *dayShifts = [daySchedule valueForKey:@"scheduleTimes"];
    NSDictionary *dayShiftInfo = [dayShifts objectAtIndex:indexPath.row];
    NSString *shiftTime = [dayShiftInfo valueForKey:@"shiftTime"];
    NSString *shiftLocationName = [dayShiftInfo valueForKey:@"locationName"];
    
    if (allScheduleOpen) {
        NSString *emp = [[dayShiftInfo valueForKey:@"employeeId"] stringValue];
        for (NSDictionary *scheduleDic in employeeList) {
            NSString *temp = [scheduleDic[@"ID"] stringValue];
            if ([temp isEqualToString:emp]) {
                cell.nameLabel.text = scheduleDic[@"Name"];
                break;
            }
        }
    } else {
        if (![NSString isNilOrEmpty:shiftLocationName])
            cell.nameLabel.text = shiftLocationName;
        else
            cell.nameLabel.text = @"";
    }
    cell.timeLabel.textColor = UIColorFromRGB(EZCLOCKER_BLUE_COLOR);
    cell.timeLabel.text = shiftTime;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //if (allScheduleOpen) {
        return 70;
  //  } else {
  //      return 44;
  //  }
}

- (void)shiftDetailsViewDidFinish:(ShiftDetailsViewController *)controller
{
    [self.navigationController popViewControllerAnimated:YES];
}


/*-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
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

         //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
         //   [alert show];
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

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//    if (mode == OperationGet)
//    {
           [self stopSpinner];
    
    //clear the prev schedule
    [scheduleList removeAllObjects];
    NSError *error = nil;
    NSString *schStartTime;
    NSString *shiftDateString;
    NSString *schEndTime;
    NSDictionary *newSchedule;
   
 
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
        NSString *resultMessage = [results valueForKey:@"message"];
        

       if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from ScheduleViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
           //if we've already shown an error to the user don't bug him again
           if (showErrorMessage){
               UIAlertController * alert = [UIAlertController
                                            alertControllerWithTitle:@"ERROR"
                                            message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                            preferredStyle:UIAlertControllerStyleAlert];
               
               UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
               
               [alert addAction:defaultAction];
               
               [self presentViewController:alert animated:YES completion:nil];

           //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Server Failure" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            //   [alert show];
           }
        }
        else {
            
  
    
            NSDateFormatter *formatterDateTime12 = [[NSDateFormatter alloc] init];
            [formatterDateTime12 setDateFormat:@"h:mm a"];
            
            NSDateFormatter *formatterDateFromServer = [[NSDateFormatter alloc] init];
            [formatterDateFromServer setDateFormat:@"MM/dd/yyyy"];
            
            NSDateFormatter *formatterLongDate = [[NSDateFormatter alloc] init];
            //this gives me Monday, Tuesday..etc.
            [formatterLongDate setDateFormat:@"EEEE, MMM dd, yyyy"];
    

            NSArray *schedules = [results valueForKey:@"schedules"];
            NSString *shiftTime;
            NSDate *nextShiftDate;
            NSDictionary *nextShiftDateDict, *shiftInfo;
            NSNumber *shiftLocId;
            NSString *shiftNotes;
            NSDate *DateValue;
            NSString *startTime;
            NSString *endTime;

            nextShiftDateDict = [results valueForKey:@"nextShift"];
            
            if (![nextShiftDateDict isEqual:[NSNull null]] && (nextShiftDateDict != nil)){
            
                schStartTime = [nextShiftDateDict valueForKey:@"startDateTimeIso8601"];
                startTime  = [schStartTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
            
                DateValue = [formatterISO8601DateTime dateFromString:schStartTime];
                nextShiftDate = DateValue;
                startTime = [formatterDateTime12 stringFromDate:DateValue];

                schEndTime = [nextShiftDateDict valueForKey:@"endDateTimeIso8601"];
                endTime  = [schEndTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
            
                DateValue = [formatterISO8601DateTime dateFromString:schEndTime];
                endTime = [formatterDateTime12 stringFromDate:DateValue];
                shiftTime = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
            
                shiftDateString = [nextShiftDateDict valueForKey:@"shiftDateString"];
                DateValue = [formatterDateFromServer dateFromString:shiftDateString];
                shiftDateString = [formatterDate stringFromDate:DateValue];
               
                _nextShiftLabel.text = shiftTime;
                _shiftDate.text = shiftDateString;
            }

            else{
                _shiftDate.text = @"You don't have ";
                _nextShiftLabel.text = @"a shift scheduled";
            }
            
            NSString *totalHours = [results valueForKey:@"totalTimeForPeriod"];
            if (![totalHours isEqual:[NSNull null]] && (totalHours != nil))
                _totalHoursValue.text = totalHours;

            for (NSDictionary *schedule in schedules){
                
                
                schStartTime = [schedule valueForKey:@"startDateTimeIso8601"];
                startTime  = [schStartTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                
                NSDate *DateValue = [formatterISO8601DateTime dateFromString:schStartTime];
//                nextShiftDate = DateValue;
                startTime = [formatterDateTime12 stringFromDate:DateValue];
 //               shiftDate = [formatterDate stringFromDate:DateValue];
                
                schEndTime = [schedule valueForKey:@"endDateTimeIso8601"];
                endTime  = [schEndTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                
                DateValue = [formatterISO8601DateTime dateFromString:schEndTime];
                endTime = [formatterDateTime12 stringFromDate:DateValue];

                shiftDateString = [schedule valueForKey:@"shiftDateString"];
                DateValue = [formatterDateFromServer dateFromString:shiftDateString];
                shiftDateString = [formatterLongDate stringFromDate:DateValue];
                
                shiftLocId = [schedule valueForKey:@"locationId"];
                
                shiftNotes = [schedule valueForKey:@"notes"];


                //check if the date is already in the list
               
                newSchedule = [[NSMutableDictionary alloc] init];
                shiftInfo =   [[NSMutableDictionary alloc] init];
                [shiftInfo setValue:shiftLocId forKey:@"shiftLocId"];
                [shiftInfo setValue:shiftNotes forKey:@"notes"];
                
                shiftTime = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
                [shiftInfo setValue:shiftTime forKey:@"shiftTime"];
                
                NSMutableArray *dayShifts;// = [[NSMutableArray alloc] initWithCapacity:0];
                
                
                //check if the date is already in the list
                int idx = [self FindScheduleDate:shiftDateString];
                //if not found
                bool scheduleExists = idx != -1;
                if (!scheduleExists )
                {
                    newSchedule = [[NSMutableDictionary alloc] init];
                    [newSchedule setValue:shiftDateString forKey:@"shiftDateString"];
                    dayShifts = [[NSMutableArray alloc] initWithCapacity:0];
                    [newSchedule setValue:shiftDateString forKey:@"scheduleDate"];
                }
                else{
                    newSchedule = [scheduleList objectAtIndex:idx];
                    dayShifts = [newSchedule valueForKey:@"scheduleTimes"];
                }

                [dayShifts addObject:shiftInfo];

//                shiftTime = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
//                [dayShifts addObject:shiftTime];
                
                [newSchedule setValue:dayShifts forKey:@"scheduleTimes"];
 
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
                
                
//                [scheduleList addObject:newSchedule];
                
                
        }
                

    }
        [_scheduleTable reloadData];
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

 //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
 //   [alert show];
    
    connection = nil;
    data = nil;
}
 
 */

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


-(void) callGetEmployeeSchedule{
    [self callGetEmployeeScheduleAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //clear the prev schedule
            [scheduleList removeAllObjects];
            NSError *error = nil;
            NSString *schStartTime;
            NSString *shiftDateString;
            NSString *schEndTime;
            NSDictionary *newSchedule;
           
         
         //   NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
                NSString *resultMessage = [aResults valueForKey:@"message"];
                

               if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
                    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from ScheduleViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                   //if we've already shown an error to the user don't bug him again
                   if (showErrorMessage){
                       UIAlertController * alert = [UIAlertController
                                                    alertControllerWithTitle:@"ERROR"
                                                    message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                                    preferredStyle:UIAlertControllerStyleAlert];
                       
                       UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                       
                       [alert addAction:defaultAction];
                       
                       [self presentViewController:alert animated:YES completion:nil];

                   //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Server Failure" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    //   [alert show];
                   }
                }
                else {
                    
                    
            
                    NSDateFormatter *formatterDateTime12 = [[NSDateFormatter alloc] init];
                    [formatterDateTime12 setDateFormat:@"h:mm a"];
                    [formatterDateTime12 setTimeZone:[NSTimeZone localTimeZone]];
                    
                    NSDateFormatter *formatterDateFromServer = [[NSDateFormatter alloc] init];
                    [formatterDateFromServer setDateFormat:@"MM/dd/yyyy"];
                    [formatterDateFromServer setTimeZone:[NSTimeZone localTimeZone]];

                    
                    NSDateFormatter *formatterLongDate = [[NSDateFormatter alloc] init];
                    //this gives me Monday, Tuesday..etc.
                    [formatterLongDate setDateFormat:@"EEEE, MMM dd, yyyy"];
                    [formatterLongDate setTimeZone:[NSTimeZone localTimeZone]];


                    NSArray *schedules = [aResults valueForKey:@"schedules"];
                    NSArray *locations = [aResults valueForKey:@"scheduleLocations"];
                    NSString *shiftTime;
                    NSDate *nextShiftDate;
                    NSDictionary *nextShiftDateDict, *shiftInfo;
                    NSNumber *shiftLocId;
                    NSString *shiftNotes;
                    NSDate *DateValue;
                    NSString *startTime;
                    NSString *endTime;
                    NSString *locationName;

                    nextShiftDateDict = [aResults valueForKey:@"nextShift"];
                    
                    if (![nextShiftDateDict isEqual:[NSNull null]] && (nextShiftDateDict != nil)){
                    
                        schStartTime = [nextShiftDateDict valueForKey:@"startDateTimeIso8601"];
                        startTime  = [schStartTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                    
                        DateValue = [formatterISO8601DateTime dateFromString:schStartTime];
                        nextShiftDate = DateValue;
                        startTime = [formatterDateTime12 stringFromDate:DateValue];

                        schEndTime = [nextShiftDateDict valueForKey:@"endDateTimeIso8601"];
                        endTime  = [schEndTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                    
                        DateValue = [formatterISO8601DateTime dateFromString:schEndTime];
                        endTime = [formatterDateTime12 stringFromDate:DateValue];
                        shiftTime = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
                    
                        shiftDateString = [nextShiftDateDict valueForKey:@"shiftDateString"];
                        DateValue = [formatterDateFromServer dateFromString:shiftDateString];
                        shiftDateString = [formatterDate stringFromDate:DateValue];
                       
                        _nextShiftLabel.text = shiftTime;
                        _shiftDate.text = shiftDateString;
                    }

                    else{
                        _shiftDate.text = @"You don't have ";
                        _nextShiftLabel.text = @"a shift scheduled";
                    }
                    
                    NSString *totalHours = [aResults valueForKey:@"totalTimeForPeriod"];
                    if (![totalHours isEqual:[NSNull null]] && (totalHours != nil))
                        _totalHoursValue.text = totalHours;

                    for (NSDictionary *schedule in schedules){
                        
                        
                        schStartTime = [schedule valueForKey:@"startDateTimeIso8601"];
                      //  startTime  = [schStartTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                        
                        NSDate *DateValue = [formatterISO8601DateTime dateFromString:schStartTime];
                        
        //                nextShiftDate = DateValue;
                        startTime = [formatterDateTime12 stringFromDate:DateValue];
                        NSString *strDateValue = @"Not Null!";
                       if ([NSString isNilOrEmpty:startTime])
                       {
                           if ([NSDate isNilOrNull:DateValue])
                           {
                               strDateValue = @"is Null!";
                           }
                           [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from ScheduleViewController startTime is null. schStartTime = %@ DateValue= %@", schStartTime, strDateValue]];

                       }
            
         //               shiftDate = [formatterDate stringFromDate:DateValue];
                        
                        schEndTime = [schedule valueForKey:@"endDateTimeIso8601"];
                        endTime  = [schEndTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                        
                        DateValue = [formatterISO8601DateTime dateFromString:schEndTime];
                        endTime = [formatterDateTime12 stringFromDate:DateValue];

                        shiftDateString = [schedule valueForKey:@"shiftDateString"];
                        DateValue = [formatterDateFromServer dateFromString:shiftDateString];
                        shiftDateString = [formatterLongDate stringFromDate:DateValue];
                        
                        shiftLocId = [schedule valueForKey:@"locationId"];
                        
                        shiftNotes = [schedule valueForKey:@"notes"];


                        //check if the date is already in the list
                       
                        newSchedule = [[NSMutableDictionary alloc] init];
                        shiftInfo =   [[NSMutableDictionary alloc] init];
                        [shiftInfo setValue:shiftLocId forKey:@"shiftLocId"];
                        locationName = @"";
                        if ((locations != nil) && [locations count] > 0)
                        {
                            for (NSDictionary *loc in locations)
                            {
                                NSString *locName = [loc valueForKey:@"name"];
                                NSNumber *locID = [loc valueForKey:@"id"];
                                if ([shiftLocId intValue] == [locID intValue])
                                    locationName = locName;

                            }
                        }
                        [shiftInfo setValue:locationName forKey:@"locationName"];

                        [shiftInfo setValue:shiftNotes forKey:@"notes"];
                        
                        shiftTime = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
                        [shiftInfo setValue:shiftTime forKey:@"shiftTime"];
                        
                        NSMutableArray *dayShifts;// = [[NSMutableArray alloc] initWithCapacity:0];
                        
                        
                        //check if the date is already in the list
                        int idx = [self FindScheduleDate:shiftDateString];
                        //if not found
                        bool scheduleExists = idx != -1;
                        if (!scheduleExists )
                        {
                            newSchedule = [[NSMutableDictionary alloc] init];
                            [newSchedule setValue:shiftDateString forKey:@"shiftDateString"];
                            dayShifts = [[NSMutableArray alloc] initWithCapacity:0];
                            [newSchedule setValue:shiftDateString forKey:@"scheduleDate"];
                        }
                        else{
                            newSchedule = [scheduleList objectAtIndex:idx];
                            dayShifts = [newSchedule valueForKey:@"scheduleTimes"];
                        }

                        [dayShifts addObject:shiftInfo];

        //                shiftTime = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
        //                [dayShifts addObject:shiftTime];
                        
                        [newSchedule setValue:dayShifts forKey:@"scheduleTimes"];
         
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
                        
                        
        //                [scheduleList addObject:newSchedule];
                        
                        
                }
                        

            }
                [_scheduleTable reloadData];

        }
    }];
}


-(void) GetAllEmployeeSchedule {
    [self callGetAllEmployeeScheduleAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //clear the prev schedule
            [scheduleList removeAllObjects];
            NSError *error = nil;
            NSString *schStartTime;
            NSString *shiftDateString;
            NSString *schEndTime;
            NSDictionary *newSchedule;
           
         
         //   NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
                NSString *resultMessage = [aResults valueForKey:@"message"];
                

               if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
                    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from ScheduleViewController GetAllSchedules JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                   //if we've already shown an error to the user don't bug him again
                   if (showErrorMessage){
                       UIAlertController * alert = [UIAlertController
                                                    alertControllerWithTitle:@"ERROR"
                                                    message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                                    preferredStyle:UIAlertControllerStyleAlert];
                       
                       UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                       
                       [alert addAction:defaultAction];
                       
                       [self presentViewController:alert animated:YES completion:nil];

                   //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Server Failure" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    //   [alert show];
                   }
                }
                else {
                    
          
            
                    NSDateFormatter *formatterDateTime12 = [[NSDateFormatter alloc] init];
                    [formatterDateTime12 setDateFormat:@"h:mm a"];
                    
                    NSDateFormatter *formatterDateFromServer = [[NSDateFormatter alloc] init];
                    [formatterDateFromServer setDateFormat:@"MM/dd/yyyy"];
                    
                    NSDateFormatter *formatterLongDate = [[NSDateFormatter alloc] init];
                    //this gives me Monday, Tuesday..etc.
                    [formatterLongDate setDateFormat:@"EEEE, MMM dd, yyyy"];
            

                    NSArray *schedules = [aResults valueForKey:@"schedules"];
                    NSString *shiftTime;
                    NSDictionary *shiftInfo;
                    NSNumber *shiftLocId;
                    NSString *shiftNotes;

                    NSString *startTime;
                    NSString *endTime;

                    
                    NSString *totalHours = [aResults valueForKey:@"totalTimeForPeriod"];
                    if (![totalHours isEqual:[NSNull null]] && (totalHours != nil))
                        _totalHoursValue.text = totalHours;

                    for (NSDictionary *schedule in schedules){
                      //since this is an employee who is viewing all schedles, only show what's published
                      bool isPublished = [[schedule valueForKey:@"published"] boolValue];
                      if (isPublished)
                      {
                        schStartTime = [schedule valueForKey:@"startDateTimeIso8601"];
                        startTime  = [schStartTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                        
                        NSDate *DateValue = [formatterISO8601DateTime dateFromString:schStartTime];
        //                nextShiftDate = DateValue;
                        startTime = [formatterDateTime12 stringFromDate:DateValue];
         //               shiftDate = [formatterDate stringFromDate:DateValue];
                        
                        schEndTime = [schedule valueForKey:@"endDateTimeIso8601"];
                        endTime  = [schEndTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                        
                        DateValue = [formatterISO8601DateTime dateFromString:schEndTime];
                        endTime = [formatterDateTime12 stringFromDate:DateValue];

                        shiftDateString = [schedule valueForKey:@"shiftDateString"];
                        DateValue = [formatterDateFromServer dateFromString:shiftDateString];
                        shiftDateString = [formatterLongDate stringFromDate:DateValue];
                        
                        shiftLocId = [schedule valueForKey:@"locationId"];
                        
                        shiftNotes = [schedule valueForKey:@"notes"];


                        //check if the date is already in the list
                       
                        newSchedule = [[NSMutableDictionary alloc] init];
                        shiftInfo =   [[NSMutableDictionary alloc] init];
                        [shiftInfo setValue:shiftLocId forKey:@"shiftLocId"];
                        [shiftInfo setValue:shiftNotes forKey:@"notes"];
                        
                        shiftTime = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
                        [shiftInfo setValue:shiftTime forKey:@"shiftTime"];
                        [shiftInfo setValue:[schedule valueForKey:@"employeeId"] forKey:@"employeeId"];
                        NSMutableArray *dayShifts;// = [[NSMutableArray alloc] initWithCapacity:0];
                        
                        
                        //check if the date is already in the list
                        int idx = [self FindScheduleDate:shiftDateString];
                        //if not found
                        bool scheduleExists = idx != -1;
                        if (!scheduleExists )
                        {
                            newSchedule = [[NSMutableDictionary alloc] init];
                            [newSchedule setValue:shiftDateString forKey:@"shiftDateString"];
                            dayShifts = [[NSMutableArray alloc] initWithCapacity:0];
                            [newSchedule setValue:shiftDateString forKey:@"scheduleDate"];
                        }
                        else{
                            newSchedule = [scheduleList objectAtIndex:idx];
                            dayShifts = [newSchedule valueForKey:@"scheduleTimes"];
                        }

                        [dayShifts addObject:shiftInfo];

        //                shiftTime = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
        //                [dayShifts addObject:shiftTime];
                        
                        [newSchedule setValue:dayShifts forKey:@"scheduleTimes"];
         
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
                        
                        
        //                [scheduleList addObject:newSchedule];
                        
                        }
                }
                        

            }
                [_scheduleTable reloadData];

        }
    }];
}

-(void) callGetAllEmployeeScheduleAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    [self startSpinnerWithMessage:@"Connecting to Server.."];
    showErrorMessage = true;
 //   mode = OperationGet;

    NSString *httpPostString;
    UserClass *user = [UserClass getInstance];
//    NSString *employeeIDStr = [NSString stringWithFormat:@"%@", user.userID];
    
 //   NSString *periodStart = [formatterISO8601Date stringFromDate:startingDate];
    NSString *periodStart = [formatterDateYYYYMMDD stringFromDate:startingDate];
//    periodStart  = [periodStart stringByReplacingOccurrencesOfString:@"+0000" withString:@"Z"];
//    periodStart  = [periodStart stringByReplacingOccurrencesOfString:@"-0000" withString:@"Z"];

    
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    
//    httpPostString = [NSString stringWithFormat:@"%@employee/%@/schedules?days=7&periodStartDate=%@&timeZoneId=%@", SERVER_URL, user.userID, periodStart, timeZoneId];
    httpPostString = [NSString stringWithFormat:@"%@api/v1/schedules?dateInWeek=%@&timeZoneId=%@", SERVER_URL, periodStart, timeZoneId];

   // dateInWeek ISO date
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];

    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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

    
    //set request url to the NSURLConnection
   /* NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
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

      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
    */
        
    }
-(void) callGetEmployeeScheduleAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    [self startSpinnerWithMessage:@"Connecting to Server.."];
    showErrorMessage = true;
 //   mode = OperationGet;

    NSString *httpPostString;
    UserClass *user = [UserClass getInstance];
    
    NSString *periodStart = [formatterDateYYYYMMDD stringFromDate:startingDate];
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    
//    httpPostString = [NSString stringWithFormat:@"%@employee/%@/schedules?days=7&periodStartDate=%@&timeZoneId=%@", SERVER_URL, user.userID, periodStart, timeZoneId];
    httpPostString = [NSString stringWithFormat:@"%@employee/%@/schedules?dateInWeek=%@&timeZoneId=%@", SERVER_URL, user.userID, periodStart, timeZoneId];

   // dateInWeek ISO date
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];

    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"employerId"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"authToken"];
    
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

    
    //set request url to the NSURLConnection
   /* NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
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

      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
    */
        
    }
    
    
-(void) getEmployeesList:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    UserClass *user = [UserClass getInstance];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/thin/employee", SERVER_URL];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    urlRequest.timeoutInterval = TIME_OUT_REQUEST;
    
    
    //set HTTP Method
    //  [urlRequest setHTTPMethod:@"POST"];
    
    [urlRequest setHTTPMethod:@"GET"];
    //    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:[user.employerID stringValue] forHTTPHeaderField:@"x-ezclocker-employerId"];
    [urlRequest setValue:user.authToken forHTTPHeaderField:@"x-ezclocker-authToken"];
    
    
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

-(void) AllEmployeeList
{
    [self startSpinnerWithMessage:@"Updating, please wait..."];
    
    [self getEmployeesList:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            NSArray *employees = [results valueForKey:@"employees"];
            NSLog(@"employees :: %@", employees);
//            [employeeList removeAllObjects];
            employeeList = [[NSMutableArray alloc] init];
            for (NSDictionary *employee in employees){
                NSMutableDictionary *employeeObj = [[NSMutableDictionary alloc] init];
                NSString *name = [employee valueForKey:@"employeeName"];
                NSString *employeeID = [employee valueForKey:@"id"];
                [employeeObj setValue:name forKey:@"Name"];
                [employeeObj setValue:employeeID forKey:@"ID"];
                [employeeList addObject:employeeObj];
            }
            if (allScheduleOpen) {
                [self setAllSchedule];
            } else {
                [self setSchedule];
            }
            
        }
    }];
    
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
    
    if (allScheduleOpen)
        [self GetAllEmployeeSchedule];
    else
        [self callGetEmployeeSchedule];

}



-(IBAction)DatePickerCancelClick{
    [self closeDatePicker:self];
}


-(void) updateCurrentSelectedDate:(NSDate*)newDate{
    startingDate = newDate;
    [_selectDateButton setTitle:[formatterDate stringFromDate:startingDate] forState:UIControlStateNormal];
}

- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)myScheduleButtonClicked:(id)sender {
    [scheduleList removeAllObjects];
    [_scheduleTable reloadData];
    [self setSchedule];
    allScheduleOpen = NO;
}

- (void)allScheduleButtonClicked:(id)sender {
    [scheduleList removeAllObjects];
      [_scheduleTable reloadData];
    [self setAllSchedule];
    allScheduleOpen = YES;
}

-(void)setAllSchedule {
    CGFloat leading = (self.view.frame.size.width / 2.0);
    _pagerLeadingConstraint.constant = leading;
    [_nextShiftView setHidden:YES];
    _shiftViewHeight.constant = 0;
    [self GetAllEmployeeSchedule];
}

-(void)setSchedule {
    _pagerLeadingConstraint.constant = 0;
    [_nextShiftView setHidden:NO];
    _shiftViewHeight.constant = 112;
    [self callGetEmployeeSchedule];
}

- (IBAction)doChangeDate{
    [self DatePickerView];
}

- (IBAction)doChangeDateBtnClick:(id)sender {
    [self doChangeDate];
}

- (IBAction)doPrevDateClick:(id)sender {
    
    
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.day = -7;
    NSDate *newDate = [[NSCalendar currentCalendar]dateByAddingComponents:dateComponents
                                                                   toDate: startingDate options:0];
    [self updateCurrentSelectedDate:newDate];
    if (allScheduleOpen)
        [self GetAllEmployeeSchedule];
    else
        [self callGetEmployeeSchedule];
}

- (IBAction)doNextDateClick:(id)sender {
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.day = 7;
    NSDate *newDate = [[NSCalendar currentCalendar]dateByAddingComponents:dateComponents
                                                                   toDate: startingDate
                                                                  options:0];
    [self updateCurrentSelectedDate:newDate];
    
    if (allScheduleOpen)
        [self GetAllEmployeeSchedule];
    else
        [self callGetEmployeeSchedule];
}
@end
