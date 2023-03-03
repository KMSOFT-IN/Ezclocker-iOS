//
//  EmployerSettingsViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 8/31/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import "EmployerSettingsViewController.h"
#import "ECSlidingViewController.h"
#import "user.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "NSDictionary+Extensions.h"
#import "NSData+Extensions.h"
#import "SharedUICode.h"
#import "NSString+Extensions.h"
#import <GooglePlaces/GooglePlaces.h>
#import "EmployerOverTimeTableViewController.h"
#import "EmployerAutoBreaksTableViewController.h"
#import "EarlyClockInTableViewController.h"
#import "ScheduleStartDaysViewController.h"
#import "LoginViewController.h"
#import "InitialSlidingViewController.h"
#import "MenuViewController.h"

@interface EmployerSettingsViewController () <EmployerOverTimeTableViewControllerDelegate>
{
    BOOL CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS;
    BOOL CALCULATE_DAILY_OVERTIME_IN_TIME_SHEET_EXPORTS;
    NSNumber *CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS;
    NSNumber *CALCULATE_DAILY_OVERTIME_AFTER_HOURS;
    BOOL ALLOW_AUTOMATIC_BREAKS;
    NSNumber *AUTO_BREAK_WORK_HOURS_OPTION;
    NSNumber *AUTO_BREAK_WORK_MINUTES_OPTION;
    NSNumber *RESTRICT_CLOCK_IN_TO_SCHEDULE;
    NSNumber *ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE;
    NSNumber *ROUND_CLOCK_IN_CLOCK_OUT_OPTION;
    NSNumber *SCHEDULE_START_DAY;
}
@end

@implementation EmployerSettingsViewController

bool scheduleDayChanged = FALSE;
bool disableEmployeeEditingChanged = FALSE;
bool enablePushNotificationsChanged = FALSE;
const int MAX_OPTIONS = 13;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS = [NSNumber numberWithInt:40];
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Settings";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;
    _settingsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _saveBtn.enabled = FALSE;
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    _appVersionLabel.text = appVersionString;
    
    UserClass *user = [UserClass getInstance];
    _employerEmail.text = user.userEmail;
    
    //enable overtime if the subscription supports it
    NSMutableArray *features = user.subscription_enabledFeatures;
     if ((features != nil) && ([features count] > 0) && ([features indexOfObject:@"OVERTIME"] != NSNotFound) )
     {
         _overtimeCellView.contentView.alpha = 1.0f;
         _overtimeCellView.userInteractionEnabled = YES;
         _overtimeDetailLabel.text = @"Tap to set overtime calculations.";
     }
     else
     {
        _overtimeCellView.contentView.alpha = 0.2;
        _overtimeCellView.userInteractionEnabled = NO;
         _overtimeDetailLabel.text = @"You need to upgrade your subscription to access this feature.";
     }

    [self callGetAllOptions];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];

}
// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

