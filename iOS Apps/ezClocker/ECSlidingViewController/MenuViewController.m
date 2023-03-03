//
//  MenuViewController.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import "MenuViewController.h"
#import "user.h"
#import "LoginViewController.h"
#import "CommonLib.h"
#import "EmailFeedbackViewController.h"
#import "LoginPersonalViewController.h"
#import "ViewAccountViewController.h"
#import "DataManager.h"
#import "SharedUICode.h"
#import "AddPersonInitialViewController.h"
#import "reachability.h"
#import "MetricsLogWebService.h"
#import "PushNotificationManager.h"
#import "NSString+Extensions.h"
#import "TeamModeViewController.h"



@interface MenuViewController()
@property (nonatomic, strong) NSArray *menuItems;
@end

@implementation MenuViewController
@synthesize menuItems;
@synthesize NameLabel;
@synthesize MenuTableView;


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.slidingViewController setAnchorRightRevealAmount:250.0f];
  self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(refreshData:) name:kForceSyncCompleteInAppWillEnterForegroundNotification object:nil];
}

- (void)refreshData:(NSNotification*)notification {
    [self.MenuTableView reloadData];
}


-(void) viewWillAppear:(BOOL)animated{
    UserClass *user = [UserClass getInstance];
#ifdef PERSONAL_VERSION
    self.menuItems = [NSArray arrayWithObjects:@"Home", @"Customers", @"Job List", @"Subscription", @"Send Us Feedback", @"Settings", @"Force Sync", @"Account", nil];
      //  self.menuItems = [NSArray arrayWithObjects:@"Home", @"Send Us Feedback", @"Settings", @"Force Sync", @"Account", nil];
#elif defined IPAD_VERSION
    self.menuItems = [NSArray arrayWithObjects:@"Dashboard", @"Send Us Feedback", @"Employees", @"Schedules", @"Locations", @"Job List", @"Team Mode", @"Force Sync", @"Settings", @"Sign Out", nil];
    //self.menuItems = [NSArray arrayWithObjects:@"Home", @"Send Us Feedback", @"Employees", @"Schedules", @"Locations", @"Job List", @"Team Mode", @"Force Sync", @"Settings", @"Sign Out", nil];
#else
//    UserClass *user = [UserClass getInstance];
  //  if ([user.userType isEqualToString:@"employer"])
    if ([user.userType isEqualToString:@"employer"])
      self.menuItems = [NSArray arrayWithObjects:@"Dashboard", @"Send Us Feedback", @"Employees", @"Schedules", @"Locations", @"Job List", @"Time off", @"Subscription", @"Force Sync", @"Settings", @"Sign Out", nil];
    //for managers don't show them the subscription manu option
    else if (CommonLib.userIsManager) //(user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"]))
        self.menuItems = [NSArray arrayWithObjects:@"Dashboard", @"Send Us Feedback", @"Employees", @"Schedules", @"Locations", @"Job List", @"Time off", @"Force Sync", @"Settings", @"Sign Out", nil];
    else
        self.menuItems = [NSArray arrayWithObjects:@"Home", @"Send Us Feedback", @"Time off", @"Force Sync", @"Sign Out", nil];
#endif

    if ([user.employerName length] != 0)
    {
        NameLabel.text = [[NSString alloc] initWithString:user.employerName];
//        NameLabel.minimumFontSize = 16.0;
        NameLabel.adjustsFontSizeToFitWidth=YES;
//        NameLabel.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:(16.0)];

    }
    UIColor *orangeLightOp = UIColorFromRGB(GRAY_BACKGROUND_DARK_COLOR);
    self.view.backgroundColor = orangeLightOp;
    MenuTableView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_DARK_COLOR);
  //  MenuTableView.separatorColor = [UIColor whiteColor];

    [MenuTableView reloadData];
    

}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Actions";
    
}

