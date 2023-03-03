//
//  AppDelegate.m
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "user.h"
#import "SubscriptionWebService.h"
#import "CommonLib.h"
#import "SVProgressHUD.h"
#import "Mixpanel.h"
#import "LocationManager.h"
#import "PushNotificationManager.h"
#import "DataManager.h"
#import "Reachability.h"
#import "MetricsLogWebService.h"
#import "SharedUICode.h"
#import "NSString+Extensions.h"
#import "EZPurchaseManager.h"
#import "NSDate+Extensions.h"
#import "NSNumber+Extensions.h"
#ifndef PERSONAL_VERSION
#import <GooglePlaces/GooglePlaces.h>
#import "SVProgressHUD.h"
#import <Amplitude/Amplitude.h>

#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif

#endif



@implementation AppDelegate

@synthesize subscriptionWebService;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Override point for customization after application launch.
    //make all the navigation bars light blue from the header_background image
    UIImage *image = [UIImage imageNamed:@"header_background.jpg"];
    [[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    if (@available(iOS 15.0, *)) {
        [[UINavigationBar appearance] setScrollEdgeAppearance:[UINavigationBar appearance].standardAppearance];
        UINavigationBarAppearance* appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        //[[UINavigationBar appearance] setTitleTextAttributes:
            //[NSDictionary dictionaryWithObjectsAndKeys:
             //[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
        [appearance setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
        appearance.backgroundColor = [UIColor colorWithRed:82.0/255.0 green:157.0/255.0 blue:195.0/255.0 alpha:1.0];
        
        [UINavigationBar appearance].standardAppearance = appearance;
        [UINavigationBar appearance].scrollEdgeAppearance = appearance;
        
    }
    //make all bar buttons clear with no borders
    [[UIBarButtonItem appearance] setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    //   self.window.tintColor = [UIColor whiteColor];
    
    
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setRingThickness:5];
    [SVProgressHUD setFont:[UIFont boldSystemFontOfSize:16]];
    
 //   NSShadow *shadow = [[NSShadow alloc] init];
 //   shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
 //   shadow.shadowOffset = CGSizeMake(0.0, -1.0);
    //this is the one that sets the back button's to white
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    
    // Navigation bar buttons appearance
    
    
    [[UINavigationBar appearance]setShadowImage:[[UIImage alloc] init]];
    
    //Mixpanel setup
    
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    
    //CrashLytics & Firebase setup
    [FIRApp configure];
    // [Fabric with:@[[Crashlytics class]]];
    
    
    
#ifdef DEBUG
    //    [[UIApplication sharedApplication] performSelector:@selector(setApplicationBadgeString:) withObject:@"d"];
#endif
    
#ifndef PERSONAL_VERSION
    //Google Places (used for locations) setup
    // [GMSPlacesClient provideAPIKey:@"AIzaSyC1k7JYP-TUkpErVSFCzobaGvt57QfH1Co"];
    [GMSPlacesClient provideAPIKey:@"AIzaSyCl6yRlDKhSLfEZ23T0VXA8gD8UJXIKzBQ"];
    
    
    //This got moved to InitialSlidingViewController so we can call it only if we are an employer which we do not have that info here
    
    [[LocationManager defaultLocationManager] setDelegate:self];
    [[LocationManager defaultLocationManager] startTracking];
    
    UIPageControl *pageControl = [UIPageControl appearance];
    
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor orangeColor];
    pageControl.backgroundColor = [UIColor whiteColor];
    
#endif
    //no push notifications for ipad or personal app
#if !defined(PERSONAL_VERSION) && !defined(IPAD_VERSION)
    
    // Handle APN on Terminated state, app launched because of APN
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        PushNotificationManager* manager = [PushNotificationManager sharedManager];
        [manager addPushNotification:userInfo];
    }
//    NSUInteger types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
//    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
//
    UIApplication* app = [UIApplication sharedApplication];
//    [app registerUserNotificationSettings:notificationSettings];
    [app registerForRemoteNotifications];
    [self registerNotification];
    
#endif
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    [self getKeyboardHeight];
   
#if !defined(IPAD_VERSION) // If Not iPad
    [Amplitude instance].trackingSessionEvents = YES;
#ifndef PERSONAL_VERSION // for Personal App
    // Initialize SDK
    [[Amplitude instance] initializeApiKey:@"e156d1b3e7b304a2ed07fb6967522e95"];
#else // for business ios App
    [[Amplitude instance] initializeApiKey:@"f0584045f37fe4bd59a2eba8602f9a93"];
#endif
#endif
    return YES;
}



