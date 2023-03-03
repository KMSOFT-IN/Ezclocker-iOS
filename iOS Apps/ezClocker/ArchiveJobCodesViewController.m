//
//  ArchiveJobCodesViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 12/13/20.
//  Copyright © 2020 ezNova Technologies LLC. All rights reserved.
//

#import "ArchiveJobCodesViewController.h"
#import "ECSlidingViewController.h"
#import "SharedUICode.h"
#import "user.h"
#import "CommonLib.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
//#import "UpdateEmployeeListWebService.h"
#import "NSDictionary+Extensions.h"

@interface ArchiveJobCodesViewController ()

@end

@implementation ArchiveJobCodesViewController

const int GET_ARCHIVED_JOBS = 1;
const int ACTIVATE_JOB = 2;
const int DELETE_JOB = 3;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        archiveJobList = [[NSMutableArray alloc] init];
      //  self.title = NSLocalizedString(@"Acrhive", @"Archive");
      //  self.tabBarItem.image = [UIImage imageNamed:@"cabinet"];

    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *customView  = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 90, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Archive List";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    [self getArchivedJobs];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*-(void) updateActiveEmployees
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    UpdateEmployeeListWebService *updateEmployeeListWebService = [[UpdateEmployeeListWebService alloc] init];
    updateEmployeeListWebService.delegate = self;
    [updateEmployeeListWebService updateActiveEmployeeList];
   
}

- (void)EmployeeListUpdateServiceCallDidFinish:(UpdateEmployeeListWebService *)controller ErrorCode: (int) errorValue;
{
    [self stopSpinner];
    if (errorValue != 0) {
        [SharedUICode messageBox:nil message:@"There was an issue fetching the locations from the server. Please try again later" withCompletion:^{
            return;
        }];
        
    }
    else{
        
    }
    
}
*/

-(void) getArchivedJobs {
    [self startSpinnerWithMessage:@"Fetching data, please wait..."];
    
    [self callJobArchiveAPI:GET_ARCHIVED_JOBS selectedEmployee: nil withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
                [archiveJobList removeAllObjects];
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
                 for (NSDictionary *jobCode in jobCodesFromServer){
                     assignToAllEmployees = 0;
                     jobCodeId = [jobCode valueForKey:@"id"];
                     NSNumber* archived = [jobCode valueForKey:@"archived"];
                     if ([archived intValue] > 0)
                     {
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
                     
                         [archiveJobList addObject: _jobCode];

                        }
                 }
                 [_archiveJobsTableView reloadData];
                 
            NSString *count = [NSString stringWithFormat:@"%lu",(unsigned long)[archiveJobList count]];
                 NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
                 [dictionary setValue:count forKey:@"jobCodeCount"];
 //                [NSNotificationCenter.defaultCenter postNotificationName: ksetJobCodeViewNotification object:nil userInfo:dictionary];
                 
        }

    }];
    
}

- (void)unArchiveEmployeeAtIndexPath:(NSIndexPath*)indexPath {
    NSMutableDictionary *job =  [archiveJobList objectAtIndex:indexPath.row];
    NSNumber *jobId = [job valueForKey:@"id"];
    [self callActivateEmployee: jobId forRowAtIndexPath:(NSIndexPath*) indexPath];
}

-(void) callActivateEmployee: (NSNumber*) jobId forRowAtIndexPath:(NSIndexPath*) indexPath
{
    [self startSpinnerWithMessage:@"Activating, please wait..."];
    
    [self callJobArchiveAPI:ACTIVATE_JOB selectedEmployee: jobId withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            //if we get a forbiden message like no available slots thens how the message from the server
            if (aErrorCode == SERVICE_FORBIDEN_ERROR)
                [SharedUICode messageBox:nil message:aResultMessage withCompletion:^{
                    return;
                }];
            else {
                [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
            }
        }
        else{
            [SharedUICode messageBox:nil message:@"Job has been successfully activated." withCompletion:^{
                return;
            }];
            //remove the employee from the local employeelist
            [archiveJobList removeObjectAtIndex:indexPath.row];
            
            // Delete the row from the data source
            [_archiveJobsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [_archiveJobsTableView setEditing:NO animated: YES];
            [self __setEditButtons];
            
            //update the global employee list for user class
  //          [self updateActiveEmployees];
        }
        
    }];
    
}