//because we are overridng the color of the section header we'll also need to set the Header text
//because by using this method it will override whatever is in titleForHeaderInSection method
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *tempView=[[UIView alloc]initWithFrame:CGRectMake(0,200,300,244)];
    tempView.backgroundColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR);
    UILabel *tempLabel=[[UILabel alloc]initWithFrame:CGRectMake(15,0,300,22)];
    tempLabel.backgroundColor=[UIColor clearColor];
    tempLabel.textColor = [UIColor whiteColor];
    tempLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0f];
    tempLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    tempLabel.text =  @"Operations";
    
    
    [tempView addSubview:tempLabel];
    
    return tempView;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
  return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *cellIdentifier = @"MenuItemCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
  }
  
  cell.textLabel.font = [UIFont systemFontOfSize:14.0];
  cell.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_DARK_COLOR);
  cell.contentView.backgroundColor = [UIColor clearColor];
  cell.textLabel.text = [self.menuItems objectAtIndex:indexPath.row];
    if ([cell.textLabel.text isEqualToString:@"Home"] || [cell.textLabel.text isEqualToString:@"Dashboard"])
    {
//    if (indexPath.row == HOME_ROW){
//        cell.imageView.image = [UIImage imageNamed:@"home2"];
        cell.imageView.image = [UIImage imageNamed:@"home_24x24"];
        
    }
    else if ([cell.textLabel.text isEqualToString:@"Force Sync"])
    {
   // else if (indexPath.row == FORCE_SYNC_ROW) {
        DataManager* manager = [DataManager sharedManager];
        NSError* error = nil;
        if (nil == manager.employee) {
            cell.textLabel.text = @"Force Sync - Employee Not Selected";
        } else {
            NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&error];
            if (nil != error) {
                cell.textLabel.text = @"Force Sync - Error";
            } else {
                if (count > 0) {
                    cell.textLabel.text = [NSString stringWithFormat:@"Force Sync - %d pending update(s)", (int)count];
                } else {
                    cell.textLabel.text = @"Force Sync - No pending updates";
                }
            }
        }

        cell.imageView.image = [UIImage imageNamed:@"sync_24x24"];
    } else if ([cell.textLabel.text isEqualToString:@"Send Us Feedback"])
        cell.imageView.image = [UIImage imageNamed:@"email_24x24"];
    //we only want to show the subscription/shopping_cart for employers
    else if ([cell.textLabel.text isEqualToString:@"Employees"])
        cell.imageView.image = [UIImage imageNamed:@"employee_24x24"];
    else if ([cell.textLabel.text isEqualToString:@"Subscription"])
        cell.imageView.image = [UIImage imageNamed:@"subscribe_24x24"];
    else if ([cell.textLabel.text isEqualToString:@"Schedules"])
        cell.imageView.image = [UIImage imageNamed:@"schedule_24x24"];
 
    else if ([cell.textLabel.text isEqualToString:@"Locations"])
        cell.imageView.image = [UIImage imageNamed:@"location_24x24"];
    else if ([cell.textLabel.text isEqualToString:@"Job List"])
            cell.imageView.image = [UIImage imageNamed:@"jobCode_24x24"];
    else if ([cell.textLabel.text isEqualToString:@"Time off"])
            cell.imageView.image = [UIImage imageNamed:@"airplane"];
    else if ([cell.textLabel.text isEqualToString:@"Customers"])
        cell.imageView.image = [UIImage imageNamed:@"employee_24x24"];
     else if ([cell.textLabel.text isEqualToString:@"Settings"])
        cell.imageView.image = [UIImage imageNamed:@"settings_24x24"];
    else if ([cell.textLabel.text isEqualToString:@"Team Mode"])
        cell.imageView.image = [UIImage imageNamed:@"team24X24"];
    else
        cell.imageView.image = [UIImage imageNamed:@"signOut_24x24"];
//#endif
    

  return cell;
}

