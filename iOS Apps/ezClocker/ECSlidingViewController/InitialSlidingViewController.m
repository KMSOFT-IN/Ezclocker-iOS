//
//  InitialSlidingViewController.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/25/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import "InitialSlidingViewController.h"
#import "LoginViewController.h"
#import "SubscriptionViewController.h"
#import "CommonLib.h"
#import "user.h"
#import "PushNotificationManager.h"
#import "LocationEntityFields.h"
#import "SetupPersonalAccount.h"
#import "CreateEmployerAccountViewController.h"
#import "FirstTopViewController.h"
#import "TimeSheetDetailViewController.h"
#import "SharedUICode.h"
#import "DataManager.h"
#import "NSString+Extensions.h"
#import "EmployerStartScreenViewController.h"

@import Firebase;

@interface InitialSlidingViewController() <UITabBarControllerDelegate>

@end


@implementation InitialSlidingViewController

#ifdef IPAD_VERSION
BOOL showSignupWizard = false;
#endif

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    UIStoryboard *storyboard;
    
    //    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    //    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    //        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    //    }
    //#if !defined(PERSONAL_VERSION) && !defined(IPAD_VERSION)
#ifndef PERSONAL_VERSION
    wizardController = [storyboard instantiateViewControllerWithIdentifier:@"WizardViewController"];
    
    addPersonInitialNavController = [storyboard instantiateViewControllerWithIdentifier:@"AddPersonInitialNav"];
    addPersonIntitialController =  (AddPersonInitialViewController *) addPersonInitialNavController.topViewController ;
    addPersonIntitialController.delegate = (id) self;
    
  //  createController = [storyboard instantiateViewControllerWithIdentifier:@"CreateEmployerAccount"];
    createController = [storyboard instantiateViewControllerWithIdentifier:@"EmployerStartScreenViewController"];
 
    createController.delegate = (id) self;
    
    createControllerStep2 = [storyboard instantiateViewControllerWithIdentifier:@"CreateEmployerAccountStep2"];
    createControllerStep2.delegate = (id) self;
#ifdef IPAD_VERSION
    UIStoryboard *iPadStoryboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    loginController = [iPadStoryboard instantiateViewControllerWithIdentifier:@"Login_iPad"];
#else
    loginController = [storyboard instantiateViewControllerWithIdentifier:@"Login"];
#endif
    loginController.delegate = (id) self;
#endif
    
    
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder { 
    
}



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
#ifdef IPAD_VERSION
    if (showSignupWizard)
    {
        showSignupWizard = false;
        
        //        V2 = [[UIViewController alloc]init];
        //        [V2.view setBackgroundColor:[UIColor redColor]];
        //        [self.view setBackgroundColor:[UIColor yellowColor]];
        wizardController.view.bounds = self.view.bounds;
        [self.view addSubview:wizardController.view];
        
        //V2.view = wizardController;
        //        V2.modalPresentationStyle = UIModalPresentationFormSheet;
        //        V2.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        //        [self presentViewController:V2 animated:YES completion:nil];
        //         V2.view.superview.frame = CGRectMake(0, 0, 768, 1024); //it's important to do this after presentModalViewController
        //        V2.view.superview.center = self.view.center;
    }
#endif
}