//MARK:- Tableview Delegate


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return MAX_OPTIONS;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //auto break
    if (indexPath.row == 7)
    {
        EmployerAutoBreaksTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmployerAutoBreaks"];
        viewController.ALLOW_AUTOMATIC_BREAKS = ALLOW_AUTOMATIC_BREAKS;
        viewController.AUTO_BREAK_WORK_HOURS_OPTION = AUTO_BREAK_WORK_HOURS_OPTION;
        viewController.AUTO_BREAK_WORK_MINUTES_OPTION = AUTO_BREAK_WORK_MINUTES_OPTION;
        viewController.delegate = self;
        [self.navigationController pushViewController:viewController animated:YES];
    }
    //overtime
    else if (indexPath.row == 8)
    {
        EmployerOverTimeTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmployerOverTimeTableViewController"];
        viewController.CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS = CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS;
        viewController.CALCULATE_DAILY_OVERTIME_IN_TIME_SHEET_EXPORTS = CALCULATE_DAILY_OVERTIME_IN_TIME_SHEET_EXPORTS;
        viewController.CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS = CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS;
        viewController.CALCULATE_DAILY_OVERTIME_AFTER_HOURS = CALCULATE_DAILY_OVERTIME_AFTER_HOURS;
        viewController.delegate = self;
        [self.navigationController pushViewController:viewController animated:YES];
    }
    //Restrict Early clock in
    if (indexPath.row == 9)
    {
        EarlyClockInTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EarlyClockIn"];

        viewController.delegate = self;
        if (ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE)
            viewController.selectedOptionIndex = ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE;
        else
            viewController.selectedOptionIndex = [NSNumber numberWithInt: -1];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    //Rounding
    if (indexPath.row == 10)
    {
        RoundingTimeClockViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RoundingTimeClock"];

        viewController.delegate = self;
        if (ROUND_CLOCK_IN_CLOCK_OUT_OPTION)
            viewController.selectedOptionIndex = ROUND_CLOCK_IN_CLOCK_OUT_OPTION;
        else
            viewController.selectedOptionIndex = [NSNumber numberWithInt: 0];

        [self.navigationController pushViewController:viewController animated:YES];
    }
    //Schedule Start Day
    if (indexPath.row == 11)
    {
        ScheduleStartDaysViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ScheduleStartDate"];

        viewController.delegate = self;
        if (SCHEDULE_START_DAY)
            viewController.selectedOptionIndex = SCHEDULE_START_DAY;
        else
            viewController.selectedOptionIndex = [NSNumber numberWithInt: 0];

        [self.navigationController pushViewController:viewController animated:YES];
    }

}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //last row is the delete so make the cell bigger
    if (indexPath.row == MAX_OPTIONS - 1)
        return 80;
    else
        return 48;
}

//MARK:- Button Click



- (IBAction)doSave:(id)sender {
    [self startSpinnerWithMessage:@"Saving, please wait..."];
    
    [self callEmployerOptionsSetAll: [_allowEditSwitch isOn] withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue saving the options. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        
        disableEmployeeEditingChanged = FALSE;
    }];

 
    _saveBtn.enabled = FALSE;
    
}

- (IBAction)doSwitchChanged:(id)sender {
    _saveBtn.enabled = TRUE;
    disableEmployeeEditingChanged = TRUE;
}


