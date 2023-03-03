//
//  CustomersViewController.m
//  ezClocker Personal
//
//  Created by Raya Khashab on 11/28/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//
#import "ECSlidingViewController.h"
#import "user.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "NSNumber+Extensions.h"
#import "FirstTopViewController.h"
#import "DataManager.h"
#import "CustomerWebservice.h"
#import "EZPurchaseManager.h"


#import "CustomersViewController.h"

@interface CustomersViewController ()

@end

@implementation CustomersViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Dashboard";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
 //we are already doing this in the AppDelegate
//#ifdef PERSONAL_VERSION
    //check license
//    SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
    
//    subscriptionWebService.delegate = (id) self;
    
//    [subscriptionWebService checkValidLicense];
//#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self getAllCustomers];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [curCustomerNameIDList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
    }
    if ([curCustomerNameIDList count] > 0)
    {
        NSDictionary *customerObj = [curCustomerNameIDList objectAtIndex:indexPath.row];
        cell.textLabel.text = [customerObj valueForKey:@"name"];
        
        BOOL isClockedIn = [[customerObj valueForKey:@"isClockedIn"] boolValue];
        if (isClockedIn){
            cell.detailTextLabel.textColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
            //X58B100
            cell.detailTextLabel.text = @"Clocked In";
        }
        else
            cell.detailTextLabel.text = @"";
    }
    return cell;
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //prevent the user from leaving the employee list while in edit mode
    if (self.tableView.editing) {
        [SharedUICode messageBox:nil message:@"You cannot view customer details while in edit mode.  Cancel editing or tap the red icon to delete the location." withCompletion:^{
            
        }];
        return;
    }
    customerDetailViewConroller = [self.storyboard instantiateViewControllerWithIdentifier:@"CustomerDetails"];

    
    // ...
    // Pass the selected object to the new view controller.
    UserClass *user = [UserClass getInstance];
    customerDetailViewConroller.customerDetails = [curCustomerNameIDList objectAtIndex:indexPath.row];
    
    customerDetailViewConroller.delegate = self;
    
    [self.navigationController pushViewController:customerDetailViewConroller animated:YES];
}

*/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *storyboard;
    
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    
    FirstTopViewController* firstTop = [storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
    [firstTop setDelegate:self];
    firstTop.fromCustomerDetail = YES;
    firstTop.previousNavigation = self.navigationController;


    NSDictionary *curCustomerObj = [curCustomerNameIDList objectAtIndex:indexPath.row];
    UserClass *user = [UserClass getInstance];
    NSNumber *tmpCurCustomerId = [curCustomerObj valueForKey:@"id"];
    user.curCustomerId = [curCustomerObj valueForKey:@"id"];
    
    //When we have customers then we should clear out the global variables there is no global activeTimeEntryId (the global variables are old code
    user.activeTimeEntryId = nil;
    user.lastClockIn = @"";
    user.lastClockOut = @"";
    user.currentClockMode = ClockModeIn;
    user.activeTimeEntryId = nil;

    DataManager* manager = [DataManager sharedManager];
    NSError* error = nil;
    if (![manager deleteAllRecordsForEmployee:&error]) {
#ifndef RELEASE
        NSLog(@"Error while deleting all employees on logout %@", error);
        [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:UNKNOWN_ERROR description:@"ERROR_DELETING_ALL_EMPLOYEES" error:error];
#endif
        
    }
//     [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController pushViewController:firstTop animated:YES];
//  [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
//    [self.navigationController setNavigationBarHidden:YES];
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

-(void) fetchAllCustomers
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
//    [CustomerWebservice fetchAllCustomers:^(NSMutableArray *array) {
//
//    }]
    [CustomerWebservice callGetAllCustomers:YES withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue fetching the customers from the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else {
            [self fillArrayValue:aResults];
        }
    }];
}

-(void)fillArrayValue: (NSDictionary * _Nullable) aResults {
     NSString *name;
     NSNumber *customerID;
     NSNumber* isClockedIn;
     NSString *email;
     UserClass *user = [UserClass getInstance];
     NSArray *customers = [aResults valueForKey:@"customers"];
    //block them if they have more than 1 customer and a subscription that's expired
    if (customers.count > 1)
    {
        NSString *provider = user.subscription_planProvider;
        BOOL isExpired = ((![NSNumber isNilOrNull:user.subscription_IsValid]) && ([user.subscription_IsValid intValue] == 0));//![[EZPurchaseManager sharedInstance] isNotExpired];
        //we check the subscription provider as a safety check bc it means the subscription webs service was called
        if ((![CommonLib onFreePlan]) && (isExpired) && (![NSString isNilOrEmpty:provider])) {
            [self enableView:NO];
        }
     }
     if (customers.count > 0)
     {
         [curCustomerNameIDList removeAllObjects];
         [user.customerNameIDList removeAllObjects];
     }
    
     for (NSDictionary *customer in customers){
         name = [customer valueForKey:@"name"];
         customerID = [customer valueForKey:@"id"];
         email = [customer valueForKey:@"emailAddress"];
         NSObject *tmpJson = [customer valueForKey:@"activeTimeEntry"];
         isClockedIn = 0;
         if ((![tmpJson isEqual:[NSNull null]]) && (tmpJson != nil))
             isClockedIn = [NSNumber numberWithInt:1];
         
         NSMutableDictionary *customerObj = [[NSMutableDictionary alloc] init];
         [customerObj setValue:name forKey:@"name"];
         [customerObj setValue:customerID forKey:@"id"];
         [customerObj setValue:email forKey:@"email"];
         [customerObj setValue:isClockedIn forKey:@"isClockedIn"];
         [user.customerNameIDList addObject:customerObj];
     }
     if ([user.customerNameIDList count] > 0)
     {
         curCustomerNameIDList =  [NSMutableArray arrayWithArray:user.customerNameIDList];
         [_customersListTableView reloadData];
     }
}

-(void) getAllCustomers {
    [self fetchAllCustomers];
}

- (void) enableView: (BOOL) isEnable {
   
    if (isEnable == NO) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Alert"
                                     message:@"Please purchase a subscription to access this feature."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* subscribeAction = [UIAlertAction actionWithTitle:@"Subscribe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            UIViewController*  newTopViewController;
#ifdef PERSONAL_VERSION
            newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavPersonalSubscription"];
#else
            newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavSubscriptionPlans"];
            
#endif
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
        
        [alert addAction:subscribeAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)nameTextField:(id)sender {
}

- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];

}


- (void)CustomerDetailsDidFinish:(CustomerDetailsViewController *)controller CancelWasSelected:(bool)cancelWasSelected;
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    [self getAllCustomers];
}

//this is a call back from the subscription license check webservice
- (void)subscriptionValid{
    [[EZPurchaseManager sharedInstance] setIsNotExpired:YES];
//    [self enableView:YES];
}


- (void)subscriptionNotValid{
    [[EZPurchaseManager sharedInstance] setIsNotExpired:NO];
//    [self enableView:NO];
}

- (void)subscriptionError
{
}

- (void)subscriptionExpired
{
    [[EZPurchaseManager sharedInstance] setIsNotExpired:NO];
}

@end