- (void)viewDidLoad {
    [super viewDidLoad];
    //    if ([CommonLib DoWeHaveNetworkConnection]){
    //this will prevent the screens to overlap the navigation bar for iOS 7
    self.navigationController.navigationBar.translucent = NO;
    
    //tell the App Delegate to launch the main view controller
    AppDelegate *mainDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    if (mainDelegate.subscriptionWebService == nil)
        mainDelegate.subscriptionWebService = [[SubscriptionWebService alloc] init];
    
    mainDelegate.subscriptionWebService.delegate = (id) self;
    
    
    UIStoryboard *storyboard;
    
    //  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    // } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    //   storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    // }
    
    if (![self firstTimeinApp]){
        UserClass *user = [UserClass getInstance];
        //if we are in Team Mode (iPad)
        if([user.userType isEqualToString:TEAM_USER_TYPE])
        {
            UIStoryboard *iPadStoryboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
            
            self.topViewController = [iPadStoryboard instantiateViewControllerWithIdentifier:@"NavteamModeViewController"];
            
            TeamModeViewController* teamModeViewController =  (TeamModeViewController *) ((UINavigationController*) self.topViewController).topViewController ;
            //hook the delegate so when a user picks Admin Mode it will come back here to sign out
            teamModeViewController.delegate = (id) self;
        }

        else if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)) //((user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"])))
        {
            
            //if employer has no employees then show the initial screen for adding employees
            if ([user.employeeCount intValue] == 0)
                self.topViewController = addPersonInitialNavController;
            else
                self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
            
        }
        else {
#ifdef PERSONAL_VERSION
            UIViewController *newTopViewController;
            if ([user.customerNameIDList count] > 1)
            {
                newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavCustomers"];
            }
            else
            {
                //if we only have one customer then pick that
                if ([user.customerNameIDList count] == 1)
                {
                    NSDictionary *curCustomerObj = [user.customerNameIDList objectAtIndex:0];
                    
                    // NSNumber *tmpCurCustomerId = [curCustomerObj valueForKey:@"id"];
                    user.curCustomerId = [curCustomerObj valueForKey:@"id"];
                }
                newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
                //               if (bIsForceSync) {
                //                   [self forceSync:FALSE newTopViewController:newTopViewController];
                //                   return;
                //               }
            }
            
            self.topViewController = newTopViewController;
            //  [firstTop setDelegate:self];
#else
            
            FirstTopViewController* firstTop = [storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
            self.topViewController = firstTop;
            [firstTop setDelegate:self];
#endif
        }
    }
    else{
        //if we are running the personal app version
#ifdef PERSONAL_VERSION
        FirstTopViewController* firstTop = [storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
        
        self.topViewController = firstTop;
        
        [self startSpinnerWithMessage:@"Initializing..."];
        SetupPersonalAccount *personalAccount = [[SetupPersonalAccount alloc]init];
        personalAccount.delegate = (id) self;
        [firstTop setDelegate:self];
        [personalAccount setupIndivdualAccount];
        
        
#else
#ifdef IPAD_VERSION
        //use this flag to show the signup wizard dialog in the didAppear method
        showSignupWizard = true;
#else
        
        //turn off the top status bar
        shouldHideStatusBar = YES;
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
        
        self.topViewController = wizardController; //createController;
        
#endif
        wizardController.delegate = (id) self;
#endif
        
    }
    
    
    
}
- (void)gotoScheduleNotification:(NSNotification*)notification {
    UIStoryboard *storyboard;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
    UserClass* user = [UserClass getInstance];
    if (nil != user.userID) {
        FirstTopViewController* firstTop = [storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
        firstTop.gotoScheduleTab = TRUE;
        self.topViewController = firstTop;
        [firstTop setDelegate:self];
        
    } else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Notification" message:@"Please login and then go to the schedule" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:^{
            
        }];
    }
}
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    return TRUE;
}



- (BOOL)prefersStatusBarHidden {
    return shouldHideStatusBar;
}

- (void)viewDidUnload
{
    
    [super viewDidUnload];
}

- (void)CreateEmployerAccountViewControllerDidFinish:(LoginViewController *)controller
{
    UIStoryboard *storyboard;
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    UserClass *user = [UserClass getInstance];
    //if employer has no employees then show the initial screen for adding employees
    if ([user.employeeCount intValue] == 0)
        self.topViewController = addPersonInitialNavController;
    else
        self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
    
}

- (void) EmployerStartScreenSignupSelected: (EmployerStartScreenViewController*) controller
{
    self.topViewController = createControllerStep2;
}

- (void) EmployerStartScreenSignInSelected: (EmployerStartScreenViewController*) controller
{
    self.topViewController = loginController;
}


#ifndef PERSONAL_VERSION
- (void)CreateEmployerAccountStep2DidFinish:(CreateEmployerStep2ViewController *)controller
{
    shouldHideStatusBar = NO;
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    
    UIStoryboard *storyboard;
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    
    UserClass *user = [UserClass getInstance];
    //if employer has no employees then show the initial screen for adding employees
    if ([user.employeeCount intValue] == 0)
        self.topViewController = addPersonInitialNavController;
    else
        self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
    
}
//if the customer goes back from create account step2 back to step 1
- (void)createViewControllerFromStep2WasSelected:(CreateEmployerStep2ViewController *)controller
{
#ifdef IPAD_VERSION
    [createControllerStep2.view removeFromSuperview];
    V2.view.superview.frame = CGRectMake(0, 0, 200, 400);
    // V2.view.autoresizesSubviews = YES;
    createController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                              UIViewAutoresizingFlexibleHeight);
    createController.view.frame = CGRectMake(0, 0, V2.view.frame.size.width, V2.view.frame.size.height);
    
    [V2.view addSubview:createController.view];
    