- (void)signOutCompletely {
    [self startSpinnerWithMessage:@"Loging out..."];
    CGFloat kbHeight = [NSUserDefaults.standardUserDefaults floatForKey:keyboardHeight];
    
#ifndef PERSONAL_VERSION

    NSString* deviceToken = [PushNotificationManager getDeviceToken];
    if (![NSString isNilOrEmpty:deviceToken]) {
        [PushNotificationManager saveDeviceTokenAsString:deviceToken];
    }
#endif

    //delete all saved information
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
#ifndef PERSONAL_VERSION
    
    if (![NSString isNilOrEmpty:deviceToken]) {
        [PushNotificationManager saveDeviceTokenAsString:deviceToken];
    }
    deviceToken = [PushNotificationManager getDeviceToken];

#endif
    
    

    //clear out the singelton
    [UserClass releaseInstance];
    
    DataManager* manager = [DataManager sharedManager];
    NSError* error = nil;
    if (![manager clearAllData:&error]) {
#ifndef RELEASE
        NSLog(@"Error while deleting all employees on logout %@", error);
        [ErrorLogging logError:error];
#endif
    }
    [DataManager closeManager];
    
    [self stopSpinner];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

#ifndef PERSONAL_VERSION

    AppDelegate.sharedInstance.appToken = deviceToken;
    
    [defaults removeObjectForKey:kApnTokenKey];
    [defaults setBool:NO forKey:kApnTokenSentSucessfullyKey];
    
    PushNotificationManager* obj = [PushNotificationManager sharedManager];
    obj.registering = FALSE;
#endif
    

    [defaults setFloat:kbHeight forKey:keyboardHeight];
    [defaults synchronize];
    
#ifdef IPAD_VERSION
    UIStoryboard *iPadStoryboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    LoginViewController *loginController = [iPadStoryboard instantiateViewControllerWithIdentifier:@"Login_iPad"];
#else

    LoginViewController *loginController = [self.storyboard instantiateViewControllerWithIdentifier:@"Login"];
#endif
    
    loginController.delegate = (id) self;
    [self loadNewTopViewController:loginController];
}


- (void)loadNewTopViewController:(UIViewController*)newTopViewController {
#ifdef IPAD_VERSION
    if ([newTopViewController isKindOfClass:[LoginViewController class]])
    {
        
        UIViewController *blankView = [self.storyboard instantiateViewControllerWithIdentifier:@"blankViewController"];
        self.slidingViewController.topViewController = blankView;
        
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = blankView;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
        
        
        //for the iPAD version we don't want users to signup
        ((LoginViewController*) newTopViewController).signinOnly = YES;
        
        //        newTopViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
        //                                                 UIViewAutoresizingFlexibleHeight);
        // loginController.view.frame = CGRectMake(0, 0, V2.view.frame.size.width, V2.view.frame.size.height);
        
        
        //  [V2.view addSubview:loginController.view];
        //V2.view = wizardController;
        newTopViewController.view.bounds = self.view.bounds;
        //        newTopViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        //        newTopViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        //        newTopViewController.view.frame = CGRectMake(0, 0, 100, 50);
        [self presentViewController:newTopViewController animated:YES completion:nil];
        //         newTopViewController.view.frame = CGRectMake(0, 0, 100, 50); //it's important to do this after presentModalViewController
        //        newTopViewController.view.superview.center = self.view.center;
    }
    else
    {
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
    }
#else
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = newTopViewController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
    }];
