//
//  TimeSheetMasterViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "TimeSheetMasterViewController.h"
#import "AddTimeEntryViewController.h"
#import "TimeSheetDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "user.h"
#import "CommonLib.h"
#import "EmailTimeSheetViewController.h"
#import "ECSlidingViewController.h"
#import "MetricsLogWebService.h"
#import "EmailFeedbackViewController.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "DataManager.h"
#import "Employee+Extensions.h"
#import "Employee.h"
#import "DayHistoryItem.h"
#import "DayHistoryItem+CoreDataProperties.h"
#import "ClockInfo+CoreDataProperties.h"
#import "ClockInfo+Extensions.h"
#import "SharedUICode.h"
#import "completionblockdefines.h"
#import "coredatadefines.h"
#import "TimeEntry+Extensions.h"
#import "DateRangeViewController.h"
#import <StoreKit/StoreKit.h>
#import "CustomersViewController.h"


@interface TimeSheetMasterViewController () <StartEndDateInterface, TimeSheetDetailViewControllerDelegate, WWCalendarTimeSelectorProtocol>
{
}

@property (nonatomic, copy) NSString *startdate;
@property (nonatomic, copy) NSString *enddate;
@property (nonatomic, copy) NSString *selectedFromDateValue;
@property (nonatomic, copy )NSString *selectedToDateValue;
@property (nonatomic, assign) DateRangeMode curDateRangeActive;
@property (nonatomic, assign) bool fetchData;
@property (nonatomic, retain) UIRefreshControl* refreshControl;

@end

@implementation TimeSheetMasterViewController
@synthesize TimeEntryTableView;
@synthesize timeEntryItems;
@synthesize employeeID;
@synthesize employeeName;
@synthesize refreshControl;

UIButton *fromDateBtn, *toDateBtn;
//UIImagePickerController* imagePickerController;
UIDatePicker *theDatePicker;
UIToolbar* pickerToolbar;
UIView* pickerViewDate;
//set the color and gradient


//NSString *const ADD_TIME_ENTRY = @"Add Time Entry";
NSString *const EMAIL_TIME_SHEET = @"Email Time Sheet";

- (void)initValues {
    self.startdate= @"";
    self.enddate = @"";
    self.selectedFromDateValue = @"";
    self.selectedToDateValue = @"";
    self.fetchData = true;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.title = NSLocalizedString(@"Time Sheet", @"Time Sheet");
        self.tabBarItem.image = [UIImage imageNamed:@"folder"];
        user = [UserClass getInstance];
        [self initValues];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //   editFlag = NO;
    
    //    ratingDialogType = EnjoyingEzClokcer_dlg;
    ratingDialogType = Feedback_None;
    
    timeEntryItems = [[NSMutableDictionary alloc] initWithCapacity:0];
    TimeEntryTableView.allowsSelectionDuringEditing = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    TimeEntryTableView.contentInset = UIEdgeInsetsMake(0., 0., CGRectGetHeight(self.tabBarController.tabBar.frame), 0);
    
    popoverContent = [[UIViewController alloc] init];
    
    //ios 7
    self.navigationController.navigationBar.translucent = NO;
    
    
    [_selectDateButton1 addTarget:self action:@selector(doChangeDate) forControlEvents:UIControlEventTouchUpInside];
    
    
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Please wait..."];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    [TimeEntryTableView addSubview:refreshControl];
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(dataManagerProcessCompleteNotification:) name:kDataManagerProcessCompleteNotification object:nil];
    [center addObserver:self selector:@selector(refreshData) name:@"RefreshEmployeeData" object:nil];
    
    [self initColorsAndImages];
    if (_fromCustomerDetail == YES) {
        
        UIButton* backButton = [UIButton buttonWithType: UIButtonTypeCustom];
        [backButton setFrame:CGRectMake(0, 0, 50, 50)];
        backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -40, 0, 0);
        
        [backButton setImage:[UIImage imageNamed:@"icArrowBack"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(Back_btn:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *modalButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        [self.navigationItem setLeftBarButtonItem:modalButton animated:YES];
        
        [self.menuBarItem setBackgroundVerticalPositionAdjustment:-100.0f forBarMetrics:UIBarMetricsDefault];
    } else {
        //        [self.backInsideButton setContentEdgeInsets:UIEdgeInsetsMake(0, -500, 0, 0)];
    }
    
    [center addObserver:self
               selector:@selector(reciveAddTimeEntry:)
                   name:kDataWasModifiedNotification
                 object:nil];
}

-(IBAction)Back_btn:(id)sender
{
    //Your code here
    [self.previousNavigation setNavigationBarHidden:NO];
    [self.previousNavigation popViewControllerAnimated:NO];
}

- (void)dataManagerProcessCompleteNotification:(NSNotification*)notification {
    // This will be called when force sync as well as after an item is deleted for clock in/clock out because it already existed according to the server.
    // Just simply reloadData
    //This may be causing the crash in Crashlytics where indexPath.row > then the row count
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.TimeEntryTableView reloadData];
    });
}

- (void)reciveAddTimeEntry:(NSNotification*)notification {
    _TotalHoursLabel.text = @"0h 0m";
    
    DataManager* manager = [DataManager sharedManager];
    if (!manager.isBusy) {
        NSError* error = nil;
        NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&error];
        if (nil == error) {
            if (0 == count && [CommonLib DoWeHaveNetworkConnection]) {
                [self refreshTimeEntries:TRUE displayBusyMsg:FALSE];
            } else {
                [self refreshTimeEntries:FALSE displayBusyMsg:FALSE];
            }
        } else {
#ifndef RELEASE
            NSLog(@"Error while checking current employee needing submission - %@", error.localizedDescription);
            [ErrorLogging logError:error];
#endif
        }
    }
}

- (void)showServerBusy {
    [SharedUICode displayServerIsBusy];
}

- (void)refreshData {
    DataManager* manager = [DataManager sharedManager];
    if (manager.isBusy) {
        [refreshControl endRefreshing];
        [self showServerBusy];
        return;
    }
    
    NSError* error = nil;
    [manager stopTimer];
    NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&error];
    if (nil != error) {
        [refreshControl endRefreshing];
        [SharedUICode messageBox:@"Error" message:[NSString stringWithFormat:@"There was an error checking if current employee has pending updates - %@", error.localizedDescription]];
        [ErrorLogging logError:error];
        [manager startUpdateTimer];
        return;
    }
    if (![CommonLib DoWeHaveNetworkConnection]) {
        [refreshControl endRefreshing];
        [SharedUICode messageBox:nil message:@"No Internet Connection.  Make sure you have an internet connection and not on airplane mode." withCompletion:^{
            [manager startUpdateTimer];
            return;
        }];
        return;
    }
    
    if (0 == count) {
        [self refreshTimeEntries:TRUE displayBusyMsg:TRUE];
    } else {
        [SharedUICode yesNo:nil message:@"You have PENDING UPDATES to the server.  If you refresh now, you will lose ALL unsaved pending changes to the server.\n\nAre you absolutely sure?" yesBtnTitle:@"Yes - Please Refresh" noBtnTitle:@"No - Do Nothing" withCompletion:^(YesNoCancelResult Result) {
            switch (Result) {
                case resultYes:
                    [self refreshTimeEntries:TRUE displayBusyMsg:TRUE];
                    break;
                case resultNo:
                    [refreshControl endRefreshing];
                    [manager startUpdateTimer];
                    break;
                default:
                    break;
            }
        }];
    }
}