-(void) callEmployerOptionsSetAll: (int)selectedRow withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    NSString *httpPostString = [NSString stringWithFormat:@"%@employerOptions/setAll/%@?source=iPhone&authToken=%@", SERVER_URL, tmpEmployerID, tmpAuthToken];
    
    
    NSMutableArray *arrayOfDicts = [[NSMutableArray alloc] init];
    
   
    NSString *optionValue = ([_allowEditSwitch isOn] ? @"1" : @"0");

    NSDictionary *dict1 = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"EMPLOYER_DISABLE_TIME_ENTRY_EDITING", @"optionName",
                          optionValue, @"optionValue",
                          nil];
    [arrayOfDicts addObject:dict1];

    optionValue = ([_allowPushNotificationsSwitch isOn] ? @"1" : @"0");

    NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"PUSH_NOTIFICATIONS_ENABLED", @"optionName",
                          optionValue, @"optionValue",
                          nil];
    
    [arrayOfDicts addObject:dict2];
    
  //  NSString *selectedStartDayStr = [NSString stringWithFormat:@"%@",SCHEDULE_START_DAY];

    
    NSDictionary *dict3 = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"startDay", @"optionName",
                           SCHEDULE_START_DAY, @"optionValue",
                           nil];
    
    [arrayOfDicts addObject:dict3];
   
    optionValue = ([_allowBreaksSwitch isOn] ? @"1" : @"0");

    NSDictionary *unpaidBreaksDict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"ALLOW_RECORDING_OF_UNPAID_BREAKS", @"optionName",
                          optionValue, @"optionValue",
                          nil];
    [arrayOfDicts addObject:unpaidBreaksDict];

    
    if (ALLOW_AUTOMATIC_BREAKS) {
        optionValue = @"1";
    } else {
        optionValue = @"0";
    }

    NSDictionary *dictAutoBreakEnabled = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"ALLOW_AUTOMATIC_BREAKS", @"optionName",
                           optionValue, @"optionValue",
                           nil];
    
    [arrayOfDicts addObject:dictAutoBreakEnabled];

    optionValue = (NSString *) AUTO_BREAK_WORK_HOURS_OPTION;
    
    NSDictionary *dictAutoBreakAfterHours = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"AUTO_BREAK_WORK_HOURS_OPTION", @"optionName",
                           optionValue, @"optionValue",
                           nil];
    
    [arrayOfDicts addObject:dictAutoBreakAfterHours];
    
    
    optionValue = (NSString *) AUTO_BREAK_WORK_MINUTES_OPTION;
    
    NSDictionary *dictAutoBreakDuration = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"AUTO_BREAK_WORK_MINUTES_OPTION", @"optionName",
                           optionValue, @"optionValue",
                           nil];
    
    [arrayOfDicts addObject:dictAutoBreakDuration];
    
    
    if (CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS) {
        optionValue = @"1";
    } else {
        optionValue = @"0";
    }

    NSDictionary *dict4 = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS", @"optionName",
                           optionValue, @"optionValue",
                           nil];
    
    [arrayOfDicts addObject:dict4];
    
 //   optionValue = [CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS stringValue];
    
    optionValue = (NSString *) CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS;

    
    NSDictionary *dict5 = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS", @"optionName",
                           optionValue, @"optionValue",
                           nil];
    
    [arrayOfDicts addObject:dict5];
    
    if (CALCULATE_DAILY_OVERTIME_IN_TIME_SHEET_EXPORTS) {
        optionValue = @"1";
    } else {
        optionValue = @"0";
    }
    NSDictionary *dictDailyOvertime = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"CALCULATE_DAILY_OVERTIME", @"optionName",
                           optionValue, @"optionValue",
                           nil];
    
    [arrayOfDicts addObject:dictDailyOvertime];
    
 //   optionValue = [CALCULATE_DAILY_OVERTIME_AFTER_HOURS stringValue];
    optionValue = (NSString *) CALCULATE_DAILY_OVERTIME_AFTER_HOURS;

    NSDictionary *dictDailyOvertimeHours = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"CALCULATE_DAILY_OVERTIME_AFTER_HOURS", @"optionName",
                           optionValue, @"optionValue",
                           nil];
    
    [arrayOfDicts addObject:dictDailyOvertimeHours];
    
    optionValue = ([_requireGPSSwitch isOn] ? @"1" : @"0");

    NSDictionary *dict6 = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"REQUIRE_LOCATION_FOR_CLOCKINOUT", @"optionName",
                          optionValue, @"optionValue",
                          nil];
    
    [arrayOfDicts addObject:dict6];
    
    optionValue = ([_allowCoworkersScheduleSwtich isOn] ? @"1" : @"0");

    NSDictionary *dict7 = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"ALLOW_EMPLOYEES_TO_SEE_COWORKER_SCHEDULES", @"optionName",
                          optionValue, @"optionValue",
                          nil];
    
    [arrayOfDicts addObject:dict7];
    
    if (ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE)
    {
  //      optionValue = [ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE stringValue];
        int optionIntVal = [ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE intValue];
        NSNumber *restrictEarlyClockInOn = [NSNumber numberWithInt:0];
        if (optionIntVal > 0)
            restrictEarlyClockInOn = [NSNumber numberWithInt:1];

        NSDictionary *dictEarlyClockInOnOff = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"RESTRICT_CLOCK_IN_TO_SCHEDULE", @"optionName",
                          restrictEarlyClockInOn, @"optionValue",
                          nil];
        
        NSDictionary *dictEarlyClockIn = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE", @"optionName",
                          ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE, @"optionValue",
                          nil];

        [arrayOfDicts addObject:dictEarlyClockInOnOff];
        [arrayOfDicts addObject:dictEarlyClockIn];
    }
    
    if (ROUND_CLOCK_IN_CLOCK_OUT_OPTION)
    {
        int iOptionVal = [ROUND_CLOCK_IN_CLOCK_OUT_OPTION intValue];
        if (iOptionVal == 1)
            optionValue = @"NEAREST_5";
        else if (iOptionVal == 2)
            optionValue = @"NEAREST_6";
        else if (iOptionVal == 3)
            optionValue = @"NEAREST_15";
        else
            optionValue = @"NONE";
        
        NSNumber *isRoundingOn = [NSNumber numberWithInt:0];
        if (![optionValue isEqualToString:@"NONE"])
            isRoundingOn = [NSNumber numberWithInt:1];
        
        NSDictionary *dictRoundingOption, *dictIsRondingOnOff;
        
        //turn on or off rounding
        dictIsRondingOnOff = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"ROUND_CLOCK_IN_CLOCK_OUT", @"optionName",
                                  isRoundingOn, @"optionValue",
                          nil];
        //set the rounding value
        dictRoundingOption = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"ROUND_CLOCK_IN_CLOCK_OUT_OPTION", @"optionName",
                            optionValue, @"optionValue",
                            nil];
    
        [arrayOfDicts addObject:dictIsRondingOnOff];
        [arrayOfDicts addObject:dictRoundingOption];
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arrayOfDicts
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];

    
  /*  NSString* request_body = [NSString
                              stringWithFormat:@"authToken=%@&employerId=%@",
                              [tmpAuthToken URLUTF8Encode],
                              [[user.employerID  stringValue] URLUTF8Encode]
                              ];
    */
    request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    //   NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
   // ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

    
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
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
                
   //             [self stopSpinner];
                
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

