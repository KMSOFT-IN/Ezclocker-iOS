//
//  TimeOffTotalsViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 02/12/23.
//  Copyright © ezNova Technologies LLC. All rights reserved.
//

#import "TimeOffTotalsViewController.h"
#import "ECSlidingViewController.h"
#import "user.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "PushNotificationManager.h"
#import "EZPurchaseManager.h"
#import "NSNumber+Extensions.h"
#import "NSDictionary+Extensions.h"
#import "WebViewController.h"
#import "NSDate+Extensions.h"

@interface TimeOffTotalsViewController ()

@end

@implementation TimeOffTotalsViewController



- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    timeOffTotalsList = [[NSMutableArray alloc] init];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Time Off Totals";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@"Time Off Totals"];

    [self getAllTimeOffTotals];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    UserClass *user = [UserClass getInstance];
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
        return [timeOffTotalsList count];
   else
       return 4;

    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell2";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
    }

    if ((timeOffTotalsList != nil) && ([timeOffTotalsList count] > 0))
    {
        UserClass *user = [UserClass getInstance];
        if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
        {
            NSDictionary *timeOffObj = [timeOffTotalsList objectAtIndex:indexPath.row];
            NSString *detailText = [NSString stringWithFormat:@"PTO: %@ SICK: %@ HOLIDAY: %@ UNPAID: %@", [timeOffObj valueForKey:@"PTOTotals"], [timeOffObj valueForKey:@"sickTotals"], [timeOffObj valueForKey:@"HolidayTotals"], [timeOffObj valueForKey:@"unpaidTotals"]];
        
            if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
            {
                cell.textLabel.text = [timeOffObj valueForKey:@"employeeName"];
                detailText = detailText;
            }
            else
            {
                cell.textLabel.text = detailText;
            }

            cell.detailTextLabel.text = detailText;
        }
        else
        {
            NSDictionary *timeOffObj = [timeOffTotalsList objectAtIndex:0];
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = [NSString stringWithFormat: @"Total PTO Taken: %@ hrs", [timeOffObj valueForKey:@"PTOTotals"]];
                    break;
                case 1:
                    cell.textLabel.text = [NSString stringWithFormat: @"Total Sick Taken: %@ hrs", [timeOffObj valueForKey:@"sickTotals"]];
                    break;
                case 2:
                    cell.textLabel.text = [NSString stringWithFormat: @"Total Holiday Taken: %@ hrs", [timeOffObj valueForKey:@"HolidayTotals"]];
                    break;
                case 3:
                    cell.textLabel.text = [NSString stringWithFormat: @"Total Unpaid Taken: %@ hrs", [timeOffObj valueForKey:@"unpaidTotals"]];
                    break;

                default:
                    break;
            }
        }
   
    }
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{  
    
}

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


