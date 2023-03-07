//
//  TimeOffListViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 01/21/23.
//  Copyright © ezNova Technologies LLC. All rights reserved.
//

#import "TimeOffListViewController.h"
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
#import "TimeOffFiltersViewController.h"

@interface TimeOffListViewController ()

@end

@implementation TimeOffListViewController

int FILTER_SECTION = 0;
int PENDING_SECTION = 1;
int APPROVED_SECTION = 2;
int DENIED_SECTION = 3;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString *currentYearString = [formatter stringFromDate:[NSDate date]];
    filterByDate = currentYearString;
   // [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    } else {
        // Fallback on earlier versions
    }

    UserClass *user = [UserClass getInstance];
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
    {
        filterByEmployeeId = @-1;
        filterByEmployeeName = @"All Employees";
    }
    else
    {
        filterByEmployeeId = user.userID;
        filterByEmployeeName = @"";
    }
    
    timeOffList = [[NSMutableArray alloc] init];
    pendingTimeOffList = [[NSMutableArray alloc] init];
    approvedTimeOffList = [[NSMutableArray alloc] init];
    deniedTimeOffList = [[NSMutableArray alloc] init];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    //self.tableView.contentInset = UIEdgeInsetsMake(0, -20, 0, -20);
    
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Time Off Requests";
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
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@"Time Off Requests"];
 /*   UserClass *user = [UserClass getInstance];

    NSMutableArray *features = user.subscription_enabledFeatures;
    if ((features != nil) && ([features count] > 0) && ([features indexOfObject:@"JOBS"] != NSNotFound) )
    {
        [self enableView:YES];
//        [self getAllJobCodes];
    }
    else{
        [self enableView:NO];
    }
   */
    [self getAllTimeOffRequests];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == FILTER_SECTION)
        return 1;
    else if (section == PENDING_SECTION)
        return [pendingTimeOffList count];
    else if (section == APPROVED_SECTION)
        return [approvedTimeOffList count];
    else
        return [deniedTimeOffList count];

}

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
    
    if (section == FILTER_SECTION)
        tempLabel.text = @"Filters";
    else if (section == PENDING_SECTION)
        tempLabel.text = @"Pending";
    else if (section == APPROVED_SECTION)
        tempLabel.text = @"Approved";
    else
        tempLabel.text = @"Denied";
    
    [tempView addSubview:tempLabel];
    return tempView;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == FILTER_SECTION)
        return 0;
    else
        return 34.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == FILTER_SECTION)
    {
        static NSString *CellIdentifier = @"Cell1";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
        }

        UIFont *fontBold = [UIFont boldSystemFontOfSize:16.0f];

        cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];
        UserClass *user = [UserClass getInstance];
        NSString *lblText;
        if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
        {
            lblText = [NSString stringWithFormat: @"View: %@", filterByEmployeeName];
           cell.detailTextLabel.text = filterByDate;
        }
        else
        {
            lblText = [NSString stringWithFormat: @"View: %@", filterByDate];

        }
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc]initWithString:lblText];
        [string addAttribute:NSFontAttributeName value:fontBold range:NSMakeRange(0, string.length)];
        cell.textLabel.attributedText = string;

    }
    else
    {
        static NSString *CellIdentifier = @"Cell2";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
        }

        UILabel *lblStatus;
        NSDictionary *timeOffObj;
        if (indexPath.section == PENDING_SECTION)
            timeOffObj = [pendingTimeOffList objectAtIndex:indexPath.row];
        else if (indexPath.section == APPROVED_SECTION)
            timeOffObj = [approvedTimeOffList objectAtIndex:indexPath.row];
        else
            timeOffObj = [deniedTimeOffList objectAtIndex:indexPath.row];
        
        if (![NSDictionary isNilOrNull:timeOffObj])
        {
            UserClass *user = [UserClass getInstance];
            NSString *detailText = @"";
            if (![NSString isNilOrEmpty:[timeOffObj valueForKey:@"displayStartDate"]])
                detailText = [timeOffObj valueForKey:@"displayStartDate"];
            
            NSString *reqType = [timeOffObj valueForKey:@"requestType"];
            reqType = [reqType stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            if ([reqType isEqualToString:@"UNPAID TIME OFF"])
                reqType = @"UNPAID";
            if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
            {
                cell.textLabel.text = [timeOffObj valueForKey:@"employeeName"];
                if (![NSString isNilOrEmpty: reqType])
                    detailText = [NSString stringWithFormat:@"%@ (%@)", reqType, detailText];
            }
            else
            {
                cell.textLabel.text = reqType;
            }

            cell.detailTextLabel.text = detailText;
            lblStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
            lblStatus.backgroundColor = [UIColor clearColor];
            [lblStatus setTag:101];
            lblStatus.textAlignment = NSTextAlignmentRight;
            cell.accessoryView = lblStatus;
            NSString *requestStatus = [timeOffObj valueForKey:@"requestStatus"];
            lblStatus.text = requestStatus;
            lblStatus.font = [lblStatus.font fontWithSize:16];
            if ([requestStatus isEqualToString:@"APPROVED"])
                lblStatus.textColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
            else if ([requestStatus isEqualToString:@"DENIED"] || [requestStatus    isEqualToString:@"CANCELED"])
                lblStatus.textColor = [UIColor redColor];
            else
                lblStatus.textColor = [UIColor darkGrayColor];
        }
    }
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //if we did not pick the first section
    if (indexPath.section != FILTER_SECTION)
    {
        timeOffDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TimeOffDetailViewController"];

        // Pass the selected object to the new view controller.
    
        NSMutableArray *timeOffList = nil;
        if (indexPath.section == PENDING_SECTION)
            timeOffList = pendingTimeOffList;
        else if (indexPath.section == APPROVED_SECTION)
            timeOffList = approvedTimeOffList;
        else if (indexPath.section == DENIED_SECTION)
            timeOffList = deniedTimeOffList;
        if (timeOffList != nil)
        {
            NSDictionary *timeOffObj = [timeOffList objectAtIndex:indexPath.row];
            if (![[timeOffObj valueForKey:@"isEmptyRequest"] isEqualToString:@"true"])
            {
                timeOffDetailViewController.selectedTimeOff = timeOffObj;

                timeOffDetailViewController.delegate = self;

                [self.navigationController pushViewController:timeOffDetailViewController animated:YES];
            }
        }


    }
    else
    {
        timeOffFiltersViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TimeOffFiltersViewController"];
        timeOffFiltersViewController.delegate = self;

        [self.navigationController pushViewController:timeOffFiltersViewController animated:YES];

    }

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