#endif
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

   // NSString *identifier = [NSString stringWithFormat:@"%@Top", [self.menuItems objectAtIndex:indexPath.row]];
    UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor whiteColor];

    NSString *identifier = [self.menuItems objectAtIndex:indexPath.row];
    UIViewController *newTopViewController;
    if ([identifier isEqualToString:@"Send Us Feedback"])
    {
        EmailFeedbackViewController *emailFeedbackController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmailFeedback"];
        UINavigationController *navFeedback = [[UINavigationController alloc] initWithRootViewController:emailFeedbackController];
        newTopViewController = navFeedback;

//        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationFeedback"];
    }
    else
    {
        if ([identifier isEqualToString:@"Account"])
        {
#ifdef PERSONAL_VERSION
            UserClass *user = [UserClass getInstance];
            //figure out if the user already has an account or not
            if (![user.hasAccount isEqualToString:@"YES"]){
                CreatePersonalAccountViewController *createAccountController = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccount"];
            
            
                createAccountController.delegate = (id) self;

              UINavigationController *navCreateAccount = [[UINavigationController alloc] initWithRootViewController:createAccountController];

            
                newTopViewController = navCreateAccount;
            }
            else{
                UINavigationController *viewPersonalAccountNav = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationViewAccount"];
                
                
                ViewAccountViewController *viewPersonalAccountController = (ViewAccountViewController *)viewPersonalAccountNav.topViewController;
                
                viewPersonalAccountController.delegate = (id) self;
                
                newTopViewController = viewPersonalAccountNav;

  //              newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationViewAccount"];
                
            }
#endif

         }
        else if ([identifier isEqualToString:@"Reminders"])
            {
#ifdef PERSONAL_VERSION
                    newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"navReminders"];
                    
#endif
                
            }

        else{
            if ([identifier isEqualToString:@"Sign Out"])
            {
                DataManager* manager = [DataManager sharedManager];
                if ([manager isBusy]) {
                    [SharedUICode displayServerIsBusy];
                    return;
                }
                NSError* error = nil;
                [manager stopTimer];
                NSInteger count = [manager anyEmployeesNeedingSubmission:&error];
                if (nil != error) {
                    [SharedUICode messageBox:@"Error" message:[NSString stringWithFormat:@"There was an error while checking if any employees had pending updates - %@", error.localizedDescription]];
                    [ErrorLogging logError:error];
                    [manager startUpdateTimer];
                    return;
                }
                if (0 == count) {
                    [self signOutCompletely];
                    return;
                } else {
                    [SharedUICode yesNo:nil message:@"You have PENDING UPDATES to the server.  If you sign out now, you will lose ALL unsaved pending changes to the server.\n\nAre you absolutely sure?" yesBtnTitle:@"Yes - Please Sign Out" noBtnTitle:@"No - Do Nothing" withCompletion:^(YesNoCancelResult Result) {
                        switch (Result) {
                            case resultYes:{
                                [self signOutCompletely];
                                return;
                                break;
                            }
                            case resultNo:{
                                [manager startUpdateTimer];
                                return;
                            }
                            default:
                                break;
                        }
                        return;
                    }];
                    return;
                }

            }
            else {
                
                if ([identifier isEqualToString:@"Subscription"])
                {
#ifdef PERSONAL_VERSION
                    newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavPersonalSubscription"];
#else
                    newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavSubscriptionPlans"];
#endif
                }
                else

                {
                    if ([identifier isEqualToString:@"Schedules"])
                    {
                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavSchedule"];
                    }
                    else if ([identifier isEqualToString:@"Employees"])
                    {
                       // newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavEmployees"];
                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmployeesMgmtTabController"];
                        
                    }
                    else if ([identifier isEqualToString:@"Locations"])
                    {
                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavLocations"];
                        newTopViewController.title = @"Locations";
                    }
                    else if ([identifier isEqualToString:@"Job List"])
                    {
                       // newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavJobCodesList"];
                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JobslistTabController"];

                    }
                    else if ([identifier isEqualToString:@"Time off"])
                    {
                       // newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavJobCodesList"];
                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TimeOffTabController"];

                    }

                    else if ([identifier isEqualToString:@"Customers"])
                    {
                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavCustomersMgmt"];
                        
                    }

                    else if ([identifier isEqualToString:@"Settings"])
                    {
#ifdef PERSONAL_VERSION
                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavPersonalAppSettings"];
#else
                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavSettings"];
//                        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TestView"];
#endif
                    }
                    else if ([identifier isEqualToString:@"Team Mode"])
                    {
                        UIStoryboard *iPadStoryboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
                        newTopViewController = [iPadStoryboard instantiateViewControllerWithIdentifier:@"NavteamModeViewController"];
                        
                         TeamModeViewController* teamModeViewController =  (TeamModeViewController *) ((UINavigationController*) newTopViewController).topViewController ;
                        //hook the delegate so when a user picks Admin Mode it will come back here to sign out
                        teamModeViewController.delegate = (id) self;
                        
                        UserClass *user = [UserClass getInstance];
                        
                        user.userType = TEAM_USER_TYPE;
                        
                        //we only want to save user type in case the app crashes then we want it to open the TeamModeViewController screen
                        [[NSUserDefaults standardUserDefaults] setValue:user.userType forKey:@"userType"];
                        
                        [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data

                        
                    }
                    else{
                        BOOL bIsForceSync = ([identifier isEqualToString:@"Force Sync"]);
                        UserClass *user = [UserClass getInstance];
                       // if ([user.userType isEqualToString:@"employer"])
                        if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager))//(user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"])))
                        {
                            //if no employees then show the initial employee screen where they can add employees
                            if ([user.employeeCount intValue] == 0)
                            {
                                newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AddPersonInitialNav"];
                               AddPersonInitialViewController* addPersonIntitialController =  (AddPersonInitialViewController *) ((UINavigationController*) newTopViewController).topViewController ;
                                
                                addPersonIntitialController.delegate = (id) self;
                            }
                            else {
                                newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
                                if (bIsForceSync) {
                                    [self forceSync:TRUE newTopViewController:newTopViewController];
                                    return;
                                }
                            }

                        }
                        else {
#ifdef PERSONAL_VERSION
                            if ([user.customerNameIDList count] > 1)
                            {
                               newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavCustomers"];
                            }
                            else
                            {
                                if ([user.customerNameIDList count] == 1)
                                {
                                    NSDictionary *curCustomerObj = [user.customerNameIDList objectAtIndex:0];
                                
                                   // NSNumber *tmpCurCustomerId = [curCustomerObj valueForKey:@"id"];
                                    user.curCustomerId = [curCustomerObj valueForKey:@"id"];
                                }
                                newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
                                if (bIsForceSync) {
                                    [self forceSync:FALSE newTopViewController:newTopViewController];
                                    return;
                                }
                            }
#else
                            newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
                            if (bIsForceSync) {
                                [self forceSync:FALSE newTopViewController:newTopViewController];
                                return;
                            }
#endif
                        }
                    }

                }
            }
        }
      
    }
    [self loadNewTopViewController:newTopViewController];
}