- (void)weeklyOverTime:(BOOL)overtime weeklyOverTimeHour:(NSNumber *)hour dailyOvertime:(BOOL)dailyOvertime dailyOvertimeHour: (NSNumber*) dailyHour{
    
    [self.navigationController popViewControllerAnimated:YES];
    
    CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS = overtime;
    CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS = hour;
    
    CALCULATE_DAILY_OVERTIME_IN_TIME_SHEET_EXPORTS = dailyOvertime;
    CALCULATE_DAILY_OVERTIME_AFTER_HOURS = dailyHour;
    
    if (CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS) {
        self.weeklyOnOffLabel.text = @"ON";
    } else {
        self.weeklyOnOffLabel.text = @"OFF";
    }
     _saveBtn.enabled = TRUE;
}

/*-(void)callSetEmployerDisableEditingOption: (bool) switchIsOn withCompletion:(ServerResponseCompletionBlock)completion

{
    //    DEBUG_MSG
    //    NSAssert(nil != completion, @"completion block cannot be nil %@", msg); NSAssert(nil != employeeId && [employeeId integerValue] > 0, @"employerId cannot be nil and must be valid %@", msg);
    
    
    
    UserClass *user = [UserClass getInstance];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    
    int optionValue = (switchIsOn ? 1 : 0);
    NSString *httpPostString = [NSString stringWithFormat:@"%@employerOptions/set/%@?optionName=%@&optionValue=%d&source=iPhone&authToken=%@", SERVER_URL, tmpEmployerID, @"EMPLOYER_DISABLE_TIME_ENTRY_EDITING", optionValue, tmpAuthToken];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    request.HTTPMethod = @"PUT";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
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
                //               }
            }];
        }
    }];
    [dataTask resume];
    
}
*/

-(void)callSetEmployerEnablePushNotifications: (bool) switchIsOn withCompletion:(ServerResponseCompletionBlock)completion

{
    //    DEBUG_MSG
    //    NSAssert(nil != completion, @"completion block cannot be nil %@", msg); NSAssert(nil != employeeId && [employeeId integerValue] > 0, @"employerId cannot be nil and must be valid %@", msg);
    
    
    
    UserClass *user = [UserClass getInstance];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    
    int optionValue = (switchIsOn ? 1 : 0);
    NSString *httpPostString = [NSString stringWithFormat:@"%@employerOptions/set/%@?optionName=%@&optionValue=%d&source=iPhone&authToken=%@", SERVER_URL, tmpEmployerID, @"PUSH_NOTIFICATIONS_ENABLED", optionValue, tmpAuthToken];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    request.HTTPMethod = @"PUT";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
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
                //               }
            }];
        }
    }];
    [dataTask resume];
    
}

-(void) callGetAllOptions
{
    [self startSpinnerWithMessage:@"Checking Account..."];
    UserClass *user = [UserClass getInstance];
    [self callGetAllOptionsAPI:user.userID withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        [self checkOptions:aResults];
    }];

}