#else
    self.topViewController = createController;
#endif
    
    
}

- (void)CreateEmployerWasSelected:(CreateEmployerStep2ViewController *)controller { 
    
}


//this gets called whent he customer presses the continue button from the create employer screen
- (void)CreateEmployerStep2WasSelected:(CreateEmployerAccountViewController *)controller
{
#ifdef IPAD_VERSION
    [createController.view removeFromSuperview];
    V2.view.superview.frame = CGRectMake(0, 0, 200, 400);
    // V2.view.autoresizesSubviews = YES;
    createControllerStep2.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                                   UIViewAutoresizingFlexibleHeight);
    createControllerStep2.view.frame = CGRectMake(0, 0, V2.view.frame.size.width, V2.view.frame.size.height);
    
    [V2.view addSubview:createControllerStep2.view];
    
#else
    self.topViewController = createControllerStep2;
#endif
    
    
}

#endif


//if the customer selected signin from the create view then it will come back here so we can switch views
- (void)loginViewControllerWasSelected:(CreateEmployerAccountViewController *)controller
{
#ifdef IPAD_VERSION
    [createController.view removeFromSuperview];
    V2.view.superview.frame = CGRectMake(0, 0, 200, 400);
    // V2.view.autoresizesSubviews = YES;
    loginController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                             UIViewAutoresizingFlexibleHeight);
    loginController.view.frame = CGRectMake(0, 0, V2.view.frame.size.width, V2.view.frame.size.height);
    
    [V2.view addSubview:loginController.view];
    
#else
    self.topViewController = loginController;
#endif
    
    
}

- (void)showConfirmationDlg:(CreateEmployerAccountViewController *)controller { 
    
}


//when the customer selects the last screen from the wizard show login
- (void)wizardViewControllerDidFinish:(CreateEmployerAccountViewController *)controller
{
    //if we are using the iPad then show only the login screen do not allow them to create an account
#ifdef IPAD_VERSION
    [wizardController.view removeFromSuperview];
    //    V2.view.superview.frame = CGRectMake(0, 0, 200, 400);
    //   // V2.view.autoresizesSubviews = YES;
    //    loginController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
    //                                              UIViewAutoresizingFlexibleHeight);
    //    loginController.view.frame = CGRectMake(0, 0, V2.view.frame.size.width, V2.view.frame.size.height);
    loginController.view.bounds = self.view.bounds;
    [self.view addSubview:loginController.view];
    //    [V2.view addSubview:loginController.view];
    
#else
    self.topViewController = createController;
#endif
}


//if the customer selected signup from the login view then it will come back here so we can switch views
- (void)createViewControllerWasSelected:(LoginViewController *)controller
{
#ifdef IPAD_VERSION
    [loginController.view removeFromSuperview];
    V2.view.superview.frame = CGRectMake(0, 0, 200, 400);
    // V2.view.autoresizesSubviews = YES;
    createController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                              UIViewAutoresizingFlexibleHeight);
    createController.view.frame = CGRectMake(0, 0, V2.view.frame.size.width, V2.view.frame.size.height);
    
    [V2.view addSubview:createController.view];
    
#else
    self.topViewController = createControllerStep2;
#endif
    
    
}