/*- (void)forceSync:(BOOL)bIsEmployer {
    NSString* msg = bIsEmployer ? @"You must have an employee selected before you can force sync with the server." : @"You must be logged in order to force synce with the server.";
    if ([DataManager isClosed]) {
        [SharedUICode messageBox:@"Force Sync" message:msg];
        return;
    }
    DataManager* manager = [DataManager sharedManager];
    if (nil == manager.employee) {
        [SharedUICode messageBox:@"Force Sync" message:@"You must have an employee selected before you can force sync with the server."];
        return;
    }
    if ([manager isBusy]) {
        [SharedUICode messageBox:@"Busy" message:@"Already in the process of sending pending updates to the server."];
        return;
    }
    [self startSpinner];
    spinner.labelText = @"Syncing, please wait...";
    [manager forceSyncWithCompletion:^(UIBackgroundFetchResult result, NSError* error) {
        //NOTE: No need to do this here the data manager will call if new data

        [self stopSpinner];
        if (nil != error) {
            NSString* msg = [NSString stringWithFormat:@"Error while Force Syncing - %@", error.localizedDescription];
            [MetricsLogWebService LogException: msg];
            [SharedUICode messageBox:@"Force Sync Error" message:msg withCompletion:^{
                
            }];
        } else {
            [self.MenuTableView reloadData];
            NSError* _error = nil;
            NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&_error];
            if (nil != error) {
                NSString* msg = [NSString stringWithFormat:@"Error checking current employee pending updates - %@", error.localizedDescription];
                [MetricsLogWebService LogException: msg];
                [SharedUICode messageBox:@"Force Sync Error" message:msg withCompletion:^{
                    
                }];
                return;
            }
            if (count > 0) {
                NSString* msg = [NSString stringWithFormat:@"Force Sync still shows that you have %d pending updates.  Do you wish to try again?", (int)count];
                [SharedUICode yesNo:@"Pending Updates" message:msg yesBtnTitle:@"Yes - Please try again." noBtnTitle:@"No - I Will Retry Later" withCompletion:^(YesNoCancelResult Result) {
                    switch (Result) {
                        case resultYes:
                            [self forceSync:bIsEmployer];
                            break;
                        default:
                            break;
                    }
                }];
            } else {
                [SharedUICode messageBox:@"Force Sync" message:@"Force Sync was successful!" withCompletion:^{
                    [self.MenuTableView reloadData];
                }];
            }
        }
    }];
}
*/

