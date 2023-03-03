//
//  JobCodesViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 4/7/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import "JobCodesViewController.h"
#import "ECSlidingViewController.h"
#import "JobCodeDetailsViewController.h"
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

@interface JobCodesViewController ()

@end

@implementation JobCodesViewController

//@synthesize editButton;

const int GET_ALL_JOB_CODES = 1;
const int DELETE_JOB_CODE = 2;
const int UPDATE_JOBCODE_INFO = 3;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UserClass *user = [UserClass getInstance];
    jobCodesList = [[NSMutableArray alloc] initWithArray: user.jobCodesList];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Job List";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;
    
}

- (void) enableView: (BOOL) isEnable {
    self.editButton.enabled = isEnable;
    self.addButton.enabled = isEnable;
    
    if (isEnable == NO) {
#ifndef PERSONAL_VERSION
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Alert"
                                     message:@"Please purchase the Standard or Premium subscription to access this feature."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* backAction = [UIAlertAction actionWithTitle:@"Back to Dashboard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                    [alert dismissViewControllerAnimated:YES completion:nil];
                    

                    UIViewController*  newTopViewController;

                    newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
                    CGRect frame = self.slidingViewController.topViewController.view.frame;
                    self.slidingViewController.topViewController = newTopViewController;
                    self.slidingViewController.topViewController.view.frame = frame;
                    [self.slidingViewController resetTopView];
                }];
                
        [alert addAction:backAction];
        
        UIAlertAction* watchDemoAction = [UIAlertAction actionWithTitle:@"Watch Demo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
            [[AVAudioSession sharedInstance]
                        setCategory: AVAudioSessionCategoryPlayback
                              error: nil];
            /*NSURL* vedioURL = [[NSBundle mainBundle] URLForResource:@"iPhone_jobslist" withExtension:@"mp4"];
            AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:vedioURL];
            AVPlayer* playVideo = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            self.playerViewController = [[AVPlayerViewController alloc] init];
            self.playerViewController.player = playVideo;
            self.playerViewController.view.frame = self.view.bounds;
            [self presentViewController:self.playerViewController animated:YES completion:^{
            }];
            //[self.view addSubview:self.playerViewController.view];
            [playVideo play];*/
            
            NSURL* videoURL = [[NSBundle mainBundle] URLForResource:@"iPhone_jobslist" withExtension:@"html"];
            UINavigationController* navController = [WebViewController getInstance];
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            WebViewController* webController = (WebViewController *)[navController viewControllers].firstObject;
            webController.url = videoURL;
            [self presentViewController:navController animated:YES completion:nil];
        }];
                
        [alert addAction:watchDemoAction];

        [self presentViewController:alert animated:YES completion:nil];
                
#else

        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Alert"
                                     message:@"Please purchase a subscription to access this feature."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction* backAction = [UIAlertAction actionWithTitle:@"Home" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
            
//#ifdef PERSONAL_VERSION
            UIViewController*  newTopViewController;
            UserClass *user = [UserClass getInstance];
            //if we have more than one customer then go to the customer list dashboard "NavCustomers" else go to the clock in/out screen "FirstTop"
            if ([user.customerNameIDList count] > 1)
             {
                newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavCustomers"];
             }
            else
            {
                newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
            }
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
//#endif
        }];
        
        [alert addAction:backAction];
        
        UIAlertAction* watchDemoAction = [UIAlertAction actionWithTitle:@"Watch Demo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
            [[AVAudioSession sharedInstance]
                        setCategory: AVAudioSessionCategoryPlayback
                              error: nil];
            /*NSURL* vedioURL = [[NSBundle mainBundle] URLForResource:@"Personal_Jobslist" withExtension:@"mp4"];
            AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:vedioURL];
            AVPlayer* playVideo = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            self.playerViewController = [[AVPlayerViewController alloc] init];
            self.playerViewController.player = playVideo;
            self.playerViewController.view.frame = self.view.bounds;
            [self presentViewController:self.playerViewController animated:YES completion:^{
            }];
            //[self.view addSubview:self.playerViewController.view];
            [playVideo play];*/
            
            NSURL* videoURL = [[NSBundle mainBundle] URLForResource:@"Personal_Jobslist" withExtension:@"html"];
            UINavigationController* navController = [WebViewController getInstance];
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            WebViewController* webController = (WebViewController *)[navController viewControllers].firstObject;
            webController.url = videoURL;
            [self presentViewController:navController animated:YES completion:nil];
        }];
        [alert addAction:watchDemoAction];
        
        UIAlertAction* subscribeAction = [UIAlertAction actionWithTitle:@"Subscribe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            UIViewController*  newTopViewController;
//#ifdef PERSONAL_VERSION
            newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavPersonalSubscription"];
//#else
//            newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavSubscriptionPlans"];
            
//#endif
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
        
        [alert addAction:subscribeAction];
        
        [self presentViewController:alert animated:YES completion:nil];
#endif
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    UserClass *user = [UserClass getInstance];

#ifdef PERSONAL_VERSION

 //   [self enableView:YES];
 //   [self getAllJobCodes];
    //check if they are subscribed to the pro plan and if it's expired
    bool hasAccess = (![CommonLib onFreePlan]) && (![NSNumber isNilOrNull:user.subscription_IsValid]) && ([user.subscription_IsValid intValue] != 0);
    NSMutableArray *features = user.subscription_enabledFeatures;
    if ((hasAccess) && ((features != nil) && ([features count] > 0) && ([features indexOfObject:@"JOBS"] != NSNotFound)))
    {
        [self enableView:YES];
        [self getAllJobCodes];
    }
    else{
        [self enableView:NO];
    }
   
#else
    NSMutableArray *features = user.subscription_enabledFeatures;
    if ((features != nil) && ([features count] > 0) && ([features indexOfObject:@"JOBS"] != NSNotFound) )
    {
        [self enableView:YES];
        [self getAllJobCodes];
    }
    else{
        [self enableView:NO];
    }
   
   // [self enableView:YES];
   // [self getAllJobCodes];
#endif

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [jobCodesList count];
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
    }
    if ((jobCodesList != nil) && ([jobCodesList count] > 0))
    {
        NSDictionary *jobCodeObj = [jobCodesList objectAtIndex:indexPath.row];
        cell.textLabel.text = [jobCodeObj valueForKey:@"name"];
        if (![NSString isNilOrEmpty:[jobCodeObj valueForKey:@"description"]])
            cell.detailTextLabel.text =[jobCodeObj valueForKey:@"description"];
        else
            cell.detailTextLabel.text = @"";
    }
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