-(void)callcheckValidLicenseAndValidateReceiptOneTimeInDay {
    UserClass *user = [UserClass getInstance];
    NSString *providerPlan = user.subscription_planProvider;
    NSString *todayDate = [[NSDate date] toDefaultDateString];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setValue: todayDate forKey:@"todayDate"];

    SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
    [subscriptionWebService checkValidLicense];
    
#ifndef PERSONAL_VERSION

    //only check validateReceipt if the user is an employer
    if ([user.userType isEqualToString:@"employer"])
    {
        if ((![NSString isNilOrEmpty:providerPlan]) && ([providerPlan isEqualToString:@"APPLE_SUBSCRIPTION"]))
        {
            [[EZPurchaseManager sharedInstance] validateReceipt];
        }
    }
#else
    if ((![NSString isNilOrEmpty:providerPlan]) && ([providerPlan isEqualToString:@"APPLE_SUBSCRIPTION"]))
    {
        [[EZPurchaseManager sharedInstance] validateReceipt];
    }

#endif
}



- (void)getKeyboardHeight {
    CGFloat height = 0.0;
    CGSize frame = UIScreen.mainScreen.bounds.size;
    if (frame.height == 480) {
        // 4, 4s
        height = 253;
    }
    else if (frame.height == 568) {
        // 5, SE
        height = 253;
    }
    else if (frame.height == 667) {
        height = 260;
        //7 , 8
    }
    else if (frame.height == 736) {
        //7 , 8 plus
        height = 271;
    }
    else if (frame.height == 812) {
        // x, xs
        height = 335;
    }
    else if (frame.height == 896) {
        // xs max, xr
        height = 346;
    } else {
        height = 260;
    }
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:height forKey:keyboardHeight];
    [defaults synchronize];
}


- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (![DataManager isClosed]) {
        self.isBackgroundFetching = YES;
        DataManager* manager = [DataManager sharedManager];
        [manager forceSyncWithCompletion:^(UIBackgroundFetchResult result, NSInteger errorCode, NSError* error) {
            //NOTE: No need to do this here the data manager will call if new data
            /*if (result == UIBackgroundFetchResultNewData) {
             [DataManager postNotifyTimeSheetMasterRefresh:TRUE];
             }*/
            if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL ||
                errorCode == SERVICE_ERRORCODE_SUCCESSFUL_NOTHING_TO_DO ||
                errorCode == DATAMANAGER_NO_PENDING_UPDATES ||
                errorCode == SERVICE_UNAVAILABLE_ERROR ||
                errorCode == DATAMANAGER_BUSY) {
                // no metrics
            } else if (nil != error) {
              //  [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:UNKNOWN_ERROR description:@"ERROR_FORCE_SYNC" error:error];
                
                NSString* msg = [NSString stringWithFormat:@"Error while Force Syncing in application:performFetchWithCompletion: - %@", error.localizedDescription];
                [MetricsLogWebService LogException: msg];
            } else {
                NSString* errorCodeMsg = [CommonLib errorMsg:errorCode];
                NSString* msg = [NSString stringWithFormat:@"errorCode %d (%@) was reported during forceSync in application:performFetchWithCompletion:", (int)errorCode, errorCodeMsg];
                [MetricsLogWebService LogException:msg];
            }
            completionHandler(result);
            self.isBackgroundFetching = NO;
            if(self.callForegroundFunction) {
                [self applicationWillEnterForeground:[UIApplication sharedApplication]];
            }
            return;
        }];
        return;
    } else {
#ifndef RELEASE
        NSLog(@"DataManager is closed meaning you have signed out!");
#endif
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

/*- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
 return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
 }
 */
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    //    if (!url) {  return NO; }
    
    //    NSString *URLString = [url absoluteString];
    //    [[NSUserDefaults standardUserDefaults] setObject:URLString forKey:@"url"];
    //    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    if (![DataManager isClosed]) {
        DataManager* manager = [DataManager sharedManager];
        [manager stopTimer];
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
#ifndef PERSONAL_VERSION
    [[LocationManager defaultLocationManager] stopTracking];
#endif
}
/*
- (id<ISpinner>)startSpinnerWithMessage:(NSString*)message {
    UIViewController* controller = [SharedUICode getRoot];
    id<ISpinner> spinner = nil;
    if (controller && [controller conformsToProtocol:@protocol(ISpinner)]) {
        spinner = (id <ISpinner>)controller;
        [spinner startSpinnerWithMessage:@"Syncing, please wait."];
    }
    return spinner;
}
*/
//In some situations when you bring the app to the foreground and it syncs offline time entries the spinner will lockup the app and never go away although the time entry has been synced. I'm taking out SVProgressHUD bc I'm not sure if that's what is causing it.
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if(self.isBackgroundFetching) {
        self.callForegroundFunction = YES;
        return;
    }
    self.callForegroundFunction = NO;
    if (![DataManager isClosed]) {
        DataManager* manager = [DataManager sharedManager];
        [SVProgressHUD showWithStatus:@"Syncing, please wait..."];
        [manager forceSyncWithCompletion:^(UIBackgroundFetchResult result, NSInteger errorCode, NSError* error) {
            //NOTE: No need to do this here the data manager will call if new data
            /*if (result == UIBackgroundFetchResultNewData) {
             DataManager postNotifyTimeSheetMasterRefresh:TRUE];
             }*/
            [SVProgressHUD dismiss];
            NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
            if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL ||
                errorCode == SERVICE_ERRORCODE_SUCCESSFUL_NOTHING_TO_DO ||
                errorCode == DATAMANAGER_NO_PENDING_UPDATES) {

                [center postNotificationName:kCheckClockStatusNotification object:nil];
            } else if (nil != error) {
                if (!(errorCode == SERVICE_UNAVAILABLE_ERROR || errorCode == DATAMANAGER_BUSY)) {
                   // [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_UNAVAILABLE_ERROR description:@"SERVICE_UNAVAILABLE_ERROR" error:error];
                    NSString* msg = [NSString stringWithFormat:@"Error while Force Syncing in applicationWillEnterForeground - %@", error.localizedDescription];
                    [MetricsLogWebService LogException: msg];
                }
            } else {
                NSString* errorCodeMsg = [CommonLib errorMsg:errorCode];
                NSString* msg = [NSString stringWithFormat:@"errorCode %d (%@) was reported during forceSync in applicationWillEnterForeground", (int)errorCode, errorCodeMsg];
                [MetricsLogWebService LogException:msg];
            }
            // notify the MenuViewController in case you have it open when it gets here so it can reload the menu to show how many pending updates
            [center postNotificationName:kForceSyncCompleteInAppWillEnterForegroundNotification object:nil];
//
        }];
    } else {
#ifndef RELEASE
        NSLog(@"DataManager is closed meaning you have signed out!");
#endif
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
#ifndef PERSONAL_VERSION
    [[LocationManager defaultLocationManager] startTracking];
    
#endif
    
    NSString *date = [[NSUserDefaults standardUserDefaults] valueForKey:@"todayDate"];
    NSString *todayDate = [[NSDate date] toDefaultDateString];
    
    //if we are running the iPhone business app and the subscription plan they've used for their subscription is Apple then call validate receipt to call Apple which will then call our backend server to update the expiration date
    //we only want to call validate receipt every 24hrs
    UserClass *user = [UserClass getInstance];
 //   NSString *providerPlan = user.subscription_planProvider;
    //if we don't have the provider plan then call the subscription web service to get an update of all the license stuff
    
    //need to figure out what to do with the kiosk app for now if we are a business app check if we are an employer and we have not hijacked then call the once a day validate
#if !defined(PERSONAL_VERSION) && !defined(IPAD_VERSION)
    //only check license for employers
 //   if ([user.userType isEqualToString:@"employer"])
    if ([user.userType isEqualToString:@"employer"] || (CommonLib.userIsManager)) //(user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_MANAGER"])))
    {
        //skip if I've hijacked the account
        if ((![NSNumber isNilOrNull:user.realUserId]) && (![CommonLib isAdminAccount:user.realUserId]))
        {
        
            if ((date == nil) || (![date isEqualToString:todayDate]))
                [self callcheckValidLicenseAndValidateReceiptOneTimeInDay];
        }
    }
    //personal app
#elif !defined(IPAD_VERSION)
    NSString *providerPlan = user.subscription_planProvider;
            if ([NSString isNilOrEmpty:providerPlan])
            {
                    SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
                    [subscriptionWebService checkValidLicense];
            }
            else{
                //only call if we have an Apple subscription bc I tried to call all the time and it caused issus with the server. Also check the user to make sure it's not hijacked
                 if ((date == nil) || (![date isEqualToString:todayDate])) {
                        [self callcheckValidLicenseAndValidateReceiptOneTimeInDay];
                }
                    
            }
#endif
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    UserClass *user = [UserClass getInstance];
    
    //rating dialog settings
    int didUserGiveFeedback = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userGaveUsRatingFeedback"] intValue];
    
    user.userGaveUsRatingFeedback = [NSNumber numberWithInt:didUserGiveFeedback];
    
    int tmpValue = [[[NSUserDefaults standardUserDefaults] objectForKey:@"appLaunchCounter"] intValue];
    if (didUserGiveFeedback == 0)
    {
        
        tmpValue++;
        //go a head and save it back in after inc
        [[NSUserDefaults standardUserDefaults] setInteger:tmpValue forKey:@"appLaunchCounter"];
    }
    //this counter will tell us how many times we've launched the app and after a certain amount of times we'll prompt them
    user.appLaunchCounter = [NSNumber numberWithInt:tmpValue];
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#ifndef PERSONAL_VERSION

#pragma mark Location Services Lifecycle
-(void) locationError:(NSError *) error;
{
    bool bDisableDialog = [[NSUserDefaults standardUserDefaults] boolForKey:DISABLE_LOCATION_REMINDER_DIALOG_KEY];
    bool locationDialogOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"LocationDialogOpen"];
    
    //R.K.: for some reason this was true even though you accept the GPS location tracking
    if ((error) && (error.code == kCLErrorDenied) && (!bDisableDialog) && (!locationDialogOpen)) {
        //prompt user to renable location services
     //   UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Location Services" message:@"This app requires location services to be enabled. Pleases go to Settings App> Privacy > Location and switch ON location services for ezClocker." delegate:nil cancelButtonTitle:@"Do NOT Show Again" otherButtonTitles:@"OK", nil];
       // alert.delegate = self;
       // [alert show];
        
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"LocationDialogOpen"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
#endif

/*
#pragma mark Alert View Actions
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    bool bDisableDialog = (buttonIndex == 0); //set disable value
    //persist selection
    [[NSUserDefaults standardUserDefaults] setBool:bDisableDialog forKey:DISABLE_LOCATION_REMINDER_DIALOG_KEY];
    
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"LocationDialogOpen"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //   [[NSUserDefaults standardUserDefaults] synchronize];
}
 */

/*
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive) {
        [SharedUICode messageBox:@"Reminder" message:notification.alertBody withCompletion:^{
            return;
        }];
    }
} */


-(void)registerNotification {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"request authorization succeeded!");
//            [self showAlert];
        }
    }];
}