- (void)forceSync:(BOOL)bIsEmployer newTopViewController:(UIViewController*)newTopViewController {
    NSAssert(nil != newTopViewController, @"newTopViewController cannot be nil");
    
    NSString* msg = bIsEmployer ? @"You must have an employee selected before you can force sync with the server." : @"You must be logged in order to force synce with the server.";
    if ([DataManager isClosed]) {
        [ErrorLogging logErrorWithDomain:@"FORCE_SYNC" code:UNKNOWN_ERROR description:@"ERROR_FORCE_SYNC" error:nil];
        [SharedUICode messageBox:@"Force Sync" message:msg];
        [self loadNewTopViewController:newTopViewController];
        return;
    }
    DataManager* manager = [DataManager sharedManager];
    if (nil == manager.employee) {
        [ErrorLogging logErrorWithDomain:@"FORCE_SYNC" code:UNKNOWN_ERROR description:@"ERROR_FORCE_SYNC" error:nil];
        [SharedUICode messageBox:@"Force Sync" message:@"You must have an employee selected before you can force sync with the server."];
        [self loadNewTopViewController:newTopViewController];
        return;
    }
    if ([manager isBusy]) {
        [SharedUICode messageBox:@"Busy" message:@"Already in the process of sending pending updates to the server."];
        [self loadNewTopViewController:newTopViewController];
        return;
    }
    NSError* error = nil;
    NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&error];
    if (nil != error) {
        [ErrorLogging logError:error];
        NSString* msg = [NSString stringWithFormat:@"Error checking current employee pending updates - %@.\n\nPlease try again later.", error.localizedDescription];
        [MetricsLogWebService LogException: msg];
        [SharedUICode messageBox:@"Force Sync Error" message:msg withCompletion:^{
            [self loadNewTopViewController:newTopViewController];
            return;
        }];
        return;
    }
    if (0 == count) {
        [SharedUICode messageBox:@"" message:@"No pending updates exist." withCompletion:^{
            [self loadNewTopViewController:newTopViewController];
            return;
        }];
        return;
    }
    [self startSpinnerWithMessage:@"Syncing, please wait..."];
    [manager forceSyncWithCompletion:^(UIBackgroundFetchResult result, NSInteger errorCode, NSError* error) {
        //NOTE: No need to do this here the data manager will call if new data
        /*if (result == UIBackgroundFetchResultNewData) {
         [DataManager postNotifyTimeSheetMasterRefresh:TRUE];
         }*/
        [self stopSpinner];
        if (errorCode == SERVICE_UNAVAILABLE_ERROR) {
            [SharedUICode messageBox:@"" message:@"No internet connection detected.  Reconnect to the internet and try again." withCompletion:^{
                [self loadNewTopViewController:newTopViewController];
            }];
            return;
        }
        if (nil != error) {
            [ErrorLogging logError:error];
            [MetricsLogWebService LogException: msg];
            [SharedUICode messageBox:@"" message:error.localizedDescription withCompletion:^{
                [self loadNewTopViewController:newTopViewController];
            }];
            return;
        } else {
            [self.MenuTableView reloadData];
            NSError* _error = nil;
            NSInteger count = [manager doesCurrentEmployeeNeedingSubmission:&_error];
            if (nil != error) {
                NSString* msg = [NSString stringWithFormat:@"Error checking current employee pending updates - %@", error.localizedDescription];
                [MetricsLogWebService LogException: msg];
                [SharedUICode messageBox:@"Force Sync Error" message:msg withCompletion:^{
                    [self loadNewTopViewController:newTopViewController];
                }];
                return;
            }
            if (count > 0) {
                NSString* msg = [NSString stringWithFormat:@"Force Sync still shows that you have %d pending updates.  Do you wish to try again?", (int)count];
                [SharedUICode yesNo:@"Pending Updates" message:msg yesBtnTitle:@"Yes - Please try again." noBtnTitle:@"No - I Will Retry Later" withCompletion:^(YesNoCancelResult Result) {
                    switch (Result) {
                        case resultYes:
                            [self forceSync:bIsEmployer newTopViewController:newTopViewController];
                            break;
                        default: {
                            [self loadNewTopViewController:newTopViewController];
                            break;
                        }
                    }
                }];
            } else {
                [SharedUICode messageBox:@"Force Sync" message:@"Force Sync was successful!" withCompletion:^{
                    [self.MenuTableView reloadData];
                    [self loadNewTopViewController:newTopViewController];
                }];
            }
        }
    }];
}


