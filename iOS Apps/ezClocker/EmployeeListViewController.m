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
#import "PushNotificationManager.h"
#import "SharedUICode.h"
#import "NSString+Extensions.h"
#import "NSDictionary+Extensions.h"
#import "NSNumber+Extensions.h"
#import "CommonLib.h"
#import "threaddefines.h"

@interface EmployeeListViewController ()

@property (nonatomic, retain) UIRefreshControl* refreshControl;

@end

@implementation EmployeeListViewController
@synthesize refreshControl;
@synthesize employeeListTableViewController;
@synthesize employeesList;
@synthesize timeSheetNavigationController = _timeSheetNavigationController;
@synthesize employeeDetailNavigationController = _employeeDetailNavigationController;
//@synthesize employeeProfileViewController;

NSString *const REFRESH_EMPLOYEE = @"Refresh";
NSString *const ADD_EMPLOYEE = @"Add";
NSString *const DELETE_EMPLOYEE = @"Delete";
NSString *const EMAIL_ALL_TIMESHEETS = @"Email All TimeSheets";
bool firstTimeError;


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
        self.title = NSLocalizedString(@"Dashboard", @"Dashboard");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//            self.clearsSelectionOnViewWillAppear = NO;
 //           self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
            self.preferredContentSize = CGSizeMake(320.0, 600.0);
  
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
    
    if (employeesList == nil)
        employeesList = [[NSMutableArray alloc] initWithCapacity:0];

    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Please wait..."];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

    [self __setEditButtons];

    //this will prevent the screens to overlap the navigation bar for iOS 7
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbarHidden = FALSE;
    
/*    CGFloat safeAreaBottom = 0.0;
    if (@available(iOS 11.0, *)) {
        if(![[UIApplication sharedApplication] keyWindow])
        {
            safeAreaBottom = [[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom;
        }
      //  safeAreaBottom = UIApplication.shared.keyWindow!.safeAreaInsets.bottom;
    }
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, safeAreaBottom, 0);
 
   // employeeListTableViewController.backgroundColor = [UIColor red];
    employeeListTableViewController.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide * guide = self.view.safeAreaLayoutGuide;
    [employeeListTableViewController.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor].active = YES;
    [employeeListTableViewController.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor].active = YES;
    [employeeListTableViewController.topAnchor constraintEqualToAnchor:guide.topAnchor].active = YES;
    [employeeListTableViewController.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor].active = YES;
    
    // Refresh myView and/or main view
    [self.view layoutIfNeeded];
 */

    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.toolbarHidden = TRUE;
}

- (void)refresh:(UIRefreshControl*)sender {
    // Sanity!  The refreshControl will be removed from the tableview when editing
    if (self.tableView.editing) {
        [refreshControl endRefreshing];
        [SharedUICode messageBox:nil message:@"You cannot refresh while in edit mode.  Cancel editing in order to refresh." withCompletion:^{

        }];
        return;
    }
    [self enableBarItems:FALSE];
    [self callGetEmployees];
}

- (void)enableBarItems:(BOOL)bEnabled {
    self.navigationItem.leftBarButtonItem.enabled = bEnabled;
    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem.enabled = bEnabled;
    }
}

//- (void)editClicked:(id)sender {
//    [self setEditState];
//}

- (void)addNewEmployee {
    [self startSpinnerWithMessage:@"Checking Licensing..."];
    //call the subscription webservice to check if the user has used up all their available employee slots
    //of if their subsription has expired
    SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
    subscriptionWebService.delegate = (id) self;
   // [subscriptionWebService callHasValidLicenseWebService];
    [subscriptionWebService checkValidLicense];
}

