//
//  EmployeeClockViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "EmployeeClockViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CommonLib.h"
#import "user.h"
#import "ECSlidingViewController.h"
#import "Mixpanel.h"
#import "CommonLib.h"
#import "MetricsLogWebService.h"
#import "CheckClockStatusWebService.h"
#import "ClockWebServices.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "debugdefines.h"
#import "DataManager.h"
#import "TimeEntry.h"
#import "TimeEntry+CoreDataProperties.h"
#import "TimeEntry+Extensions.h"
#import "ClockInfo.h"
#import "ClockInfo+CoreDataProperties.h"
#import "SharedUICode.h"
#import "coredatadefines.h"
#import "NSNumber+Extensions.h"
#import "MenuViewController.h"
#import "ClockInfo+Extensions.h"
#import <Crashlytics/Crashlytics.h>
#import "TimeSheetDetailViewController.h"
#import "EmailFeedbackViewController.h"
#import "AppStoreRatingWebService.h"
#import "CoreDataUtils.h"



@interface EmployeeClockViewController () <checkClockStatusWebServicesDelegate, TimeSheetDetailViewControllerDelegate>

@property (nonatomic, assign) bool bOverrideLocationCheck;
@property (nonatomic, assign) ClockMode lastClockMode;
@property (nonatomic, assign) NSDate *lastClockTime;
@property (nonatomic, retain) ClockWebServices* clockWebServices;
@property (nonatomic, copy) NSManagedObjectID* timeEntryObjectID;
@property (nonatomic, retain, readonly) TimeEntry* timeEntry;

@end

@implementation EmployeeClockViewController
//@synthesize lblDebug;
@synthesize clockInBtn;
@synthesize clockOutBtn;
@synthesize currentTimeLabel;
@synthesize TimeClockTableView;
//@synthesize myLocationManager;
@synthesize bOverrideLocationCheck, lastClockMode, lastClockTime;
@synthesize bannerView= _bannerView;
@synthesize admobBannerView = _admobBannerView;

bool isAccountCreatedPrompt = false;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.tabBarItem.image = [UIImage imageNamed:@"clock"];
        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        
        [center addObserver: self
                   selector: @selector(enteredBackground:)
                       name: @"didEnterBackground"
                     object: nil];
        [center addObserver: self
                   selector: @selector(enteredForeground:)
                       name: @"didEnterForeground"
                     object: nil];
        
        [center addObserver:self selector:@selector(dataManagerProcessCompleteNotification:) name:kDataManagerProcessCompleteNotification object:nil];

        self.title = NSLocalizedString(@"Clock in/out", @"Clock in/out");
        self.tabBarItem.image = [UIImage imageNamed:@"clock"];

        [self initialize];

    }

    
    //this contains the user data like employerId
//    user = [UserClass getInstance];
  
    return self;
}

- (void)dataManagerProcessCompleteNotification:(NSNotification*)notification {
    // This will be called when force sync as well as after an item is deleted for clock in/clock out because it already existed according to the server.
    // Just simply reloadData
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.TimeClockTableView reloadData];
    });

}


- (void)initialize {
    formatterISO8601DateTime = [[NSDateFormatter alloc] init];
    [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    formatterDateTime12hr = [[NSDateFormatter alloc] init];
    formatterTime = [[NSDateFormatter alloc] init];
    [formatterTime setDateFormat:@"h:mm:ss a"];
#ifndef PERSONAL_VERSION
    [formatterDateTime12hr setDateFormat:@"MM/dd/yyyy h:mm:ss a"];
#else
    [formatterDateTime12hr setDateFormat:@"MM/dd/yyyy h:mm a"];
#endif
    //[formatterDateTime setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:-18000]];
    
    //set time zones
    [formatterISO8601DateTime setTimeZone:[NSTimeZone localTimeZone]];
    [formatterDateTime12hr setTimeZone:[NSTimeZone localTimeZone]];
    [formatterTime setTimeZone:[NSTimeZone localTimeZone]];
    
    //color the buttons
    clockInBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    clockOutBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);

}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}