- (void)createAccountViewControllerDidFinish:(CreatePersonalAccountViewController *)controller
{
    UIViewController *newTopViewController;
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
    
    UINavigationController *viewPersonalAccountNav = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationViewAccount"];
    
    
    ViewAccountViewController *viewPersonalAccountController = (ViewAccountViewController *)viewPersonalAccountNav.topViewController;
    
    viewPersonalAccountController.delegate = (id) self;
    
    newTopViewController = viewPersonalAccountNav;
    
 //   UINavigationController *navLoginPersonal = [[UINavigationController alloc] initWithRootViewController:viewPersonalAccountController];

    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = newTopViewController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
    }];
}
- (void)loginPersonalViewControllerDidFinished:(LoginPersonalViewController *)controller
{
    UIViewController *newTopViewController;
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
 //   newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationViewAccount"];
    
    UINavigationController *viewPersonalAccountNav = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationViewAccount"];
    
    
    ViewAccountViewController *viewPersonalAccountController = (ViewAccountViewController *)viewPersonalAccountNav.topViewController;
    
    viewPersonalAccountController.delegate = (id) self;
    
    newTopViewController = viewPersonalAccountNav;

    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = newTopViewController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
    }];
}

- (void)dealloc {
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}


- (void)loginViewControllerDidFinish:(LoginViewController *)controller UserName:(NSString*) userName Password: (NSString *) userPassword
{
    UserClass *user = [UserClass getInstance];
#ifdef IPAD_VERSION
   // [controller.view removeFromSuperview];
   // [self dismissViewControllerAnimated:NO completion:nil];
 //   AppDelegate.sharedInstance.isPortrait = NO;
    [controller dismissViewControllerAnimated:YES completion:nil];
#endif

    UIViewController *newTopViewController;
    UIStoryboard *storyboard;
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
   //  if ([user.userType isEqualToString:@"employer"])
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)) //((user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"])))
        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
    else
        newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = newTopViewController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
    }];
}
- (void)viewDidUnload {
    [self setNameLabel:nil];
    [self setMenuTableView:nil];
    [super viewDidUnload];
}