- (void)addClicked:(id)sender {
    [self addNewEmployee];
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

- (void)__cancelEditing {
    [self setEditButtons];
}

- (void)cancelEditing {
    if (nil == self.navigationItem.leftBarButtonItem) {
        return;
    }
    [self __cancelEditing];
}

- (void)beforeEditingBegins {
    // override on iPad to hide the detail view if you will have a detail view
}

- (void)setEditState {
    if (nil == self.navigationItem.leftBarButtonItem) {
        return;
    }
    if (self.editing) { // Not editing go into edit mode
        [self setEditing:NO animated:YES];
        [self __cancelEditing];
        return;
    }

    [self beforeEditingBegins];
    [self setEditing:YES animated:YES];

    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelClicked:)];
    self.navigationItem.leftBarButtonItem = cancelButton;

    self.navigationItem.rightBarButtonItems = nil;

   // UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClicked:)];
  //  self.navigationItem.rightBarButtonItem = addButton;

    [refreshControl removeFromSuperview];
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

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClicked:)];
    
//    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editClicked:)];
   // self.navigationItem.rightBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:addButton, nil];

    [self.tableView addSubview:refreshControl];
}

- (void)setCancelButtonForSwipDelete {
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelClicked:)];
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

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return 60;
//}
- (void)beforeDeleteObject {
    //Clear any references and etc.
}

//removed the edit button
/*
- (void)deleteEmployeeAtIndexPath:(NSIndexPath*)indexPath {
    NSMutableDictionary *employee =  [employeesList objectAtIndex:indexPath.row];
    NSNumber *empID = [employee valueForKey:@"ID"];
    [employeesList removeObjectAtIndex:indexPath.row];
    // Delete the row from the data source
    [employeeListTableViewController deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [employeeListTableViewController setEditing:NO animated: YES];
    editFlag = NO;
    [self callDeleteEmployee: empID];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    if (mode != OperationNone) {
        [SharedUICode messageBox:nil message:@"Cannot delete at this time.  Currently processing a request.  Please try again in a few minutes." withCompletion:^{
            
        }];
        return;
    }

    UIView *view = [cancelButton valueForKey:@"view"];
    [SharedUICode yesNoCancel:nil message:@"Delete Employee.  Are you sure?" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing" rootControl:view withCompletion:^(YesNoCancelResult Result) {
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
}
*/

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
    self.navigationController.toolbarHidden = FALSE;
        if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
            self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
      }
    
    firstTimeError = TRUE;
    