/*-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
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
    @try {
        UserClass *user = [UserClass getInstance];
//    [self.myWebView loadHTMLString:[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding] baseURL:nil];
    UIAlertView *alert;
    
//    if (currentDistanceinMiles > 100)
//    {
//        alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error: Your Current Location is no valid" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
 //       [alert show];
        
  //  }
    NSError *error = nil;
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
        

    NSString *resultMessage = [results valueForKey:@"message"];
    int errorValue = [[results valueForKey:@"errorCode"] intValue];
        
#ifndef PERSONAL_VERSION
    if (errorValue == WEB_SERVICE_OUT_OF_RANGE_ERROR) {
        //outside of clock in/out range  prompt for override
        [self promptForOverride:resultMessage];
        return;
    }
#endif

    //if message is null or <> Success then the call failed
    if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
        if ([resultMessage isEqual:[NSNull null]])
        {
            alert = [[UIAlertView alloc] initWithTitle:nil message:@"Time Entry from Server Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }

        else{
            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from EmployeeClockViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
            if (resultMessage.length > 0)
            {
                alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }

        }
        //if error code = 1 that means that person has already clocked in from the website so
        if (errorValue  == 1){
                [self enableButton:clockOutBtn];        
                [self disableButton:clockInBtn];
                user.currentClockMode = ClockModeOut;
                strLastClockInTime = @"";
        }
        //if error code = 2 that means that person has already clocked out from the website so    
        else if (errorValue  == 2){
                [self enableButton:clockInBtn];
                [self disableButton:clockOutBtn];        
                user.currentClockMode = ClockModeIn;
                strLastClockOutTime = @"";
            
        }

        
    }
    else {
        NSDictionary *timeEntry = [results valueForKey:@"timeEntry"];
        if ([timeEntry count] != 0)
        {
            //to figure out which JSON result this came from
            if (apiCallType == CheckActiveClock)
            {
                
                apiCallType = CheckTimeEntryByID;
                user.activeTimeEntryId = [timeEntry valueForKey:@"id"];
                if (user.currentClockMode == ClockModeIn)
                {
                    strLastClockInTime = [formatterDateTime12hr stringFromDate:lastClockInTime];
                    strLastClockOutTime = @"";
                    user.lastClockIn = strLastClockInTime;
                    user.lastClockOut = strLastClockOutTime;
                    //log to mixpanel if we are production
                    if ([CommonLib isProduction])
                    {
                        Mixpanel *mixpanel = [Mixpanel sharedInstance];
                        [mixpanel track:@"Employee Clockin" properties:@{ @"email": user.userEmail}];
                    }

                }
                else
                {
                    strLastClockOutTime = [formatterDateTime12hr stringFromDate:lastClockOutTime];
                    user.lastClockOut = strLastClockOutTime;
                }
                //[timeEntry valueForKey:@"clockInString"];
                //[timeEntry valueForKey:@"clockOutString"];
                [self updateUI];
            }
            else
            {
                [self stopSpinner];
                NSString *clockOutTime = [NSString stringWithFormat:@"%@",[timeEntry valueForKey:@"clockOutIso8601"]];
                clockOutTime  = [clockOutTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                NSDate *DateValue = [formatterISO8601DateTime dateFromString:clockOutTime];
                timeEntryNotes = [timeEntry valueForKey:@"notes"];
                strLastClockOutTime = [formatterDateTime12hr stringFromDate:DateValue];
                user.lastClockOut = strLastClockOutTime;
                [TimeClockTableView reloadData];

            }
        }
        
    }
    }//try
    @finally{
        self.bOverrideLocationCheck = NO;//reset
        [self stopSpinner];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self stopSpinner];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
    
    connection = nil;
    data = nil;
}

*/
- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self tick:nil];
}

-(NSDate*) getCurrentDateTime{
    return [NSDate date];
    //NSString *currentDateTime = [formatterDateTime stringFromDate:[NSDate date]];

    //return currentDateTime;
    
}

-(NSString*) getCurrentTime{
    NSString *currentDateTime = [formatterTime stringFromDate:[NSDate date]];
    return currentDateTime;
    
}

static BOOL checkingClockStatus = false;

#pragma mark - Check Clock Status
-(void) checkClockStatus:(BOOL)bAlreadyClockedInOut {
    //if we are the personal app then exit - only check clock status for the business app
    if (!bAlreadyClockedInOut) {
#ifdef PERSONAL_VERSION
        [self determineClockInOrClockOut:nil activeClockInFlag:false];
        return;
#endif
    }
    UserClass *user = [UserClass getInstance];
    //since this gets called everytime it comes to the foreground, in the situation where we've logged out and take it to the background then again to the foreground then this gets called and bombs out so check for user.UserID <> nil
    if (nil == user.userID)
    {
        return;
    }
    
    if (checkingClockStatus) { // prevent multiple calls to checkClockStatus being called within this view because checkClockStatus below is async
        return;
    }
#ifndef RELEASE
    NSLog(@"setting checkingClockStatus = TRUE");
#endif
    
    checkingClockStatus = TRUE;
    [self startSpinnerWithMessage:@"Connecting to Server.."];
    DataManager* manager = [DataManager sharedManager];
    while ([manager isBusy]) { // sanity!
        sleep(1);
    }
    DataManager* dataManager = [DataManager sharedManager];
    [dataManager checkAndLoadEmployeeInfo:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
        [manager checkClockStatus:user.userID withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
            [self stopSpinner];
            
            
            //if no error
            if (aErrorCode == SERVICE_ERRORCODE_SUCCESSFUL)
            {
                
                //NSDictionary *timeEntryRec = [aResults valueForKey:ktimeEntryKey];
                NSDictionary *timeEntryRec = [aResults valueForKey:@"clockInOutState"];
                if (nil != timeEntryRec) {
                    DEBUG_MSG
                    NSNumber *timeEntryId = [timeEntryRec valueForKey:@"id"];
                    NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);
                    user.activeTimeEntryId = timeEntryId;
                    
                    NSError* error = nil;
                    DataManager* dataManager = [DataManager sharedManager];
                    
                    TimeEntry* aTimeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];
                    [self determineClockInOrClockOut:aTimeEntry activeClockInFlag: true];
                    return;
                }
                
                if (user.activeTimeEntryId && [user.activeTimeEntryId integerValue] > 0) {
                    NSError* __error = nil;
                    TimeEntry* timeEntry = [manager fetchTimeEntryByID:user.activeTimeEntryId error:&__error];
                    BOOL bPendingUpdates = FALSE;
                    if (timeEntry && [timeEntry hasPendingUpdates]) {
                        bPendingUpdates = TRUE;
                    }
                    if (!bPendingUpdates) {
                        [manager callGetTimeEntryByIDWebService:user.activeTimeEntryId withCompletion:^(NSInteger bErrorCode, NSString * _Nullable bResultMessage, NSDictionary * _Nullable bResults, NSError * _Nullable bError) {
                            if (bErrorCode == SERVICE_ERRORCODE_SUCCESSFUL) {
                                NSDictionary* timeEntryRec = [bResults valueForKey:ktimeEntryKey];
                                if (nil != timeEntryRec) {
                                    DEBUG_MSG
                                    NSNumber* timeEntryId = [timeEntryRec valueForKey:@"id"];
                                    NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);
                                    user.activeTimeEntryId = timeEntryId;
                                    
                                    NSError* error = nil;
                                    DataManager* dataManager = [DataManager sharedManager];
                                    
                                    TimeEntry* aTimeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];
                                    [self determineClockInOrClockOut:aTimeEntry activeClockInFlag: false];
                                }
                            } else {
                                [self determineClockInOrClockOut:nil activeClockInFlag: false];
                            }
                            checkingClockStatus = FALSE;
#ifndef RELEASE
                            NSLog(@"setting checkingClockStatus = FALSE");
#endif
                            
                        }];
                        return;
                    } else {
                        [self determineClockInOrClockOut:timeEntry activeClockInFlag: false];
                    }
                } else {
                    [self determineClockInOrClockOut:nil activeClockInFlag:false];
                }
            } else {
                [self determineClockInOrClockOut:nil activeClockInFlag:false];
            }
            checkingClockStatus = FALSE;