-(void) callDeleteJobCode:(NSNumber*)jobCodeId withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    NSString *request_body;
    UserClass *user = [UserClass getInstance];
    

#ifdef PERSONAL_VERSION
        httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags/personal/%@", SERVER_URL, jobCodeId];
#else
    httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags/%@", SERVER_URL, jobCodeId];
#endif
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    urlRequest.timeoutInterval = TIME_OUT_REQUEST;
    
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"DELETE"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    
#ifdef PERSONAL_VERSION
    NSString *personalId = [user.userID stringValue];
    [urlRequest setValue:personalId forHTTPHeaderField:@"x-ezclocker-personal-id"];
#endif
    
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
    //    [self stopSpinner];
    
}

- (void)cancelClicked:(id)sender {
    __cancelling = TRUE;
    @try {
        [self __cancelEditing];
    }
    @finally {
        __cancelling = FALSE;
    }
}


- (void)archiveJobAtIndexPath:(NSIndexPath*)indexPath {
 //   NSMutableDictionary *employee =  [archiveEmployeeList objectAtIndex:indexPath.row];
 //   NSNumber *empID = [employee valueForKey:@"id"];
    NSMutableDictionary *jobCodeObj =  [jobCodesList objectAtIndex:indexPath.row];
    NSNumber *jobID = [jobCodeObj valueForKey:@"id"];
    [self callArchiveJob: jobID forRowAtIndexPath:(NSIndexPath*) indexPath];
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *activateAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Archive"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        
       [self archiveJobAtIndexPath:indexPath];
        
    }];
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        UIView *view = [cancelButton valueForKey:@"view"];
        [SharedUICode yesNoCancel:nil message:@"Delete Job.  Are you sure? You cannot revert this operation" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing" rootControl:view withCompletion:^(YesNoCancelResult Result) {
            switch (Result) {
                case resultYes: {
                    [self deleteJobCodeAtIndexPath:indexPath];
                    break;
                }
                case resultNo:
                    break;
                default: {
                    [self cancelClicked:self];
                    break;
                }
            }
        }];
        
    }];

    activateAction.backgroundColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
    
    deleteAction.backgroundColor = [UIColor redColor];

    return @[activateAction, deleteAction];
}