-(void) callJobArchiveAPI: (int)flag selectedEmployee:(NSNumber*) jobId withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    
    UserClass *user = [UserClass getInstance];
    
    if (flag == GET_ARCHIVED_JOBS)
    {
 
#ifdef PERSONAL_VERSION
        NSString *personalId = [user.userID stringValue];
        httpPostString = [NSString stringWithFormat:@"%@api/v1/employee/%@/datatags", SERVER_URL, personalId];
#else
        httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags?ez-entity-type=EMPLOYEE&filter=ARCHIVED", SERVER_URL];
#endif
    }
    else if (flag == DELETE_JOB)
        httpPostString = [NSString stringWithFormat:@"%@api/v1/archive/employee/remove/%@", SERVER_URL, jobId];
    else
            httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags/unarchive/%@", SERVER_URL, jobId];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    if (flag == GET_ARCHIVED_JOBS)
        [urlRequest setHTTPMethod:@"GET"];
    else if (flag == DELETE_JOB)
        [urlRequest setHTTPMethod:@"DELETE"];
    else
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        return [archiveJobList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
      //  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
    }
    if ((archiveJobList != nil) && ([archiveJobList count] > 0))
    {
        NSDictionary *jobCodeObj = [archiveJobList objectAtIndex:indexPath.row];
        cell.textLabel.text = [jobCodeObj valueForKey:@"name"];
        if (![NSString isNilOrEmpty:[jobCodeObj valueForKey:@"description"]])
            cell.detailTextLabel.text =[jobCodeObj valueForKey:@"description"];
    }
    
    return cell;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *activateAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Activate"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        
       [self unArchiveEmployeeAtIndexPath:indexPath];
        
    }];
 /*   UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        UIView *view = [cancelButton valueForKey:@"view"];
        [SharedUICode yesNoCancel:nil message:@"Delete Employee.  Are you sure? You cannot revert this operation" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing" rootControl:view withCompletion:^(YesNoCancelResult Result) {
            switch (Result) {
                case resultYes: {
                    [self deleteEmployeeAtIndexPath:indexPath];
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
  */

    activateAction.backgroundColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
    
 //   deleteAction.backgroundColor = [UIColor redColor];

    return @[activateAction];
}

// Override to support editing the table view.
/*- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
       // [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        UIView *view = [cancelButton valueForKey:@"view"];
        [SharedUICode yesNoCancel:nil message:@"Delete Employee.  Are you sure? You cannot revert this operation" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing" rootControl:view withCompletion:^(YesNoCancelResult Result) {
            switch (Result) {
                case resultYes: {
                    [self deleteEmployeeAtIndexPath:indexPath];
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

    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/
- (void)deleteEmployeeAtIndexPath:(NSIndexPath*)indexPath {
    [self startSpinnerWithMessage:@"Deleting, please wait..."];
    NSMutableDictionary *job =  [archiveJobList objectAtIndex:indexPath.row];
    NSNumber *jobId = [job valueForKey:@"id"];
    [self callJobArchiveAPI:DELETE_JOB selectedEmployee: jobId withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            //remove the employee from the local employeelist
            [archiveJobList removeObjectAtIndex:indexPath.row];
            
            // Delete the row from the data source
            [_archiveJobsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [_archiveJobsTableView setEditing:NO animated: YES];
            [self __setEditButtons];

        }
    }];
}
/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setEditButtons {
    if (self.tableView.editing) {
        [self setEditing:NO animated:TRUE];
    }
    
    [self __setEditButtons];
}

- (void)__setEditButtons {
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:UIBarButtonItemStylePlain target:self action:@selector(revealMenu:)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditClick:)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:editButton, nil];
    
}

- (void)setCancelButtonForSwipDelete {
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelClick:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    // self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.rightBarButtonItems = nil;
    
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setCancelButtonForSwipDelete];
}


- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!__cancelling) {
        [self __cancelEditing];
    }
}

static BOOL __cancelling = FALSE;
- (void)cancelClicked:(id)sender {
    __cancelling = TRUE;
    @try {
        [self __cancelEditing];
    }
    @finally {
        __cancelling = FALSE;
    }
}

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

- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)onEditClick:(id)sender {
        [self setEditState];
}


@end