#ifndef RELEASE
            NSLog(@"setting checkingClockStatus = FALSE");
#endif
            
        }];
    }];
}

- (TimeEntry*)timeEntry {
    if (nil == _timeEntryObjectID) {
        return nil;
    }
    DataManager* manager = [DataManager sharedManager];
    NSError* error = nil;
    TimeEntry* result = (TimeEntry*)[manager existingObjectByID:_timeEntryObjectID error:&error];
    if (nil != error) {
        return nil;
    }
    return result;
}

//in some situations we were getting a stuck clock in where there was an active clock and values in both clock in and clock out so activeClockInFlag is passed to make sure when it's set to true to always enable the clock out button so they can clock out
- (void)determineClockInOrClockOut:(TimeEntry*)aTimeEntry activeClockInFlag:(bool) isActiveClockIn{
    UserClass *user = [UserClass getInstance];

    TimeEntry* __timeEntry = aTimeEntry;
    if (nil == __timeEntry) {
        DataManager* manager = [DataManager sharedManager];
        NSError* error = nil;
        __timeEntry = [manager fetchMostRecentTimeEntry:&error];
        if (nil != error) {
#ifndef RELEASE
            NSLog(@"error fetching most recent time entry - %@", error.localizedDescription);
#endif
            __timeEntry = nil;
        }


    }
    if ((nil == __timeEntry) || (!__timeEntry.clockIn && !__timeEntry.clockOut)) {
        strLastClockInTime = @"";
        strLastClockOutTime = @"";
        user.lastClockIn = @"";
        user.lastClockOut = @"";
        [self enableClockIn];
        user.currentClockMode = ClockModeIn;
        user.activeTimeEntryId = nil;
        self.timeEntryObjectID = nil;
        [self updateUI];
        return;
    }
    
    self.timeEntryObjectID = __timeEntry.objectID;
    
    NSNumber* timeEntryID = __timeEntry.timeEntryID;
    if ([NSNumber isNilOrNull:timeEntryID]) {
        user.activeTimeEntryId = nil;
    } else if ((user.activeTimeEntryId == nil) || (![NSNumber isEquals:timeEntryID dest:user.activeTimeEntryId])) {
        user.activeTimeEntryId = timeEntryID;
    }
    
    //set the offlineMode to a value so we know if we should flag it as not synced
    if ([__timeEntry getDBStatus] == dsUpdated)
    {
        offlineMode = All_Synced;
    }
    
    // Check clockOut if there is one enable clock in
    if (__timeEntry.clockIn && __timeEntry.clockOut) {
        //sometimes (rare) we endup with a clock in and clock out but it's still an active clock in so check for that flag to determine which buttons to enable
        if (isActiveClockIn){
            [self enableClockOut:strLastClockInTime];
            user.currentClockMode = ClockModeIn;
        }
        else {
            [self enableClockIn];
            user.currentClockMode = ClockModeOut;
        }
        strLastClockInTime = [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString];
        strLastClockOutTime = [__timeEntry.clockOut.dateTimeEntry toLongDateTimeString];

        user.lastClockIn = strLastClockInTime;
        user.lastClockOut = strLastClockOutTime;
    } else if (__timeEntry.clockIn) {
        strLastClockOutTime = @"";
        user.lastClockOut = @"";
        strLastClockInTime = [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString];
//        if ([__timeEntry getDBStatus] != dsUpdated)
//        {
//            strLastClockInTime = [NSString stringWithFormat:@"%@ -Not Synced", strLastClockInTime];
//        }
        user.lastClockIn = strLastClockInTime;
        [self enableClockOut:strLastClockInTime];
        user.currentClockMode = ClockModeOut;
    }
    [self updateUI];
}

//this is the callback that comes from the clock status web service. The error code will tell us what to do
- (void)checkClockStatusServiceCallDidFinish:(CheckClockStatusWebService *)controller timeEntryRec:(NSDictionary *)timeEntryRec ErrorCode:(int)errorValue {

/*    [self stopSpinner];

    //if no error
    if (errorValue == SERVICE_ERRORCODE_SUCCESSFUL)
    {
        DEBUG_MSG
        NSString* clockTime = nil;
        TimeEntry* timeEntry = nil;
        NSNumber* timeEntryId = nil;
        if (nil != timeEntryRec) {
            timeEntryId = [timeEntryRec valueForKey:@"id"];
            NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);

            NSError* error = nil;
            DataManager* dataManager = [DataManager sharedManager];
            timeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];
            clockTime = [timeEntry.clockIn.dateTimeEntry toLongDateTimeString];
        }
        if (![NSString isNilOrEmpty:clockTime])
        {
            [self stopSpinner];
            strLastClockInTime = clockTime;
            user.lastClockIn = strLastClockInTime;
            timeEntryNotes = timeEntry.notes;
            strLastClockOutTime = @"";
            user.lastClockOut = @"";
            user.activeTimeEntryId = timeEntryId;
            [self enableButton:clockOutBtn];
            [self disableButton:clockInBtn];
            [TimeClockTableView reloadData];

        }
        else{
            [self enableButton:clockInBtn];
            [self disableButton:clockOutBtn];
            //if the clock in label has a value but the clock out doesn't and we have an active time entry id then call the get api to get the clock out
            if ((user.activeTimeEntryId != nil) && (user.activeTimeEntryId > 0))
            {
                apiCallType = CheckTimeEntryByID;
                [self callGetTimeEntryByIDWebService: user.activeTimeEntryId];
            }
            else
                [self stopSpinner];
        }
        
        
    }*/
}