-(NSNumber*) getEmployeeId: (NSString*) employeeName
{
    NSNumber *empId = nil;
    UserClass *user = [UserClass getInstance];
    for (NSDictionary *empObj in user.employeeList) {
        NSString *empName = empObj[@"Name"];
        if ([empName isEqualToString:employeeName])
        {
            empId = empObj[@"ID"];
            break;
        }
    }
    return empId;
}


-(void) getAllTimeOffRequests
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callTimeOffAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            NSString *reqStartDateTimeIso = @"";
            NSString *reqEndDateTimeIso = @"";
            NSString *startDateTimeLong = @"";
            NSString *endDateTimeLong = @"";
            NSString *startDate = @"";
            NSString *endDate = @"";
            NSDate *startDateTime, *endDateTime;
            NSString *employeeName = @"";
            NSNumber *employeeId;
            NSString *displayStartDate, *displayEndDate, *displayDate;
            NSDateFormatter *formatterISO8601DateTime = [[NSDateFormatter alloc] init];
            [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            //[formatterISO8601DateTime setTimeZone:[NSTimeZone localTimeZone]];
            [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [timeOffList removeAllObjects];
            [pendingTimeOffList removeAllObjects];
            [approvedTimeOffList removeAllObjects];
            [deniedTimeOffList removeAllObjects];
            NSArray *timeOffFromServer = [aResults valueForKey:@"entities"];
            
            NSMutableDictionary *timeOffReq;
            for (NSDictionary *serverTimeOffReq in timeOffFromServer){
                timeOffReq = [serverTimeOffReq mutableCopy];
                employeeId = [timeOffReq valueForKey:@"employeeId"];
                employeeName = [self getEmployeeName:employeeId];
                [timeOffReq setValue:employeeName forKey:@"employeeName"];
                reqStartDateTimeIso = [timeOffReq valueForKey:@"requestStartDateIso"];
                startDateTime = [formatterISO8601DateTime dateFromString:reqStartDateTimeIso];
                startDateTimeLong = [startDateTime toLongDateTimeString];
                displayStartDate = [startDateTime toEEMMddFormat];
                startDate = [startDateTime toDefaultDateString];
                [timeOffReq setValue:startDate forKey:@"reqStartDate"];

                 reqEndDateTimeIso = [timeOffReq valueForKey:@"requestEndDateIso"];
                 endDateTime = [formatterISO8601DateTime dateFromString:reqEndDateTimeIso];
                 endDateTimeLong = [endDateTime toLongDateTimeString];
                 displayEndDate = [endDateTime toEEMMddFormat];
                if ([displayEndDate isEqualToString: displayStartDate])
                    displayDate = displayStartDate;
                else
                    displayDate = [NSString stringWithFormat:@"%@ - %@", displayStartDate, displayEndDate];
                [timeOffReq setValue:displayDate forKey:@"displayStartDate"];
                 [timeOffReq setValue:endDateTimeLong forKey:@"reqEndDateTime"];
                 endDate = [endDateTime toDefaultDateString];
                 [timeOffReq setValue:endDate forKey:@"reqEndDate"];
                  [timeOffReq setValue:startDateTimeLong forKey:@"reqStartDateTime"];
 
                if ([[timeOffReq valueForKey:@"requestStatus"] isEqualToString:@"PENDING"])
                   [pendingTimeOffList addObject:timeOffReq];
                else if ([[timeOffReq valueForKey:@"requestStatus"] isEqualToString:@"APPROVED"])
                    [approvedTimeOffList addObject:timeOffReq];
                else if  ([[timeOffReq valueForKey:@"requestStatus"] isEqualToString:@"DENIED"])
                    [deniedTimeOffList addObject: timeOffReq];

            }
            NSDictionary *emptyTimeOffReq = [[NSDictionary alloc]
                          initWithObjectsAndKeys:@"No requests available", @"employeeName", @"true", @"isEmptyRequest", nil];
            if (pendingTimeOffList.count == 0)
                [pendingTimeOffList addObject:emptyTimeOffReq];
            if (approvedTimeOffList.count == 0)
                [approvedTimeOffList addObject:emptyTimeOffReq];
            if (deniedTimeOffList.count == 0)
                [deniedTimeOffList addObject:emptyTimeOffReq];
            [_timeOffTableView reloadData];
            }
      }];
   
    
}