- (void)refresh:(UIRefreshControl*)sender {
    [self refreshData];
}

- (void)viewDidUnload
{
    [self setTimeEntryTableView:nil];
    timeEntryItems = nil;
    [self setTotalHoursLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    UserClass *user = [UserClass getInstance];
    
    // if ([user.userType isEqualToString:@"employer"])
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)) //((user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"])))
        [self.parentViewController.navigationItem setTitle:employeeName];
    else
    {
        _jobCodes = user.jobCodesList;
        UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 44)];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
        titleLabel.text = @"Time Sheet";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [customView addSubview:titleLabel];
        self.navigationItem.titleView = customView;
    }
    
    if ([user.payrollStartDate length] > 0)
        self.startdate = user.payrollStartDate;
    if ([user.payrollEndDate length] > 0)
        self.enddate = user.payrollEndDate;
    
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonAction)];
    
    actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonAction)];
    
    //if we are using the business app, check if they are an employee who has the option can not edit or kiosk only option set to figure out if we should show the add button
#ifndef PERSONAL_VERSION
    
    //  if ([user.userType isEqualToString:@"employer"])
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)) //((user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"])))
    {
        self.parentViewController.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:actionButton, addButton, nil];
    }
    //for the kiosk app when an employee signs in we don't want to show them the add time entry option
    else if ([user.userType isEqualToString:@"team"]){
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:actionButton, nil];
    }
    
    else
    {
        bool canNotEdit = (user.disableTimeEntryEditing);
        if ([self isEmployeeBlocked] || canNotEdit)
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:actionButton, nil];
        else
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:actionButton, addButton, nil];
    }
    
#else
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:actionButton, addButton, nil];
    
#endif
    
    _TotalHoursLabel.text = @"0h 0m";
    
    DataManager* manager = [DataManager sharedManager];
    if (!manager.isBusy) {
        NSError* error = nil;
        NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&error];
        if (nil == error) {
            if (0 == count && [CommonLib DoWeHaveNetworkConnection]) {
                [self refreshTimeEntries:TRUE displayBusyMsg:FALSE];
            } else {
                [self refreshTimeEntries:FALSE displayBusyMsg:FALSE];
            }
        } else {
#ifndef RELEASE
            NSLog(@"Error while checking current employee needing submission - %@", error.localizedDescription);
            [ErrorLogging logError:error];
#endif
        }
    }
    
}
-(void)closeDatePicker{
#ifdef IPAD_VERSION
    self.selectedFromDateValue = fromToDatePicker.fromDateValue;
    self.selectedToDateValue = fromToDatePicker.toDateValue;
    
    [self dismissViewControllerAnimated:NO completion:nil];
#else
    [pickerViewDate removeFromSuperview];
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
#ifndef IPAD_VERSION
    [self closeDatePicker];
#endif
    if ([self.view isFirstResponder]) {
        [self.view resignFirstResponder];
    }
    [super viewWillDisappear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    /*   DataManager* manager = [DataManager sharedManager];
     if (!manager.isBusy) {
     NSError* error = nil;
     NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&error];
     if (nil == error) {
     if (0 == count && [CommonLib DoWeHaveNetworkConnection]) {
     [self refreshTimeEntries:TRUE displayBusyMsg:FALSE];
     } else {
     [self refreshTimeEntries:FALSE displayBusyMsg:FALSE];
     }
     } else {
     #ifndef RELEASE
     NSLog(@"Error while checking current employee needing submission - %@", error.localizedDescription);
     #endif
     }
     }*/
    [TimeSheetDetailViewController popAndReleaseDetail];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    DataManager* manager = [DataManager sharedManager];
    if ([manager isBusy]) {
        return 1;
    }
    NSArray* __timeHistory = manager.timeHistory;
    @synchronized(__timeHistory) {
        if (nil == __timeHistory || [__timeHistory count] == 0) {
            return 1;
        } else {
            return [__timeHistory count];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34.f;
}

- (float) formatMillisecondsToDecimal: (long) milliseconds{
    unsigned long seconds = milliseconds / 1000;
    unsigned long minutes = seconds / 60;
    unsigned long hours = minutes / 60;
    minutes %= 60;
    float minutesToDecimal = minutes / 60.0;
    float duration = hours + minutesToDecimal;
    return duration;
}

//because we are overridng the color of the section header we'll also need to set the Header text
//because by using this method it will override whatever is in titleForHeaderInSection method
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect mainFrame = UIScreen.mainScreen.bounds;
    
    UIView *tempView=[[UIView alloc]initWithFrame:CGRectMake(0,200,mainFrame.size.width,244)];
    tempView.backgroundColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR);
    //  UILabel *tempLabel = [[UILabel alloc] init];
    UILabel *tempLabel=[[UILabel alloc]initWithFrame:CGRectMake(16,0,mainFrame.size.width - 32,36)];
    tempLabel.backgroundColor=[UIColor clearColor];
    tempLabel.textColor = [UIColor whiteColor];
    tempLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0f];
    tempLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    
    UILabel *tempLabel2 = [[UILabel alloc]initWithFrame:CGRectMake(15,0,mainFrame.size.width - 32,36)];
    tempLabel2.backgroundColor=[UIColor clearColor];
    tempLabel2.textColor = [UIColor whiteColor];
    tempLabel2.font = [UIFont fontWithName:@"Helvetica" size:16.0f];
    tempLabel2.font = [UIFont boldSystemFontOfSize:16.0f];
    tempLabel2.textAlignment = NSTextAlignmentRight;
    
    
    DataManager* manager = [DataManager sharedManager];
    
    NSArray* __timeHistory = manager.timeHistory;
    @synchronized(__timeHistory) {
        if (nil != __timeHistory && [__timeHistory count] > 0)
        {
            DayHistoryItemInfo* info = [manager.timeHistory objectAtIndex:section];
            
            float totalDayPay = info.dayTotalPay;
#ifdef PERSONAL_VERSION
            if ((totalDayPay > 0) || (user.individualHourlyPayRate > 0))
                user.showTotalPay = true;
#else
         //   if (totalDayPay > 0)
          //      user.showTotalPay = true;
            user.showTotalPay = false;
#endif
            
            if (user.showTotalPay)
            {
                
                //  float totalDayPay = info.dayTotalPay;
                
                float __totalPay = 0;
#ifdef PERSONAL_VERSION
                float durationDay = info.dayTotalsInDecimal;
                __totalPay = durationDay * user.individualHourlyPayRate;
#endif
                //NSString* formattedPay = [NSString stringWithFormat:@"%@/$%.02f", info.displayDateTimeStr, totalPay];
                NSString* formattedPay = @"";
                if (totalDayPay > 0)
                    formattedPay = [NSString stringWithFormat:@"%@ ($%.02f)", info.displayTimeShortStr, totalDayPay];
                else
                    formattedPay = [NSString stringWithFormat:@"%@ ($%.02f)", info.displayTimeShortStr, __totalPay];
                tempLabel.text = info.displayDateStr;
                tempLabel2.text = formattedPay;
                
            }
            else
            {
                tempLabel.text = info.displayDateStr;
                tempLabel2.text = info.displayTimeLongStr;
            }
        }
        else {
            tempLabel.text =  @"No timesheet entries available";
        }
    }
    
    [tempView addSubview:tempLabel];
    [tempView addSubview:tempLabel2];
    
    return tempView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // Return the number of rows in the section.
    DataManager* manager = [DataManager sharedManager];
    if ([manager isBusy]) {
        return 0;
    }
    NSArray* history = manager.timeHistory;
    @synchronized(history) {
        if ((nil == history) || ([history count] <= 0)) {
            return 0;
        }
        // Return the number of rows in the section.
        DayHistoryItemInfo* info = [history objectAtIndex:section];
        if (nil == info) {
            return 0;
        }
        NSArray *timeEntriesHistory = info.timeEntries;
        if (nil == timeEntriesHistory) {
            return 0;
        }
        NSInteger count = timeEntriesHistory.count;
        return count;
    }
}