- (void)adminModeWasSelected:(TeamModeViewController *)controller;
{
    //[self signOutCompletely];
    //since we know only the iPad version has the Team Mode/Admin Mode just go stright to the employer dashboard
    //[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    
    UIStoryboard *storyboard;
    
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    
    self.slidingViewController.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];

}
- (void)loginViewControllerWasSelected:(CreateEmployerAccountViewController *)controller
{
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
#ifdef IPAD_VERSION
    UIStoryboard *iPadStoryboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    LoginViewController *loginController = [iPadStoryboard instantiateViewControllerWithIdentifier:@"Login_iPad"];

#else
    LoginViewController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"Login"];
#endif
    
    loginController.delegate = (id) self;
    
    self.slidingViewController.topViewController = loginController;
    
}
- (void)loginPersonalViewControllerWasSelected:(CreateEmployerAccountViewController *)controller
{
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
    
    LoginPersonalViewController *loginPersonalController = [storyboard instantiateViewControllerWithIdentifier:@"LoginPersonalView"];
    
    loginPersonalController.delegate = (id) self;
    
    UINavigationController *navLoginPersonal = [[UINavigationController alloc] initWithRootViewController:loginPersonalController];
    
    /*   [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
     CGRect frame = self.slidingViewController.topViewController.view.frame;
     self.slidingViewController.topViewController = newTopViewController;
     self.slidingViewController.topViewController.view.frame = frame;
     [self.slidingViewController resetTopView];
     
     }];
     */
    
    self.slidingViewController.topViewController = navLoginPersonal;
    
    
    
}
- (void)loginPersonalWasSelectedFromViewAccount:(ViewAccountViewController *)controller
{
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
    
    LoginPersonalViewController *loginPersonalController = [storyboard instantiateViewControllerWithIdentifier:@"LoginPersonalView"];
    
    loginPersonalController.delegate = (id) self;
    
    //since this came from a logout action from the view account screen don't show the don't have an account create one button
    loginPersonalController.hidAccountSetupButton = YES;
    
//    UINavigationController *navLoginPersonal = [[UINavigationController alloc] initWithRootViewController:loginPersonalController];
    
    /*   [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
     CGRect frame = self.slidingViewController.topViewController.view.frame;
     self.slidingViewController.topViewController = newTopViewController;
     self.slidingViewController.topViewController.view.frame = frame;
     [self.slidingViewController resetTopView];
     
     }];
     */
    
    self.slidingViewController.topViewController = loginPersonalController;
    
    
    
}
- (void)createPersonalViewControllerWasSelected:(LoginPersonalViewController *)controller
{
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
    
    CreatePersonalAccountViewController *createPersonalController = [storyboard instantiateViewControllerWithIdentifier:@"CreateAccount"];
    
    createPersonalController.delegate = (id) self;
    
    UINavigationController *navCreaePersonal = [[UINavigationController alloc] initWithRootViewController:createPersonalController];
    
   
    self.slidingViewController.topViewController = navCreaePersonal;
    
}

- (void)createViewControllerWasSelected:(LoginViewController *)controller
{
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }

    CreateEmployerAccountViewController *createController = [storyboard instantiateViewControllerWithIdentifier:@"CreateEmployerAccount"];
    createController.delegate = (id) self;

    self.slidingViewController.topViewController = createController;

}

- (void)newEmployeeAdded:(AddPersonInitialViewController *)controller
{
    UIViewController *newTopViewController;

    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
    
    UserClass *user = [UserClass getInstance];
    //if we added the first employee then switch the top view to employeelist instead of the initial add person view controller
    if ([user.employeeCount intValue] > 0)
    {
        newTopViewController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
        self.slidingViewController.topViewController = newTopViewController;

        
    }
    
}


@end