- (void) tick:(id)sender
{
    NSString *time = self.getCurrentTime;
    self.currentTimeLabel.text = time;
     [ self performSelector: @selector(tick:)
      withObject: nil
      afterDelay: 1.0
     ]; 
}
		
-(void) enableButton:(UIButton*) curBtn {
    //make sure the button is set to enabled
    curBtn.enabled = TRUE;
    curBtn.alpha = 1.0f;
    [[curBtn layer] setCornerRadius:4.0f];


  //  UIColor *blueRidgeMtns = UIColorFromRGB(0x63a8cc);
//    self.topNavigationBar.titleTextAttributes = @{UITextAttributeTextColor : [UIColor blackColor]};
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor], UITextAttributeTextColor,
      [UIColor clearColor], UITextAttributeTextShadowColor,
      [UIFont fontWithName:@"Helvetica Neue-Bold" size:0.0], UITextAttributeFont, nil]];
   
    
  //  [self.topNavigationBar setBackgroundImage:[UIImage imageNamed: @"header_background"]
    //               forBarMetrics:UIBarMetricsDefault];
//    UIImage *image = [UIImage imageNamed:@"header_background.jpg"];
//    [[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
  //  [[UINavigationBar appearance] setTintColor:blueColorOp];
    
 //   [[UIBarButtonItem appearance] setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    //ios 7
  //  self.navigationController.navigationBar.translucent = NO;

    
    //make the text white
    curBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);

  //  [curBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

}

-(void) disableButton:(UIButton*) curBtn{
      //[[clockInBtn layer] setMasksToBounds:YES];
    [[curBtn layer] setCornerRadius:7.0f];
    [[curBtn layer] setBorderWidth:0.5f];
    curBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    
    //remove the Gradient layer which gave use the blue color shades
    CALayer* layer = [curBtn.layer valueForKey:@"GradientLayer"];
    [layer removeFromSuperlayer];
    [curBtn.layer setValue:nil forKey:@"GradientLayer"];

    //diable the button
    curBtn.enabled = FALSE;
    curBtn.alpha = 0.5f;
    [curBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];   

}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UserClass *user = [UserClass getInstance];

    strLastClockInTime = @"";
    strLastClockOutTime = @"";
    timeEntryNotes = @"";
    
    ratingDialogType = Feedback_None;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClockStatusNotification:)
     
                                                 name:kCheckClockStatusNotification object:nil];
    
#ifndef RELEASE
    _devDisplayLabel.hidden = NO;
#endif
    
    
//only show ads on the personal app
#ifdef PERSONAL_VERSION

    self.bannerView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, 0, self.adBannerContainer.bounds.size.width, self.adBannerContainer.bounds.size.height)];
    [self.bannerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.bannerView setDelegate:self];
    [self.adBannerContainer addSubview:self.bannerView];

    //uncomment this when you want to test adMob
    [self bannerView:self.bannerView didFailToReceiveAdWithError:nil];
#endif

    currentDistanceinMiles = 150;
//    self.myLocationManager = [[CLLocationManager alloc] init];
//    self.myLocationManager.delegate = self;


  /*  if ([user.userID intValue] == 0)
    {
        LoginViewController *loginController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        loginController.delegate = (id) self;
        loginController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        
        [self presentModalViewController:loginController animated:YES];

       // [self callLoginWebService];
    }
    else { //the user has been authenticated so check if he has set a passcode
        if ([user.userPin length]  > 0)
            [self showPasscodeViewController:NO];
    }*/
    
  //  strLastClockInTime = @"";
  //  strLastClockOutTime = @"";
    //set up the info button
  /*  UIButton* infoButton = [UIButton buttonWithType: UIButtonTypeInfoLight];

    [infoButton setTitle:@"Settings" forState:UIControlStateNormal];
    [infoButton addTarget:self action:@selector(infoButtonAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *modalButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    [self.navigationItem setLeftBarButtonItem:modalButton animated:YES];  
    
    //set up the settings button
    self.settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonAction)];
                                                     
    
    self.navigationItem.leftBarButtonItem = self.settingsButton;
   */
    //reset to start
    //user.currentClockMode = ClockModeIn;
    //check to see what mode we are to figure out how we want to set the buttons
    if (user.currentClockMode == ClockModeIn){
        [self enableButton:clockInBtn];        
        [self disableButton:clockOutBtn];
    }
    else {
        [self disableButton:clockInBtn];
        [self enableButton:clockOutBtn];        
    }
    

    
    [self tick:nil];

}

- (void)checkClockStatusNotification:(NSNotification*)notification {
    [self checkClockStatus:false];
}