static UIImage* clockInImage = nil;
static UIImage* clockOutImage = nil;

- (void)initColorsAndImages {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clockInImage = [UIImage imageNamed:@"clockin.png"];
        clockOutImage = [UIImage imageNamed:@"clockout.png"];
    });
}

- (void)setPendingUpdate:(UITableViewCell*)cell pending:(BOOL)bIsPendingUpdate {
    if (bIsPendingUpdate) {
        cell.backgroundColor = [CommonLib getHatchedBackColor];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
   //     cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    DataManager* manager = [DataManager sharedManager];
    NSArray* __timeHistory = manager.timeHistory;
    @synchronized(__timeHistory) {
        if (__timeHistory != nil && [__timeHistory count] > 0){
            DayHistoryItemInfo* info = [__timeHistory objectAtIndex:indexPath.section];
            NSArray *timeEntriesPerDay = info.timeEntries;
            if ((timeEntriesPerDay == nil) || (timeEntriesPerDay.count == 0) || (indexPath.row >= timeEntriesPerDay.count))
            {
                //Crashlytics is reporting a crash in this area so trying to figure out the root cause
                NSString *msg = [NSString stringWithFormat:@"Crash: TimeSheetMasterViewController.cellForRowAtIndexPath indexPath.row= %ld  timeEntriesPerDay.count= %lu self.startdate= %@ self.enddate= %@",(long)indexPath.row, (unsigned long)timeEntriesPerDay.count, self.startdate, self.enddate];
                [MetricsLogWebService LogException: msg];
                
                cell.textLabel.text = @"";
                cell.detailTextLabel.text = @"";
                return cell;
                
            }
            TimeEntryInfo* timeEntryInfo = [timeEntriesPerDay objectAtIndex:indexPath.row];
            TimeEntry* timeEntry = timeEntryInfo.timeEntry;
            NSString *timeEntryType = timeEntry.timeEntryType;
            bool isTimeEntryBreak = false;
            if ((![NSString isNilOrEmpty:timeEntryType]) && ([timeEntryType isEqualToString:@"BREAK"]))
                isTimeEntryBreak = true;
            BOOL bIsPendingUpdate = ([timeEntry getDBStatus] != dsUpdated);
            switch (timeEntryInfo.clockMode) {
                case 0: {
                    if (timeEntry.clockIn) {
                        if (!bIsPendingUpdate) {
                            bIsPendingUpdate = ([timeEntry.clockIn getDBStatus] != dsUpdated);
                        }
                        NSString* dateTime = [timeEntry.clockIn.dateTimeEntry toDefaultTimeString];
                        if (bIsPendingUpdate)
                        {
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ (Not Synced)",dateTime];
                            cell.backgroundColor = UIColorFromRGB(LIGHT_RED_COLOR);
                            if (isTimeEntryBreak)
                                cell.detailTextLabel.text = @"Break In";
                            else
                                cell.detailTextLabel.text = @"";
                        }
                        else
                        {
                            cell.textLabel.text = dateTime;
                            cell.backgroundColor = [UIColor whiteColor];
                            if (isTimeEntryBreak)
                                cell.detailTextLabel.text = @"Break In";
                            else
                                cell.detailTextLabel.text = @"";
                        }
                        
                    }                    //                    [self setPendingUpdate:cell pending:bIsPendingUpdate];
                    cell.imageView.image = clockInImage;

                    break;
                }
                case 1: {
                    if (timeEntry.clockOut) {
                        if (!bIsPendingUpdate) {
                            bIsPendingUpdate = ([timeEntry.clockOut getDBStatus] != dsUpdated);
                        }
                        NSString* dateTime = [timeEntry.clockOut.dateTimeEntry toDefaultTimeString];
                        if (bIsPendingUpdate)
                        {
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ (Not Synced)",dateTime];
                            cell.backgroundColor = UIColorFromRGB(LIGHT_RED_COLOR);
                            if (isTimeEntryBreak)
                                cell.detailTextLabel.text = @"Break Out";
                            else
                                cell.detailTextLabel.text = @"";
                        }
                        else
                        {
                            cell.textLabel.text = dateTime;
                            cell.backgroundColor = [UIColor whiteColor];
                            if (isTimeEntryBreak)
                                cell.detailTextLabel.text = @"Break Out";
                            else
                                cell.detailTextLabel.text = @"";
                        }
                    }
                    //                    [self setPendingUpdate:cell pending:bIsPendingUpdate];
                    cell.imageView.image = clockOutImage;
                    break;
                }
                default:
                    break;
            }
        }
        
        return cell;
    }
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    UserClass *user = [UserClass getInstance];
    //    if([user.userType isEqualToString:TEAM_USER_TYPE])
    //        return nil;
    //    else
    return indexPath;
}

-(bool) isEmployeeBlocked
{
    bool blocked = false;
    //don't check if we are using the Kiosk app or personal app
#if !defined(PERSONAL_VERSION) && !defined(IPAD_VERSION)
    UserClass *user = [UserClass getInstance];
    if (![user.userType isEqualToString:@"employer"])
    {
        NSNumber *isBlockedFromClockingInOut = user.employeePermissions[@"DISALLOW_EMPLOYEE_TIMEENTRY"];
        if ([isBlockedFromClockingInOut boolValue])
            blocked = true;
    }
#endif
    return blocked;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //if this is an employee who does not have permission to make changes then block
    if ([self isEmployeeBlocked])
    {
        return;
    }
    
    // Navigation logic may go here. Create and push another view controller.
    TimeSheetDetailViewController* controller = [TimeSheetDetailViewController showDetail:self];
    // ...
    // Pass the selected object to the new view controller.
    //    if (editFlag)
    //    {
    
    TimeEntryInfo *selectedTimeEntry;
    DataManager* manager = [DataManager sharedManager];
    NSArray* __timeHistory = manager.timeHistory;
    @synchronized(__timeHistory) {
        if (__timeHistory != nil && __timeHistory.count > 0){
            DayHistoryItemInfo* info = [__timeHistory objectAtIndex:indexPath.section];
            
            NSArray *timeEntriesPerDay = info.timeEntries;
            
            selectedTimeEntry = [timeEntriesPerDay objectAtIndex:indexPath.row];
            
            TimeEntry* timeEntry = selectedTimeEntry.timeEntry;
            
            //   NSString *clockoutValue = timeEntry.clockOut ? [timeEntry.clockOut.dateTimeEntry toLongDateTimeString] : @"";
            
            bool isActiveClockIn = false;
            
            if ((user.activeClockInId != nil) && ([timeEntry.timeEntryID doubleValue] == [user.activeClockInId doubleValue]))
                isActiveClockIn = true;
            //sometimes the reason activeClicInId is false is because we are in offline mode so check to see if there is a clock out value
            if (user.activeClockInId == nil)
            {
                ClockInfo *clockOutInfo = timeEntry.clockOut;
                //if we don't have a clock out then assume it's an active clock in
                if (clockOutInfo == nil)
                {
                    isActiveClockIn = true;
                }
                
            }
            
            if (isActiveClockIn)
            {
                controller.editClockMode = EDIT_ACTIVE_CLOCK;
            }
            else
            {
                controller.editClockMode = NON_ACTIVE_CLOCK;
            }
            
            controller.timeEntryObjectID = timeEntry.objectID;
            controller.selectedMode = selectedTimeEntry.clockMode;
        }
        
        controller.employeeName = employeeName;
        controller.employeeId = employeeID;
        controller.jobCodes = _jobCodes;
        //move the jobCodeId to the TimeEntry object
        //  controller.jobCodeId =
        [self.navigationController pushViewController:controller animated:YES];
    }
    
}

/*-(void)CheckRateUsOnAppStoreTrigger
 {
 //launch the review dialog
 int visitCounter = (int) [user.appLaunchCounter integerValue];
 int didUserGiveRatingFeedback = (int) [user.userGaveUsRatingFeedback integerValue];
 //only launch if the counter is a certain number and we haven't asked him before and it's been 21 since they installed the app so they've been using it for a while now
 NSDate *todaysDate = [NSDate date];
 NSInteger numOfDaysSinceInstall = [CommonLib daysBetweenDate:user.appInstallDate andDate:todaysDate];
 
 
 if ((visitCounter >= MAX_TIMES_APP_LAUNCHED) && (didUserGiveRatingFeedback == 0) && numOfDaysSinceInstall > 14)
 
 {
 
 [self stopSpinner];
 //turn off the dialog so we don't show it anymore
 user.userGaveUsRatingFeedback = [NSNumber numberWithInt:1];
 [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
 
 //show first rating dialog
 ratingDialogType = EnjoyingEzClokcer_dlg;
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Enjoying ezClocker?" delegate:self cancelButtonTitle:@"Not really" otherButtonTitles:@"Yes!", nil];
 
 [alert show];
 
 }
 
 
 }
 */

-(void) refreshTimeEntries:(BOOL)bRefresh displayBusyMsg:(BOOL)bDislayBusyMsg {
    @synchronized (self) {
        //if employr view did not give us the employeeID then use user.userid which is the current user of the app
        if (0 == [employeeID intValue]) {
            employeeID = user.userID;
        }
        
        DataManager* dataManager = [DataManager sharedManager];
        if ([dataManager isBusy]) {
            [refreshControl endRefreshing];
            if (bDislayBusyMsg) {
                [SharedUICode displayServerIsBusy];
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:DATAMANAGER_BUSY description:@"DATAMANAGER_BUSY" error:nil];
                return;
            }
            [dataManager startUpdateTimer];
            return;
        }
        
        //only resume if we have an employeeID because if we don't then we are in trouble and don't need to show that to the user
        if (0 == [employeeID intValue])
        {
            [dataManager startUpdateTimer];
            [refreshControl endRefreshing];
            return;
        }
        
#ifndef RELEASE
        NSLog(@"emplID= %d", [employeeID intValue]);
        
#endif
        if (nil == user) {
            [dataManager startUpdateTimer];
            [refreshControl endRefreshing];
        }
        
        [user checkPayrollStartDate:self]; // this will set startDate and endDate
        [_selectDateButton1 setTitle:[NSString stringWithFormat:@"%@ - %@",self.startdate, self.enddate] forState:UIControlStateNormal];
        [self startSpinnerWithMessage:@"Refreshing, please wait..."];
        NSDictionary* dict = @{kStartDateKey: self.startdate, kEndDateKey: self.enddate};
        [dataManager loadTimesheetsForEmployee:dict refresh:bRefresh withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
            if (errorCode == SERVICE_UNAVAILABLE_ERROR) {
 //               [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_UNAVAILABLE_ERROR description:@"SERVICE_UNAVAILABLE_ERROR" error:error];
                [refreshControl endRefreshing];
                [self stopSpinner];
                [SharedUICode displayServiceUnavailableError];
                [dataManager startUpdateTimer];
                [TimeEntryTableView reloadData];
                return;
            }
            if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_UNKNOWN_ERROR description:@"SERVICE_ERRORCODE_UNKNOWN_ERROR" error:error];
                [refreshControl endRefreshing];
                [self stopSpinner];
                [SharedUICode checkResultsMessageAndDisplayError:resultMessage error:error];
                [dataManager startUpdateTimer];
                [TimeEntryTableView reloadData];
                return;
            }
            
            if (bRefresh) { // if refreshed then reset so we get the most recent from the database but check clock status will reset it.
                //UserClass* __userClass = [UserClass getInstance];
                // __userClass.activeTimeEntryId = nil;
            }
            
            
            NSString *totalDuration = [DataManager formatInterval:dataManager.totalDuration];
            
            totalPay = dataManager.totalPay;
            
#ifdef PERSONAL_VERSION
            if ((totalPay > 0) || (user.individualHourlyPayRate > 0))
                user.showTotalPay = true;
#else
         //   if (totalPay > 0)
         //       user.showTotalPay = true;
            user.showTotalPay = false;
#endif
            
            if (user.showTotalPay)
            {
                
                //float totalPay = 0;
                
#ifdef PERSONAL_VERSION
                //if we have a totalPay value from the dataManager that means they used jobCodes and it got calculated when we went through the timesheet and calculated total time
                //else calculate the totalPay by multiplying total hours by the hourly rate they entered in the settings screen
                // totalPay = dataManager.totalPay;
                if (totalPay == 0)
                {
                    float totalDurationFloat = [DataManager formatIntervalToDecimal: dataManager.totalDuration];
                    totalPay = totalDurationFloat * user.individualHourlyPayRate;
                    
                }

#endif
                
                if (totalPay > 0)
                {
                    //format the float to a currency string to add the $ and commas
                    NSNumberFormatter *_currencyFormatter = [[NSNumberFormatter alloc] init];
                    [_currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    NSString* formatedResult = [_currencyFormatter stringFromNumber: [NSNumber numberWithFloat: totalPay]];
                    
                    NSString* formattedPay = [NSString stringWithFormat:@"%@ = %@", totalDuration, formatedResult];
                    
                    _TotalHoursLabel.text = formattedPay;
                    
                    //here I want to show the pay as green
                    NSInteger pos = [formattedPay rangeOfString:@"$"].location;
                    
                    NSMutableAttributedString *text =
                    [[NSMutableAttributedString alloc]
                     initWithAttributedString: _TotalHoursLabel.attributedText];
                    
                    UIColor *txtColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
                    
                    NSInteger lengthRemainder = formattedPay.length - pos;
                    
                    [text addAttribute:NSForegroundColorAttributeName
                                 value: txtColor
                                 range:NSMakeRange(pos, lengthRemainder)];
                    
                    [_TotalHoursLabel setAttributedText: text];
                }
                else
                {
                    totalDuration = [NSString stringWithFormat:@"Total Hours: %@", totalDuration];
                    _TotalHoursLabel.text = totalDuration;
                    
                    //if we are not going to show the pay then add Total Hours: and make it slight smaller font
                    NSMutableAttributedString *text =
                    [[NSMutableAttributedString alloc]
                     initWithAttributedString: _TotalHoursLabel.attributedText];
                    
                    UIFont *font = [UIFont fontWithName:_TotalHoursLabel.font.fontName size:20.0];
                    
                    [text addAttribute:NSFontAttributeName value: font range:NSMakeRange(0, 12)];
                    
                    [_TotalHoursLabel setAttributedText: text];
                }
                
                
            }
            else{
                
                totalDuration = [NSString stringWithFormat:@"Total Hours: %@", totalDuration];
                _TotalHoursLabel.text = totalDuration;
                
                NSMutableAttributedString *text =
                [[NSMutableAttributedString alloc]
                 initWithAttributedString: _TotalHoursLabel.attributedText];
                
                UIFont *font = [UIFont fontWithName:_TotalHoursLabel.font.fontName size:20.0];
                
                [text addAttribute:NSFontAttributeName value: font range:NSMakeRange(0, 12)];
                
                [_TotalHoursLabel setAttributedText: text];
                
                
            }
            
            [refreshControl endRefreshing];
            [TimeEntryTableView reloadData];
            
            //only prompt the please review us dialog for employer bc the employee gets it when they press the clock out button
            //     if ([user.userType isEqualToString:@"employer"])
            if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)) //((user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"])))
                [self CheckRateUsOnAppStoreTrigger];
            
            
            [self stopSpinner];
            [dataManager startUpdateTimer];
        }];
    }
}

