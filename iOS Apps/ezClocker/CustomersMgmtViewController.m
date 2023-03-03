//
//  CustomersMgmtViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 7/27/19.
//  Copyright © 2019 ezNova Technologies LLC. All rights reserved.
//

#import "CustomersMgmtViewController.h"
#import "ECSlidingViewController.h"
#import "user.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "NSData+Extensions.h"
#import "NSNumber+Extensions.h"
#import "NSString+Extensions.h"
#import "FirstTopViewController.h"
#import "EZPurchaseManager.h"
#import "CustomerWebservice.h"
#import "WebViewController.h"

@interface CustomersMgmtViewController ()

@end

@implementation CustomersMgmtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Customers";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //check to see if we need to show the please purchase a subscription if we have more than one customer because one customer is free

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
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
        
    }
    
    return cell;
    
}

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
    NSDictionary *curCustomerObj = [curCustomerNameIDList objectAtIndex:indexPath.row];
    user.curCustomerId = [curCustomerObj valueForKey:@"id"];
    
    customerDetailViewConroller.customerDetails = [curCustomerNameIDList objectAtIndex:indexPath.row];
    
    customerDetailViewConroller.delegate = self;
    
    [self.navigationController pushViewController:customerDetailViewConroller animated:YES];
    
    
}


/*- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
 {
 UIStoryboard *storyboard;
 
 storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
 
 FirstTopViewController* firstTop = [storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
 [firstTop setDelegate:self];
 
 NSDictionary *curCustomerObj = [curCustomerNameIDList objectAtIndex:indexPath.row];
 UserClass *user = [UserClass getInstance];
 user.curCustomerId = [curCustomerObj valueForKey:@"id"];
 //   [firstTop setTitle:@"Title1"];
 
 [self.navigationController pushViewController:firstTop animated:YES];
 
 
 }
 */

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
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
    
    [SharedUICode yesNoCancel:nil message:@"Delete Customer.  Are you sure?" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing" rootControl:view withCompletion:^(YesNoCancelResult Result) {
        switch (Result) {
            case resultYes: {
                [self deleteCustomerAtIndexPath:indexPath];
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
     [CustomerWebservice callGetAllCustomers:YES withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue fetching the customers from the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else {
            
            [self fillArrayValue:aResults];
            [self __setEditButtons];
            [self showDemoVideoAlert];
        }
    }];
}

-(void)fillArrayValue: (NSDictionary * _Nullable) aResults {
    NSString *name;
    NSNumber *customerID;
    NSString *email;
    
    UserClass *user = [UserClass getInstance];
    NSArray *customers = [aResults valueForKey:@"customers"];
    if (customers.count > 0)
    {
        [curCustomerNameIDList removeAllObjects];
        [user.customerNameIDList removeAllObjects];
    }
    

    for (NSDictionary *customer in customers){
        name = [customer valueForKey:@"name"];
        customerID = [customer valueForKey:@"id"];
        email = [customer valueForKey:@"emailAddress"];
        
        NSMutableDictionary *customerObj = [[NSMutableDictionary alloc] init];
        [customerObj setValue:name forKey:@"name"];
        [customerObj setValue:customerID forKey:@"id"];
        [customerObj setValue:email forKey:@"email"];
        
        [user.customerNameIDList addObject:customerObj];
    }
    
    curCustomerNameIDList =  [NSMutableArray arrayWithArray:user.customerNameIDList];
    if ([curCustomerNameIDList count] == 0)
    {
        NSMutableDictionary *customerObj = [[NSMutableDictionary alloc] init];
        [customerObj setValue:@"default" forKey:@"name"];
        [customerObj setValue:nil forKey:@"id"];
        [curCustomerNameIDList addObject:customerObj];
    }
    else {
        //  if ([user.customerNameIDList count] > 0)
        //   {
        [[NSUserDefaults standardUserDefaults] setObject:user.customerNameIDList forKey:@"customerNameIDList"];
        
    //    [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
        
        
        //  }
    }
    [self enableView:YES];
    //if we have more than 1 customer check to see if the subscription is expired if it is then block them
   /* if (customers.count > 1)
    {
        if ((![CommonLib onFreePlan]) && (![NSNumber isNilOrNull:user.subscription_IsValid]) && ([user.subscription_IsValid intValue] != 0))
        {
  //      if ((![CommonLib onFreePlan]) && [[EZPurchaseManager sharedInstance] isNotExpired]) {
            [self enableView:YES];
        } else {
            [self enableView:NO];
        }
    }
*/
    //if there is only one customer do not show the edit button just show the add to prevent them from deleting the default customer
    if ([curCustomerNameIDList count] == 1)
        [self __setAddButtonOnly];
    [_customersListTableView reloadData];
}

-(void) getAllCustomers
{
    [self fetchAllCustomers];
}

- (IBAction)nameTextField:(id)sender {
}

- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
    
}