- (void)viewDidUnload
{
//only show ads on the personal app
#ifdef PERSONAL_VERSION
   
    self.bannerView.delegate=nil;
    self.admobBannerView.delegate = nil;
#endif
    [self setCurrentTimeLabel:nil];
    formatterDateTime12hr = nil;
    formatterTime = nil;
    [self setClockInBtn:nil];
    [self setClockOutBtn:nil];
    [self setTimeClockTableView:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [self setLblDebug:nil];
   // [myLocationManager stopUpdatingLocation];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    UserClass *user = [UserClass getInstance];

	[super viewWillAppear: animated];
    //reset the flag to check Active Clock first
    apiCallType = CheckActiveClock;
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];
    

    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    self.slidingViewController.underRightViewController = nil;
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];

    if (user.lastClockIn != nil)
        strLastClockInTime = user.lastClockIn;
    if (user.lastClockOut != nil)
        strLastClockOutTime = user.lastClockOut;
    
     [TimeClockTableView reloadData];

    //only apply this for the business app
//#ifndef PERSONAL_VERSION
//    if ([user.userID integerValue] > 0)
//        [self checkClockStatus];
    
//#endif
   // [self checkScheduledToWork];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //only apply this for the business app
    //Should do this when the UI is really visible
//#ifndef PERSONAL_VERSION
    //for the personal app when it first launches there is no userID
    UserClass *user = [UserClass getInstance];
    if ([user.userID integerValue] > 0)
        [self checkClockStatus:false];
    
//#else
//    [TimeClockTableView reloadData];
//#endif

    [TimeSheetDetailViewController popAndReleaseDetail];
    
}

-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!self.bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
    //    banner.frame = CGRectOffset(banner.frame, 0, 50);
        [UIView commitAnimations];
        self.bannerIsVisible = YES;
    }
}

#ifdef PERSONAL_VERSION
//if iAd fails pickup adMob
-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError
                                                                      *)error

{
    if (self.bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOff" context:NULL];
        banner.frame = CGRectOffset(banner.frame, 0, -50);
        [UIView commitAnimations];
        self.bannerIsVisible = NO;
    }
    
    //switch to adMob:
    
    // 1
    [self.bannerView removeFromSuperview];
    
    // 2
    
    _admobBannerView = [[GADBannerView alloc]
                        initWithFrame:CGRectMake(0.0,0.0,
                                                 GAD_SIZE_320x50.width,
                                                 GAD_SIZE_320x50.height)];
    

    
    // 3

    self.admobBannerView.adUnitID = @"ca-app-pub-6730679122734693/8271726764";
    
    self.admobBannerView.rootViewController = self;

    self.admobBannerView.delegate = self;
    
    // 4
    [self.adBannerContainer addSubview:self.admobBannerView];
    
    GADRequest *request = [GADRequest request];
    

    [self.admobBannerView loadRequest:request];
    
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    [self.admobBannerView removeFromSuperview];
}
#endif

- (void) getLocation:(id)sender
{
 //   [myLocationManager startUpdatingLocation];
}

-(void) updateUI {
    UserClass *user = [UserClass getInstance];

/*    if (user.currentClockMode == ClockModeIn)
    {
        //switch the enable and disable so clockIn is now disabled
        [self enableButton:clockOutBtn];
        [self disableButton:clockInBtn];
        
        //switch the clock mode

 
        user.currentClockMode = ClockModeOut;
        
    }
    else {
        //switch the enable and disable so clockOut is now disabled    
        [self enableButton:clockInBtn];
        [self disableButton:clockOutBtn];
        //switch the clock mode
        [TimeClockTableView reloadData];
        user.currentClockMode = ClockModeIn;
    }*/
    [TimeClockTableView reloadData];
    //save data
    [[NSUserDefaults standardUserDefaults] setInteger:user.currentClockMode forKey:@"clockMode"];
    [[NSUserDefaults standardUserDefaults] setObject:user.activeTimeEntryId forKey:@"activeTimeEntryId"];
    [[NSUserDefaults standardUserDefaults] setObject:user.lastClockIn forKey:@"lastClockIn"];
    [[NSUserDefaults standardUserDefaults] setObject:user.lastClockOut forKey:@"lastClockOut"];

}
- (IBAction)doCockIn:(id)sender {
//        [[Crashlytics sharedInstance] crash];

    [self doClockInSteps];
    
}
-(void)doClockInSteps{
    UserClass *user = [UserClass getInstance];

    CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking in")

    [self startSpinnerWithMessage:@"Clocking in.."];
    
    DataManager* dataManager = [DataManager sharedManager];
    [dataManager checkAndLoadEmployeeInfo:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
        lastClockInTime = self.getCurrentDateTime;
        strLastClockInTime = [formatterDateTime12hr stringFromDate:lastClockInTime];
        strLastClockOutTime = @"";
    
#ifndef PERSONAL_VERSION
    
        [ self performSelector: @selector(getLocation:)
                withObject: nil
                afterDelay: 0
     ];
#endif
    
        //take out
        // [self updateUI];
        self.lastClockMode = ClockModeIn;
        self.lastClockTime = lastClockInTime;
        _clockWebServices = [[ClockWebServices alloc] init];
        _clockWebServices.delegate = self;
        [_clockWebServices callTCSWebService:ClockModeIn timeEntryObjectID:nil dateTime:[NSDate date] employeeID: user.userID locOverride:YES];
    }];
//    [self callTCSWebService:ClockModeIn dateTime:lastClockInTime];
}

#ifdef PERSONAL_VERSION
-(void)CheckifAccountWasCreated
{
    UserClass *user= [UserClass getInstance];
    if ([user.hasAccount isEqualToString: @"YES"])
    {
         isAccountCreatedPrompt = true;
         return;
    }
    //launch the you need to create an account dialog
    int visitCounter = (int) [user.appLaunchCounter integerValue];
    NSDate *todaysDate = [NSDate date];
    NSInteger numOfDaysSinceInstall = [CommonLib daysBetweenDate:user.appInstallDate andDate:todaysDate];

    if ((visitCounter >= MAX_TIMES_APP_LAUNCHED) && (numOfDaysSinceInstall > 7))
    {
        [self stopSpinner];

        isAccountCreatedPrompt = true;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"We noticed you have not created an account. Please create an account so you don't lose your data" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
        [alert show];
        
    }

}
#endif