-(void)CheckRateUsOnAppStoreTrigger
{
    //launch the review dialog
    [SharedUICode CheckRateUsOnAppStoreTrigger:self :^(NSInteger index) {
        [self stopSpinner];
        if (index == 0) {
            // For No
            //            ratingDialogType = EnjoyingEzClokcer_dlg;
            [self didNotEnjoyEzClocker];
        } else if (index == 1) {
            // For Yes
            //            ratingDialogType = EnjoyingEzClokcer_dlg;
            //[self enjoyedEzClockerWasSelected];
            
            if (@available(iOS 10.3, *)) {
                [SKStoreReviewController requestReview];
            } else {
                [self willingToGiveUsRating];
            }
            
        } else {
            // For visitCounter zero
        }
    }];
}

/*-(void) enjoyedEzClockerWasSelected
 {
 UIAlertController * alert = [UIAlertController
 alertControllerWithTitle:@""
 message:@"How about a rating on the App Store, then?"
 preferredStyle:UIAlertControllerStyleAlert];
 
 UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Ok, sure"
 style:UIAlertActionStyleDefault
 handler:^(UIAlertAction * action){
 [self saveRatingToUserDefault];
 if (@available(iOS 10.3, *)) {
 [SKStoreReviewController requestReview];
 } else {
 [self willingToGiveUsRating];
 }
 }];
 
 UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"No, thanks"
 style:UIAlertActionStyleDefault
 handler:^(UIAlertAction * action){
 [self notWillingToGiveUsRating];
 }];
 
 [alert addAction:yesButton];
 [alert addAction:noButton];
 
 [self presentViewController:alert animated:YES completion:nil];
 
 
 }
 */