- (void)deleteJobCodeAtIndexPath:(NSIndexPath*)indexPath {
    NSMutableDictionary *jobCodeObj =  [jobCodesList objectAtIndex:indexPath.row];
    NSNumber *jobCodeID = [jobCodeObj valueForKey:@"id"];
    [_jobCodesListTable setEditing:NO animated: YES];
    [self onCancelClick:self];
    //    editFlag = NO;
    
    [self startSpinnerWithMessage:@"Deleting, please wait..."];
    
    [self callDeleteJobCode:jobCodeID withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        else{
            [jobCodesList removeObjectAtIndex:indexPath.row];
            UserClass *user = [UserClass getInstance];
            [user.jobCodesList removeObjectAtIndex:indexPath.row];
            // Delete the row from the data source
            [_jobCodesListTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
    
}

/*- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    UIView *view = [cancelButton valueForKey:@"view"];
    
    [SharedUICode yesNoCancel:nil message:@"Delete Selected JobCode.  Are you sure?" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing" rootControl:view withCompletion:^(YesNoCancelResult Result) {
        switch (Result) {
            case resultYes: {
                [self deleteJobCodeAtIndexPath:indexPath];
                [self setEditing:NO animated:TRUE];
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
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 //   if (self.editButton.enabled == NO) {
 //       return;
 //   }
    //prevent the user from leaving the employee list while in edit mode
    if (self.tableView.editing) {
        [SharedUICode messageBox:nil message:@"You cannot view job details while in edit mode.  Pleae click the red icon to delete the job or cancel editing." withCompletion:^{
            
        }];
        return;
    }
    
    JobCodeDetailsViewController *jobCodeDetailViewConroller;
#ifdef PERSONAL_VERSION
    jobCodeDetailViewConroller = [self.storyboard instantiateViewControllerWithIdentifier:@"JobCodeDetails"];
#else
        jobCodeDetailViewConroller = [self.storyboard instantiateViewControllerWithIdentifier:@"BizJobCodeDetails"];
#endif
   
    // ...
    // Pass the selected object to the new view controller.
    
    jobCodeDetailViewConroller.jobCodeDetails = [jobCodesList objectAtIndex:indexPath.row];
    
    jobCodeDetailViewConroller.delegate = self;
    
    [self.navigationController pushViewController:jobCodeDetailViewConroller animated:YES];
    
    
}
-(void) getAllJobCodes
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callJobCodesAPI:GET_ALL_JOB_CODES withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            //save all the values we got back to the employeeDetails object so we can keep track of what changed
            [jobCodesList removeAllObjects];
            UserClass *user = [UserClass getInstance];
            [user.jobCodesList removeAllObjects];
            NSNumber *jobCodeId;
            NSString *jobCodeName;
            NSString *jobCodeIdDescription;
       //     NSString *jobCodeDisplayValue;
            NSString *hourlyRateValue;
            NSMutableDictionary *_jobCode;
            NSArray *jobCodesFromServer = [aResults valueForKey:@"entities"];
            
            /*          if ([jobCodesFromServer count] > 0)
             {
             //the first item will be None
             _jobCode = [[NSMutableDictionary alloc] init];
             [_jobCode setValue:0 forKey:@"id"];
             [_jobCode setValue:@"None" forKey:@"jobCodeTagId"];
             [_jobCode setValue:@"None" forKey:@"displayValue"];
             // [jobCodesList addObject: _jobCode];
             [user.jobCodesList addObject:_jobCode];
             }
             */
            NSNumber *assignToAllEmployees;
            NSNumber *isArchived;
            for (NSDictionary *jobCode in jobCodesFromServer){
              isArchived = [jobCode valueForKey:@"archived"];
              if ([isArchived intValue] == 0)
              {
                assignToAllEmployees = 0;
                jobCodeId = [jobCode valueForKey:@"id"];
                jobCodeName = [jobCode valueForKey:@"tagName"];//tagId
                jobCodeIdDescription = [jobCode valueForKey:@"description"];
              //  jobCodeDisplayValue = [jobCode valueForKey:@"displayValue"];
                hourlyRateValue = [jobCode valueForKey:@"value"];//used to be tagvalue
               // employeeId = [jobCode valueForKey:@"employeeId"];
                NSArray *assignedToEntities = [jobCode valueForKey: @"assignedToEntities"];
                NSMutableArray *assignedEmployeeList = [NSMutableArray new];
                for (NSDictionary *assignedEntity in assignedToEntities)
                {
                    NSDictionary *assignedEzEntity = [assignedEntity valueForKey: @"assignedEzEntity"];
                    NSNumber *isPrimary = [assignedEntity valueForKey: @"level"];
                    if ([NSDictionary isNilOrNull:assignedEzEntity])
                    {
                       assignToAllEmployees = [NSNumber numberWithInt:1];
                    }
                    else{
                        NSDictionary *employeeObj = [[NSMutableDictionary alloc] init];
                        NSString *employeeName = [assignedEzEntity valueForKey:@"employeeName"];
                         [employeeObj setValue:employeeName forKey:@"employeeName"];
                        
                         [employeeObj setValue:[assignedEzEntity valueForKey:@"id"] forKey:@"employeeId"];
                        
                        [employeeObj setValue:isPrimary forKey:@"isPrimary"];

                        // [employeeObj setValue:employeeId forKey:@"employeeId"];
                        // [employeeObj setValue:isPrimary forKey:@"isPrimary"];
                         [assignedEmployeeList addObject:employeeObj];

                    }
                }
                
                _jobCode = [[NSMutableDictionary alloc] init];
                @try{
                    [_jobCode setValue:jobCodeId forKey:@"id"];
                    [_jobCode setValue:jobCodeName forKey:@"name"];
                    [_jobCode setValue:jobCodeIdDescription forKey:@"description"];
                  //  [_jobCode setValue:jobCodeDisplayValue forKey:@"displayValue"];
                    [_jobCode setValue:hourlyRateValue forKey:@"hourlyRateValue"];
                    [_jobCode setValue:assignToAllEmployees forKey:@"assignToAllEmployees"];
                    [_jobCode setValue:assignedEmployeeList forKey:@"assignedEmployeeList"];
                    
                }
                @catch(NSException* ex) {
                    NSLog(@"Exception in setting JobCodes from Server: %@", ex);
                }
                
                [jobCodesList addObject: _jobCode];
                [user.jobCodesList addObject:_jobCode];
              }
            }
            [_jobCodesListTable reloadData];
            
            NSString *count = [NSString stringWithFormat:@"%lu",(unsigned long)[jobCodesList count]];
            NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
            [dictionary setValue:count forKey:@"jobCodeCount"];
            [NSNotificationCenter.defaultCenter postNotificationName: ksetJobCodeViewNotification object:nil userInfo:dictionary];
            
        }
    }];
    
}
#ifdef PERSONAL_VERSION
-(void) callJobCodesAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    
    
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    NSString *employeeID = [user.userID stringValue];
    // NSString *request_body;
    
    // NSString *employeeID = [_employeeDetails valueForKey:@"ID"];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/employee/%@/datatags", SERVER_URL, employeeID];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
  
    
    //set HTTP Method
    if (flag == GET_ALL_JOB_CODES)
        [urlRequest setHTTPMethod:@"GET"];
    //  else if (flag == ADD_JOB_CODE)
    //      [urlRequest setHTTPMethod:@"POST"];
    //  else
    //      [urlRequest setHTTPMethod:@"PUT"];
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
#else
-(void) callJobCodesAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    
    
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    
    