-(void)CheckRateUsOnAppStoreTrigger
{
    UserClass *user= [UserClass getInstance];
    //launch the review dialog if they haven't given us a review before
    int didUserGiveRatingFeedback = (int) [user.userGaveUsRatingFeedback integerValue];
    if (didUserGiveRatingFeedback)
        return;
    int visitCounter = (int) [user.appLaunchCounter integerValue];
    //only launch if the counter is a certain number and we haven't asked him before and it's been 21 since they installed the app so they've been using it for a while now
    NSDate *todaysDate = [NSDate date];
    NSInteger numOfDaysSinceInstall = [CommonLib daysBetweenDate:user.appInstallDate andDate:todaysDate];
//    if (true)
    if ((visitCounter >= MAX_TIMES_APP_LAUNCHED) && (didUserGiveRatingFeedback == 0) && numOfDaysSinceInstall > 14)
    {
        [self stopSpinner];
        /*               //turn off the dialog so we don't show it anymore
         user.userGaveUsRatingFeedback = [NSNumber numberWithInt:1];
         [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
         */
        //show first rating dialog
        ratingDialogType = EnjoyingEzClokcer_dlg;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Enjoying ezClocker?" delegate:self cancelButtonTitle:@"Not really" otherButtonTitles:@"Yes!", nil];
        
        [alert show];
        
    }
    
    
}

- (IBAction)doClockOut:(id)sender {
    [self doClockOutSteps];
}