-(void) saveRatingToUserDefault {
    [SharedUICode checkPromptCount:^(NSInteger index) {
        NSDate *currentDate = [NSDate date];
        if (index == 1) {
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"totalCount"];
            
            NSDate *firstDate = [SharedUICode add4MonthIntoDate:currentDate];
            NSDate *secondDate = [SharedUICode add4MonthIntoDate:firstDate];
            
            [[NSUserDefaults standardUserDefaults] setValue:firstDate forKey:@"firstDate"];
            [[NSUserDefaults standardUserDefaults] setValue:secondDate forKey:@"secondDate"];
            //  [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else if (index == 2) {
            [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"totalCount"];
            //   [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else if (index == 3) {
            [[NSUserDefaults standardUserDefaults] setInteger:3 forKey:@"totalCount"];
            //   [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }];
}

-(void)didNotEnjoyEzClocker
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"Would you mind giving us some feedback?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Ok, sure"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action){
        [self willingToGiveUsFeedback];
    }];
    
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"No, thanks"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action){
        [self cancelFeedback];
    }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}
-(void)willingToGiveUsFeedback
{
    //take them to our feedback screen
    EmailFeedbackViewController *emailFeedbackController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmailFeedback"];
    UINavigationController *emailFeedbackNavigationController = [[UINavigationController alloc] initWithRootViewController:emailFeedbackController];
    
    
    emailFeedbackController.delegate = (id) self;
    emailFeedbackController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:emailFeedbackNavigationController animated:YES completion:nil];
    
}

-(void)cancelFeedback
{
    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Somebody Didn't want to give us feedback :-("]];
    
}

/*- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
 if(ratingDialogType == EnjoyingEzClokcer_dlg)
 {
 if (buttonIndex != [alertView cancelButtonIndex]) {
 //show second rating dialog
 ratingDialogType = CanYouRateUs_dlg;
 
 if (@available(iOS 10.3, *)) {
 [SKStoreReviewController requestReview];
 } else {
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"How about a rating on the App Store, then?" delegate:self cancelButtonTitle:@"No, thanks" otherButtonTitles:@"Ok, sure", nil];
 
 [alert show];
 }
 }
 else{
 
 ratingDialogType = GiveUsFeedback_dlg;
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Would you mind giving us some feedback?" delegate:self cancelButtonTitle:@"No, thanks" otherButtonTitles:@"Ok, sure", nil];
 
 [alert show];
 
 
 }
 }
 else if(ratingDialogType == CanYouRateUs_dlg){
 if (buttonIndex != [alertView cancelButtonIndex]) {
 //10/15/17 RK : took this out and moved it back to the calling function
 //user.userGaveUsRatingFeedback = [NSNumber numberWithInt:1];
 //[[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
 
 //send a notification to let us know that someone went to the app store to rate us
 [MetricsLogWebService LogException: [NSString stringWithFormat:@"Somebody Selected to Rate us on the App Store. Yay!!!!"]];
 #ifdef PERSONAL_VERSION
 //   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-personal-time-tracking/id833047956?mt=8"]];
 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-personal-time-tracking/id833047956?mt=8"]options:@{} completionHandler:nil];
 #elif IPAD_VERSION
 //          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-kiosk-time-tracking/id1339692641?mt=8"]];
 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-kiosk-time-tracking/id1339692641?mt=8"]options:@{} completionHandler:nil];
 #else
 //       [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker/id800807197?ls=1&mt=8"]];
 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker/id800807197?ls=1&mt=8"]options:@{} completionHandler:nil];
 #endif
 }
 //took this out on 10/14/2017 bc we were getting too many 3 star reviews
 
 }
 else if (ratingDialogType == GiveUsFeedback_dlg)
 {
 if (buttonIndex != [alertView cancelButtonIndex]) {
 //take them to our feedback screen
 EmailFeedbackViewController *emailFeedbackController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmailFeedback"];
 UINavigationController *emailFeedbackNavigationController = [[UINavigationController alloc] initWithRootViewController:emailFeedbackController];
 
 
 emailFeedbackController.delegate = (id) self;
 emailFeedbackController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
 
 [self presentViewController:emailFeedbackNavigationController animated:YES completion:nil];
 
 }
 else{
 
 [MetricsLogWebService LogException: [NSString stringWithFormat:@"Somebody Didn't want to give us feedback :-("]];
 
 }
 
 }
 }
 */

