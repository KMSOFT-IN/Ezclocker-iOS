//
//  EmployeeListViewController.m
//
//  Created by Raya Khashab on 1/19/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "EmployeeListViewController.h"
#import "AddEmployeeViewController.h"
#import "TimeSheetMasterViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "MetricsLogWebService.h"
#import "EmailTimeSheetViewController.h"
#import "SharedUICode.h"
#import "SharedUICode.h"
#import "NSString+Extensions.h"


@interface EmployeeListViewController ()

@property (nonatomic, retain) UIRefreshControl* refreshControl;


@end

@implementation EmployeeListViewController
@synthesize employeeListTableViewController;
@synthesize refreshControl;
@synthesize employeesList;
@synthesize timeSheetNavigationController = _timeSheetNavigationController;
@synthesize employeeDetailNavigationController = _employeeDetailNavigationController;
//@synthesize employeeProfileViewController;

NSString *const REFRESH_EMPLOYEE = @"Refresh";
NSString *const ADD_EMPLOYEE = @"Add";
NSString *const DELETE_EMPLOYEE = @"Delete";
NSString *const EMAIL_ALL_TIMESHEETS = @"Email All TimeSheets";



/*- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
 */

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self){
        self.title = NSLocalizedString(@"Employee List", @"Employee List");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//            self.clearsSelectionOnViewWillAppear = NO;
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        }

    }
    
//    user = [UserClass getInstance];
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callGetEmployees)
     
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];

    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];

    

    editFlag = NO;
    
    employeesList = [[NSMutableArray alloc] initWithCapacity:0];

    employeeListTableViewController.allowsSelectionDuringEditing = YES;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonAction)];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonAction)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:actionButton, addButton, nil];
    
    //this will prevent the screens to overlap the navigation bar for iOS 7
    self.navigationController.navigationBar.translucent = NO;

//    PushNotificationManager* manager = [PushNotificationManager sharedManager];
//    [manager registerForPushNotification:^(BOOL successful, NSError *error) {
        
//    }];


}