- (void)loginViewControllerDidFinish:(LoginViewController *)controller UserName:(NSString*) userName Password: (NSString *) userPassword
{
    shouldHideStatusBar = NO;
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    
    UserClass *user = [UserClass getInstance];
    UIStoryboard *storyboard;
    //   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    //    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    //        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    //    }
    
    
    if (([user.userType isEqualToString:@"employer"]) || (CommonLib.userIsManager)){ //((user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"]))) {
        //if we running the iPad target then remove the popup screen
#ifdef IPAD_VERSION
        // [controller.view removeFromSuperview];
        [controller dismissViewControllerAnimated:YES completion:nil];
        [self dismissViewControllerAnimated:NO completion:nil];
        
#endif
        self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
    }
    else {
        FirstTopViewController* firstTop = [storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
        self.topViewController = firstTop;
        [firstTop setDelegate:self];
        
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

//takes this out for now
- (void)subscriptionExpired{
    /*    SubscriptionViewController *subscriptionController = [self.storyboard instantiateViewControllerWithIdentifier:@"Subscription"];
     //hook the delegate so we know when the customer's subscription has passed. We'll get a call back with subscriptionCheckPassed delgate call
     subscriptionController.delegate = (id) self;
     
     self.topViewController = subscriptionController;
     */
    
}
- (void)subscriptionValid{
    
}

- (void)subscriptionNotValid{
    
}

- (void)subscriptionError { 
    
}


-(void) subscriptionCheckPassed{
    //all is good with the subscription so let them in the app. This gets passed from subscription view controller
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
    UserClass *user = [UserClass getInstance];
    //if employer has no employees then show the initial screen for adding employees
    if ([user.employeeCount intValue] == 0)
        self.topViewController = addPersonInitialNavController;
    else
        self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
    
    
}
- (void)RegisterationFinished{
    
    [self stopSpinner];
    /*   UIStoryboard *storyboard;
     if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
     storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
     } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
     storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
     }
     self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
     */
}

//if an error happened when we registered like connection failed or something
- (void)RegisterationFailed{
    [self stopSpinner];
}

- (void)setAppInstallDate {
    UserClass *user = [UserClass getInstance];
    user.appInstallDate = [NSDate date];
    //save
    [[NSUserDefaults standardUserDefaults] setObject:user.appInstallDate forKey:@"appInstallDate"];
    //  [[NSUserDefaults standardUserDefaults] synchronize]; //write out the
}

- (void) logUserToCrashlyticsKit: (UserClass*) currentUser{
    //    [CrashlyticsKit setUserIdentifier:[NSString stringWithFormat:@"12345"];
    //    [CrashlyticsKit setUserEmail:currentUser.userEmail];
    //    [CrashlyticsKit setUserName:@"Test User"];
    [[FIRCrashlytics crashlytics] setUserID:currentUser.userEmail];
}


-(BOOL)firstTimeinApp{
    // return true;
    
    BOOL firstTime = false;
    //    LoginViewController *loginController;
    //load up the user object with the user values that got saved when they logged in
    UserClass *user = [UserClass getInstance];
    
    
    user.userType = [[NSUserDefaults standardUserDefaults] stringForKey:@"userType"];
    
    NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userAuthorities"] mutableCopy];// [[NSUserDefaults standardUserDefaults] objectForKey: @"userAuthorities"];
    user.userAuthorities = array;
    
    
    int tmpValue = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"employerId"];
    
    user.employerID = [NSNumber numberWithInt:tmpValue];
    
    tmpValue = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"employeeId"];
    user.userID = [NSNumber numberWithInt:tmpValue];
    
    tmpValue = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"userId"];
    user.realUserId = [NSNumber numberWithInt:tmpValue];
    
    
    if ([user.userID intValue] == 0)
    {
        firstTime = true;
        user.employeeCount = [NSNumber numberWithInt:0];
        //record the install date so we can use it for review app trigger
        [self setAppInstallDate];
    }
    else{
        //this got added because employeeCount was added after people had ezClocker installed
        //employeeCount is used to display the initial add person screen but if we know this is not their first time in the app then don't show it
        user.employeeCount = [[NSUserDefaults standardUserDefaults] objectForKey:@"employeeCount"];
        if (user.employeeCount == 0)
            //count 1 is not the correct number but init it with a 1 then employee list screen will get the correct value when it loads.
            user.employeeCount = [NSNumber numberWithInt:1];;
        
    }
    
    
    //*************************************************************************************************************************
    // shouldn't set this here it should start off as nil so that it uses the most recent from the database
    // if check clock status doesn't return anything.  Also when we refresh from timesheet master it will clear this as well
    // so we use the most recent from the database after it refreshes from the server.
    //user.activeTimeEntryId = [[NSUserDefaults standardUserDefaults] objectForKey:@"activeTimeEntryId"];
    
    user.lastEmailToSent = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastEmailToSent"];
    
    user.payrollStartDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"payrollStartDate"];
    user.payrollEndDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"payrollEndDate"];
    
    user.disableTimeEntryEditing = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"disableTimeEntryEditing"];
    
    user.requireLocationForClockInOut = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"requireLocationForClockInOut"];
    
    user.showTotalPay = false;
    