/*    employeeListTableViewController.rowHeight = UITableViewAutomaticDimension;
    employeeListTableViewController.estimatedRowHeight = 44;
    
    employeeListTableViewController.sectionHeaderHeight = UITableViewAutomaticDimension;
    employeeListTableViewController.estimatedSectionHeaderHeight = 0;
    
    employeeListTableViewController.sectionFooterHeight = UITableViewAutomaticDimension;
    employeeListTableViewController.estimatedSectionFooterHeight = 0;
*/
    UserClass *user = [UserClass getInstance];
    NSString *providerPlan = user.subscription_planProvider;
    //if the user has an expired license/is not valid then check to see if they are on the free trial which is the website or Braintree and tell them to go the website to renew
    if ((![NSNumber isNilOrNull:user.subscription_IsValid]) && ([user.subscription_IsValid intValue] == 0))

    {
        if ((![NSString isNilOrEmpty:providerPlan]) && (([providerPlan isEqualToString:@"EZCLOCKER_FREE_TRIAL"]) || ([providerPlan isEqualToString:@"BRAINTREEPAYMENTS_SUBSCRIPTION"])) )
        {
            [SharedUICode messageBox:nil message:@"Your ezClocker subscription has expired. Your subscription was made outside the iPhone app. To fix this please sign into ezclocker.com via a computer and enter your credit card. If you have any questions please send email to support@ezclocker.com." withCompletion:^{
                return;
            }];
        }
    }
    [self callGetEmployees];

    PushNotificationManager* manager = [PushNotificationManager sharedManager];
    [manager registerForPushNotification:^(BOOL successful, NSError *error) {

    }];
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
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [UIImage imageNamed:@"person"];
    }
    
    // Configure the cell...
    if ([employeesList count] > 0) {
         NSMutableDictionary *employee = [employeesList objectAtIndex:indexPath.row];
        cell.textLabel.text = [employee valueForKey:@"Name"];
        BOOL isClockedIn = [[employee valueForKey:@"isClockedIn"] boolValue];
        NSString *assignedJobName = [employee valueForKey:@"assignedJobName"];
        if (isClockedIn){
            cell.detailTextLabel.textColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
            if ([NSString isNilOrEmpty:assignedJobName])
                cell.detailTextLabel.text = @"Clocked In";
            else
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", @"Clocked In", assignedJobName];
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

// ***************************************************************************************************
// NOTE: This is where the EmployeeProfileViewController that represents Clock In/Clock Out is created
// ***************************************************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //prevent the user from leaving the employee list while in edit mode
    if (self.tableView.editing) {
        [SharedUICode messageBox:nil message:@"You cannot view employee while in edit mode.  Cancel editing or tap the red icon to delete the employee." withCompletion:^{
            
        }];
        return;
    }

    NSMutableDictionary *employee = [employeesList objectAtIndex:indexPath.row];

    // Navigation logic may go here. Create and push another view controller.
    if (!empProfileViewController){
#ifdef IPAD_VERSION
         UIStoryboard *iPadStoryboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
        empProfileViewController = [iPadStoryboard instantiateViewControllerWithIdentifier:@"EmployeeProfileiPad"];
#else
        empProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmployeeProfileViewController"];
#endif
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
        empProfileViewController.primaryJobCode = [employee valueForKey:@"primaryJobCode"];
    }
    if (empTimeSheetViewController){
        user.userID = [employee valueForKey:@"ID"];

        empTimeSheetViewController.employeeID = [employee valueForKey:@"ID"];//user.userID;
        empTimeSheetViewController.employeeName = [employee valueForKey:@"Name"];
        //pass the selected employee email so it can be used in the email time sheet
        //user.userEmail = [employee valueForKey:@"Email"];
        empTimeSheetViewController.employeeEmail = [employee valueForKey:@"Email"];//user.userEmail;
        empTimeSheetViewController.jobCodes = [employee valueForKey:@"jobCodes"];
        empTimeSheetViewController.primaryJobCode = [employee valueForKey:@"primaryJobCode"];
    }
  //  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {

        [self.navigationController pushViewController:self.tabBarController animated:YES];
  //  }
 //   else {
 //       [empProfileViewController LoadData];
 //   }
 
}

-(void) refreshButtonAction
{
     [self callGetEmployees];   
}

-(void) menuButtonAction
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}


- (void)addEmployeeViewControllerDidFinish:(UIViewController *)controller CancelWasSelected:(bool)cancelWasSelected
{
    [self dismissViewControllerAnimated:YES completion:nil];
    //don't call the server if the customer pressed the cancel button
    if (!cancelWasSelected)
        [self callGetEmployees];
}