- (void)viewDidUnload
{
    [self setEmployeeListTableViewController:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear: animated];
        if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
            self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
      }
    
    [self callGetEmployees];
 //   PushNotificationManager* manager = [PushNotificationManager sharedManager];
 //   [manager registerForPushNotification:^(BOOL successful, NSError *error) {
        
 //   }];

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [employeesList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EmployeeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [UIImage imageNamed:@"person"];
        }
        
    }
    
    // Configure the cell...
    if ([employeesList count] > 0) {
         NSMutableDictionary *employee = [employeesList objectAtIndex:indexPath.row];
        cell.textLabel.text = [employee valueForKey:@"Name"];
        BOOL isClockedIn = [[employee valueForKey:@"isClockedIn"] boolValue];
        if (isClockedIn){
            cell.detailTextLabel.textColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);;
            //X58B100
            cell.detailTextLabel.text = @"Clocked In";
        }
        else
            cell.detailTextLabel.text = @"";

   }
  
  //  cell.textLabel.text = [sampleItems objectAtIndex:indexPath.row];

    
    return cell;
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *employee = [employeesList objectAtIndex:indexPath.row];

    // Navigation logic may go here. Create and push another view controller.
    if (!empProfileViewController){
        empProfileViewController = [[EmployeeProfileViewController alloc] initWithNibName:@"EmployeeProfileViewController" bundle:nil];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    
            // self.employeetimeSheetViewController.delegate = (id) self;
            }
        //create a navigation controller for the timesheet tab
        //        empProfileViewController = [[EmployeeProfileViewController alloc] initWithNibName:@"EmployeeProfileViewController" bundle:nil];
        

        
            _employeeDetailNavigationController = [[UINavigationController alloc] initWithRootViewController:empProfileViewController];
       
            //create a navigation controller for the timesheet tab
        //        TimeSheetMasterViewController *viewController2;
        //    AddEmployeeViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationAddEmployee"];

            empTimeSheetViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TimeSheetMasterViewController"];
       // empTimeSheetViewController = [[TimeSheetMasterViewController alloc] initWithNibName:@"TimeSheetMasterViewController_iPhone" bundle:nil];

    
            self.timeSheetNavigationController = [[UINavigationController alloc] initWithRootViewController:empTimeSheetViewController];
                
            self.tabBarController = [[UITabBarController alloc] init];
            self.tabBarController.viewControllers = [NSArray arrayWithObjects:empTimeSheetViewController, empProfileViewController, nil];
    
    }
    UserClass* user = [UserClass getInstance];
    if (empProfileViewController){
        user.userID = [employee valueForKey:@"ID"];
        empProfileViewController.employeeID = [employee valueForKey:@"ID"];//user.userID;
        empProfileViewController.employeeName = [employee valueForKey:@"Name"];
        //user.userEmail = [employee valueForKey:@"Email"];
        empProfileViewController.employeeEmail = [employee valueForKey:@"Email"];;//user.userEmail;
       // empProfileViewController.employeeEmail = user.userEmail;
        empProfileViewController.acceptedInvite = [employee valueForKey:@"acceptedInvite"];
    }
    if (empTimeSheetViewController){
        user.userID = [employee valueForKey:@"ID"];
        empTimeSheetViewController.employeeID = [employee valueForKey:@"ID"];//user.userID;
        empTimeSheetViewController.employeeName = [employee valueForKey:@"Name"];
        //pass the selected employee email so it can be used in the email time sheet
        //user.userEmail = [employee valueForKey:@"Email"];
        empTimeSheetViewController.employeeEmail = [employee valueForKey:@"Email"];//user.userEmail;
        //empTimeSheetViewController.employeeEmail = user.userEmail;
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {

        [self.navigationController pushViewController:self.tabBarController animated:YES];
    }
    else {
        [empProfileViewController LoadData];
    }
 
}
-(void) actionButtonAction
{
    UIActionSheet *pickerViewAction;
    //if we are in edit mode then only show the Cancel button
    if (editFlag == YES){

        pickerViewAction = [[UIActionSheet alloc] initWithTitle:@"Delete Employee"
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:nil];
    }
    else
    {
        pickerViewAction = [[UIActionSheet alloc] initWithTitle:@"Employees"
                                                                      delegate:self
                                                             cancelButtonTitle:@"Cancel"
                                                        destructiveButtonTitle:nil
                                                             otherButtonTitles:@"Refresh", @"Delete", EMAIL_ALL_TIMESHEETS, nil];
        
    }
    
    [pickerViewAction  showInView:[self.view window]];
    
}
-(void) addButtonAction
{
    [self startSpinnerWithMessage:@"Checking Licensing..."];
    //call the subscription webservice to check if the user has used up all their available employee slots
    //of if their subsription has expired
    SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
    subscriptionWebService.delegate = (id) self;
    [subscriptionWebService callHasValidLicenseWebService];

 /*   if ([user.availableEmployeeSlots intValue] <= 0)
    {
    //they have reached the max of employees
        UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You have reached the maximum number of employees. Please upgrade your account through our website and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
    else{
        AddEmployeeViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AddEmployee"];
        
        UINavigationController *addEmployeeNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        
    
//        AddEmployeeViewController *controller = [[AddEmployeeViewController alloc] initWithNibName:@"AddEmployeeViewController" bundle:nil];
        //self.timeSheetDetailViewController.delegate = (id) self;
        controller.delegate = (id) self;
        controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
        [self presentViewController:addEmployeeNavigationController animated:YES completion:nil];
    }
    */
}

-(void) refreshButtonAction
{
     [self callGetEmployees];   
}

-(void) deleteButtonAction
{
    
}

-(void) menuButtonAction
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}


- (void)addEmployeeViewControllerDidFinish:(UIViewController *)controller CancelWasSelected:(bool)cancelWasSelected
{
    [self dismissViewControllerAnimated:YES completion:nil];
    //don't call the server if the customer pressed the cancel button
}