#ifdef PERSONAL_VERSION
    httpPostString = [NSString stringWithFormat:@"%@api/v1/personal/datatags", SERVER_URL];
#else
    httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags?ez-entity-type=EMPLOYEE", SERVER_URL];
#endif

     
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];


    [urlRequest setHTTPMethod:@"GET"];
    
    //for archive do a post
    
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
#ifdef PERSONAL_VERSION
    NSString *personalId = [user.userID stringValue];
    [urlRequest setValue:personalId forHTTPHeaderField:@"x-ezclocker-personal-id"];
#endif
    
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

#endif


- (IBAction)onAddClick:(id)sender {

#ifdef PERSONAL_VERSION
    jobCodeDetailViewConroller = [self.storyboard instantiateViewControllerWithIdentifier:@"JobCodeDetails"];
#else
    jobCodeDetailViewConroller = [self.storyboard instantiateViewControllerWithIdentifier:@"BizJobCodeDetails"];
#endif
    
    jobCodeDetailViewConroller.delegate = self;
    

    
    [self.navigationController pushViewController:jobCodeDetailViewConroller animated:YES];
    //#endif
}

- (IBAction)onEditClick:(id)sender {
    [self setEditState];
}

- (void)setEditButtons {
    if (self.tableView.editing) {
        [self setEditing:NO animated:TRUE];
    }
    
    [self __setEditButtons];
}

- (void)__setEditButtons {
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:UIBarButtonItemStylePlain target:self action:@selector(revealMenu:)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddClick:)];
    
    otherEditButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditClick:)];
    // self.navigationItem.rightBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:otherEditButton, addButton, nil];
    
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




- (void)JobCodeDetailsDidFinish:(JobCodeDetailsViewController *)controller CancelWasSelected:(bool)cancelWasSelected;
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void) callArchiveJob: (NSNumber*) jobID forRowAtIndexPath:(NSIndexPath*) indexPath
{
    [self startSpinnerWithMessage:@"Archiving, please wait..."];
    
    [self callJobArchiveAPI:jobID withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            [jobCodesList removeObjectAtIndex:indexPath.row];
            UserClass *user = [UserClass getInstance];
            [user.jobCodesList removeObjectAtIndex:indexPath.row];
            // Delete the row from the data source
            [_jobCodesListTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
 
    }];
    
}

-(void) callJobArchiveAPI:(NSNumber*) jobID withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;

    UserClass *user = [UserClass getInstance];
    httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags/archive/%@", SERVER_URL, jobID];
  

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //[urlRequest setHTTPMethod:@"GET"];
    [urlRequest setHTTPMethod:@"PUT"];

    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    
#ifdef PERSONAL_VERSION
    NSString *personalId = [user.userID stringValue];
    [urlRequest setValue:personalId forHTTPHeaderField:@"x-ezclocker-personal-id"];
#endif

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


@end

