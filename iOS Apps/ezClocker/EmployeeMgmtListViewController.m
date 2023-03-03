//
//  EmployeeMgmtListViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 9/27/17.
//  Copyright © 2017 ezNova Technologies LLC. All rights reserved.
//

#import "EmployeeMgmtListViewController.h"
#import "ECSlidingViewController.h"
#import "user.h"
#import "EmployeeInfoViewController.h"
#import "SharedUICode.h"
#import "CommonLib.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"


@interface EmployeeMgmtListViewController ()

@end

@implementation EmployeeMgmtListViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
      //  self.title = NSLocalizedString(@"Active", @"Active");
      //  self.tabBarItem.image = [UIImage imageNamed:@"star"];
        
    }
    
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.title = NSLocalizedString(@"Employees", @"Employees");
    
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Active List";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;
    
    UserClass *user = [UserClass getInstance];
    employeeList = [[NSMutableArray alloc] initWithArray: user.employeeList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    UserClass *user = [UserClass getInstance];

    //check to see if anything changed (like an employee got activated then reload the UI
    if ([employeeList count] != [user.employeeList count])
    {
        employeeList = [[NSMutableArray alloc] initWithArray: user.employeeList];
        [_employeesTableViewController reloadData];
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [employeeList count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
       // cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
    }

    NSDictionary *empObj = [employeeList objectAtIndex:indexPath.row];
    NSString *empName = [empObj valueForKey:@"Name"];
    cell.textLabel.text = empName;

    return cell;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Archive"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){

        [self archiveEmployeeAtIndexPath:indexPath];

   // UITableViewRowAction *archiveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Archive" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
 //           [self archiveEmployeeAtIndexPath:indexPath];
        }];
    deleteAction.backgroundColor = [UIColor redColor];

    return @[deleteAction];
}

- (void)archiveEmployeeAtIndexPath:(NSIndexPath*)indexPath {
    NSMutableDictionary *employee =  [employeeList objectAtIndex:indexPath.row];
    NSNumber *empID = [employee valueForKey:@"ID"];
    [self callArchiveEmployee: empID forRowAtIndexPath:(NSIndexPath*) indexPath];
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
/*    if (mode != OperationNone) {
        [SharedUICode messageBox:nil message:@"Cannot delete at this time.  Currently processing a request.  Please try again in a few minutes." withCompletion:^{
            
        }];
        return;
    }
    */
    UIView *view = [cancelButton valueForKey:@"view"];
    [SharedUICode yesNoCancel:nil message:@"Archive Employee.  Are you sure?" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing" rootControl:view withCompletion:^(YesNoCancelResult Result) {
        switch (Result) {
            case resultYes: {
                [self archiveEmployeeAtIndexPath:indexPath];
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
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //prevent the user from leaving the employee list while in edit mode
    if (self.tableView.editing) {
        [SharedUICode messageBox:nil message:@"You cannot view employee details while in edit mode.  Cancel editing or tap the red icon to archive the employee." withCompletion:^{
            
        }];
        return;
    }
    
    EmployeeInfoViewController *employeeInfoDetailViewConroller;
    employeeInfoDetailViewConroller = [self.storyboard instantiateViewControllerWithIdentifier:@"EmployeeInfo"];
    
    // ...
    // Pass the selected object to the new view controller.
    NSDictionary *empObj = [employeeList objectAtIndex:indexPath.row];
    NSMutableDictionary *empDetailsObj = [[NSMutableDictionary alloc] init];
    [empDetailsObj setValue:[empObj valueForKey:@"ID"] forKey:@"ID"];
    [empDetailsObj setValue:[empObj valueForKey:@"Name"] forKey:@"name"];

    employeeInfoDetailViewConroller.employeeDetails = empDetailsObj;

    employeeInfoDetailViewConroller.delegate = self;
    
    [self.navigationController pushViewController:employeeInfoDetailViewConroller animated:YES];
    
    
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
    
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditClick:)];

    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:editButton, addButton, nil];
    
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

- (void)addNewEmployee {
    [self startSpinnerWithMessage:@"Checking Licensing..."];
    //call the subscription webservice to check if the user has used up all their available employee slots
    //of if their subsription has expired
    SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
    subscriptionWebService.delegate = (id) self;
    [subscriptionWebService checkValidLicense];
}

- (void)addEmployeeViewControllerDidFinish:(UIViewController *)controller CancelWasSelected:(bool)cancelWasSelected
{
    if (!cancelWasSelected)
    {
        [self updateEmployeeList];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    //don't call the server if the customer pressed the cancel button
}

- (void)subscriptionError{
    [self stopSpinner];
    //let them in even if we have an error (give them a free period). the subscription web service
    //sent back a metric exceoption to notify us
    AddEmployeeViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AddEmployee"];
    
    UINavigationController *addEmployeeNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    
    controller.delegate = (id) self;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:addEmployeeNavigationController animated:YES completion:nil];
    
    
}
- (void)subscriptionExpired{
    [self stopSpinner];
    //since we are already on the subscription page. Show an alert message
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"ERROR"
                                 message:@"Your subsription has expired. Please go to the subscription page to update your account"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];

   // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Your subsription has expired. Please go to the subscription page to update your account" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
   // [alert show];
    
}