-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            [self stopSpinner];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //error 503 is when tomcat is down
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
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
    if (mode == OperationGet)
    {
        UserClass *user = [UserClass getInstance];

        UIAlertView *alert;
        //   [self stopSpinner];
        NSError *error = nil;
        NSString *name;
        NSStream *employeeEmail;
        NSNumber *employeeID;
        NSNumber *acceptedInvite;
        NSNumber *isClockedIn;
        employeesList = nil;
        employeesList = [[NSMutableArray alloc] initWithCapacity:0];
        
//    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
        NSString *resultMessage = [results valueForKey:@"message"];

        NSMutableDictionary *item;
        //if message is null or <> Success then the call failed
        if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from EmployeeListViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];

        }
        else {
         
//            NSDictionary *employeeNameIDItem;
            
            NSArray *employees = [results valueForKey:@"employees"];
            int employeeCnt = (int) employees.count;
            user.employeeCount = [NSNumber numberWithInt: employeeCnt];
            //persist selection
            [[NSUserDefaults standardUserDefaults] setObject:user.employeeCount forKey:@"employeeCount"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            
            for (NSDictionary *employee in employees){
                
                name = [employee valueForKey:@"employeeName"];
                employeeID = [employee valueForKey:@"id"];
                
                NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]init];
                [mutableDict setObject:name forKey:[employeeID stringValue]];


             //   employeeNameIDItem = [[NSMutableDictionary alloc] init];
                [user.employeeNameIDList setValue:name forKey:[employeeID stringValue]];
            //    [user.employeeNameIDList addObject:employeeNameIDItem];


                acceptedInvite = [employee valueForKey:@"acceptedInvite"];
                NSObject *tmpJson = [employee valueForKey:@"activeTimeEntry"];
                isClockedIn = 0;
                if (![tmpJson isEqual:[NSNull null]])
                    isClockedIn = [NSNumber numberWithInt:1];
                
                employeeEmail = [employee valueForKey:@"employeeContactEmail"];
            
                item = [[NSMutableDictionary alloc] init];
            
                [item setValue:name forKey:@"Name"];
                [item setValue:employeeID forKey:@"ID"];
                [item setValue:acceptedInvite forKey:@"acceptedInvite"];
                [item setValue:isClockedIn forKey:@"isClockedIn"];
                [item setValue:employeeEmail forKey:@"Email"];

            
                [employeesList addObject:item];
        
            }
        }
        
        [employeeListTableViewController reloadData];
        
  
    }
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self stopSpinner];
    //if we have a network connection show one message to the user else show another
    //some reason this is returning an error = timed out in the new release for no reason going to take it out for now
    if ([CommonLib DoWeHaveNetworkConnection] )
    {
  /*      NSString *msg = [NSString
                         stringWithFormat:@"3.ezClocker is unable to connect to the server at this time. Please try again later error =%@", [error localizedDescription]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
        [alert show];
   */
    }
    else
        [SharedUICode displayServiceUnavailableErrorWithMsg:@"NOTE: You can  clock in/clock employees, we will save to the server later when it is available."];

    connection = nil;
    data = nil;
}

-(void) callGetEmployees{
    mode = OperationGet;
    UIAlertView *alert;
    NSString *httpPostString;
    NSString *request_body;
    UserClass *user = [UserClass getInstance];
//    user.authToken = @"f57fd8bf-3b12-4012-b580-9ab0be6e8303";
//    int *employerID = 25;
//    user.employerName = @"EZNova Technologies";
//    user.employerID = [NSNumber numberWithInt:employerID];

    httpPostString = [NSString stringWithFormat:@"%@api/v1/thin/employee", SERVER_URL];

//    httpPostString = [NSString stringWithFormat:@"%@employee/get/%@", SERVER_URL, user.employerID];
    
    //Implement request_body for send request here authToken and clock DateTime set into the body.
    request_body = [NSString 
                    stringWithFormat:@"authToken=%@",
                    [user.authToken  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                    ];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];



    //set HTTP Method
  //  [urlRequest setHTTPMethod:@"POST"];
    
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:[user.employerID stringValue] forHTTPHeaderField:@"x-ezclocker-employerId"];
    [urlRequest setValue:user.authToken forHTTPHeaderField:@"x-ezclocker-authToken"];


    
    //set request body into HTTPBody.
//    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
    
    
}