#ifdef PERSONAL_VERSION
    user.individualHourlyPayRate = [[NSUserDefaults standardUserDefaults] doubleForKey:@"individualHourlyPayRate"];
    if (user.individualHourlyPayRate > 0)
        user.showTotalPay = true;
    
    NSMutableArray *savedCustomers = [[NSMutableArray alloc] initWithArray: [[NSUserDefaults standardUserDefaults] objectForKey:@"customerNameIDList"]];
    if ((savedCustomers) && ([savedCustomers count] > 0)) {
        user.customerNameIDList = savedCustomers;
    }
#endif
    
    NSMutableArray *savedJobCodes = [[NSMutableArray alloc] initWithArray: [[NSUserDefaults standardUserDefaults] objectForKey:@"jobCodesList"]];
    if (savedJobCodes) {
        user.jobCodesList = savedJobCodes;
    }
    int tmpClockMode = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"clockMode"];
    user.currentClockMode = tmpClockMode;
    NSString *strValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"];
    user.authToken = strValue;
    user.employerName = [[NSUserDefaults standardUserDefaults] stringForKey:@"name"];
    
    //if we are a employee login
    if (![user.userType isEqualToString:@"employer"])
    {
        user.employeeName = [[NSUserDefaults standardUserDefaults] stringForKey:@"employeeName"];
        if ([NSString isNilOrEmpty:user.employeeName])
            user.employeeName = @"";
    }
    
    NSString *strClockTime = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastClockIn"];
    if (strClockTime == nil) {
        strClockTime = @"";
    }
    
    user.userPin = [[NSUserDefaults standardUserDefaults] stringForKey:@"Passcode"];
    if (user.userPin == nil) {
        user.userPin = @"";
    }
    
    user.lastClockIn = strClockTime;
    strClockTime = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastClockOut"];
    if (strClockTime == nil) {
        strClockTime = @"";
    }
    user.lastClockOut = strClockTime;
    
    user.userEmail = [[NSUserDefaults standardUserDefaults] stringForKey:@"userEmail"];
    if (user.userEmail == nil) {
        user.userEmail = @"";
    }
    user.appInstallDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"appInstallDate"];
    
    if (nil == user.appInstallDate) {
        [self setAppInstallDate];
    }
    
    user.userGaveUsRatingFeedback = [[NSUserDefaults standardUserDefaults] objectForKey:@"userGaveUsRatingFeedback"];
    
#ifdef PERSONAL_VERSION
    user.indivdualName = [[NSUserDefaults standardUserDefaults] stringForKey: @"UserName"];
    user.hasAccount = [[NSUserDefaults standardUserDefaults] stringForKey: @"HasAccount"];
    user.individualGeneratedPassword = [[NSUserDefaults standardUserDefaults] stringForKey: @"generatedUserPassword"];
    user.clockInReminders = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"ClockInReminders" ] mutableCopy];
    user.clockOutReminders = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"ClockOutReminders" ] mutableCopy];
    if (user.clockInReminders == nil)
        user.clockInReminders = [[NSMutableArray alloc] init];
    if (user.clockOutReminders == nil)
        user.clockOutReminders = [[NSMutableArray alloc] init];
    
    if (([user.clockInReminders count] > 0) || ([user.clockOutReminders count] > 0))
        user.remindersSet = YES;
    else
        user.remindersSet = NO;
    
    