- (void)subscriptionNotValid{
    [self stopSpinner];
    UserClass *user = [UserClass getInstance];
    NSString *msg = @"";
    //check to see if they do not have an Apple subscription then direct them to the website to enter their credit card
    if (![NSString isEquals:user.subscription_planProvider dest:@"APPLE_SUBSCRIPTION"])
    {
        msg = @"Your subscription has expired. Please sign-in to our website ezclocker.com and enter your credit card payment.";
        [SharedUICode messageBox:@"Error" message:msg withCompletion:^{
            return;
        }];
    }
    else
    {
       //  msg = @"Our records indicate that your subscription has expired. Please click the menu icon at the top left corner> select Subscription> select manage subscriptions > Go to ITunes Store to validate your iTunes ezClocker subscription expiration date.";
        //     [SharedUICode messageBox:@"Error" message:msg withCompletion:^{
        //         return;
        //     }];
            //version 1.9.23 let them add employees until we fix the bug
            AddEmployeeViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AddEmployee"];
             
             
             UINavigationController *addEmployeeNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
             
             
             controller.delegate = (id) self;
             controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
             
             [self presentViewController:addEmployeeNavigationController animated:YES completion:nil];

    }

}

//this is a call back from the subscription webservice
- (void)subscriptionValid{
    [self stopSpinner];
    UserClass *user = [UserClass getInstance];
    
    if ([user.availableEmployeeSlots intValue] <= 0)
    {
#ifdef IPAD_VERSION
        //they have reached the max of employees
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"You have reached the maximum number of employees. Please upgrade your account using the account page from the ezClocker website and try again"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You have reached the maximum number of employees. Please upgrade your account using the account page from the ezClocker website and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
#else
        NSString *msg = @"";
        //check to see if we are on the free plan then show them a message that talks about the 30 days free otherwise, just tell them to upgrade
        NSString *freeTrialEndMessage = @"You have reached the maximum number of employees for the free plan. Please pick a subscription and get 30 days FREE using the subsciption page.";
        NSString *NeedToUpgradeMessage = @"You have reached the maximum number of employees. Please upgrade your account using the subsciption page and try again.";
        
        if (CommonLib.userIsManager)//(user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"]))
        {
            freeTrialEndMessage = @"You have reached the maximum number of employees for the free plan. You do not have access to subscribe. Please ask the employer to pick a subscription and get 30 days FREE using the account page from the ezClocker website and try again.";
            NeedToUpgradeMessage = @"You have reached the maximum number of employees. You do not have access to upgrade. Please ask the employer of the account to upgrade using the subsciption screen on their app or ezClocker website and try again.";
        }
        if ([NSString isEquals:user.subscription_planProvider dest:@"EZCLOCKER_SUBSCRIPTION"])
        {
            msg = freeTrialEndMessage;
        }
        else
        {
            msg = NeedToUpgradeMessage;
        }
        UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"Alert"
                                             message:msg
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                
                UIAlertAction* backAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                    
                    [alert dismissViewControllerAnimated:YES completion:nil];
                    
                }];
                
                [alert addAction:backAction];
        
                // check to see if they are an employer bc if they are a manager (not employer) we don't want to show them the subscribe button
                if ([user.userType isEqualToString:@"employer"])
                {

                    UIAlertAction* subscribeAction = [UIAlertAction actionWithTitle:@"Subscribe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        UIViewController*  newTopViewController;

        
                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavSubscriptionPlans"];
                    
                        CGRect frame = self.slidingViewController.topViewController.view.frame;
                        self.slidingViewController.topViewController = newTopViewController;
                        self.slidingViewController.topViewController.view.frame = frame;
                        [self.slidingViewController resetTopView];
                    }];
                
                    [alert addAction:subscribeAction];
                }
                
                [self presentViewController:alert animated:YES completion:nil];

        //they have reached the max of employees
      /*  UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"You have reached the maximum number of employees. Please upgrade your account using the subsciption page and try again"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
       */

      //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You have reached the maximum number of employees. Please upgrade your account using the subsciption page and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
        
#endif
    }
    else{
        AddEmployeeViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AddEmployee"];
        
        
        UINavigationController *addEmployeeNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        
        
        controller.delegate = (id) self;
        controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self presentViewController:addEmployeeNavigationController animated:YES completion:nil];
        
    }
    
}


- (IBAction)onAddClick:(id)sender {
    [self addNewEmployee];
}