-(void) callDeleteEmployee: (NSNumber*) empID{
    mode = OperationDelete;
    UIAlertView *alert;
    NSString *httpPostString;
    NSString *request_body;
    UserClass *user = [UserClass getInstance];
    
    httpPostString = [NSString stringWithFormat:@"%@employee/remove/%@/%@", SERVER_URL, user.employerID, empID];
    //Implement request_body for send request here authToken and clock DateTime set into the body.
    request_body = [NSString
                    stringWithFormat:@"authToken=%@",
                    [user.authToken  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                    ];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
    
    
}

-(void) editButtonAction
{
    /*    if (editFlag == YES){
     editFlag = NO;
     self.navigationItem.leftBarButtonItem.title = @"Edit";
     [TimeEntryTableView setEditing:NO animated: NO];
     }
     else {
     editFlag = YES;
     self.navigationItem.leftBarButtonItem.title = @"Done";
     */
    [employeeListTableViewController setEditing:YES animated: YES];
    
    //    }
}

-(void) emailAllTimeSheetsAction
{
    EmailTimeSheetViewController *emaiViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmailTimeSheet"];
    
    UINavigationController *emailNavigationController = [[UINavigationController alloc] initWithRootViewController:emaiViewController];
    
    
    UserClass *user = [UserClass getInstance];
    NSString *startdate, *enddate;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale: [[NSLocale alloc]
                               initWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    
 
    //if we don't have payroll start date then pass today's date as the end date and 7 days before as the start
    if ([user.payrollStartDate length] == 0)
    {
        NSTimeInterval secondsPerDay = 24 * 60 * 60;
        NSDate *today = [[NSDate alloc] init];
        NSDate *oneWeek;
        
        oneWeek = [today dateByAddingTimeInterval: -secondsPerDay * 7];

        startdate =[dateFormatter stringFromDate:oneWeek];
        
        enddate = [dateFormatter stringFromDate:today];
        
    }
    else{
        //use the saved parytoll dates but change them to ISO
        startdate = user.payrollStartDate;
        enddate = user.payrollEndDate;
    }
    emaiViewController.startDate = startdate;
    emaiViewController.endDate = enddate;
    
 //   emaiViewController.employeeID = employeeID;
 //   emaiViewController.employeeEmail = _employeeEmail;
    
    emaiViewController.emailAllTimeSheets = YES;
    
    emaiViewController.delegate = (id) self;
    emaiViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    
    [self presentViewController:emailNavigationController animated:YES completion:nil];
 }


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    //Get the name of the current pressed button
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if  ([buttonTitle isEqualToString:ADD_EMPLOYEE]) {
        [self addButtonAction];
    }
    else
    {
        if  ([buttonTitle isEqualToString:DELETE_EMPLOYEE]) {
            editFlag = YES;
            [self editButtonAction];
        }
        else
        {
            if ([buttonTitle isEqualToString:REFRESH_EMPLOYEE]){
                [self refreshButtonAction];
            
            }
            else if ([buttonTitle isEqualToString:EMAIL_ALL_TIMESHEETS]){
                [self emailAllTimeSheetsAction];
            }
            
            //cancel button was selected so turn off editing incase it was on
            else{
                [employeeListTableViewController setEditing:NO animated: YES];
                editFlag = NO;
            }
        }
    }
    
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableDictionary *employee =  [employeesList objectAtIndex:indexPath.row];
        NSNumber *empID = [employee valueForKey:@"ID"];
        [employeesList removeObjectAtIndex:indexPath.row];
        // Delete the row from the data source
        [employeeListTableViewController deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [employeeListTableViewController setEditing:NO animated: YES];
        editFlag = NO;
        [self callDeleteEmployee: empID];
    }
}




- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Your subsription has expired. Please go to the subscription page to update your account" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
}
//this is a call back from the subscription webservice
- (void)subscriptionValid{
    [self stopSpinner];
    UserClass *user = [UserClass getInstance];
    
    if ([user.availableEmployeeSlots intValue] <= 0)
    {
        //they have reached the max of employees
        UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You have reached the maximum number of employees. Please upgrade your account using the subsciption page and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
    else{
        AddEmployeeViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AddEmployee"];
        
        UINavigationController *addEmployeeNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        
        
        controller.delegate = (id) self;
        controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self presentViewController:addEmployeeNavigationController animated:YES completion:nil];
    }
}

- (void)emailTimeSheetViewControllerDidFinish:(EmailTimeSheetViewController *)controller
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