- (void)callGetAllOptionsAPI:(NSNumber*)employeeId withCompletion:(ServerResponseCompletionBlock)completion
{
    //    DEBUG_MSG
    //    NSAssert(nil != completion, @"completion block cannot be nil %@", msg); NSAssert(nil != employeeId && [employeeId integerValue] > 0, @"employerId cannot be nil and must be valid %@", msg);
    
    
    
    UserClass *user = [UserClass getInstance];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    
    NSString *httpPostString = [NSString stringWithFormat:@"%@employerOptions/getAll/%@?authToken=%@", SERVER_URL, tmpEmployerID, tmpAuthToken];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
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
                
                if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                    MAINTHREAD_BLOCK_START()
                    completion(errorCode, resultMessage, results, aError);
                    THREAD_BLOCK_END()
                    return;
                }
                
                if ([NSDictionary isNilOrNull:results]) {
                    MAINTHREAD_BLOCK_START()
                    completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
                    THREAD_BLOCK_END()
                } else {
                    MAINTHREAD_BLOCK_START()
                    completion(errorCode, resultMessage, results, aError);
                    THREAD_BLOCK_END()
                }
            }];
        }
    }];
    [dataTask resume];
    
}
-(void) checkOptions:(NSDictionary*) employerOptionsResults
{
    NSArray *employerOptions = [employerOptionsResults valueForKey:@"employerOptions"];;
    //check if the edit disable flag changed
    UserClass *user = [UserClass getInstance];
    //ALLOW_RECORDING_OF_UNPAID_BREAKS
    //ALLOW_AUTOMATIC_BREAKS
    //AUTO_BREAK_WORK_HOURS_OPTION value is the number in the edit box
    //AUTO_BREAK_WORK_MINUTES_OPTION value is the number in the edit box
    //RESTRICT_CLOCK_IN_TO_SCHEDULE value =0 means not selcted and then each value represents the drop down value
    //ROUND_CLOCK_IN_CLOCK_OUT_OPTION value is None or the value of the drop box
    //NONE, NEAREST_5, NEAREST_6, NEAREST_15
    NSString *optionName;
    NSNumber *optionValue;
    NSString *optionValueStr;
    NSNumberFormatter *numberFomatter = [[NSNumberFormatter alloc] init];
    for (NSDictionary* employerOption in employerOptions) {
        optionName = [employerOption valueForKey:@"optionName"];
        if ([optionName isEqualToString:@"EMPLOYER_DISABLE_TIME_ENTRY_EDITING"])
        {
            optionValue = [employerOption valueForKey:@"optionValue"];
            if (user.disableTimeEntryEditing != [optionValue intValue]){
                user.disableTimeEntryEditing = [optionValue intValue];
                //persist selection
                [[NSUserDefaults standardUserDefaults] setInteger:user.disableTimeEntryEditing forKey:@"disableTimeEntryEditing"];
  //              [[NSUserDefaults standardUserDefaults] synchronize];
            }
            if (user.disableTimeEntryEditing)
                [_allowEditSwitch setOn:YES animated:YES];
            else
                [_allowEditSwitch setOn:FALSE animated:YES];
            
        }
        //push notifications option
        else if ([optionName isEqualToString:@"PUSH_NOTIFICATIONS_ENABLED"])
        {
            optionValue = [employerOption valueForKey:@"optionValue"];
            BOOL boolValue = [optionValue boolValue];
            if (boolValue)
                optionValue = [NSNumber numberWithInt:1];
 //               optionValue = @"1";
            if (user.disableTimeEntryEditing != [optionValue intValue]){
                user.disableTimeEntryEditing = [optionValue intValue];
                //persist selection
                [[NSUserDefaults standardUserDefaults] setInteger:user.disableTimeEntryEditing forKey:@"pushNotificationsEnabled"];
  //              [[NSUserDefaults standardUserDefaults] synchronize];
            }
            if (user.disableTimeEntryEditing)
                [_allowPushNotificationsSwitch setOn:YES animated:YES];
            else
                [_allowPushNotificationsSwitch setOn:FALSE animated:YES];
            
        }
        else if ([optionName isEqualToString:@"REQUIRE_LOCATION_FOR_CLOCKINOUT"])
        {
             optionValue = [employerOption valueForKey:@"optionValue"];
   //          BOOL boolValue = [optionValue boolValue];
  
             if ([optionValue intValue] == 1)
                [_requireGPSSwitch setOn:YES animated:YES];
             else
                [_requireGPSSwitch setOn:FALSE animated:YES];
                  
        }
        else if ([optionName isEqualToString:@"ALLOW_EMPLOYEES_TO_SEE_COWORKER_SCHEDULES"])
        {
             optionValue = [employerOption valueForKey:@"optionValue"];
   //          BOOL boolValue = [optionValue boolValue];
  
             if ([optionValue intValue] == 1)
                [_allowCoworkersScheduleSwtich setOn:YES animated:YES];
             else
                [_allowCoworkersScheduleSwtich setOn:FALSE animated:YES];
                  
        }
        else if ([optionName isEqualToString:@"ALLOW_RECORDING_OF_UNPAID_BREAKS"])
        {
             optionValue = [employerOption valueForKey:@"optionValue"];
   //          BOOL boolValue = [optionValue boolValue];
  
             if ([optionValue intValue] == 1)
                [_allowBreaksSwitch setOn:YES animated:NO];
             else
                [_allowBreaksSwitch setOn:FALSE animated:NO];
                  
        }
        //Auto Break options:
        
        else if ([optionName isEqualToString:@"ALLOW_AUTOMATIC_BREAKS"])
        {
             
            optionValue = [employerOption valueForKey:@"optionValue"];
            //set the overtime total hours value
            if (!([(NSString *)optionValue isEqualToString:@"0"]))
            {
            
                self.isAutoBreakOn.text = @"ON";
                ALLOW_AUTOMATIC_BREAKS = TRUE;
            }
            else
            {
                self.isAutoBreakOn.text = @"OFF";
                ALLOW_AUTOMATIC_BREAKS = FALSE;
            }
        }
        
        
        //Auto Breaks After Hours
        else if ([optionName isEqualToString:@"AUTO_BREAK_WORK_HOURS_OPTION"])
        {
            optionValueStr = [employerOption valueForKey:@"optionValue"];
            if (!([optionValueStr isEqualToString:@"0"])) {
                optionValue = [numberFomatter numberFromString:optionValueStr];
                AUTO_BREAK_WORK_HOURS_OPTION = optionValue;
            }
        }
        //Auto Breaks duration
        else if ([optionName isEqualToString:@"AUTO_BREAK_WORK_MINUTES_OPTION"])
        {
            optionValueStr = [employerOption valueForKey:@"optionValue"];
            if (!([optionValueStr isEqualToString:@"0"])) {
                optionValue = [numberFomatter numberFromString:optionValueStr];
                AUTO_BREAK_WORK_MINUTES_OPTION = optionValue;
            }
        }

        //Overtime calcuations flag
        else if ([optionName isEqualToString:@"CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS"])
        {
            optionValue = [employerOption valueForKey:@"optionValue"];
            BOOL boolValue = [optionValue boolValue];
            //if (boolValue)
            //{
                CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS = boolValue;
                if (CALCULATE_OVERTIME_IN_TIME_SHEET_EXPORTS) {
                    self.weeklyOnOffLabel.text = @"ON";
                } else {
                    self.weeklyOnOffLabel.text = @"OFF";
                }
                //set the UI
            //}
        }
        //Overtime weekly calcuations hours
        else if ([optionName isEqualToString:@"CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS"])
        {
            NSString *optionValueStr = [employerOption valueForKey:@"optionValue"];
            //set the overtime total hours value
            if (!([optionValueStr isEqualToString:@"0"])) {
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                optionValue = [f numberFromString:optionValueStr];
                CALCULATE_WEEKLY_OVERTIME_AFTER_HOURS = optionValue ;
            }
        }
        //Overtime daily calcuations flag
        else if ([optionName isEqualToString:@"CALCULATE_DAILY_OVERTIME"])
        {
            optionValue = [employerOption valueForKey:@"optionValue"];
            BOOL boolValue = [optionValue boolValue];
            CALCULATE_DAILY_OVERTIME_IN_TIME_SHEET_EXPORTS = boolValue;

        }
        //Overtime daily calcuations hours
        else if ([optionName isEqualToString:@"CALCULATE_DAILY_OVERTIME_AFTER_HOURS"])
        {
            NSString *optionValueStr = [employerOption valueForKey:@"optionValue"];
            //set the overtime total hours value
            if (!([optionValueStr isEqualToString:@"0"])) {
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                optionValue = [f numberFromString:optionValueStr];
                CALCULATE_DAILY_OVERTIME_AFTER_HOURS = optionValue;
            }
        }
        
        //Early Clock In
 //       else if ([optionName isEqualToString:@"RESTRICT_CLOCK_IN_TO_SCHEDULE"])
         else if ([optionName isEqualToString: @"ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE"])
        {
            NSString *optionStrValue = [employerOption valueForKey:@"optionValue"];
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            optionValue = [formatter numberFromString:optionStrValue];
            ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE = optionValue ;
            int optionValInt = [optionValue intValue];
            _earlyClockInLabel.text = [CommonLib earlyClockInShortDescription:optionValInt];
        }
        //Rounding

        else if ([optionName isEqualToString:@"ROUND_CLOCK_IN_CLOCK_OUT_OPTION"])
        {
            //default option is 0 which is none
            ROUND_CLOCK_IN_CLOCK_OUT_OPTION = 0;
            NSString *optionStrValue = [employerOption valueForKey:@"optionValue"];
            //set the overtime total hours value
            if ([optionStrValue isEqualToString:@"NEAREST_5" ])
                ROUND_CLOCK_IN_CLOCK_OUT_OPTION = [NSNumber numberWithInt:1];
            else if ([optionStrValue isEqualToString:@"NEAREST_6" ])
                ROUND_CLOCK_IN_CLOCK_OUT_OPTION = [NSNumber numberWithInt:2];
            else if ([optionStrValue isEqualToString:@"NEAREST_15" ])
                ROUND_CLOCK_IN_CLOCK_OUT_OPTION = [NSNumber numberWithInt:3];

            int optionValInt = [ROUND_CLOCK_IN_CLOCK_OUT_OPTION intValue];
            _roundingTimeClockLabel.text = [CommonLib roundingTimeClockDescription: optionValInt];
            
        }

        //schedule start day option
        else if ([optionName isEqualToString:@"startDay"])
        {
            optionValue = [employerOption valueForKey:@"optionValue"];
            selectedStartDate = [optionValue intValue];
            SCHEDULE_START_DAY = optionValue;
            //set the schedule day button
            NSString *resultString = [CommonLib getDayOfTheWeek:selectedStartDate];
            _scheduleStartDayLabel.text = resultString;
            //[_scheduleDayBtn setTitle:resultString forState:UIControlStateNormal];
        }
        
    }
    
}