#else
    if (firstTime){
        //default to free when its the first time using the app but most likely we'll be calling the server to figure out if they have a subscription with us
        user.subscription_freePlanActive = YES;
        
    }
    else{
        user.subscription_freePlanActive = [[NSUserDefaults standardUserDefaults] boolForKey: @"subscription_freePlanActive"];
        user.subscription_HasActivePaidPlan = [[NSUserDefaults standardUserDefaults] boolForKey: @"subscription_HasActivePaidPlan"];
    }
    user.subscription_PlanPrice = [[NSUserDefaults standardUserDefaults] stringForKey: @"subscription_PlanPrice"];
    user.subscription_planStartDate = [[NSUserDefaults standardUserDefaults] stringForKey: @"subscription_planStartDate"];
    user.subscription_PlanExpireDate = [[NSUserDefaults standardUserDefaults] stringForKey: @"subscription_PlanExpireDate"];
    
    user.subscription_planProvider = [[NSUserDefaults standardUserDefaults] stringForKey: @"subscription_planProvider"];
    
    user.subscription_IsValid = [[NSUserDefaults standardUserDefaults] valueForKey: @"subscription_IsValid"];
    
    user.subscription_enabledFeatures = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey: @"subscription_enabledFeatures"];
    
#endif
    //   user.timeHistory = [[NSMutableDictionary alloc] initWithObjects:nil forKeys:nil];
    
    
    // user.employerID = [NSNumber numberWithInt:46];
    // user.userID = [NSNumber numberWithInt:46];
    // user.authToken = @"553eb78b-f57f-4a95-9702-4dd011a2d898";
    
    //location persistence - load previous values
    user.employerLocation.name = [[NSUserDefaults standardUserDefaults] stringForKey:LOCATION_NAME];
    user.employerLocation.employerID = [NSNumber numberWithInteger:[[NSUserDefaults standardUserDefaults] integerForKey:EMPLOYER_ID]];
    double lat = [[[NSUserDefaults standardUserDefaults] stringForKey:GPS_LATITUDE] doubleValue];
    double lon = [[[NSUserDefaults standardUserDefaults] stringForKey:GPS_LONGITUDE] doubleValue];
    user.employerLocation.location = CLLocationCoordinate2DMake(lat, lon);
    
    [self logUserToCrashlyticsKit: user];
    
    return firstTime;
    
}

- (void)newEmployeeAdded:(AddPersonInitialViewController *)controller
{
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
        self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
        
    }
    
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
    [defaults setFloat:kbHeight forKey:keyboardHeight];
    [defaults synchronize];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    
#ifdef IPAD_VERSION
    UIStoryboard *iPadStoryboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    loginController = [iPadStoryboard instantiateViewControllerWithIdentifier:@"Login_iPad"];
    
#else
    
    LoginViewController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"Login"];
#endif
    
    loginController.delegate = (id) self;
    
#ifdef IPAD_VERSION
    
    
    //  V2 = [[UIViewController alloc]init];
    
    //for the iPAD version we don't want users to signup
    loginController.signinOnly = YES;
    
    loginController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                             UIViewAutoresizingFlexibleHeight);
    // loginController.view.frame = CGRectMake(0, 0, V2.view.frame.size.width, V2.view.frame.size.height);
    
    
    //  [V2.view addSubview:loginController.view];
    //V2.view = wizardController;
    loginController.modalPresentationStyle = UIModalPresentationFormSheet;
    loginController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:loginController animated:YES completion:nil];
    // loginController.view.frame = CGRectMake(0, 0, 200, 400); //it's important to do this after presentModalViewController
    loginController.view.superview.center = self.view.center;
    
#else
    self.topViewController = loginController;
#endif
    //   [self loadNewTopViewController:loginController];
}

- (void)adminModeWasSelected:(TeamModeViewController *)controller;
{
    //since we know only the iPad version has the Team Mode/Admin Mode just go stright to the employer dashboard
    shouldHideStatusBar = NO;
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    
    UIStoryboard *storyboard;
    
    storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    
    self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationTop"];
    
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection { 
    
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container { 
    
}

- (CGSize)sizeForChildContentContainer:(nonnull id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize { 
    // NSLog(@"Container view controllers use this method to return the sizes for their child view controllers.");
    return CGSizeZero;
}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container { 
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator { 
    
}

- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator { 
    
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator { 
    
}

- (void)setNeedsFocusUpdate { 
    
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context { 
    //     NSLog(@"Returns a Boolean value indicating whether the focus engine should allow the focus update described by the specified context to occur.");
    return FALSE;
}

- (void)updateFocusIfNeeded { 
    
}

@end