-(void) getAllTimeOffTotals
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callTimeOffTotalsAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
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
            NSString *employeeName = @"";
            NSNumber *employeeId;
             NSDateFormatter *formatterISO8601DateTime = [[NSDateFormatter alloc] init];
            [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            //[formatterISO8601DateTime setTimeZone:[NSTimeZone localTimeZone]];
            [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [timeOffTotalsList removeAllObjects];
            @try{
                NSDictionary *timeOffTotlsFromServer = [aResults valueForKey:@"ezEmployeeTimeOffTotals"];
                NSString *empName = @"";
                NSString *empPTOTotals, *empHolidayTotals, *empUnpaidTotals, *empSickTotals, *empId;
                NSDictionary *timeOffTotals, *paidTimeOff, *totalTimeOffsMap, *PTODict, *holidayDict, *unpaidDict, *sickDict;
                UserClass *user = [UserClass getInstance];
                NSMutableArray *employeeList;
                if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
                    employeeList = [user.employeeList copy];
                else
                // we are signed in as an employee so there is only one employee in the list
                {
                    NSDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          user.userID, @"ID",
                                          @"", @"Name",
                                          nil];
                    employeeList = [[NSMutableArray alloc] init];
                    [employeeList addObject:dict];

                }
                for (NSDictionary *empObj in employeeList) {
                    empPTOTotals = @"0";
                    empHolidayTotals = @"0";
                    empUnpaidTotals = @"0";
                    empSickTotals = @"0";
                    empId = [empObj[@"ID"] stringValue];
                    empName = empObj[@"Name"];
                    //find employee Id from the list we got from the server
                    timeOffTotals = [timeOffTotlsFromServer valueForKey:empId];
                    if (![NSDictionary isNilOrNull:timeOffTotals])
                    {
                        paidTimeOff = [timeOffTotals valueForKey:@"paidTimeOff"];
                        if (![NSDictionary isNilOrNull:paidTimeOff])
                        {
                            totalTimeOffsMap = [paidTimeOff valueForKey:@"totalTimeOffsMap"];
                            if (![NSDictionary isNilOrNull:totalTimeOffsMap])
                            {
                                PTODict = [totalTimeOffsMap valueForKey:@"PAID_PTO"];
                                if (![NSDictionary isNilOrNull:PTODict])
                                {
                                    empPTOTotals = [PTODict valueForKey:@"decimalHoursString"];
                                }
                                holidayDict = [totalTimeOffsMap valueForKey:@"PAID_HOLIDAY"];
                                if (![NSDictionary isNilOrNull:holidayDict])
                                {
                                    empHolidayTotals = [holidayDict valueForKey:@"decimalHoursString"];
                                }
                                sickDict = [totalTimeOffsMap valueForKey:@"PAID_SICK"];
                                if (![NSDictionary isNilOrNull:sickDict])
                                {
                                    empSickTotals = [sickDict valueForKey:@"decimalHoursString"];;
                                }
                            }

                        }
                        paidTimeOff = [timeOffTotals valueForKey:@"unpaidTimeOff"];
                        if (![NSDictionary isNilOrNull:paidTimeOff])
                        {
                            totalTimeOffsMap = [paidTimeOff valueForKey:@"totalTimeOffsMap"];
                            if (![NSDictionary isNilOrNull:totalTimeOffsMap])
                            {
                                unpaidDict = [totalTimeOffsMap valueForKey:@"UNPAID_TIME_OFF"];
                                if (![NSDictionary isNilOrNull:unpaidDict])
                                {
                                    empUnpaidTotals = [unpaidDict valueForKey:@"decimalHoursString"];
                                }

                            }
                        }
                    }
                    NSDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          empId, @"employeeId",
                                          empName, @"employeeName",
                                          empPTOTotals, @"PTOTotals",
                                          empHolidayTotals, @"HolidayTotals",
                                          empUnpaidTotals, @"unpaidTotals",
                                          empSickTotals, @"sickTotals",
                                                  nil];
                    [timeOffTotalsList addObject:dict];


                }
            }
            @catch(NSException* ex) {
                NSLog(@"Exception in getting data from Server: %@", ex);
            }
        }
        [_timeOffTableView reloadData];
        }];


            
            
     
}

-(void) callTimeOffTotalsAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    
 
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    NSDateFormatter *formatterISO8601DateTime = [[NSDateFormatter alloc] init];
    [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
        httpPostString = [NSString stringWithFormat:@"%@api/v1/timeoff/calculate-totals/?selected-year=%@&target-time-zone-id=%@", SERVER_URL, @"2023", timeZoneId];
    else
    {
        NSNumber* employeeID = user.userID;
        NSString *employeeIDStr = [employeeID stringValue];
        httpPostString = [NSString stringWithFormat:@"%@api/v1/timeoff/employee/%@/calculate-totals/?selected-year=%@&target-time-zone-id=%@", SERVER_URL, employeeIDStr, @"2023", timeZoneId];
    }
    

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];

    [urlRequest setHTTPMethod:@"GET"];
 //   NSError *error;

   // jsonData = [NSJSONSerialization dataWithJSONObject:dict
  //  options:NSJSONWritingPrettyPrinted error:&error];
    


  //  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    //set request body into HTTPBody.
   // urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

    
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



- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}




@end