- (IBAction)pushNotificationSwitchChanged:(id)sender {
    _saveBtn.enabled = TRUE;
    enablePushNotificationsChanged = TRUE;

}

- (IBAction)allowEmployeesEditSwitchChanged:(id)sender {
    _saveBtn.enabled = TRUE;
    disableEmployeeEditingChanged = TRUE;

}

- (void)saveAutoBreaksOptionsDidFinish:(BOOL)autoBreak breakAfterHours:(NSNumber*)hours breakDuration: (NSNumber*) duration
{
    ALLOW_AUTOMATIC_BREAKS = autoBreak;
    AUTO_BREAK_WORK_HOURS_OPTION = hours;
    AUTO_BREAK_WORK_MINUTES_OPTION = duration;
    if (ALLOW_AUTOMATIC_BREAKS) {
        self.isAutoBreakOn.text = @"ON";
    } else {
        self.isAutoBreakOn.text = @"OFF";
    }

    _saveBtn.enabled = TRUE;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)optionWasSelected: (int) selectedOption
{
    [self.navigationController popViewControllerAnimated:YES];
    
    NSString *optionDescription = [CommonLib earlyClockInShortDescription:selectedOption];
    
    _earlyClockInLabel.text = optionDescription;
    
    if (![optionDescription isEqualToString:@"OFF"])
        _earlyClockInLabel.textColor = [UIColor blackColor];
    else
        _earlyClockInLabel.textColor = [UIColor lightGrayColor];
    
    ALLOW_EARLY_CLOCK_AT_MINS_BEFORE_SCHEDULE = [NSNumber numberWithInt:selectedOption];

    _saveBtn.enabled = TRUE;
}