-(void)willingToGiveUsRating
{
    //  [MetricsLogWebService LogException: [NSString stringWithFormat:@"Somebody Selected to Rate us on the App Store. Yay!!!!"]];
#ifdef PERSONAL_VERSION
    // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-personal-time-tracking/id833047956?mt=8"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-personal-time-tracking/id833047956?mt=8"]options:@{} completionHandler:nil];
#elif IPAD_VERSION
    //  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-kiosk-time-tracking/id1339692641?mt=8"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-kiosk-time-tracking/id1339692641?mt=8"]options:@{} completionHandler:nil];
#else
    //   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker/id800807197?ls=1&mt=8"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker/id800807197?ls=1&mt=8"]options:@{} completionHandler:nil];
#endif
}

-(void)notWillingToGiveUsRating
{
    //10/15/17 RK: took this out and moved it back to the calling function
    /*           //reset so we can ask them again later
     NSDate *todaysDate = [NSDate date];
     user.appInstallDate = todaysDate;
     user.userGaveUsRatingFeedback = [NSNumber numberWithInt:0];
     [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
     */
}


-(void) emailButtonAction
{
    
    
    EmailTimeSheetViewController *emaiViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmailTimeSheet"];
    
    timeSheetNavigationController = [[UINavigationController alloc] initWithRootViewController:emaiViewController];
    
    //    NSString *sDate = self.startdate;
    emaiViewController.startDate = self.startdate;
    emaiViewController.endDate = self.enddate;
    emaiViewController.employeeID = employeeID;
    emaiViewController.employeeEmail = _employeeEmail;
    emaiViewController.totalPay = [NSNumber numberWithFloat: totalPay];
    
    
    emaiViewController.delegate = (id) self;
    emaiViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    
    [self presentViewController:timeSheetNavigationController animated:YES completion:nil];
    
}
-(void) addButtonAction
{
    AddTimeEntryViewController *addViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AddtimeEntryViewController"];
    
    timeSheetNavigationController = [[UINavigationController alloc] initWithRootViewController:addViewController];
    
    
    
    //   AddTimeEntryViewController *controller = [[AddTimeEntryViewController alloc] initWithNibName:@"AddTimeEntryViewController" bundle:nil];
    
    addViewController.employeeID = employeeID;
    addViewController.delegate = (id) self;
    addViewController.jobCodes = _jobCodes;
    addViewController.primaryJobCode = _primaryJobCode;
    addViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:timeSheetNavigationController animated:YES completion:nil];
    
}
-(void)showActionButtonAction{
    DataManager* manager = [DataManager sharedManager];
    if ([manager isBusy]) {
        [SharedUICode displayServerIsBusy];
        return;
    }
    UIView *view = [actionButton valueForKey:@"view"];
    [SharedUICode yesNo:@"Time Sheet" message:nil yesBtnTitle:EMAIL_TIME_SHEET noBtnTitle:@"Cancel" rootControl: view withCompletion:^(YesNoCancelResult Result) {
        switch (Result) {
            case resultYes:
                [self emailButtonAction];
                break;
                
            default:
                break;
        }
    }];
}

-(void) actionButtonAction
{
#ifdef IPAD_VERSION
    [self showActionButtonAction];
#else
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Time Sheet" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // Cancel button tappped.
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:EMAIL_TIME_SHEET style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        // EMAIL_TIME_SHEET button tapped.
        
        NSString *buttonTitle = action.title;//[actionSheet buttonTitleAtIndex:buttonIndex];
        if  ([buttonTitle isEqualToString:EMAIL_TIME_SHEET]) {
            [self emailButtonAction];
        }
    }]];
    
    // Present action sheet.
    [self presentViewController:actionSheet animated:YES completion:nil];
    
    //    [pickerViewAction setBounds:CGRectMake(0,0,kbHeight, 464)];
#endif
    
    
}

/*-(void) editButtonAction
 {
 if (editFlag == YES){
 editFlag = NO;
 self.navigationItem.leftBarButtonItem.title = @"Edit";
 [TimeEntryTableView setEditing:NO animated: NO];
 }
 else {
 editFlag = YES;
 self.navigationItem.leftBarButtonItem.title = @"Done";
 [TimeEntryTableView setEditing:YES animated: YES];
 
 }
 }
 */