-(void) callTimeOffAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    
 
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    NSDateFormatter *formatterISO8601DateTime = [[NSDateFormatter alloc] init];
    [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];

    NSString *startDateRange = [NSString stringWithFormat:@"%@-01-01", filterByDate];
    NSString *endDateRange = [NSString stringWithFormat:@"%@-12-31", filterByDate];
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))
    {
        if ([filterByEmployeeId intValue] > 0)
        {
            NSString *employeeIDStr = [filterByEmployeeId stringValue];
            httpPostString = [NSString stringWithFormat:@"%@api/v1/timeoff/employee/%@?start-date-iso=%@&end-date-iso=%@&target-time-zone-id=%@&status=%@", SERVER_URL, employeeIDStr, startDateRange, endDateRange, timeZoneId, @"ALL"];

        }
        else
        {
            httpPostString = [NSString stringWithFormat:@"%@api/v1/timeoff/?start-date-iso=%@&end-date-iso=%@&target-time-zone-id=%@&status=%@", SERVER_URL, startDateRange, endDateRange, timeZoneId, @"ALL"];
        }
    }
    else
    {
        NSNumber* employeeID = user.userID;
        NSString *employeeIDStr = [employeeID stringValue];
        httpPostString = [NSString stringWithFormat:@"%@api/v1/timeoff/employee/%@?start-date-iso=%@&end-date-iso=%@&target-time-zone-id=%@&status=%@", SERVER_URL, employeeIDStr, startDateRange, endDateRange, timeZoneId, @"ALL"];

    }

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];

  //  startDate (iso)
  //  toDate (iso)
  //  target-time-zone-id (string)

    [urlRequest setHTTPMethod:@"GET"];
    
    //for archive do a post
    
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




- (IBAction)onAddClick:(id)sender {

    timeOffDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TimeOffDetailViewController"];

    
    timeOffDetailViewController.delegate = self;
    
    
    [self.navigationController pushViewController:timeOffDetailViewController animated:YES];

}


- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}



- (void)timeOffDetailViewControllerDidFinish:(TimeOffDetailViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self getAllTimeOffRequests];
}

- (void)TimeOffFiltersViewControllerDidFinish:(TimeOffFiltersViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self getAllTimeOffRequests];
}

- (void)timeOffFiltersDidFinish:(BOOL)cancelSelected employeeName:(NSString*)employeeName dateSelected: (NSString*) dateFilter
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
    //if the user pressed save then update the list using the new filters
    if (!cancelSelected)
    {
        if (![employeeName isEqualToString:@"All"])
        {
            filterByEmployeeId = [self getEmployeeId:employeeName];
            filterByEmployeeName = employeeName;
        }
        else
        {
            filterByEmployeeId = @-1;
            filterByEmployeeName = @"All Employees";
        }
        filterByDate = dateFilter;
        [self getAllTimeOffRequests];
    }
}
@end