- (void)roundingOptionWasSelected: (int) selectedOption
{
    [self.navigationController popViewControllerAnimated:YES];
    
    NSString *optionDescription = [CommonLib roundingTimeClockDescription:selectedOption];
    
    _roundingTimeClockLabel.text = optionDescription;
    
    if (![optionDescription isEqualToString:@"OFF"])
        _roundingTimeClockLabel.textColor = [UIColor blackColor];
    else
        _roundingTimeClockLabel.textColor = [UIColor lightGrayColor];

    
    ROUND_CLOCK_IN_CLOCK_OUT_OPTION = [NSNumber numberWithInt:selectedOption];

    _saveBtn.enabled = TRUE;
}

- (void)dayOptionWasSelected: (int) selectedOption
{
    [self.navigationController popViewControllerAnimated:YES];
    
    NSString *optionDescription = [CommonLib getDayOfTheWeek:selectedOption];
    
    _scheduleStartDayLabel.text = optionDescription;

    
    SCHEDULE_START_DAY = [NSNumber numberWithInt:selectedOption];

    _saveBtn.enabled = TRUE;
}


- (IBAction)doDeleteAccount:(UIButton *)sender {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Alert"
                                 message:@"Are you sure you want to delete your account?. All information will be lost"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

        [self signintoAccount];
    }];
    
    [alert addAction:defaultAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        [alert dismissViewControllerAnimated:YES completion:nil];
        
    }];
    
    [alert addAction:cancelAction];
    

    
    [self presentViewController:alert animated:YES completion:nil];

}