- (void)addTimeEntryViewControllerDidFinish:(AddTimeEntryViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)emailTimeSheetViewControllerDidFinish:(EmailTimeSheetViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveTimeEntryDidFinish:(TimeSheetDetailViewController *)controller
{
    [TimeSheetDetailViewController releaseController];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)emailFeedbackViewControllerDidFinish:(UIViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(UIButton *) createDateRangeButton
{
    UIButton *currBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 40)];
    
    //   [currBtn setTitle:@"From 09/08/13" forState:UIControlStateNormal];
    currBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [currBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    currBtn.titleLabel. numberOfLines = 0; // Dynamic number of lines
    currBtn.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    return currBtn;
    
}

-(NSDate*)convertStringToDate: (NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}

-(NSString*)convertDateToString: (NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

//picking dates for reporting
-(void)DatePickerView
{
    WWCalendarTimeSelector *selector  = (WWCalendarTimeSelector *)[[UIStoryboard storyboardWithName:@"WWCalendarTimeSelector" bundle:nil] instantiateViewControllerWithIdentifier:@"WWCalendarTimeSelector"];
    selector.delegate = self;
    //    selector.optionShowTopContainer = false;
    //    selector.optionLayoutHeight = 300;
    selector.optionSelectionType = WWCalendarTimeSelectorSelectionRange;
    NSDate *startDateObj = [self convertStringToDate:self.startdate];
    NSDate *endDateObj = [self convertStringToDate:self.enddate];
    [selector.optionCurrentDateRange setStartDate:startDateObj];
    [selector.optionCurrentDateRange setEndDate:endDateObj];
    selector.optionCurrentDate = startDateObj;
    
    self.selectedFromDateValue = self.startdate;
    self.selectedToDateValue = self.enddate;
    [self presentViewController:selector animated:YES completion:nil];
    //
    
    //    CGFloat kbHeight = [NSUserDefaults.standardUserDefaults floatForKey:keyboardHeight];
    //    CGRect screenBound = [[UIScreen mainScreen] bounds];
    //    CGSize screenSize = screenBound.size;
    //    CGFloat screenHeight = screenSize.height;
    //
    //    CGFloat safeAreaTopHeight = 0;
    //    CGFloat safeAreaBottomHeight = 0;
    //    if (@available(iOS 11, *)) {
    //        // safe area constraints already set
    //        safeAreaTopHeight = UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
    //        safeAreaBottomHeight = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    //    } else {
    //        safeAreaTopHeight = self.topLayoutGuide.length;
    //        safeAreaBottomHeight = self.bottomLayoutGuide.length;
    //    }
    //
    //    CGFloat Y = screenHeight - (kbHeight + safeAreaBottomHeight + safeAreaTopHeight);
    //    if (self.tabBarController != nil) {
    //        CGFloat tabbarHeight = self.tabBarController.tabBar.frame.size.height;
    //
    //        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, Y - tabbarHeight, self.view.frame.size.width, kbHeight)];
    //    } else {
    //        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, Y, self.view.frame.size.width, kbHeight)];
    //    }
    //
    //    [pickerViewDate setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    //
    //    //if we are running the iPhone then we start at 44 because of the toolbar
    //    CGRect pickerFrame;
    //    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    //    {
    //        pickerFrame = CGRectMake(0, 44, 0, 0);
    //    } else {
    //        pickerFrame = CGRectMake(0, 44,  screenSize.width, kbHeight - 44);
    //    }
    //
    //    theDatePicker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
    //    theDatePicker.datePickerMode = UIDatePickerModeDate;
    //    theDatePicker.hidden = NO;
    //
    //    [theDatePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
    //
    //    fromDateBtn = [self createDateRangeButton];
    //    NSString *value = [[NSString alloc] initWithFormat:@"From %@", self.startdate];
    //    [fromDateBtn setTitle:value forState:UIControlStateNormal];
    //    self.selectedFromDateValue = self.startdate;
    //
    //    //init the value of the date picker to the from date value
    //    NSDate* dateFromString = [self.startdate toDefaultDate];
    //
    //    [theDatePicker setDate:dateFromString];
    //    fromDateBtn.backgroundColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR);
    //    toDateBtn = [self createDateRangeButton];
    //    toDateBtn.backgroundColor = [UIColor grayColor];
    //    value = [[NSString alloc] initWithFormat:@"To %@", self.enddate];
    //    self.selectedToDateValue = self.enddate;
    //
    //    [toDateBtn setTitle:value forState:UIControlStateNormal];
    //
    //    [fromDateBtn addTarget:self
    //                    action:@selector(DatePickerFromDateClick)
    //          forControlEvents:UIControlEventTouchDown];
    //    [toDateBtn addTarget:self
    //                    action:@selector(DatePickerToDateClick)
    //          forControlEvents:UIControlEventTouchDown];
    //
    //
    //    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    //    pickerToolbar.barStyle=UIBarStyleBlackOpaque;
    //    [pickerToolbar sizeToFit];
    //
    //    @try {
    //
    //        NSMutableArray *barItems = [[NSMutableArray alloc] init];
    //        UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(DatePickerDoneClick)];
    //
    //        UIBarButtonItem *fromDateBarBtn = [[UIBarButtonItem alloc] initWithCustomView:fromDateBtn];
    //        UIBarButtonItem *toDateBarBtn = [[UIBarButtonItem alloc] initWithCustomView:toDateBtn];
    //        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    //
    //        //this tells us if the From or To button is active
    //        self.curDateRangeActive = FromDateActive;
    //
    //        [barItems addObject:fromDateBarBtn];
    //        [barItems addObject:toDateBarBtn];
    //        [barItems addObject:flexSpace];
    //        [barItems addObject:doneDateBarBtn];
    //        [pickerToolbar setItems:barItems animated:YES];
    //
    //#ifdef IPAD_VERSION
    //
    //        fromToDatePicker =  [self.storyboard instantiateViewControllerWithIdentifier:@"FromToDatePicker"];
    //
    //        navDatePickerController = [[UINavigationController alloc] initWithRootViewController:fromToDatePicker];
    //
    //        fromToDatePicker.navigationItem.title = @"Select Date Range";
    //        fromToDatePicker.navigationItem.rightBarButtonItem = doneDateBarBtn;
    //        fromToDatePicker.preferredContentSize = CGSizeMake(400, 400);
    //
    //
    //        fromToDatePicker.fromDateValue = self.startdate;
    //        fromToDatePicker.toDateValue = self.enddate;
    //
    //        navDatePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //        navDatePickerController.modalPresentationStyle = UIModalPresentationFormSheet;
    //
    //        [self presentViewController:navDatePickerController animated:YES completion:nil];
    //#else
    //        [pickerViewDate addSubview:pickerToolbar];
    //        [pickerViewDate addSubview:theDatePicker];
    //        [self.view addSubview:pickerViewDate];
    //#endif
    //
    //    }
    //    @catch (id theException) {
    //#ifndef RELEASE
    //        NSLog(@"%@ doesn't respond to appendString:!", [theException name]);
    //#endif
    //    }
}
- (void) WWCalendarTimeSelectorDone:(WWCalendarTimeSelector *)selector date:(NSDate *)date {
    NSLog(@"%@date:", date);
}

- (void)WWCalendarTimeSelectorDone:(WWCalendarTimeSelector *)selector dates:(NSArray<NSDate *> *)dates {
    NSLog(@"%@date:", dates);
    
    self.selectedFromDateValue = [self convertDateToString:dates.firstObject] ;
    self.selectedToDateValue = [self convertDateToString:dates.lastObject] ;
    
    [self datePickerDoneClick];
    
}
-(void)datePickerDoneClick {
    
    DataManager* manager = [DataManager sharedManager];
    if (manager.isBusy) {
        [self showServerBusy];
        return;
    }
    
    NSError* error = nil;
    [manager stopTimer];
    NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&error];
    if (nil != error) {
        [self closeDatePicker:self];
        [SharedUICode messageBox:@"Error" message:[NSString stringWithFormat:@"There was an error checking if current employee has pending updates - %@", error.localizedDescription]];
        [ErrorLogging logErrorWithDomain:@"PENDING_UPDATES" code:UNKNOWN_ERROR description:@"UNABLE_TO_CHECK_PENDING_UPDATES" error:nil];
        [manager startUpdateTimer];
        return;
    }
    
    if (![CommonLib DoWeHaveNetworkConnection]) {
        [self closeDatePicker:self];
        [SharedUICode messageBox:nil message:@"No Internet Connection.  Make sure you have an internet connection and not on airplane mode." withCompletion:^{
            [manager startUpdateTimer];
            return;
        }];
    }
    
    if (0 == count) {
        [self closeDatePickerAndCallEmployeeTimeEntriesIfNeeded];
    } else {
        [SharedUICode yesNo:nil message:@"You have PENDING UPDATES to the server.  If you refresh now, you will lose ALL unsaved pending changes to the server.\n\nAre you absolutely sure?" yesBtnTitle:@"Yes - Please Refresh" noBtnTitle:@"No - Do Nothing" withCompletion:^(YesNoCancelResult Result) {
            switch (Result) {
                case resultYes:
                    [self closeDatePickerAndCallEmployeeTimeEntriesIfNeeded];
                    break;
                case resultNo:
                    [manager startUpdateTimer];
                    break;
                default:
                    break;
            }
        }];
    }
}

-(IBAction)dateChanged{
    
    NSString *datePicked = [[theDatePicker date] toDefaultDateString];
    if (self.curDateRangeActive == FromDateActive){
        fromDateBtn.titleLabel.text = [[NSString alloc] initWithFormat:@"From %@", datePicked];
        self.selectedFromDateValue = datePicked;
    }
    else{
        toDateBtn.titleLabel.text = [[NSString alloc] initWithFormat:@"To %@", datePicked];
        self.selectedToDateValue = datePicked;
    }
}


-(BOOL)closeDatePicker:(id)sender{
#ifdef IPAD_VERSION
    self.selectedFromDateValue = fromToDatePicker.fromDateValue;
    self.selectedToDateValue = fromToDatePicker.toDateValue;
    
    [self dismissViewControllerAnimated:NO completion:nil];
#else
    [pickerViewDate removeFromSuperview];
    //   [SelectedTextField resignFirstResponder];
#endif
    
    return YES;
}

-(bool) isFromDateAfterToDates:(NSString *) fromDateStr toDate: (NSString *) toDateStr {
    
    NSDateFormatter *datePickerFormat = [[NSDateFormatter alloc] init];
    [datePickerFormat setDateFormat:@"MM/dd/yyyy"];
    NSDate *fromDate = [datePickerFormat dateFromString:fromDateStr];
    NSDate *toDate = [datePickerFormat dateFromString:toDateStr];
    
    NSComparisonResult compareResult;
    
    compareResult = [fromDate compare:toDate]; // comparing two dates
    
    if(compareResult == NSOrderedDescending)
        return TRUE;
    else
        return FALSE;
    
}

- (void)closeDatePickerAndCallEmployeeTimeEntriesIfNeeded {
    
    NSString *fromDateValue = self.selectedFromDateValue;
    NSString *toDateValue = self.selectedToDateValue;
    
    if ([self isFromDateAfterToDates:fromDateValue toDate: toDateValue])
    {
        [SharedUICode messageBox:@"Alert" message:@"You Selected the To Date Before the From Date. Please Fix" withCompletion:^{
            return;
        }];
        //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You Selected the To Date Before the From Date. Please Fix!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        //  [alert show];
    }
    
    else
    {
        [self closeDatePicker:self];
        //if the values of the date range are different from the one on the screen then fetch new time sheet with the new dates
        if (!([fromDateValue isEqualToString:self.startdate] && [toDateValue isEqualToString:self.enddate]))
        {
            self.startdate = fromDateValue;
            self.enddate = toDateValue;
            user.payrollStartDate = self.startdate;
            user.payrollEndDate = self.enddate;
            //save dates
            [[NSUserDefaults standardUserDefaults] setObject:user.payrollStartDate  forKey:@"payrollStartDate"];
            [[NSUserDefaults standardUserDefaults] setObject:user.payrollEndDate forKey:@"payrollEndDate"];
            //   [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
            
            [self refreshTimeEntries:TRUE displayBusyMsg:TRUE];
        } else {
            DataManager* manager = [DataManager sharedManager];
            [manager startUpdateTimer];
        }
    }
}

/*-(IBAction)DatePickerDoneClick{
 
 NSString *fromDateValue = self.selectedFromDateValue;
 NSString *toDateValue = self.selectedToDateValue;
 
 NSDateFormatter *datePickerFormat = [[NSDateFormatter alloc] init];
 [datePickerFormat setDateFormat:@"MM/dd/yyyy"];
 NSDate *fromDate = [datePickerFormat dateFromString:fromDateValue];
 NSDate *toDate = [datePickerFormat dateFromString:toDateValue];
 
 NSComparisonResult result;
 
 result = [fromDate compare:toDate]; // comparing two dates
 
 if(result == NSOrderedDescending)
 {
 NSString *dlgMessage = [[NSString alloc] initWithFormat:@"ERROR: The from date %@ can not be later than the to date %@", fromDateValue, toDateValue];
 
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:dlgMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
 
 [alert show];
 
 }
 else{
 
 DataManager* manager = [DataManager sharedManager];
 if (manager.isBusy) {
 [self showServerBusy];
 return;
 }
 
 NSError* error = nil;
 [manager stopTimer];
 if (![manager doesCurrentEmployeeNeedingSubmission:&error]) {
 #ifndef RELEASE
 if (nil != error) {
 [SharedUICode messageBox:@"Error" message:[NSString stringWithFormat:@"There was an error checking if the server needs update %@", error.localizedDescription]];
 [manager startUpdateTimer];
 return;
 }
 #endif
 [self closeDatePickerAndCallEmployeeTimeEntriesIfNeeded];
 } else {
 [SharedUICode yesNo:nil message:@"You have PENDING UPDATES to the server.  If you refresh now, you will lose ALL unsaved pending changes to the server.\n\nAre you absolutely sure?" yesBtnTitle:@"Yes - Please Refresh" noBtnTitle:@"No - Do Nothing" withCompletion:^(YesNoCancelResult Result) {
 switch (Result) {
 case resultYes:
 [self closeDatePickerAndCallEmployeeTimeEntriesIfNeeded];
 break;
 case resultNo:
 [manager startUpdateTimer];
 break;
 default:
 break;
 }
 }];
 }
 }
 
 }
 */

/*
 -(void) DatePickerCancelClick
 {
 [self closeDatePicker];
 
 }
 -(IBAction)DatePickerDoneClick{
 
 DataManager* manager = [DataManager sharedManager];
 if (manager.isBusy) {
 [self showServerBusy];
 return;
 }
 
 NSError* error = nil;
 [manager stopTimer];
 NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&error];
 if (nil != error) {
 [self closeDatePicker:self];
 [SharedUICode messageBox:@"Error" message:[NSString stringWithFormat:@"There was an error checking if current employee has pending updates - %@", error.localizedDescription]];
 [manager startUpdateTimer];
 return;
 }
 
 if (![CommonLib DoWeHaveNetworkConnection]) {
 [self closeDatePicker:self];
 [SharedUICode messageBox:nil message:@"No Internet Connection.  Make sure you have an internet connection and not on airplane mode." withCompletion:^{
 [manager startUpdateTimer];
 return;
 }];
 }
 
 if (0 == count) {
 [self closeDatePickerAndCallEmployeeTimeEntriesIfNeeded];
 } else {
 [SharedUICode yesNo:nil message:@"You have PENDING UPDATES to the server.  If you refresh now, you will lose ALL unsaved pending changes to the server.\n\nAre you absolutely sure?" yesBtnTitle:@"Yes - Please Refresh" noBtnTitle:@"No - Do Nothing" withCompletion:^(YesNoCancelResult Result) {
 switch (Result) {
 case resultYes:
 [self closeDatePickerAndCallEmployeeTimeEntriesIfNeeded];
 break;
 case resultNo:
 [manager startUpdateTimer];
 break;
 default:
 break;
 }
 }];
 }
 
 
 
 }
 
 -(IBAction)DatePickerFromDateClick{
 self.curDateRangeActive = FromDateActive;
 fromDateBtn.backgroundColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR);
 toDateBtn.backgroundColor = [UIColor grayColor];
 
 NSString *dataValue = [fromDateBtn.titleLabel.text substringFromIndex:5];
 NSDate* dateFromString = [dataValue toDefaultDate];
 
 [theDatePicker setDate:dateFromString];
 
 }
 -(IBAction)DatePickerToDateClick{
 self.curDateRangeActive = ToDateActive;
 toDateBtn.backgroundColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR);
 fromDateBtn.backgroundColor = [UIColor grayColor];
 
 NSString *dataValue = [toDateBtn.titleLabel.text substringFromIndex:3];
 NSDate* dateFromString = [dataValue toDefaultDate];
 
 [theDatePicker setDate:dateFromString];
 
 }
 */

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// returns the number of rows
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return 30;
    //    return [pickerViewArray count];
}



- (IBAction)doSetDateRange:(id)sender {
    [self DatePickerView];
}

-(void) doChangeDate{
    [self DatePickerView];
}

- (IBAction)revealMenu:(id)sender {
    if (_fromCustomerDetail == YES) {
        [self.previousNavigation setNavigationBarHidden:NO];
        [self.previousNavigation popViewControllerAnimated:NO];
    } else {
        [self.slidingViewController anchorTopViewTo:ECRight];
    }
}
- (void)dealloc
{
    [TimeSheetDetailViewController releaseController];
}

@end