/*
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        int statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            [self stopSpinner];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //error 503 is when tomcat is down
            [SharedUICode messageBox:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" withCompletion:^{
                mode = OperationNone;
            }];
            
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
    [self stopSpinner];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (mode == OperationGet)
    {
        UserClass *user = [UserClass getInstance];

        //   [self stopSpinner];
        NSError *error = nil;
        NSString *name;
        NSStream *employeeEmail;
        NSNumber *employeeID;
        NSNumber *acceptedInvite;
        NSNumber *isClockedIn;
        NSString *pin;

        NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
        NSString *resultMessage = [results valueForKey:@"message"];

        NSMutableDictionary *item;
        NSMutableDictionary *employeeObj;

        //if message is null or <> Success then the call failed
   //     if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"SUCCESS"])){
        if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
            //send the data that we got back to the log metrics so we can figure out what got sent back
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            //this may returns us a whole HTML page so truncate it to 100 characters
            dataString = (dataString.length > 100) ? [dataString substringToIndex:100] : dataString;
            
            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from EmployeeListViewController JSON Parsing Error= %@ resultMessage= %@ data= %@", error.localizedDescription, resultMessage, dataString]];
            [refreshControl endRefreshing];
            [self enableBarItems:TRUE];
           // [SharedUICode messageBox:nil message:@"Server Failure." withCompletion:^{

          //  }];
            mode = OperationNone;
            return;
        }
        else {
            //clear the list to reload
            
            NSArray *employees = [results valueForKey:@"employees"];

            if (employees != nil){
                [user.employeeList removeAllObjects];
                [user.employeeNameIDList removeAllObjects];
                [employeesList removeAllObjects];
 //               employeesList = [[NSMutableArray alloc] initWithCapacity:0];
                int employeeCnt = (int) employees.count;
                user.employeeCount = [NSNumber numberWithInt: employeeCnt];
                //persist selection
                [[NSUserDefaults standardUserDefaults] setObject:user.employeeCount forKey:@"employeeCount"];
              //  [[NSUserDefaults standardUserDefaults] synchronize];

            }
            for (NSDictionary *employee in employees){
                
                NSNumber *jobCodeId;
                NSString *tagName;
              //  NSString *jobCodeDisplayValue;
                NSString *description;
                NSDictionary *primaryJobCode;

                NSDictionary *assignedToEntities = [employee valueForKey: @"dataTagAssignments"];
                NSMutableArray *_jobCodeList = [[NSMutableArray alloc] init];
                NSMutableArray *jobCodes =  [assignedToEntities valueForKey: @"JOB_CODE"];
                for (NSDictionary *jobCode in jobCodes)
                {
                     jobCodeId = [jobCode valueForKey:@"id"];
                     tagName = [jobCode valueForKey:@"tagName"];//tagId
                    // jobCodeDisplayValue = [jobCode valueForKey:@"displayValue"];
                     description = [jobCode valueForKey:@"description"];

                    
                    NSMutableDictionary *_jobCode = [[NSMutableDictionary alloc] init];
                     @try{
                         [_jobCode setValue:jobCodeId forKey:@"id"];
                         [_jobCode setValue:tagName forKey:@"name"];
                        // [_jobCode setValue:jobCodeDisplayValue forKey:@"displayValue"];
                         [_jobCode setValue:description forKey:@"description"];
                         [_jobCodeList addObject:_jobCode];
                     }
                     @catch(NSException* ex) {
                         NSLog(@"Exception in setting JobCodes from Server: %@", ex);
                     }

                }

                primaryJobCode = [employee valueForKey:@"primaryJobCode"];
                
                name = [employee valueForKey:@"employeeName"];
                employeeID = [employee valueForKey:@"id"];
                
                pin = [employee valueForKey:@"teamPin"];
                
                NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]init];
                [mutableDict setObject:name forKey:[employeeID stringValue]];

                [user.employeeNameIDList  setValue:name forKey:[employeeID stringValue]];
                
                employeeObj = [[NSMutableDictionary alloc] init];
                [employeeObj setValue:name forKey:@"Name"];
                [employeeObj setValue:employeeID forKey:@"ID"];
                if
                    ((_jobCodeList != nil) && ([_jobCodeList count] > 0))
                {
                    [employeeObj setValue:_jobCodeList forKey:@"jobCodes"];
                }
                
                if (![NSDictionary isNilOrNull:primaryJobCode])
                    [employeeObj setValue:primaryJobCode forKey:@"primaryJobCode"];
                
                [user.employeeList addObject:employeeObj];

                acceptedInvite = [employee valueForKey:@"acceptedInvite"];
                NSObject *tmpJson = [employee valueForKey:@"activeTimeEntry"];
                isClockedIn = 0;
                if ((![tmpJson isEqual:[NSNull null]]) && (tmpJson != nil))
                    isClockedIn = [NSNumber numberWithInt:1];
                
                employeeEmail = [employee valueForKey:@"employeeContactEmail"];
                

            
                item = [[NSMutableDictionary alloc] init];
            
                [item setValue:name forKey:@"Name"];
                [item setValue:employeeID forKey:@"ID"];
                [item setValue:pin forKey:@"pin"];
                [item setValue:acceptedInvite forKey:@"acceptedInvite"];
                [item setValue:isClockedIn forKey:@"isClockedIn"];
                [item setValue:employeeEmail forKey:@"Email"];
                [item setValue:_jobCodeList forKey:@"jobCodes"];
                [item setValue:primaryJobCode forKey:@"primaryJobCode"];

            
                [employeesList addObject:item];
        
            }
        }
        
        [employeeListTableViewController reloadData];
    }
    [refreshControl endRefreshing];
    [self enableBarItems:TRUE];
    [self __setEditButtons];
    mode = OperationNone;
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self stopSpinner];
    [refreshControl endRefreshing];
    [self enableBarItems:TRUE];
    if (firstTimeError)
    {
        firstTimeError = false;
        [self callGetEmployees];
        
    }
    else{
    
        [SharedUICode messageBox:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" withCompletion:^{
            data = nil;
            mode = OperationNone;
        }];
    }
}
 */