// MARK: - Schedule local notification
//-(void) schedule {
//    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
//    content.title = [NSString localizedUserNotificationStringForKey:@"Elon said:"
//                                                        arguments:nil];
//    content.body = [NSString localizedUserNotificationStringForKey:@"Hello Tom！Get up, let's play with Jerry!"
//                                                       arguments:nil];
//    content.sound = [UNNotificationSound defaultSound];
//
//    // Deliver the notification in five seconds.
//    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger
//                                                triggerWithTimeInterval:5.f
//                                                repeats:NO];
//    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"FiveSecond"
//                                                                        content:content
//                                                                        trigger:trigger];
//    /// 3. schedule localNotification
//    
//    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
//    center.delegate = self;
//    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
//        if (!error) {
//            NSLog(@"add NotificationRequest succeeded!");
//        }
//    }];
//}

// MARK:- Receive Notifications

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
        willPresentNotification:(UNNotification *)notification
        withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
 
//    [SharedUICode messageBox:@"Reminder" message:notification.alertBody withCompletion:^{
//        return;
//    }];
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
           didReceiveNotificationResponse:(UNNotificationResponse *)response
           withCompletionHandler:(void (^)(void))completionHandler {

    NSLog(@"User Info : %@",response.notification.request.content.userInfo);
     completionHandler();
}