#pragma mark - Clock In/Clock Out Routines
-(void) doClockOutSteps{
    UserClass *user = [UserClass getInstance];

    CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking out")

    [self startSpinnerWithMessage:@"Clocking out.."];
    
    DataManager* dataManager = [DataManager sharedManager];
    @try {
    [dataManager checkAndLoadEmployeeInfo:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {

        lastClockOutTime = self.getCurrentDateTime;
        strLastClockOutTime = [formatterDateTime12hr stringFromDate:lastClockOutTime];
        //take out
        // [self updateUI];
        self.lastClockMode = ClockModeOut;
        self.lastClockTime = lastClockOutTime;

        _clockWebServices = [[ClockWebServices alloc] init];
        _clockWebServices.delegate = self;
        [_clockWebServices callTCSWebService:ClockModeOut timeEntryObjectID:_timeEntryObjectID dateTime:[NSDate date] employeeID: user.userID locOverride:YES];
    }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    

    //[self callTCSWebService:ClockModeOut dateTime:lastClockOutTime];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UserClass *user = [UserClass getInstance];
    switch (alertView.tag) {
        case WEB_SERVICE_OUT_OF_RANGE_ERROR: //override dialog
        {
            if (buttonIndex == 1){
                self.bOverrideLocationCheck = YES;
                ClockWebServices *clockWebServices = [[ClockWebServices alloc] init];
                clockWebServices.delegate = self;
                [clockWebServices callTCSWebService:self.lastClockMode timeEntryObjectID:_timeEntryObjectID dateTime:[NSDate date] employeeID: user.userID locOverride:YES];
                // [self callTCSWebService:self.lastClockMode dateTime:self.lastClockTime];
            }
        }break;
            
        default:
            break;
    }

    if(ratingDialogType == EnjoyingEzClokcer_dlg)
    {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            //show second rating dialog
            ratingDialogType = CanYouRateUs_dlg;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"How about a rating on the App Store, then?" delegate:self cancelButtonTitle:@"No, thanks" otherButtonTitles:@"Ok, sure", nil];
            
            [alert show];
        }
        else{
            //show third rating dialog
            //they already said they are not enjoying ezClocker so don't ask thema gain
            user.userGaveUsRatingFeedback = [NSNumber numberWithInt:1];
            [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
            
            ratingDialogType = GiveUsFeedback_dlg;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Would you mind giving us some feedback?" delegate:self cancelButtonTitle:@"No, thanks" otherButtonTitles:@"Ok, sure", nil];
            
            [alert show];
            
            
        }
    }
    else if(ratingDialogType == CanYouRateUs_dlg){
        if (buttonIndex != [alertView cancelButtonIndex]) {
            //turn off the dialog so we don't show it anymore
            user.userGaveUsRatingFeedback = [NSNumber numberWithInt:1];
            [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
            
            //log to the server that this user rated us so we don't bug them
            AppStoreRatingWebService *webService = [[AppStoreRatingWebService alloc] init];
            [webService LogRatingToServer];
            

 
#ifdef PERSONAL_VERSION
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-personal-time-tracking/id833047956?mt=8"]];
#else
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker/id800807197?ls=1&mt=8"]];
#endif
  
        }
        else
        {
            //reset so we can ask them again later
            NSDate *todaysDate = [NSDate date];
            user.appInstallDate = todaysDate;
            user.userGaveUsRatingFeedback = [NSNumber numberWithInt:0];
            [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
            
        }
    }
    else if (ratingDialogType == GiveUsFeedback_dlg)
    {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            //take them to our feedback screen
            EmailFeedbackViewController *emailFeedbackController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmailFeedback"];
            UINavigationController *emailFeedbackNavigationController = [[UINavigationController alloc] initWithRootViewController:emailFeedbackController];
            
            
            emailFeedbackController.delegate = (id) self;
            emailFeedbackController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            
            [self presentViewController:emailFeedbackNavigationController animated:YES completion:nil];
            
        }
        else{
            
            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Somebody Didn't want to give us feedback :-("]];
            
        }
        
    }
}

- (void)emailFeedbackViewControllerDidFinish:(UIViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//this is the callback that comes from the clock in/out web service. The error code will tell us what to do
- (void)clockServiceCallDidFinish:(ClockWebServices *)controller timeEntryRec:(NSDictionary *)timeEntryRec ErrorCode:(int)errorValue ClockMode:(ClockMode)clockMode
{
    [self stopSpinner];
    
    UserClass *user = [UserClass getInstance];

    if (errorValue == SERVICE_ERRORCODE_SUCCESSFUL){
        DEBUG_MSG
        TimeEntry* aTimeEntry = nil;
        if (nil != timeEntryRec) {
            NSNumber *timeEntryId = [timeEntryRec valueForKey:@"id"];
            NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);

            NSError* error = nil;
            // user.activeTimeEntryId = timeEntryId; no need to set here becaus the clockWebServices controller does it on success

            DataManager* dataManager = [DataManager sharedManager];
            aTimeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];
        }
        if (nil != aTimeEntry && clockMode == ClockModeIn) {
            if ([CommonLib isProduction])
            {
             //   Mixpanel *mixpanel = [Mixpanel sharedInstance];
             //   [mixpanel track:@"Employee Clockin" properties:@{ @"email": user.userEmail}];
            }
        }
        [self determineClockInOrClockOut:aTimeEntry activeClockInFlag: false];
        [self updateUI];
        
        //if PERSONAL check if they have created an account and if not then prompt to do so but only once
#ifdef PERSONAL_VERSION
        if (!isAccountCreatedPrompt)
            [self CheckifAccountWasCreated];
#endif
        
        //ask them to rate us after clocking out
        if (clockMode == ClockModeOut)
            [self CheckRateUsOnAppStoreTrigger];


        [DataManager postDataWasModifiedNotification];
    }
    //if error code = 1 that means that person has already clocked in from the website so
    else if (errorValue == SERVICE_ERRORCODE_ALREADY_CLOCKED_IN){
         [self checkClockStatus:true];

//        [SharedUICode messageBox:@"" message:@"You are already clocked in.  Please clock out." withCompletion:^{
 //           [self checkClockStatus];
 //       }];
        /*[self enableButton:clockOutBtn];
         [self disableButton:clockInBtn];
         user.currentClockMode = ClockModeOut;*/
        
        //       strLastClockInTime = @"";
    }
    //if error code = 2 that means that person has already clocked out from the website so
    else if (errorValue == SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT){
        [self checkClockStatus:true];

     //   [SharedUICode messageBox:@"" message:@"You are already clocked out." withCompletion:^{
     //       [self checkClockStatus];
     //   }];
        /*        [self enableButton:clockInBtn];
         [self disableButton:clockOutBtn];
         user.currentClockMode = ClockModeIn;*/
        //        strLastClockOutTime = @"";
        
    } else if (errorValue == SERVICE_UNAVAILABLE_ERROR) {
        [self determineClockInOrClockOut:nil activeClockInFlag: false];
        [self updateUI];
        [DataManager postDataWasModifiedNotification];
    }
    _clockWebServices = nil;
    
}

- (void)enableClockOut:(NSString*)clockTime {
    if (![NSString isNilOrEmpty:clockTime])
    {
        //        clockInLabel.hidden = NO;
        //        clockInLabel.text = [NSString stringWithFormat:@"Clock In: %@", clockTime];;
        //        clockOutLabel.hidden = YES;
        
        [self disableButton:clockInBtn];
        [self enableButton:clockOutBtn];

    }
    else{
        [self enableClockIn];
    }
}

- (void)enableClockIn {
    //clockInLabel.hidden = YES;
    //clockOutLabel.hidden = YES;
    [self enableButton:clockInBtn];
    [self disableButton:clockOutBtn];
}

-(void) settingsButtonAction
{
/*    SettingsViewController *controller = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    
    //call the show passcode view controller and pass in a yes which tells it we need to set the passcode or change it
    //[self showPasscodeViewController:YES];
    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];

    controller.settingsDelegate = (id) self;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentModalViewController:settingsNavigationController animated:YES];
  */  
}

-(void) showPasscodeViewController: (BOOL) setPasscode{
/*    PasscodeViewController *controller = [[PasscodeViewController alloc] initWithNibName:@"PasscodeViewController" bundle:nil];
    controller.delegate = (id) self;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    controller.passcodeSetup = setPasscode;
    
    [self presentModalViewController:controller animated:YES];
  */  
}

/*- (void)loginViewControllerDidFinish:(SettingsViewController *)controller Name:(NSString *)userName Password:(NSString *)userPassword
{
    //get rid of the login screen
    [self dismissModalViewControllerAnimated:YES];

//    [self callLoginWebService:userName Password: userPassword];
    

}


#pragma mark - Flipside View

- (void)settingsViewControllerDidFinish:(SettingsViewController *)controller
{
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)PasscodeViewControllerDidFinish:(PasscodeViewController *)controller
{
    
    [self dismissModalViewControllerAnimated:YES];
}
*/


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{	
    return 2;
}
static UIColor* hatchedBackColor = nil;


- (void)setPendingUpdate:(UITableViewCell*)cell pending:(BOOL)bIsPendingUpdate {
    if (bIsPendingUpdate) {
        cell.backgroundColor = [CommonLib getHatchedBackColor];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

/*- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.backgroundColor = [UIColor whiteColor];
    if (indexPath.row == 0){
        if (![strLastClockInTime isEqual:[NSNull null]])
        {
            cell.textLabel.text = [NSString stringWithFormat:@"IN:     %@",strLastClockInTime];
            if ([strLastClockInTime length] > 0)
            {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                if (offlineMode == ClockIn_Not_Synced || offlineMode == Both_Not_Synced)
                    cell.backgroundColor = UIColorFromRGB(LIGHT_RED_COLOR);
            }
        }
        
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"OUT: %@",strLastClockOutTime];
        if ([strLastClockOutTime length] > 0)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (offlineMode == ClockOut_Not_Synced || offlineMode == Both_Not_Synced)
                cell.backgroundColor = UIColorFromRGB(LIGHT_RED_COLOR);
        }

    }
    return cell;
}
*/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == 0){
        if (![strLastClockInTime isEqual:[NSNull null]])
        {
            TimeEntry* __timeEntry = self.timeEntry;
            if (__timeEntry && __timeEntry.clockIn) {
                BOOL bIsPendingUpdate = ([__timeEntry.clockIn getDBStatus] != dsUpdated);
                [self setPendingUpdate:cell pending:bIsPendingUpdate];
            } else {
                [self setPendingUpdate:cell pending:FALSE];

            }
            cell.textLabel.text = [NSString stringWithFormat:@"IN:     %@",strLastClockInTime];
            if ([strLastClockInTime length] > 0) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        
    }
    else
    {
        TimeEntry* __timeEntry = self.timeEntry;
        if (__timeEntry && __timeEntry.clockOut) {
            BOOL bIsPendingUpdate = ([__timeEntry.clockOut getDBStatus] != dsUpdated);
            [self setPendingUpdate:cell pending:bIsPendingUpdate];
        } else {
            [self setPendingUpdate:cell pending:FALSE];
        }
        cell.textLabel.text = [NSString stringWithFormat:@"OUT: %@",strLastClockOutTime];
        if ([strLastClockOutTime length] > 0) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //don't let users modify a time entry if activeTimeEntryID is zero that usually means it got deleted does not exist
    TimeEntry* __timeEntry = self.timeEntry;
    if (__timeEntry)
    {
        
        TimeSheetDetailViewController* controller = [TimeSheetDetailViewController showDetail:self];
        
        controller.timeEntryObjectID = self.timeEntryObjectID;
        
        if(indexPath.row == 0)
        {
            controller.selectedMode = ClockModeIn;
            controller.editClockMode = ACTIVE_CLOCKIN;
            if ([strLastClockInTime length] > 0)
            {
                [self.navigationController pushViewController:controller animated:YES];
            }
            
        }
        else{
            controller.selectedMode = ClockModeOut;
            controller.editClockMode = ACTIVE_CLOCKOUT;
            if ([strLastClockOutTime length] > 0)
                [self.navigationController pushViewController:controller animated:YES];
        }
        
    }
    
    
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return @"Last Clock Time";
}

- (void) enteredBackground: (NSNotification*) notification{
    //close any windows that maybe showing to get us back to the main clock in screen
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) enteredForeground: (NSNotification*) notification{
    UserClass *user = [UserClass getInstance];

    if ([user.userPin length]  > 0)
        [self showPasscodeViewController:NO];
}



- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];

}

/*#pragma mark Alert View Button Actions
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    UserClass *user = [UserClass getInstance];

    switch (alertView.tag) {
        case WEB_SERVICE_OUT_OF_RANGE_ERROR: //override dialog
        {
            if (buttonIndex == 1){
                self.bOverrideLocationCheck = YES;
                ClockWebServices *clockWebServices = [[ClockWebServices alloc] init];
                clockWebServices.delegate = self;
                [clockWebServices callTCSWebService:self.lastClockMode timeEntryObjectID:_timeEntryObjectID dateTime:[NSDate date] employeeID: user.userID locOverride:YES];
               // [self callTCSWebService:self.lastClockMode dateTime:self.lastClockTime];
            }
        }break;
            
        default:
            break;
    }
}
 */

#pragma mark Location Methods
-(void)promptForOverride:(NSString*)message{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Override" , nil];
    alert.delegate = self;
    alert.tag = WEB_SERVICE_OUT_OF_RANGE_ERROR;
    [alert show];
}

- (void)saveTimeEntryDidFinish:(TimeSheetDetailViewController *)controller
{
    if (nil == controller.timeEntryObjectID) {
        self.timeEntryObjectID = nil;
    }
    else if (![CoreDataUtils isEquals:self.timeEntryObjectID dest:controller.timeEntryObjectID])
    {
        self.timeEntryObjectID = controller.timeEntryObjectID; // update to the moved one
    }
        
    [TimeSheetDetailViewController releaseController];
    
    [self.navigationController popViewControllerAnimated:YES];
}

/*-(void) callGetTimeEntryByIDWebService: (NSNumber *) timeEntryID{
    
    //NSString *currentDateTime = self.getCurrentDateTime;
    UIAlertView *alert;
    
    NSString *httpPostString;
    
    
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    
    NSString *request_body;
    
    httpPostString = [NSString stringWithFormat:@"%@timeEntry/getSingle/%@/%@?timezone=%@&authToken=%@", SERVER_URL, user.employerID, timeEntryID, timeZoneId, user.authToken];
    
    
    //Implement request_body for send request here authToken and clock DateTime set into the body.
 //   request_body = [NSString
 //                   stringWithFormat:@"authToken=%@&timeZoneId:=%@",
 //                   [user.authToken   stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
 //                   [timeZoneId  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
 //                   ];
    
    //  alert = [[UIAlertView alloc] initWithTitle:nil message:request_body delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    // [alert show];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"GET"];
    
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
    
    
}*/

- (void)dealloc {
    [TimeSheetDetailViewController releaseController];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}


@end