-(void) callGetEmployees{
    [self callGetEmployeesAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [ErrorLogging logErrorWithDomain:@"GET_EMPLOYEES" code:UNKNOWN_ERROR description:@"GET_EMPLOYEES_ERROR" error:aError];
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (mode == OperationGet)
            {
                UserClass *user = [UserClass getInstance];

                //   [self stopSpinner];
                NSError *error = nil;
                NSString *name;
                NSStream *employeeEmail;
                NSNumber *employeeID;
                NSNumber *acceptedInvite;
                NSNumber *isClockedIn;
                NSString *pin;

               // NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
                NSString *resultMessage = [aResults valueForKey:@"message"];

                NSMutableDictionary *item;
                NSMutableDictionary *employeeObj;

                //if message is null or <> Success then the call failed
           //     if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"SUCCESS"])){
                if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
                    //send the data that we got back to the log metrics so we can figure out what got sent back
                    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

                    //this may returns us a whole HTML page so truncate it to 100 characters
                    dataString = (dataString.length > 100) ? [dataString substringToIndex:100] : dataString;
                    
                    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from EmployeeListViewController JSON Parsing Error= %@ resultMessage= %@ data= %@", error.localizedDescription, resultMessage, dataString]];
                    [ErrorLogging logErrorWithDomain:@"GET_EMPLOYEES" code:UNKNOWN_ERROR description:@"ERROR_EMPLOYEE_JSON_PARSING" error:aError];
                    [refreshControl endRefreshing];
                    [self enableBarItems:TRUE];
                   // [SharedUICode messageBox:nil message:@"Server Failure." withCompletion:^{

                  //  }];
                    mode = OperationNone;
                    return;
                }
                else {
                    //clear the list to reload
                    
                    NSArray *employees = [aResults valueForKey:@"employees"];

                    if (employees != nil){
                        [user.employeeList removeAllObjects];
                        [user.employeeNameIDList removeAllObjects];
                        [employeesList removeAllObjects];
         //               employeesList = [[NSMutableArray alloc] initWithCapacity:0];
                        int employeeCnt = (int) employees.count;
                        user.employeeCount = [NSNumber numberWithInt: employeeCnt];
                        //persist selection
                        [[NSUserDefaults standardUserDefaults] setObject:user.employeeCount forKey:@"employeeCount"];
                      //  [[NSUserDefaults standardUserDefaults] synchronize];

                    }
                    for (NSDictionary *employee in employees){
                        
                        NSNumber *jobCodeId;
                        NSString *tagName;
                      //  NSString *jobCodeDisplayValue;
                        NSString *description;
                        NSDictionary *primaryJobCode;

                        NSDictionary *assignedToEntities = [employee valueForKey: @"dataTagAssignments"];
                        NSMutableArray *_jobCodeList = [[NSMutableArray alloc] init];
                        NSMutableArray *jobCodes =  [assignedToEntities valueForKey: @"JOB_CODE"];
                        for (NSDictionary *jobCode in jobCodes)
                        {
                             jobCodeId = [jobCode valueForKey:@"id"];
                             tagName = [jobCode valueForKey:@"tagName"];//tagId
                            // jobCodeDisplayValue = [jobCode valueForKey:@"displayValue"];
                             description = [jobCode valueForKey:@"description"];

                            
                            NSMutableDictionary *_jobCode = [[NSMutableDictionary alloc] init];
                             @try{
                                 [_jobCode setValue:jobCodeId forKey:@"id"];
                                 [_jobCode setValue:tagName forKey:@"name"];
                                // [_jobCode setValue:jobCodeDisplayValue forKey:@"displayValue"];
                                 [_jobCode setValue:description forKey:@"description"];
                                 [_jobCodeList addObject:_jobCode];
                             }
                             @catch(NSException* ex) {
                                 NSLog(@"Exception in setting JobCodes from Server: %@", ex);
                             }

                        }

                        primaryJobCode = [employee valueForKey:@"primaryJobCode"];
                        
                        name = [employee valueForKey:@"employeeName"];
                        employeeID = [employee valueForKey:@"id"];
                        
                        pin = [employee valueForKey:@"teamPin"];
                        
                        NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]init];
                        [mutableDict setObject:name forKey:[employeeID stringValue]];

                        [user.employeeNameIDList  setValue:name forKey:[employeeID stringValue]];
                        
                        employeeObj = [[NSMutableDictionary alloc] init];
                        [employeeObj setValue:name forKey:@"Name"];
                        [employeeObj setValue:employeeID forKey:@"ID"];
                        if
                            ((_jobCodeList != nil) && ([_jobCodeList count] > 0))
                        {
                            [employeeObj setValue:_jobCodeList forKey:@"jobCodes"];
                        }
                        
                        if (![NSDictionary isNilOrNull:primaryJobCode])
                            [employeeObj setValue:primaryJobCode forKey:@"primaryJobCode"];
                        
                        [user.employeeList addObject:employeeObj];

                        acceptedInvite = [employee valueForKey:@"acceptedInvite"];
                        NSObject *tmpJson = [employee valueForKey:@"activeTimeEntry"];
                        NSString *assignedJobName;
                        isClockedIn = 0;
                        if ((![tmpJson isEqual:[NSNull null]]) && (tmpJson != nil))
                        {
                            isClockedIn = [NSNumber numberWithInt:1];
                            NSMutableArray *assignedJobs =  [tmpJson valueForKey: @"assignedJobs"];
                            for (NSDictionary *assignedJob in assignedJobs)
                            {
                                NSString *jobCodeType = [assignedJob objectForKey:@"ezDataTagType"];
                                if ([jobCodeType isEqual:@"JOB_CODE"])
                                    assignedJobName = [assignedJob objectForKey:@"tagName"];

                            }
                        }
                        
                        employeeEmail = [employee valueForKey:@"employeeContactEmail"];
                        

                    
                        item = [[NSMutableDictionary alloc] init];
                    
                        [item setValue:name forKey:@"Name"];
                        [item setValue:employeeID forKey:@"ID"];
                        [item setValue:pin forKey:@"pin"];
                        [item setValue:acceptedInvite forKey:@"acceptedInvite"];
                        [item setValue:isClockedIn forKey:@"isClockedIn"];
                        [item setValue:employeeEmail forKey:@"Email"];
                        [item setValue:_jobCodeList forKey:@"jobCodes"];
                        [item setValue: assignedJobName forKey:@"assignedJobName"];
                        [item setValue:primaryJobCode forKey:@"primaryJobCode"];

                    
                        [employeesList addObject:item];
                
                    }
                }
                
                [employeeListTableViewController reloadData];
            }
            [refreshControl endRefreshing];
            [self enableBarItems:TRUE];
            [self __setEditButtons];
            mode = OperationNone;

        }
    }];
}