- (NSString *)hexadecimalStringFromData:(NSData *)data
{
    NSUInteger dataLength = data.length;
    if (dataLength == 0) {
        return nil;
    }
    
    const unsigned char *dataBuffer = (const unsigned char *)data.bytes;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }
    return [hexString copy];
}

#ifndef PERSONAL_VERSION

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    
    //  NSString * token = [NSString trim:[NSString stringWithFormat:@"%@", deviceToken]];
    NSString * token = [self hexadecimalStringFromData:deviceToken];;
    token = [token cleanUpDeviceToken];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* oldToken = [defaults valueForKey:kApnTokenKey];
    [PushNotificationManager saveDeviceTokenAsString:token];
    BOOL sentKey = [defaults boolForKey:kApnTokenSentSucessfullyKey];
    if ((![oldToken isEqualToString:token]) || ([oldToken isEqualToString:token] && sentKey == NO)) {
        PushNotificationManager* manager = [PushNotificationManager sharedManager];
        manager.registering = FALSE;
        [defaults setBool:NO forKey:kApnTokenSentSucessfullyKey];
        [manager registerForPushNotification:^(BOOL successful, NSError *error) {
            
        }];
    }
    
    // Save the device token for now until we have logged in
    
    //    PushNotificationManager* manager = [PushNotificationManager sharedManager];
    //    [manager registerForPushNotification:^(BOOL successful, NSError *error) {
    
    //    }];
    
}
#endif

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
#ifndef RELEASE
    NSLog(@"Failed to get token, error: %@", error);
#endif
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)
userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    /*    if (application.applicationState == UIApplicationStateActive)
     {
     // Nothing to do if applicationState is Inactive, the iOS already displayed an alert view.
     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Did receive a Remote Notification" message:[NSString stringWithFormat:@"Your App name received this notification while it was running:\n%@",[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]]delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
     
     [alertView show];
     }
     */
    if (nil != userInfo) {
        PushNotificationManager* manager = [PushNotificationManager sharedManager];
        [manager addPushNotification:userInfo];
        completionHandler(UIBackgroundFetchResultNewData);
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

+ (AppDelegate *)sharedInstance
{
    static AppDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppDelegate alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