- (void)EmployeeInfoSaveDidFinish:(EmployeeInfoViewController *)controller EmployeeObj: (NSMutableDictionary*) empDetailsObj
{
    bool nameWasChanged = empDetailsObj != nil;
    if (nameWasChanged)
    {
        //remove the employee from the global lists
        for (NSDictionary *item in employeeList)
        {
            if ([[item valueForKey:@"ID"] doubleValue] == [[empDetailsObj valueForKey:@"ID"] doubleValue])
            {
                [item setValue:[empDetailsObj valueForKey:@"name"] forKey:@"Name"];
            }
        }
        
        UserClass *user = [UserClass getInstance];

        [user.employeeNameIDList setValue:[empDetailsObj valueForKey:@"name"] forKey:[[empDetailsObj valueForKey:@"ID"] stringValue]];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    if (nameWasChanged)
        [_employeesTableViewController reloadData];
}

-(void) callArchiveEmployee: (NSNumber*) empID forRowAtIndexPath:(NSIndexPath*) indexPath
{
    [self startSpinnerWithMessage:@"Archiving, please wait..."];
    
    [self callEmployeeArchiveAPI:empID withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            //remove the employee from the local employeelist
            [employeeList removeObjectAtIndex:indexPath.row];
            
            //remove the employee from the global lists
            UserClass *user = [UserClass getInstance];
            [user.employeeNameIDList removeObjectForKey:[empID stringValue]];
            
            [user.employeeList removeObjectAtIndex:indexPath.row];
            
            // Delete the row from the data source
            [_employeesTableViewController deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [_employeesTableViewController setEditing:NO animated: YES];
            [self __setEditButtons];
        }
 
    }];
    
}

-(void) callEmployeeArchiveAPI:(NSNumber*) empID withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;

    UserClass *user = [UserClass getInstance];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/archive/employee/%@", SERVER_URL, empID];
   // httpPostString = [NSString stringWithFormat:@"%@api/v1/archive/employee", SERVER_URL];
   // httpPostString = [NSString stringWithFormat:@"%@api/v1/archive/employee/unarchive/%@", SERVER_URL, @"46"];
  

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //[urlRequest setHTTPMethod:@"GET"];
    [urlRequest setHTTPMethod:@"POST"];

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

-(void) callGetEmployees:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
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

-(void) updateEmployeeList
{
    [self startSpinnerWithMessage:@"Updating, please wait..."];
    
    [self callGetEmployees:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
             UserClass *user = [UserClass getInstance];
            [user.employeeList removeAllObjects];
            [user.employeeNameIDList removeAllObjects];
            NSArray *employees = [results valueForKey:@"employees"];
            int employeeCnt = (int) employees.count;
            user.employeeCount = [NSNumber numberWithInt: employeeCnt];
            //persist selection
            [[NSUserDefaults standardUserDefaults] setObject:user.employeeCount forKey:@"employeeCount"];
  //          [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSString *name;
            NSStream *employeeEmail;
            NSNumber *employeeID;
            NSNumber *acceptedInvite;
            NSNumber *isClockedIn;
            NSString *pin;
            NSMutableDictionary *employeeObj;
            NSMutableDictionary *item;
            
            if (employees.count > 0)
                [employeeList removeAllObjects];
            for (NSDictionary *employee in employees){
                
                name = [employee valueForKey:@"employeeName"];
                employeeID = [employee valueForKey:@"id"];
                
                pin = [employee valueForKey:@"teamPin"];
                
                NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]init];
                [mutableDict setObject:name forKey:[employeeID stringValue]];
                
                [user.employeeNameIDList  setValue:name forKey:[employeeID stringValue]];
                
                employeeObj = [[NSMutableDictionary alloc] init];
                [employeeObj setValue:name forKey:@"Name"];
                [employeeObj setValue:employeeID forKey:@"ID"];
                
                [user.employeeList addObject:employeeObj];
                
                acceptedInvite = [employee valueForKey:@"acceptedInvite"];
                NSObject *tmpJson = [employee valueForKey:@"activeTimeEntry"];
                isClockedIn = 0;
                if (![tmpJson isEqual:[NSNull null]])
                    isClockedIn = [NSNumber numberWithInt:1];
                
                employeeEmail = [employee valueForKey:@"employeeContactEmail"];
                
                item = [[NSMutableDictionary alloc] init];
                
                [item setValue:name forKey:@"Name"];
                [item setValue:employeeID forKey:@"ID"];
                [item setValue:pin forKey:@"pin"];
                [item setValue:acceptedInvite forKey:@"acceptedInvite"];
                [item setValue:isClockedIn forKey:@"isClockedIn"];
                [item setValue:employeeEmail forKey:@"Email"];
                
                
            }
        
            employeeList = [[NSMutableArray alloc] initWithArray: user.employeeList];
            [_employeesTableViewController reloadData];
        }
    }];
    
}


@end