-(void) callGetEmployeesAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    if (mode != OperationNone) {
#ifndef RELEASE
        NSLog(@"Currently processing %@ request", mode == OperationGet ? @"getting employees" : @"delete");
#endif
        return;
    }

    mode = OperationGet;
    NSString *httpPostString;
    UserClass *user = [UserClass getInstance];

    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/thin/employee", SERVER_URL];

//    httpPostString = [NSString stringWithFormat:@"%@employee/get/%@", SERVER_URL, user.employerID];
    
    
    
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

/*
    //set request body into HTTPBody.
//    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        [refreshControl endRefreshing];
        [self enableBarItems:TRUE];
        [SharedUICode messageBox:nil message:@"Connection to the server failed." withCompletion:^{
             mode = OperationNone;

        }];
    }
*/
}

//removed the edit/delete button
/*
-(void) callDeleteEmployee: (NSNumber*) empID{
    if (mode != OperationNone) {
#ifndef RELEASE
        NSLog(@"Currently processing %@ request", mode == OperationGet ? @"getting employees" : @"delete");
#endif
        return;
    }

    mode = OperationDelete;
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
    urlRequest.timeoutInterval = TIME_OUT_REQUEST;

    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        [SharedUICode messageBox:nil message:@"Connection to the server failed" withCompletion:^{
            mode = OperationNone;
        }];
        
    }
    
    
}
 */