- (IBAction)onAddClick:(id)sender {

    
    //check to see if they renamed the deault customer because we need them to do that so it will create a customer Id for it before adding new ones
    NSDictionary *customerObj = [curCustomerNameIDList objectAtIndex:0];
    NSString* customerName = [customerObj valueForKey:@"name"];
    if ([NSString isEquals:customerName dest:@"default"])
     [SharedUICode messageBox:@"Alert" message:@"Please assign a name to the default customer before adding a new one. Tap the default customer, change the name and then press save." withCompletion:^{
     return;
     }];
     
     else
     {
   //      if ((![CommonLib onFreePlan]) && ([[EZPurchaseManager sharedInstance] isNotExpired])) {
         UserClass *user = [UserClass getInstance];
         if (1==1){
 //        if ((![NSNumber isNilOrNull:user.subscription_IsValid]) && ([user.subscription_IsValid intValue] != 0)){

             customerDetailViewConroller = [self.storyboard instantiateViewControllerWithIdentifier:@"CustomerDetails"];
             customerDetailViewConroller.delegate = (id) self;
        
             [self.navigationController pushViewController:customerDetailViewConroller animated:YES];
     
         } else {
             [SharedUICode messageBox:@"Alert" message:@"Please purchase a subscription to add more customers" withCompletion:^{
                 return;
             }];
         }
     }
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
    
    _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddClick:)];
    
    _editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditClick:)];
    // self.navigationItem.rightBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_editButton, _addButton, nil];
    
    if ([curCustomerNameIDList count] > 1)
    {
    
      //  if ((![CommonLib onFreePlan]) && ([[EZPurchaseManager sharedInstance] isNotExpired])) {
        UserClass *user = [UserClass getInstance];
   //     BOOL isOnFreePlan = [CommonLib onFreePlan];
        if ( (![CommonLib onFreePlan]) && (![NSNumber isNilOrNull:user.subscription_IsValid]) && ([user.subscription_IsValid intValue] != 0)) {
            [self enableView:YES];
            _editButton.enabled = YES;
            _addButton.enabled = YES;
        } else {
            [self enableView:NO];
            _editButton.enabled = NO;
            _addButton.enabled = NO;
        }
    }
    else
    {
        _editButton.enabled = NO;
    }
    
}

- (void)__setAddButtonOnly {
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:UIBarButtonItemStylePlain target:self action:@selector(revealMenu:)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddClick:)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: addButton, nil];
    
    if ([curCustomerNameIDList count] > 1)
    {
      //  if ([[EZPurchaseManager sharedInstance] isNotExpired]) {
            //            [self enableView:YES];
        UserClass *user = [UserClass getInstance];
        if ((![NSNumber isNilOrNull:user.subscription_IsValid]) && ([user.subscription_IsValid intValue] != 0)){
            addButton.enabled = YES;
        } else {
            //            [self enableView:NO];
            addButton.enabled = NO;
        }
    }
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
    
    [self setEditing:YES animated:YES];
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelClick:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItems = nil;
}


- (IBAction)onEditClick:(id)sender {
    [self setEditState];
}

- (void)CustomerDetailsDidFinish:(CustomerDetailsViewController *)controller CancelWasSelected:(bool)cancelWasSelected;
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self getAllCustomers];
}

- (void)deleteCustomerAtIndexPath:(NSIndexPath*)indexPath {
    NSMutableDictionary *customer =  [curCustomerNameIDList objectAtIndex:indexPath.row];
    NSNumber *customerId = [customer valueForKey:@"id"];
    [_customersListTableView setEditing:NO animated: YES];
    [self onCancelClick:self];
    //    editFlag = NO;
    //    [self callDeleteLocation: locID];
    
    [self startSpinnerWithMessage:@"Deleting, please wait..."];
    
    [CustomerWebservice callDeleteSelectedCustomer:customerId withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        else{
            [curCustomerNameIDList removeObjectAtIndex:indexPath.row];
            // Delete the row from the data source
            [_customersListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self __setEditButtons];
        }
    }];
    
}

//MARK:- Subscription Valid or Not

//this is a call back from the subscription license check webservice
- (void)subscriptionValid{
    //    [self enableView:YES];
}


- (void)subscriptionNotValid{
    //    [self enableView:NO];
}

- (void) enableView: (BOOL) isEnable {

    //don't let them delete the last customer
    if ([curCustomerNameIDList count] == 1)
        _editButton.enabled = NO;
    else
       _editButton.enabled = isEnable;
    
    _addButton.enabled = isEnable;

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

- (void) showDemoVideoAlert {
    if ([curCustomerNameIDList count] > 1) {
        return;
    }
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    bool isUserPressedNo = [userDefault valueForKey:@"isPersonalCustomerVideoShouldShowPressedNo"];
    if (isUserPressedNo) {
        return;
    }
    if (!self.isAlertShown) {
        self.isAlertShown = YES;
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                       message:@"Would you like to watch a demo video of how the Customers feature works?"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
            [[AVAudioSession sharedInstance]
             setCategory: AVAudioSessionCategoryPlayback
             error: nil];
            /*NSURL* vedioURL = [[NSBundle mainBundle] URLForResource:@"Personal_Customers" withExtension:@"mp4"];
            AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:vedioURL];
            AVPlayer* playVideo = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            self.playerViewController = [[AVPlayerViewController alloc] init];
            self.playerViewController.player = playVideo;
            self.playerViewController.view.frame = self.view.bounds;
            [self presentViewController:self.playerViewController animated:YES completion:^{
            }];
            //[self.view addSubview:self.playerViewController.view];
            [playVideo play];*/
            
            NSURL* videoURL = [[NSBundle mainBundle] URLForResource:@"Personal_Customers" withExtension:@"html"];
            UINavigationController* navController = [WebViewController getInstance];
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            WebViewController* webController = (WebViewController *)[navController viewControllers].firstObject;
            webController.url = videoURL;
            [self presentViewController:navController animated:YES completion:nil];
        }];
        UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
            [userDefault setBool:YES forKey:@"isPersonalCustomerVideoShouldShowPressedNo"];
            [userDefault synchronize];
        }];
        
        [alert addAction:defaultAction];
        [alert addAction:noAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