-(void) callEmployeeAPI:(int)flag UserName: (NSString*) userName Password: (NSString *) userPassword withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    // NSString *request_body;
    
    NSString *accountUserId = [user.realUserId stringValue];
    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/%@", SERVER_URL, accountUserId];

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSError *error;

/*Payload:
{
    "employerUsername": "string: employer's username",
    "employerPassword": "string: employer's password",
    "returnDeleteLog": boolean (false by default, not required)
}
 */
    

        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        [dict setValue:userName forKey:@"employerUsername"];
        [dict setValue:userPassword forKey:@"employerPassword"];
        [dict setValue:@"true" forKey:@"returnDeleteLog"];

        

    
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //set request body into HTTPBody.
        urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    

    [urlRequest setHTTPMethod:@"DELETE"];

     
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

-(void)signintoAccount
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Alert"
                                 message:@"We need to authenticate your account to confirm it's you. Please sign in the next screen."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

        LoginViewController *loginController = [self.storyboard instantiateViewControllerWithIdentifier:@"Login"];
        
        loginController.signinOnly = TRUE;
        loginController.delegate = (id) self;
        [self.navigationController pushViewController:loginController animated:FALSE];

    }];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];

    

}

- (void)loginViewControllerDidFinish:(LoginViewController *)controller UserName:(NSString*) userName Password: (NSString *) userPassword;
{
    [self.navigationController popViewControllerAnimated:YES];
    [self deleteAccount: userName Password: userPassword];
}

-(void) deleteAccount: (NSString*) userName Password: (NSString *) userPassword
{
    [self startSpinnerWithMessage:@"Deleting, please wait..."];
    
    [self callEmployeeAPI:1 UserName: userName Password: userPassword withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
                [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later or contact support@ezclocker.com to delete your account." withCompletion:^{
                    return;
                }];
        }
        else{
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Confirmation"
                                         message:@"Your Account has been deleted"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                
                [alert dismissViewControllerAnimated:YES completion:nil];
                [CommonLib signOutCompletely:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
                    
                    InitialSlidingViewController *initialSlidingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"initialView"];
                    ((AppDelegate*)[[UIApplication sharedApplication] delegate]).window.rootViewController = initialSlidingViewController;
                    //[self.navigationController pushViewController:initialSlidingViewController animated:YES];
                }];
            }];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

        }

         
    }];
    
}
@end