- (IBAction)emailAllTimeSheets:(id)sender {
    [self emailAllTimeSheetsAction];
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
    [ErrorLogging logErrorWithDomain:@"SUBSCRIPTION" code:UNKNOWN_ERROR description:@"SUBSCRIPTION_EXPIRED" error:nil];
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Alert"
                                 message:@"Your subsription has expired. Please go to the subscription page to update your account"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];

  //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Your subsription has expired. Please go to the subscription page to update your account" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  //  [alert show];
    
}

- (void)subscriptionNotValid{
    [self stopSpinner];
     UserClass *user = [UserClass getInstance];
     NSString *msg = @"";
     //check to see if they do not have an Apple subscription then direct them to the website to enter their credit card
     if (![NSString isEquals:user.subscription_planProvider dest:@"APPLE_SUBSCRIPTION"])
     {
         msg = @"Your subscription has expired. Please sign-in to our website ezclocker.com and enter your credit card payment.";
         [ErrorLogging logErrorWithDomain:@"SUBSCRIPTION" code:UNKNOWN_ERROR description:@"SUBSCRIPTION_EXPIRED" error:nil];
         [SharedUICode messageBox:@"Error" message:msg withCompletion:^{
             return;
         }];
     }
     else
     {
         //     msg = @"Our records indicate that your subscription has expired. Please click the menu icon at the top left corner> select Subscription> select manage subscriptions > Go to ITunes Store to validate your iTunes ezClocker subscription expiration date.";
        //        [SharedUICode messageBox:@"Error" message:msg withCompletion:^{
         //           return;
        //        }];
               //Version 1.9.23 & 1.9.24 Let them add employees until we fix the bug where it says it's expired but it isn't
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
                                     alertControllerWithTitle:@"Alert"
                                     message:@"You have reached the maximum number of employees. Please upgrade your account using the account page from the ezClocker website and try again"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

       // UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You have reached the maximum number of employees. Please upgrade your account using the account page from the ezClocker website and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
#else
        //they have reached the max of employees
/*        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Alert"
                                     message:@"You have reached the maximum number of employees. Please upgrade your account using the subsciption page and try again"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
*/
        NSString *msg = @"";
        NSString *freeTrialEndMessage = @"You have reached the maximum number of employees for the free plan. Please pick a subscription and get 30 days FREE using the subsciption page.";
        NSString *NeedToUpgradeMessage = @"You have reached the maximum number of employees. Please upgrade your account using the subsciption page and try again.";
        
        if (CommonLib.userIsManager) //(user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"]))
        {
            freeTrialEndMessage = @"You have reached the maximum number of employees for the free plan. You do not have access to subscribe. Please ask the employer to pick a subscription and get 30 days FREE using the account page from the ezClocker website and try again.";
            NeedToUpgradeMessage = @"You have reached the maximum number of employees. You do not have access to upgrade. Please ask the employer of the account to upgrade using the subsciption screen on their app or ezClocker website and try again.";
        }

        //check to see if we are on the free plan then show them a message that talks about the 30 days free otherwise, just tell them to upgrade
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

- (void)emailTimeSheetViewControllerDidFinish:(EmailTimeSheetViewController *)controller
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
