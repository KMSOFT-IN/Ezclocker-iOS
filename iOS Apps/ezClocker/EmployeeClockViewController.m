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
#import "TimeSheetDetailViewController.h"
#import "EmailFeedbackViewController.h"
#import "AppStoreRatingWebService.h"
#import "CoreDataUtils.h"
#import "NSDictionary+Extensions.h"
#import <StoreKit/StoreKit.h>
#import "CustomersViewController.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"
#import "JobCodeListViewController.h"
#import "PushNotificationManager.h"
#import "BreakViewController.h"

@interface EmployeeClockViewController () <checkClockStatusWebServicesDelegate, TimeSheetDetailViewControllerDelegate, LocationManagerDelegate, JobCodeListViewDelegate>
{
    NSString *notes;
}
@property (nonatomic, assign) bool bOverrideLocationCheck;
@property (nonatomic, assign) ClockMode lastClockMode;
@property (nonatomic, assign) NSDate *lastClockTime;
@property (nonatomic, retain) ClockWebServices* clockWebServices;
@property (nonatomic, copy) NSManagedObjectID* timeEntryObjectID;
@property (nonatomic, retain, readonly) TimeEntry* timeEntry;
@property (nonatomic, retain) LocationManager* locationManager;
@property (nonatomic, assign) bool beganReceivingLocationUpdates;
@property (nonatomic, assign) bool isFromForeground;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonHeight;

@property (weak, nonatomic) IBOutlet UIView *popupInsideView;
@property (strong, nonatomic) IBOutlet UIView *popUpView;
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;
@end

@implementation EmployeeClockViewController
//@synthesize lblDebug;
@synthesize clockInBtn;
@synthesize clockOutBtn;
@synthesize currentTimeLabel;
@synthesize activityIndicatorView;
@synthesize signalStrengthLabel;
@synthesize signalStrengthImageView;
@synthesize TimeClockTableView;
//@synthesize myLocationManager;
@synthesize bOverrideLocationCheck, lastClockMode, lastClockTime;
//@synthesize bannerView= _bannerView;
//@synthesize admobBannerView = _admobBannerView;



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
    //#ifndef PERSONAL_VERSION
    //    [formatterDateTime12hr setDateFormat:@"MM/dd/yyyy h:mm:ss a"];
    //#else
    //    [formatterDateTime12hr setDateFormat:@"MM/dd/yyyy h:mm a"];
    //#endif
        
    [formatterDateTime12hr setDateFormat:kLongDateTimeFormat];
    
    //set time zones
    [formatterISO8601DateTime setTimeZone:[NSTimeZone localTimeZone]];
    [formatterDateTime12hr setTimeZone:[NSTimeZone localTimeZone]];
    [formatterTime setTimeZone:[NSTimeZone localTimeZone]];
    
    //color the buttons
    clockInBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    clockOutBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    
#ifndef PERSONAL_VERSION
    
    self.beganReceivingLocationUpdates = false;
    
    [self.activityIndicatorView startAnimating];
    //RK: removed this for now i.e. displaying the GPS strength
 //   [self.signalStrengthImageView setHidden:true];
    
    self.locationManager = [LocationManager defaultLocationManager];
    
    self.locationManager.delegate = self;
#endif
}


/*- (NSUInteger)supportedInterfaceOrientations{
    return (NSUInteger)UIInterfaceOrientationMaskPortrait;
}
 */

#ifndef PERSONAL_VERSION
// MARK: LocationManagerDelegate Methods
-(void) locationUpdate:(CLLocation *) location
{
    if (self.beganReceivingLocationUpdates == false) {
        self.beganReceivingLocationUpdates = true;
        
        [self.activityIndicatorView stopAnimating];
        
        [self.activityIndicatorView setHidden:true];
        
        self.beganReceivingLocationUpdates = true;
        
      //  [self.signalStrengthImageView setHidden:false];
    }
    
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:@"GPS Signal Strength: " attributes:@{NSFontAttributeName : [UIFont fontWithName:@"Helvetica" size:17.0]}];
    
    [self.signalStrengthImageView setImage:[CommonLib accuracyIcon: location.horizontalAccuracy]];
    
    [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:[CommonLib accuracyString:location.horizontalAccuracy] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:17.0]}]];
    
    [self.signalStrengthLabel setAttributedText:attributed];
}

#endif

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
-(void) checkClockStatus{
    
//if we are the personal app then exit - only check clock status for the business app
//#ifdef PERSONAL_VERSION
//    return;
//#endif
    UserClass *user = [UserClass getInstance];
    //since this gets called everytime it comes to the foreground, in the situation where we've logged out and take it to the background then again to the foreground then this gets called and bombs out so check for user.UserID <> nil
    if (nil != user.userID)
    {
    
        if (checkingClockStatus) { // prevent multiple calls to checkClockStatus being called within this view because checkClockStatus below is async
            return;
        }
#ifndef RELEASE
            NSLog(@"setting checkingClockStatus = TRUE");
#endif

        checkingClockStatus = TRUE;
        [self startSpinnerWithMessage:@"Connecting to Server.."];
        
        DataManager* manager = [DataManager sharedManager];
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        THREAD_BLOCK_START()
        while ([manager isBusy]) { // sanity!
            sleep(1);
        }
        dispatch_semaphore_signal(sema);
        THREAD_BLOCK_END()

        if (![NSThread isMainThread]) {
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        } else {
            while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW)) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            }
        }
        
        
        
        DataManager* dataManager = [DataManager sharedManager];
        [dataManager checkAndLoadEmployeeInfo:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
            [manager checkClockStatus:user.userID withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
                [self stopSpinner];

                //if no error
                if (aErrorCode == SERVICE_ERRORCODE_SUCCESSFUL)
                {
                    //check to see if the user accepted to review us on the AppStore
                    //if the app's user.userGaveUsRatingFeedback is 0 then check with the value
                    //that came back from the server to see if the customer re-installed the app but already rated us
                    if ([user.userGaveUsRatingFeedback intValue] == 0)
                    {
                        NSNumber *userAcceptedReview = [aResults valueForKey:@"acceptedMobileReviewAsk"];
                        if (![NSNumber isNilOrNull:userAcceptedReview]){
                            if ([userAcceptedReview intValue] > 0)
                                user.userGaveUsRatingFeedback = userAcceptedReview;

                        }
                    }
                    //check to see if jobCodes got created
                     _jobCodeView.hidden = TRUE;
                    if ([user.jobCodesList count] > 0)
                    {
                        _jobCodeView.hidden = FALSE;
//                        _clockTableViewHeight.constant = -173.667;
                        jobCodesList = user.jobCodesList;
                    }
                    NSDictionary *empRec = [aResults valueForKey:@"employee"];
                    primaryJobCodeId = [empRec valueForKey:@"primaryJobCodeId"];
                    NSDictionary *activeBreakRec = [aResults valueForKey:@"activeBreak"];
                    if (![NSDictionary isNilOrNull:activeBreakRec]){
                        NSString *breakInTime = [activeBreakRec valueForKey:@"clockInIso8601"];
                        breakInTime  = [breakInTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                    
                        lastBreakInTime = [formatterISO8601DateTime dateFromString:breakInTime];
                        strLastBreakInTime = [formatterDateTime12hr stringFromDate:lastBreakInTime];
                        isActiveBreakIn = [[activeBreakRec valueForKey:@"isActiveBreak"] boolValue];
                    }
                   
                    else
                        isActiveBreakIn = FALSE;

                    if (isActiveBreakIn) {
                        [self showBreakScreen];
                    }
                    else
                    {
                        //if the employer ended the employee's break then remove the break screen
                        if (isBreakScreenShowing)
                            [self removeBreakScreen];
                            
                    }
                    NSDictionary *timeEntryRec;
                    timeEntryRec = [aResults valueForKey:@"clockInOutState"];
                  
                    if ([NSDictionary isNilOrNull:timeEntryRec])
                         timeEntryRec = [aResults valueForKey:@"latestTwoWeeksTimeEntry"];

                   // if (nil != timeEntryRec) {
                    if (![NSDictionary isNilOrNull:timeEntryRec]) {
                        DEBUG_MSG
                        NSNumber *timeEntryId = [timeEntryRec valueForKey:@"id"];
                        NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);

                        notes = [timeEntryRec valueForKey:@"notes"];
                        BOOL isEmpty = [NSString isNilOrEmpty:notes];
                        if (!isEmpty)
                            self.notesTextView.text = notes;

                        //save the latest time entry
                        user.activeTimeEntryId = timeEntryId;
                        
                        bool isActiveClockIn = [[timeEntryRec valueForKey:@"isActiveClockIn"] boolValue];
//                        bool isActiveBreakIn = [[timeEntryRec valueForKey:@"isActiveBreak"] boolValue];
                        if (isActiveClockIn)
                        {
                            user.activeClockInId = timeEntryId;
                        }
                        else
                            user.activeClockInId = nil;
                        
                        NSError* error = nil;
                        DataManager* dataManager = [DataManager sharedManager];
                        
                        TimeEntry* aTimeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];
                        if (isActiveClockIn)
                            
                            [self determineClockInOrClockOut:aTimeEntry activeClockInFlag:true];
                        else
                            [self determineClockInOrClockOut:aTimeEntry activeClockInFlag:false];
                    } else {
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
                                            [self determineClockInOrClockOut:aTimeEntry activeClockInFlag:false];
                                        }
                                    } else {
                                        [self determineClockInOrClockOut:nil activeClockInFlag:false];
                                    }
                                    checkingClockStatus = FALSE;
#ifndef RELEASE
                                    NSLog(@"setting checkingClockStatus = FALSE");
#endif

                                }];
                                return;
                            } else {
                                [self determineClockInOrClockOut:timeEntry activeClockInFlag:false];
                            }
                        } else {
                            [self determineClockInOrClockOut:nil activeClockInFlag:false];
                        }
                    }
                } else {
                    //when we are offline we need to make some assumptions if we are clocked in or out
                    DataManager* manager = [DataManager sharedManager];
                    NSError* error = nil;
                    TimeEntry* __timeEntry = [manager fetchMostRecentTimeEntry:&error];
                    ClockInfo *clockOutInfo = __timeEntry.clockOut;
                    //check to see if we are on Break by checking if the time entry if of type Break and if there is no clock out i.e. it's an active break.
                    if (((![NSString isNilOrEmpty:__timeEntry.timeEntryType]) && ([__timeEntry.timeEntryType isEqualToString:kBreakTimeEntryType])) && (clockOutInfo == nil))
                    {
                        lastBreakInTime = __timeEntry.clockIn.dateTimeEntry;
                        strLastBreakInTime = [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString];
                        [self showBreakScreen];
                    }
                    else
                    {
                        //get the last time Entry that is not a break
                        __timeEntry = [manager fetchMostRecentNormalTimeEntry:&error];
                        clockOutInfo = __timeEntry.clockOut;
                        
                        //if we don't have a clock out then assume it's an active clock in
                        if (clockOutInfo == nil)
                        {
                            [self determineClockInOrClockOut:nil activeClockInFlag:true];
                        
                        }
                        else
                            [self determineClockInOrClockOut:nil activeClockInFlag:false];
                    }
                }
                checkingClockStatus = FALSE;
#ifndef RELEASE
                NSLog(@"setting checkingClockStatus = FALSE");
#endif

                
                if (self.tabBarController.selectedIndex == 2 && self.isFromForeground) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshEmployeeData" object:nil];
                }
                self.isFromForeground = NO;
            }];
        }];
    }
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


- (void)determineClockInOrClockOut:(TimeEntry*)aTimeEntry activeClockInFlag:(bool) isActiveClockIn {
    UserClass *user = [UserClass getInstance];

#ifndef PERSONAL_VERSION
    strLastClockInTime = [aTimeEntry.clockIn.dateTimeEntry toLongDateTimeString];
    NSNumber *isBlockedFromClockingOut = user.employeePermissions[@"DISALLOW_EMPLOYEE_TIMEENTRY"];
    if ([isBlockedFromClockingOut boolValue])
    {
        [self disableBothButtons];
      //  return;
    }
#endif
    
    TimeEntry* __timeEntry = aTimeEntry;
    if (nil == __timeEntry) {
        if ([user.customerNameIDList count] > 0)
        {
             __timeEntry = nil;
        }
        else
        {
            DataManager* manager = [DataManager sharedManager];
            NSError* error = nil;
//            __timeEntry = [manager fetchMostRecentTimeEntry:&error];
            __timeEntry = [manager fetchMostRecentNormalTimeEntry:&error];
            if (nil != error) {
#ifndef RELEASE
                NSLog(@"error fetching most recent time entry - %@", error.localizedDescription);
#endif
                __timeEntry = nil;
                [ErrorLogging logError:error];
            }
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
    
 //    BOOL bIsPendingUpdate = ([__timeEntry.clockIn getDBStatus] != dsUpdated);
//    bIsPendingUpdate = ([__timeEntry getDBStatus] != dsUpdated);
 //   bool isActiveClockIn = [CommonLib isActiveClockIn:__timeEntry ClockMode:(ClockMode)clockMode];//(user.activeClockInId != nil);

/*    NSString *msg;
    if (lastClockOutTime == nil)
    {
        msg = @"LastClockOuttime is empty";

    }
    else
        msg = @"LastClockOutTime is NOT empty";

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
        [alert show];
    */

    //show the job code if it exists
    if (![NSNumber isNilOrNull:__timeEntry.jobCodeId])
    {
        NSString *jobCodeName;
        NSNumber *jobCodeId;
        for (NSDictionary *jobCodeObj in jobCodesList)
         {
             jobCodeName = [jobCodeObj valueForKey:@"name"];
             jobCodeId = [jobCodeObj valueForKey:@"id"];
             if ([jobCodeId isEqualToNumber:__timeEntry.jobCodeId])
                 _jobCodeTextField.text = jobCodeName;
         }

    }
        
    if (isActiveClockIn){
        [self enableClockOut:strLastClockInTime];
        NSNumber *isBreaksAllowed = user.employerOptions[@"ALLOW_RECORDING_OF_UNPAID_BREAKS"];
        if ([isBreaksAllowed boolValue])
        {
            [self enableBreakIn];
        }
        user.currentClockMode = ClockModeIn;
    }
    else {
        [self enableClockIn];
        user.currentClockMode = ClockModeOut;
    }
    
//    if (__timeEntry.clockIn && __timeEntry.clockOut) {
    if (!isActiveClockIn) {
        //sometimes (rare) we endup with a clock in and clock out but it's still an active clock in so check for that flag to determine which buttons to enable
        
        strLastClockInTime = [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString];

        strLastClockOutTime = [__timeEntry.clockOut.dateTimeEntry toLongDateTimeString];

        if ([NSString isNilOrEmpty:strLastClockOutTime])
            strLastClockOutTime = @"";
        
        user.lastClockIn = strLastClockInTime;
        user.lastClockOut = strLastClockOutTime;
  //  } else if (__timeEntry.clockIn) {
    } else {
        strLastClockOutTime = @"";
        user.lastClockOut = @"";
        strLastClockInTime = [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString];
//        if ([__timeEntry getDBStatus] != dsUpdated)
//        {
//            strLastClockInTime = [NSString stringWithFormat:@"%@ -Not Synced", strLastClockInTime];
//        }
        user.lastClockIn = strLastClockInTime;
     //   [self enableClockOut:strLastClockInTime];
      //  user.currentClockMode = ClockModeOut;
    }
    [[DataManager sharedManager] saveData];
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

if ([curBtn.titleLabel.text isEqualToString:@"Break"])
curBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);
else
curBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);

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

    //disable the button
    curBtn.enabled = FALSE;
    curBtn.alpha = 0.5f;
    [curBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];   
    NSLog(@"Button Disable : %@",curBtn.titleLabel.text);
}

-(void) disableBothButtons
{
    [self disableButton:clockInBtn];
    [self disableButton:clockOutBtn];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _jobCodeView.hidden = FALSE;
    UserClass *user = [UserClass getInstance];

    isBreakScreenShowing = false;
    strLastClockInTime = @"";
    strLastClockOutTime = @"";
    timeEntryNotes = @"";
    TimeClockTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    ratingDialogType = Feedback_None;
    
    [self setFramePicker];
    [self registerForKeyboardNotifications];
    jobCodesList = user.jobCodesList;
    
//    _popupInsideView.layer.borderColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR).CGColor;
//    _popupInsideView.layer.borderWidth = 2;
//    _popupInsideView.layer.cornerRadius = 10;
    
//    _notesTextView.layer.borderColor = UIColor.grayColor.CGColor;
//    _notesTextView.layer.borderWidth = 1;
//    _notesTextView.layer.cornerRadius = 10;
    
    
    
//only check clock status for the business app
//#ifndef PERSONAL_VERSION
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClockStatusNotification:)
     
                                                 name:kCheckClockStatusNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setJobCodeViewIsHidden:)
       
                                                   name:ksetJobCodeViewNotification object:nil];
    
//#endif
    
#ifndef RELEASE
 //   _devDisplayLabel.hidden = NO;
#endif
    
    //for smaller screens like the SE make the buttons smaller, for larger screens like XS make the clock label bigger
    if (UIScreen.mainScreen.bounds.size.height < 600 ) {
        self.buttonHeight.constant = 60;
    } else {
        self.buttonHeight.constant = 70;
        //[currentTimeLabel setFont:[UIFont fontWithName:@"Helvetica" size:36.0f]];
        [currentTimeLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:36.0f]];
    }
    
    //not showing the GPS strength signal for now, RK: worried that employees will think it's always tracking
//#ifdef PERSONAL_VERSION
    
    signalStrengthLabel.hidden = YES;
    signalStrengthImageView.hidden = YES;
    activityIndicatorView.hidden = YES;
    
//took out the ads for version 1.4 since they were not working
/*    self.bannerView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, 0, self.adBannerContainer.bounds.size.width, self.adBannerContainer.bounds.size.height)];
    [self.bannerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.bannerView setDelegate:self];
    [self.adBannerContainer addSubview:self.bannerView];

    //uncomment this when you want to test adMob
    [self bannerView:self.bannerView didFailToReceiveAdWithError:nil];
 */
//#endif

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
        [clockInBtn setTitle:@"Clock In" forState:UIControlStateNormal];
        clockInBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
        [self enableButton:clockInBtn];
        [self disableButton:clockOutBtn];
    }
    else {

        NSNumber *isBreaksAllowed = user.employerOptions[@"ALLOW_RECORDING_OF_UNPAID_BREAKS"];
        if ([isBreaksAllowed boolValue])
        {
            [clockInBtn setTitle:@"Break" forState:UIControlStateNormal];
            clockInBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);
            [self enableButton:clockInBtn];

        }
        else
            [self disableButton:clockInBtn];

        [self enableButton:clockOutBtn];
    }
    
    if (_fromCustomerDetail == YES) {
       
        UIButton* backButton = [UIButton buttonWithType: UIButtonTypeCustom];
        [backButton setFrame:CGRectMake(0, 0, 50, 50)];
        backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -40, 0, 0);
        [backButton setImage:[UIImage imageNamed:@"icArrowBack"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(Back_btn:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *modalButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        [self.navigationItem setLeftBarButtonItem:modalButton animated:YES];
        
        [self.menuBarItem setBackgroundVerticalPositionAdjustment:-100.0f forBarMetrics:UIBarMetricsDefault];
    } else {
       
    }
}


- (void)registerForKeyboardNotifications
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(keyboardDidShow:)
    name:UIKeyboardWillShowNotification
    object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(keyboardDidHide:)
    name:UIKeyboardWillHideNotification
    object:nil];
    
}

- (void)keyboardDidShow: (NSNotification *) notif{
    NSDictionary* info = [notif userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    [self.popupInsideView setFrame:CGRectMake(0, kbSize.height, 320, 253)];
    self.bottomConstraint.constant = kbSize.height;
}
                          
- (void)keyboardDidHide: (NSNotification *) notif{
//    [self.popupInsideView setFrame:CGRectMake(0, 414, 320, 253)];
    self.bottomConstraint.constant = 0;
}
                                                    

-(void)setJobCodeViewIsHidden:(NSNotification*)notification {
    
    NSDictionary* userInfo = notification.userInfo;
    NSString *value = [userInfo[@"jobCodeCount"] stringValue];
    if ([value isEqualToString:@"0"]) {
         _jobCodeView.hidden = TRUE;
    } else {
         _jobCodeView.hidden = FALSE;
    }
}

-(IBAction)Back_btn:(id)sender
{
    //Your code here
    [self.previousNavigation setNavigationBarHidden:NO];
    [self.previousNavigation popViewControllerAnimated:NO];
}

-(IBAction)notes_btn:(id)sender
{
    CGFloat y = UIScreen.mainScreen.bounds.size.height - self.popupInsideView.frame.size.height;
    [self.popupInsideView setFrame:CGRectMake(0, y, 320, 253)];
    [self.popupInsideView setBounds:CGRectMake(0, 0, 320, 253)];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [self.popupInsideView setFrame:CGRectMake(0, 0, 320, 253)];
    [UIView commitAnimations];
    self.popUpView.frame = [UIScreen.mainScreen bounds];
    [UIApplication.sharedApplication.keyWindow addSubview:_popUpView];
}

-(IBAction)submitNotes:(id)sender
{
    notes = self.notesTextView.text;
//    BOOL bIsReachable = [CommonLib DoWeHaveNetworkConnection];
 //   if (bIsReachable)
 //   {
        if ([NSString isNilOrEmpty:self.notesTextView.text]) {
            [SharedUICode messageBox:@"Error" message:@"Please enter notes." withCompletion:^{
                return;
            }];
         //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter notes." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
         //   [alert show];
        } else {
            [self callModifyTimeEntryWebService];
            [self.popUpView removeFromSuperview];
        }
 //   }
}

-(IBAction)cancelNotes:(id)sender
{
    self.notesTextView.text = notes;
    [self.popUpView removeFromSuperview];
}

- (void) orientationChanged:(NSNotification *)note
{
    self.popUpView.frame = self.view.bounds;
    [self.popUpView updateConstraints];
    [self.popUpView layoutIfNeeded];
}

- (void)checkClockStatusNotification:(NSNotification*)notification {
    self.isFromForeground = YES;
    [self checkClockStatus];
}


- (void)viewDidUnload
{
//took out ads
    /*
#ifdef PERSONAL_VERSION
   
    self.bannerView.delegate=nil;
    self.admobBannerView.delegate = nil;
#endif
*/
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


- (void)CheckAndForceSync:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
//if (![DataManager isClosed]) {
    DataManager* manager = [DataManager sharedManager];
    [SVProgressHUD showWithStatus:@"Syncing, please wait..."];
//        __block id<ISpinner> spinner = [self startSpinnerWithMessage:@"Syncing, please wait..."];
    [manager forceSyncWithCompletion:^(UIBackgroundFetchResult result, NSInteger errorCode, NSError* error) {
        //NOTE: No need to do this here the data manager will call if new data
        /*if (result == UIBackgroundFetchResultNewData) {
         DataManager postNotifyTimeSheetMasterRefresh:TRUE];
         }*/
 //       NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL ||
            errorCode == SERVICE_ERRORCODE_SUCCESSFUL_NOTHING_TO_DO ||
            errorCode == DATAMANAGER_NO_PENDING_UPDATES) {
            [SVProgressHUD dismiss];
            completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
            return;
 //           [center postNotificationName:kCheckClockStatusNotification object:nil];
        } else if (nil != error) {
            if (!(errorCode == SERVICE_UNAVAILABLE_ERROR || errorCode == DATAMANAGER_BUSY)) {
                NSString* msg = [NSString stringWithFormat:@"Error while Force Syncing in EmployeeClockViewController - %@", error.localizedDescription];
                [MetricsLogWebService LogException: msg];
            }
            [SVProgressHUD dismiss];
            completion(errorCode, nil, nil, nil);
            return;
        } else {
            NSString* errorCodeMsg = [CommonLib errorMsg:errorCode];
            NSString* msg = [NSString stringWithFormat:@"errorCode %d (%@) was reported during forceSync in EmployeeClockViewController", (int)errorCode, errorCodeMsg];
            [MetricsLogWebService LogException:msg];
            [SVProgressHUD dismiss];
            completion(SERVICE_ERRORCODE_UNKNOWN_ERROR, nil, nil, nil);
            return;
        }
        // notify the MenuViewController in case you have it open when it gets here so it can reload the menu to show how many pending updates
 //       [center postNotificationName:kForceSyncCompleteInAppWillEnterForegroundNotification object:nil];

    }];
//} else {
//#ifndef RELEASE
//    NSLog(@"DataManager is closed meaning you have signed out!");
//#endif
//}
}
    
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    self.popUpView.frame = self.view.bounds;
    UserClass *user = [UserClass getInstance];
//    if (user.currentClockMode == ClockModeIn){
//        [self enableButton:clockInBtn];
//        [self disableButton:clockOutBtn];
//    }
//    else {
//        [self disableButton:clockInBtn];
//        [self enableButton:clockOutBtn];
//    }
    [[_jobCodeView layer] setCornerRadius:0.0f];
    [[_jobCodeView layer] setBorderWidth:0.5f];
    [[_jobCodeView layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    
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
    
    if ([user.jobCodesList count] == 0)
        _jobCodeView.hidden = TRUE;
//        _clockTableViewHeight.constant = -129.667;
    _timeEntryObjectID = nil;
     [TimeClockTableView reloadData];
    
    
    [TimeSheetDetailViewController popAndReleaseDetail];
    
    //for the personal app when it first launches there is no userID
    if ([user.userID integerValue] > 0) {
//        if (clockOutBtn.enabled) {
            [self checkClockStatus];
//        }
    }
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
    
//    [TimeSheetDetailViewController popAndReleaseDetail];
//
//    //for the personal app when it first launches there is no userID
//    UserClass *user = [UserClass getInstance];
//    if ([user.userID integerValue] > 0)
//    {
//
//        [self checkClockStatus];
//
//    }
    
//#else
//    [TimeClockTableView reloadData];
//#endif

//    [TimeSheetDetailViewController popAndReleaseDetail];
    
}

/*-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!self.bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
    //    banner.frame = CGRectOffset(banner.frame, 0, 50);
        [UIView commitAnimations];
        self.bannerIsVisible = YES;
    }
}
 */

#ifdef PERSONAL_VERSION
//took out ads
//if iAd fails pickup adMob
/*-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError
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
 */
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

-(bool) isLocationRequired
{
    bool result = FALSE;
    //first check if the require location option is set on the employer side
    UserClass *user = [UserClass getInstance];
    bool requireLocation = (user.requireLocationForClockInOut);
    //if the employer does not have Require GPS location information to clock in or out option turned on then just let them clock in/out
    if (!requireLocation)
    {
        result = FALSE;
    }
    //else it's required so check if they gave authorization
    else{
        if([CLLocationManager locationServicesEnabled] &&
           [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {
            result = FALSE;
        }
        else {
            result = TRUE;
        }
    }
    return result;
}

//MARK: - Break button click

-(IBAction)doCockIn:(id)sender {
    if ([clockInBtn.titleLabel.text isEqualToString:@"Break"])
         [self doBreakInSteps];
     else
     {

//        [[Crashlytics sharedInstance] crash];

#ifdef PERSONAL_VERSION
      [self doClockInSteps];
#elif IPAD_VERSION
      //if we are using the business app or kiosk and the employee does not have a primary job assigned to them and they have jobs then force the employee to pick a job before clocking in
      if (([NSNumber isNilOrNull:primaryJobCodeId]) && ([jobCodesList count] > 0))
          [self showJobCodesPicker];
      else
      {
          [self doClockInSteps];
      }
#else
    bool locationIsRequired = [self isLocationRequired];
    if (!locationIsRequired)
    {
        //if we are using the business app or kiosk and have jobs then force the employee to pick a job before clocking in
        if (([NSNumber isNilOrNull:primaryJobCodeId]) && ([jobCodesList count] > 0))
            [self showJobCodesPicker];
        else
        {
            [self doClockInSteps];
        }
    }
    else{
        [ErrorLogging logErrorWithDomain:@"LOCATION_SERVICES" code:SERVICE_UNAVAILABLE_ERROR description:@"LOCATION_SERVICES_OFF" error: nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Location Services is Off: Your employer has mandated that your location services (GPS) must be turned on when clocking in/out. Go to your phone's settings>ezClocker app>set location to While Using"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    }
 
#endif
     }
    
}

-(void)doBreakInSteps{
    NSNumber* _selectedJobCodeId = nil;
    //if the employee has a primary job code then send that else send the one they selected which should  be the value of the job text field
    if (![NSNumber isNilOrNull:primaryJobCodeId])
        _selectedJobCodeId = primaryJobCodeId;
    else
    {
        //if we have a job code selected
        if (![NSString isNilOrEmpty:_jobCodeTextField.text])
            [self getSelectedJobCode];
        if (![NSDictionary isNilOrNull:selectedJobCode])
            _selectedJobCodeId = [selectedJobCode valueForKey:@"id"];
    }
    
    lastBreakInTime = self.getCurrentDateTime;
    strLastBreakInTime = [formatterDateTime12hr stringFromDate:lastBreakInTime];
    strLastBreakOutTime = @"";
    
    _clockWebServices = [[ClockWebServices alloc] init];
    _clockWebServices.delegate = self;
    UserClass *user = [UserClass getInstance];
    [_clockWebServices callTCSWebService:BreakModeIn timeEntryObjectID:nil dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];
    

}

-(void)doBreakOutSteps{
    NSNumber* _selectedJobCodeId = nil;
    //if the employee has a primary job code then send that else send the one they selected which should  be the value of the job text field
    if (![NSNumber isNilOrNull:primaryJobCodeId])
        _selectedJobCodeId = primaryJobCodeId;
    else
    {
        //if we have a job code selected
        if (![NSString isNilOrEmpty:_jobCodeTextField.text])
            [self getSelectedJobCode];
        if (![NSDictionary isNilOrNull:selectedJobCode])
            _selectedJobCodeId = [selectedJobCode valueForKey:@"id"];
    }

    _clockWebServices = [[ClockWebServices alloc] init];
    _clockWebServices.delegate = self;
    UserClass *user = [UserClass getInstance];
    
    [SVProgressHUD showWithStatus:@"Connecting to Server.."];
    
    NSError* error1 = nil;
    DataManager* dataManager = [DataManager sharedManager];
    TimeEntry *time = [dataManager fetchMostRecentTimeEntry:&error1];
    _timeEntryObjectID = time.objectID;
    
    [_clockWebServices callTCSWebService:BreakModeOut timeEntryObjectID:_timeEntryObjectID dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];

}


-(void)doClockInSteps{
    [CommonLib logEvent:@"Clock in"];
    UserClass *user = [UserClass getInstance];

  //  CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking in")

    [self CheckAndForceSync:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
        
        if (aError != nil) {
            [ErrorLogging logError:aError];
        }
      //  [self stopSpinner];

 //       if ((aErrorCode != 0)) {
          //  NSString* errorCodeMsg = [CommonLib errorMsg:aErrorCode];
 //           NSString* msg = [NSString stringWithFormat:@"errorCode %d (%@) was reported during forceSync in EmployeeClockViewController.doClockInSteps", (int)aErrorCode, @"Not sure"];
 //           [MetricsLogWebService LogException:msg];
 //       }
 //       else
  //      {
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
                NSNumber* _selectedJobCodeId = nil;
                //if the employee has a primary job code then send that else send the one they selected which should  be the value of the job text field
                if (![NSNumber isNilOrNull:primaryJobCodeId])
                    _selectedJobCodeId = primaryJobCodeId;
                else
                {
                    //if we have a job code selected
                    if (![NSString isNilOrEmpty:_jobCodeTextField.text])
                        [self getSelectedJobCode];
                    if (![NSDictionary isNilOrNull:selectedJobCode])
                        _selectedJobCodeId = [selectedJobCode valueForKey:@"id"];
                }
                _clockWebServices = [[ClockWebServices alloc] init];
                _clockWebServices.delegate = self;
                [_clockWebServices callTCSWebService:ClockModeIn timeEntryObjectID:nil dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];
            }];
            self.notesTextView.text = @"";
            notes = @"";
        //    [self callTCSWebService:ClockModeIn dateTime:lastClockInTime];

  //      }

        
    }];


 }

-(void)getSelectedJobCode
{
    NSString *name;
    
    for (NSDictionary *jobCodeObj in jobCodesList)
    {
        name = [jobCodeObj valueForKey:@"name"];
        if ([name isEqualToString:_jobCodeTextField.text])
            selectedJobCode = [jobCodeObj copy];
    }

}
#ifdef PERSONAL_VERSION
- (void)resetAppInstallDate {
    UserClass *user = [UserClass getInstance];
    user.appInstallDate = [NSDate date];
    //save
    [[NSUserDefaults standardUserDefaults] setObject:user.appInstallDate forKey:@"appInstallDate"];
  //  [[NSUserDefaults standardUserDefaults] synchronize]; //write out the
}


-(void)CheckifAccountWasCreated
{
    UserClass *user= [UserClass getInstance];
    if ([user.hasAccount isEqualToString: @"YES"])
    {
        return;
    }
    //launch the you need to create an account dialog
    int visitCounter = (int) [user.appLaunchCounter integerValue];
    NSDate *todaysDate = [NSDate date];
    NSInteger numOfDaysSinceInstall = [CommonLib daysBetweenDate:user.appInstallDate andDate:todaysDate];
    if ((visitCounter >= MAX_TIMES_APP_LAUNCHED) && (numOfDaysSinceInstall > 7))
    {
        [self stopSpinner];
        
        //reset the numOfDaysSinceInstall to 0 so we prompt them again after 7 days
        [self resetAppInstallDate];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Information"
                                     message:@"We noticed you have not created an account. Please create an account so you don't lose your data"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"We noticed you have not created an account. Please create an account so you don't lose your data" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
      //  [alert show];
        
    }
    
}
#endif

-(void)CheckRateUsOnAppStoreTrigger
{
    
    //    UserClass *user= [UserClass getInstance];
    //    //launch the review dialog if they haven't given us a review before
    //    int didUserGiveRatingFeedback = (int) [user.userGaveUsRatingFeedback integerValue];
    //    if (didUserGiveRatingFeedback)
    //        return;
    //    int visitCounter = (int) [user.appLaunchCounter integerValue];
    //    //only launch if the counter is a certain number and we haven't asked him before and it's been 21 since they installed the app so they've been using it for a while now
    //    NSDate *todaysDate = [NSDate date];
    //    NSInteger numOfDaysSinceInstall = [CommonLib daysBetweenDate:user.appInstallDate andDate:todaysDate];
    //
    //    if ((visitCounter >= MAX_TIMES_APP_LAUNCHED) && (didUserGiveRatingFeedback == 0) && numOfDaysSinceInstall > 14)
    //    {
    //        [self stopSpinner];
    //        //turn off the dialog so we don't show it anymore
    //         user.userGaveUsRatingFeedback = [NSNumber numberWithInt:1];
    //         [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
    //         [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
    
    //show first rating dialog
    //        ratingDialogType = EnjoyingEzClokcer_dlg;
    [SharedUICode CheckRateUsOnAppStoreTrigger:self :^(NSInteger index) {
        [self stopSpinner];
        if (index == 0) {
            // For No
            //                 ratingDialogType = EnjoyingEzClokcer_dlg;
            [self didNotEnjoyEzClocker];
        } else if (index == 1) {
            // For Yes
            //                 ratingDialogType = EnjoyingEzClokcer_dlg;
            //                [self enjoyedEzClockerWasSelected];
            
            if (@available(iOS 10.3, *)) {
                [SKStoreReviewController requestReview];
            } else {
                [self willingToGiveUsRating];
            }
        } else {
            // For visitCounter zero
        }
    }];
    //    }
    
    
}

- (IBAction)doClockOut:(id)sender {
#ifdef PERSONAL_VERSION
    [self doClockOutSteps];
#elif IPAD_VERSION
    [self doClockOutSteps];
#else
    bool locationIsRequired = [self isLocationRequired];
    if (!locationIsRequired)
    {
        [self doClockOutSteps];
    }
    else{
        [ErrorLogging logErrorWithDomain:@"LOCATION_SERVICES" code:SERVICE_UNAVAILABLE_ERROR description:@"LOCATION_SERVICES_OFF" error: nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Location Services is Off: Your employer has mandated that your location services (GPS) must be turned on when clocking in/out. Go to your phone's settings>ezClocker app>set location to While Using"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    
#endif

   
}

#pragma mark - Clock In/Clock Out Routines
-(void) doClockOutSteps{
    UserClass *user = [UserClass getInstance];

    //CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking out")
    

    [self CheckAndForceSync:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
      //  [self stopSpinner];

 //       if ((aErrorCode != 0)) {
          //  NSString* errorCodeMsg = [CommonLib errorMsg:aErrorCode];
 //           NSString* msg = [NSString stringWithFormat:@"errorCode %d (%@) was reported during forceSync in EmployeeClockViewController.doClockOutSteps", (int)aErrorCode, @"Not sure"];
 //           [MetricsLogWebService LogException:msg];
 //       }
 //       else
 //       {

            [self startSpinnerWithMessage:@"Clocking out.."];
            [CommonLib logEvent:@"Clock out"];
            DataManager* dataManager = [DataManager sharedManager];

                [dataManager checkAndLoadEmployeeInfo:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {

                    lastClockOutTime = self.getCurrentDateTime;
                    strLastClockOutTime = [formatterDateTime12hr stringFromDate:lastClockOutTime];
                    //take out
                    // [self updateUI];
                    self.lastClockMode = ClockModeOut;
                    self.lastClockTime = lastClockOutTime;
                    NSNumber* _selectedJobCodeId = nil;
                    if (![NSDictionary isNilOrNull:selectedJobCode])
                        _selectedJobCodeId = [selectedJobCode valueForKey:@"id"];
                    _clockWebServices = [[ClockWebServices alloc] init];
                    _clockWebServices.delegate = self;
        
                    NSError* error1 = nil;
                    TimeEntry *timeEntry = [dataManager fetchMostRecentNormalTimeEntry:&error1];
                    //if the time entry back is a break then call Fetch Most Normal Non Break Time Entry
 //                   if ((![NSString isNilOrEmpty:timeEntry.timeEntryType]) && ([timeEntry.timeEntryType isEqualToString:kBreakTimeEntryType]))
  //                  {
  //                      timeEntry = [dataManager fetchMostRecentNormalTimeEntry:&error1];
  //                  }
 
                    _timeEntryObjectID = timeEntry.objectID;
        
        
                    [_clockWebServices callTCSWebService:ClockModeOut timeEntryObjectID:_timeEntryObjectID dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];
                }];
   //         }

        }];

        
}

/*-(void) enjoyedEzClockerWasSelected
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"How about a rating on the App Store, then?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Ok, sure"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action){
                                                          if (@available(iOS 10.3, *)) {
                                                              [SKStoreReviewController requestReview];
                                                          } else {
                                                              [self willingToGiveUsRating];
                                                          }
                                                      }];

    
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"No, thanks"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action){
                                                         [self notWillingToGiveUsRating];
                                                     }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];

}
*/

-(void)didNotEnjoyEzClocker
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"Would you mind giving us some feedback?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Ok, sure"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action){
                                                          [self willingToGiveUsFeedback];
                                                      }];
    
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"No, thanks"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action){}];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];

}
-(void)willingToGiveUsRating
{
    //log to the server that this user rated us so we don't bug them
    AppStoreRatingWebService *webService = [[AppStoreRatingWebService alloc] init];
    [webService LogRatingToServer];
    
#ifdef PERSONAL_VERSION
  //  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-personal-time-tracking/id833047956?mt=8"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-personal-time-tracking/id833047956?mt=8"]options:@{} completionHandler:nil];
#elif IPAD_VERSION
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-kiosk-time-tracking/id1339692641?mt=8"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-kiosk-time-tracking/id1339692641?mt=8"]options:@{} completionHandler:nil];
#else
  //  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker/id800807197?ls=1&mt=8"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker/id800807197?ls=1&mt=8"]options:@{} completionHandler:nil];
#endif

}

-(void)notWillingToGiveUsRating
{
    //10/15/17 RK: took this out and moved it back to the calling function
    /*           //reset so we can ask them again later
     NSDate *todaysDate = [NSDate date];
     user.appInstallDate = todaysDate;
     user.userGaveUsRatingFeedback = [NSNumber numberWithInt:0];
     [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
     */
}
-(void)willingToGiveUsFeedback
{
    //take them to our feedback screen
    EmailFeedbackViewController *emailFeedbackController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmailFeedback"];
    UINavigationController *emailFeedbackNavigationController = [[UINavigationController alloc] initWithRootViewController:emailFeedbackController];
        
        
    emailFeedbackController.delegate = (id) self;
    emailFeedbackController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
    [self presentViewController:emailFeedbackNavigationController animated:YES completion:nil];

}




- (void)emailFeedbackViewControllerDidFinish:(UIViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) showBreakScreen
{
    //don't show the break screen if we are already showing it
    if (!isBreakScreenShowing)
    {
        UINavigationController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"breakNavController"];
        BreakViewController * controller = viewController.viewControllers.firstObject;
        controller.strClockInTime = strLastClockInTime;
        controller.strBreakInTime = strLastBreakInTime;
        controller.breakInTime = lastBreakInTime;
        controller.delegate = self;
        if (@available(iOS 13.0, *)) {
            //[viewController setModalInPresentation:YES];
            [viewController setDefinesPresentationContext:NO];
            [viewController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        } else {
            // Fallback on earlier versions
        }
        isBreakScreenShowing = true;
        //[self presentViewController:viewController animated:YES completion:nil];
        [self.navigationController pushViewController:controller animated:YES];
    }

}

- (void) removeBreakScreen
{
    [self.navigationController popViewControllerAnimated:YES];
    isEndBreak = false;
    isBreakScreenShowing = false;
}
//this is the callback that comes from the clock in/out web service. The error code will tell us what to do
- (void)clockServiceCallDidFinish:(ClockWebServices *)controller timeEntryRec:(NSDictionary *)timeEntryRec ErrorCode:(int)errorValue resultMessage: (NSString *) resultMessage ClockMode:(ClockMode)clockMode
{
    [self stopSpinner];
    
    if (isEndBreak) {
        [self removeBreakScreen];
    }
    UserClass *user = [UserClass getInstance];


    if (errorValue == SERVICE_ERRORCODE_SUCCESSFUL){
        DEBUG_MSG

        TimeEntry* aTimeEntry = nil;
        bool isActiveClockIn = false;
        if (nil != timeEntryRec) {
            NSNumber *timeEntryId = [timeEntryRec valueForKey:@"id"];
            NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);

            NSError* error = nil;
            // user.activeTimeEntryId = timeEntryId; no need to set here becaus the clockWebServices controller does it on success

            DataManager* dataManager = [DataManager sharedManager];
            aTimeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];
            
            isActiveClockIn = [[timeEntryRec valueForKey:@"isActiveClockIn"] boolValue];
            if (isActiveClockIn)
                user.activeClockInId = timeEntryId;
            else
                user.activeClockInId = nil;

        }
        if (nil != aTimeEntry && clockMode == ClockModeIn) {
            if ([CommonLib isProduction])
            {
             //   Mixpanel *mixpanel = [Mixpanel sharedInstance];
             //   [mixpanel track:@"Employee Clockin" properties:@{ @"email": user.userEmail}];
            }
        }
        
        if (clockMode == BreakModeIn)
        {
            [self showBreakScreen];
        }
        if (isActiveClockIn)
            [self determineClockInOrClockOut:aTimeEntry activeClockInFlag:true];
        else
            [self determineClockInOrClockOut:aTimeEntry activeClockInFlag:false];

//        [self determineClockInOrClockOut:aTimeEntry ClockMode:clockMode];
        [self updateUI];
        
        //if PERSONAL check if they have created an account and if not then prompt to do so but only once
#ifdef PERSONAL_VERSION
        if (clockMode == ClockModeOut)
            [self CheckifAccountWasCreated];
#endif

        //ask them to rate us after clocking out
        if (clockMode == ClockModeOut)
            [self CheckRateUsOnAppStoreTrigger];



    }
    //if error code = 1 that means that person has already clocked in from the website so
    else if (errorValue == SERVICE_ERRORCODE_ALREADY_CLOCKED_IN){
        [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_ALREADY_CLOCKED_IN description:@"SERVICE_ERRORCODE_ALREADY_CLOCKED_IN" error: nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"You are already clocked in.  Please clock out."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self checkClockStatus];
            
        }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    //if error code = 2 that means that person has already clocked out from the website so
    else if (errorValue == SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT){
        [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT description:@"SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT" error: nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"You are already clocked out."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self checkClockStatus];
        }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    //if error code = 8 that means that person has already took a break in from the website so
    else if (errorValue == SERVICE_ERRORCODE_ALREADY_BREAKED_IN){
        [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_ALREADY_BREAKED_IN description:@"SERVICE_ERRORCODE_ALREADY_BREAKED_IN" error: nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"You are already on a break.  Please end break"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self checkClockStatus];
            
        }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    //if error code = 9 that means that person has already ended their break from the website so
    else if (errorValue == SERVICE_ERRORCODE_ALREADY_BREAKED_OUT){
        [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_ALREADY_BREAKED_OUT description:@"SERVICE_ERRORCODE_ALREADY_BREAKED_OUT" error: nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Your break has already ended."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self checkClockStatus];
        }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }

    else if (errorValue == SERVICE_ERRORCODE_EARLYCLOCKIN) {
        [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_EARLYCLOCKIN description:@"SERVICE_ERRORCODE_EARLYCLOCKIN" error: nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:resultMessage
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    }
    else if (errorValue == SERVICE_ACCESSDENIED_ERROR) {
        [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ACCESSDENIED_ERROR description:@"SERVICE_ACCESSDENIED_ERROR" error: nil];
        NSString* msg = [NSString stringWithFormat:@"Error while Clocking in/out EmployeeClockViewController - AuthToken= %@, message= %@", user.authToken, resultMessage];
        [MetricsLogWebService LogException: msg];
        
        NSString* displayMsg = @"Please sign out of the app and sign back in to be authorized. If this continues to happen please notify support@ezclocker.com";

        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Unauthorized"
                                     message:displayMsg
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    }
    else if (errorValue == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
        [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_UNKNOWN_ERROR description:@"SERVICE_ERRORCODE_UNKNOWN_ERROR" error: nil];
        NSString* msg = [NSString stringWithFormat:@"Error while Clocking in/out EmployeeClockViewController - AuthToken= %@, message= %@", user.authToken, resultMessage];
        [MetricsLogWebService LogException: msg];

        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:resultMessage
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    }
    else if (errorValue == SERVICE_UNAVAILABLE_ERROR) {
        //Since this could be caused by an offline 
//        [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_UNAVAILABLE_ERROR description:@"SERVICE_UNAVAILABLE_ERROR" error: nil];
        if (clockMode == BreakModeIn)
            [self showBreakScreen];
        else
        {
            //if I just clocked in or just finished a break the show that we are actively clocked in
            if ((clockMode == ClockModeIn) ||(clockMode == BreakModeOut))
            {
                [self determineClockInOrClockOut:nil activeClockInFlag:true];
            }
            else {
                [self determineClockInOrClockOut:nil activeClockInFlag:false];
            }

            [self updateUI];
        }
    }
    _clockWebServices = nil;
    
}

- (void)enableClockOut:(NSString*)clockTime {
    UserClass *user = [UserClass getInstance];
    NSNumber *isBlockedFromClockingOut = user.employeePermissions[@"DISALLOW_EMPLOYEE_TIMEENTRY"];
    if (![isBlockedFromClockingOut boolValue])
    {
        NSNumber *isBreaksAllowed = user.employerOptions[@"ALLOW_RECORDING_OF_UNPAID_BREAKS"];
        if (![isBreaksAllowed boolValue])
            [self disableButton:clockInBtn];
        
        [self enableButton:clockOutBtn];

    }
}

- (void)enableBreakIn{
    UserClass *user = [UserClass getInstance];
    NSNumber *isBlockedFromClockingIn = user.employeePermissions[@"DISALLOW_EMPLOYEE_TIMEENTRY"];
    if (![isBlockedFromClockingIn boolValue])
    {
        [clockInBtn setTitle:@"Break" forState:UIControlStateNormal];
        clockInBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);

        [self enableButton:clockInBtn];

    }
}

- (void)enableClockIn {
    UserClass *user = [UserClass getInstance];
    NSNumber *isBlockedFromClockingIn = user.employeePermissions[@"DISALLOW_EMPLOYEE_TIMEENTRY"];
    if (![isBlockedFromClockingIn boolValue])
    {

        [clockInBtn setTitle:@"Clock In" forState:UIControlStateNormal];
        clockInBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);

        [self enableButton:clockInBtn];
        [self disableButton:clockOutBtn];
    }
}


-(void) showPasscodeViewController: (BOOL) setPasscode{
/*    PasscodeViewController *controller = [[PasscodeViewController alloc] initWithNibName:@"PasscodeViewController" bundle:nil];
    controller.delegate = (id) self;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    controller.passcodeSetup = setPasscode;
    
    [self presentModalViewController:controller animated:YES];
  */  
}



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
    
    //this is to fix the large font issue with iPhone PLUS
    if (cell.textLabel.font.pointSize > 20)
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0]];

    
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
          //  if ([strLastClockInTime length] > 0) {
          //      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          //  }
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
     //   if ([strLastClockOutTime length] > 0) {
     //       cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      //  }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //if this is an employee who does not have permission to make changes then block
#if !defined(PERSONAL_VERSION) && !defined(IPAD_VERSION)
    UserClass *user = [UserClass getInstance];
    NSNumber *isBlockedFromClockingOut = user.employeePermissions[@"DISALLOW_EMPLOYEE_TIMEENTRY"];
    if ([isBlockedFromClockingOut boolValue])
    {
        return;
    }
#endif

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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
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
    if (_fromCustomerDetail == YES) {
        [self.previousNavigation setNavigationBarHidden:NO];
        [self.previousNavigation popViewControllerAnimated:NO];
    } else {
        [self.slidingViewController anchorTopViewTo:ECRight];
    }


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
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Alert"
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Override"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action){}];
    
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"Cancel"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action){}];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];

    [self presentViewController:alert animated:YES completion:nil];

 //   UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Override" , nil];
  //  alert.delegate = self;
  //  alert.tag = WEB_SERVICE_OUT_OF_RANGE_ERROR;
 //   [alert show];
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


- (IBAction)doJobCodes:(id)sender {
    
}

- (void)setFramePicker {
    CGFloat kbHeight = [NSUserDefaults.standardUserDefaults floatForKey:keyboardHeight];
    CGFloat safeAreaTopHeight = 0;
    CGFloat safeAreaBottomHeight = 0;
    if (@available(iOS 11, *)) {
        // safe area constraints already set
        safeAreaTopHeight = UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
        safeAreaBottomHeight = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    } else {
        safeAreaTopHeight = self.view.safeAreaInsets.top;
        safeAreaBottomHeight = self.view.safeAreaInsets.bottom;
    }
    
    CGFloat Y = self.view.frame.size.height -  (kbHeight + safeAreaBottomHeight + safeAreaTopHeight);
    if (self.tabBarController != nil) {
        CGFloat tabbarHeight = self.tabBarController.tabBar.frame.size.height;
        
        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, Y - tabbarHeight, self.view.frame.size.width, kbHeight)];
    } else {
        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, Y, self.view.frame.size.width, kbHeight)];
    }
    
    [pickerViewDate setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    
    //if we are running the iPhone then we start at 44 because of the toolbar
    CGRect pickerFrame;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        //        pickerFrame = CGRectMake(0, 44, 0, 0);
        pickerFrame = CGRectMake(0, 0, 350, 250);
    } else {
        pickerFrame = CGRectMake(0, 44, self.view.frame.size.width, kbHeight - 44);
    }
    pickerViewJobCode = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerViewJobCode.dataSource = self;
    pickerViewJobCode.delegate = self;
    
    _jobCodeTextField.delegate = self;
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // We are now showing the UIPickerViewer instead
    
    // Close the keypad if it is showing
    [self.view.superview endEditing:YES];
    
#ifdef PERSONAL_VERSION
    [self showJobCodesPicker];
#else
    //For the biz app if they already clocked out then don't allow them to change the job code (it has no effect)
    if (clockOutBtn.enabled)
        [self showJobCodesPicker];
    else
    {
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"You can not change a job after a clock out"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
#endif
    return  NO;
}

-(void) showJobCodesPicker{
    
    
 /*   pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    pickerToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [pickerToolbar sizeToFit];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(EmployeePickerCancelClick)];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 80, 20.0f)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(jobCodePickerDoneClick)];
    
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:cancelBtn, flexSpace, titleButton, flexSpace, doneDateBarBtn, nil];
    
    [pickerToolbar setItems:itemArray animated:YES];
    int row = 0;
    int pos = 0;
    BOOL isEmpty = !(_jobCodeTextField.text && _jobCodeTextField.text.length > 0);
    
    if (!isEmpty)
    {
        NSString *name;
        for (NSDictionary *jobCodeObj in jobCodesList)
        {
            name = [jobCodeObj valueForKey:@"name"];
            if ([name isEqualToString:_jobCodeTextField.text])
                pos = row;
            else
                row++;
        }
    }
    //if the employee Name TextField is empty then default it to the first name in the employeeList
    
    [pickerViewJobCode selectRow:pos inComponent:0 animated:YES];
    
    */
#ifdef IPAD_VERSION
    
    [pickerViewDate addSubview:pickerViewJobCode];
    popoverContent.view = pickerViewDate;
    popoverContent.modalPresentationStyle = UIModalPresentationPopover;
    popoverContent.preferredContentSize = CGSizeMake(350, 250); //self.parentViewController.childViewControllers.lastObject.preferredContentSize.height-100);
    //popoverContent.popoverPresentationController.sourceView = _scrollView;
    popoverContent.popoverPresentationController.sourceRect = _jobCodeTextField.superview.frame;
    [self presentViewController:popoverContent animated:YES completion:nil];
#else
//    [pickerViewDate addSubview:pickerToolbar];
//    [pickerViewDate addSubview:pickerViewJobCode];
//    [self.view addSubview:pickerViewDate];
    
    UINavigationController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"jobCodeList"];
    JobCodeListViewController * controller = viewController.viewControllers.firstObject;
    controller.delegate = self;
    [self presentViewController:viewController animated:YES completion:nil];
    
    
#endif
    
    
}

- (void)searchJobCode:(NSDictionary *)jobCodeObj {
    
    if (self.clockInBtn.alpha == 1) {
         [self enableButton:clockInBtn];
         [self disableButton:clockOutBtn];
 //       NSLog(@"BUtton in : ", self.clockOutBtn.titleLabel.text);
     }
     else {
         [self disableButton:clockInBtn];
         [self enableButton:clockOutBtn];
 //        NSLog(@"BUtton out : ", self.clockOutBtn.titleLabel.text);
     }
    
    _jobCodeTextField.text = [jobCodeObj valueForKey:@"name"];
    selectedJobCode = jobCodeObj;
    //if clock out button is enabled then that means we are in active clock in and we need to update the selected job code on the server
#ifdef PERSONAL_VERSION
    if (clockOutBtn.enabled)
        [self assignSelectedJobCode ];
#else
    if (clockOutBtn.enabled)
        [self assignSelectedJobCode];
    else
        [self doClockInSteps];
#endif
}

-(IBAction)jobCodePickerDoneClick{
    NSInteger row = [pickerViewJobCode selectedRowInComponent:0];
    
    // [_employeeButton setTitle:[employeeList objectAtIndex:row] forState:UIControlStateNormal];
    NSDictionary *jobCodeObj = [jobCodesList objectAtIndex:row];
    _jobCodeTextField.text = [jobCodeObj valueForKey:@"name"];
    selectedJobCode = [jobCodesList objectAtIndex:row];

    [self closeJobCodePicker:self];
    
    //the first itme is None so we don't want to send that to the server
//    if (row > 0)
    if (clockOutBtn.enabled)
        [self assignSelectedJobCode ];
}

-(BOOL)closeJobCodePicker:(id)sender{
    [pickerViewJobCode removeFromSuperview];
    [pickerViewDate removeFromSuperview];
    return YES;
}

-(IBAction)EmployeePickerCancelClick{
    [self closeJobCodePicker:self];
}

#pragma mark -
#pragma mark Picker Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [jobCodesList count];
 }

#pragma mark Picker Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSDictionary *jobCodeObj = [jobCodesList objectAtIndex:row];
    NSString *name = [jobCodeObj valueForKey:@"name"];
    
    return name;
}

-(void) callModifyTimeEntryWebService{
    //NSString *currentDateTime = self.getCurrentDateTime;
    
    DataManager* manager = [DataManager sharedManager];
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        
        NSError* error = nil;
        __timeEntry = [manager fetchMostRecentTimeEntry:&error];
        _timeEntryObjectID = self.timeEntry.objectID;
        
        
        //        [SharedUICode messageBox:nil message:@"There was an issue with the Time Entry." withCompletion:^{
        //            return;
        //        }];
    }
    
    NSString *selectedJobCodeId = [selectedJobCode valueForKey:@"id"];
    
    NSDate* clockInDateValue = __timeEntry.clockIn.dateTimeEntry;
    
    NSDate* clockOutDateValue = __timeEntry.clockOut.dateTimeEntry;
    if (__timeEntry == nil) {
        return;
    }
    [self startSpinnerWithMessage:@"Connecting to Server.."];
    
    NSString *notes = self.notesTextView.text;
    
    if ([NSString isNilOrEmpty:notes]) {
        notes = nil;
    }
    
    [manager modifyTimeEntryOnServer:__timeEntry clockIn:clockInDateValue clockOut:clockOutDateValue notes:notes jobCodeId: selectedJobCodeId partialTimeEntry: @"NO" withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
        
        [self stopSpinner];
        
        if (nil != results) { // If we had changed the date of the time entry that means it was moved so we need to check to see if the _timeEntryObjectID is different and update
            TimeEntry* timeEntry = [results objectForKey:ktimeEntryKey];
            NSManagedObjectID *obj1 = self.timeEntryObjectID;
            NSManagedObjectID *obj2 = timeEntry.objectID;
            if ((nil != timeEntry) && ![obj1 isEqual:obj2])
            {
                self.timeEntryObjectID = timeEntry.objectID;
//                NSLog(@"timeEntryObjectID : ",self.timeEntryObjectID);
            }
//            if (nil != timeEntry && ![self.timeEntryObjectID isEquals:timeEntry.objectID]) {
//                self.timeEntryObjectID = timeEntry.objectID;
//            }
        }

        switch (errorCode) {
            case DATAMANAGER_BUSY: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:DATAMANAGER_BUSY description:@"DATAMANAGER_BUSY" error: error];
                [SharedUICode displayServerIsBusy];
                break;
            }
            case SERVICE_UNAVAILABLE_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_UNAVAILABLE_ERROR description:@"SERVICE_UNAVAILABLE_ERROR" error: error];
                [SharedUICode displayServiceUnavailableErrorWithMsg:@"NOTE: You can continue to modify time entries and we will save to the server later." withCompletion:^{
                    [DataManager postDataWasModifiedNotification];
  //                  [self.delegate saveTimeEntryDidFinish:self];
                }];
                break;
            }
            case SERVICE_ERRORCODE_UNKNOWN_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_UNKNOWN_ERROR description:@"SERVICE_ERRORCODE_UNKNOWN_ERROR" error: error];
                [SharedUICode checkResultsMessageAndDisplayError:resultMessage error:error];
//[self showDatePicker];
                break;
            }
            case SERVICE_ERRORCODE_SUCCESSFUL: {
                [DataManager postDataWasModifiedNotification];
              //  [self updateUserClockInClockOut];
               // [self.delegate saveTimeEntryDidFinish:self];
                break;
            }
            default: {
#ifndef RELEASE
                DEBUG_MSG
                NSLog(@"Unhandled errorCode: %ld %@ %@", (long)errorCode, msg, error.localizedDescription);
#endif
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:UNKNOWN_ERROR description:@"UNKNOWN_ERROR" error: error];
                break;
            }
        }
    }];


}
-(void) assignSelectedJobCode
{
    //if we are offline don't call the server API to save the data
    BOOL bIsReachable = [CommonLib DoWeHaveNetworkConnection];
    if (bIsReachable)
        [self callModifyTimeEntryWebService];
    
 }

/*-(void) assignSelectedJobCode
{
    
    int mode = 1;

    [self callTagMapsAPI:mode withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue saving the job code. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        //           [self.delegate JobCodeDetailsDidFinish:self CancelWasSelected:NO];
        
    }];
}
 */

-(void) callTagMapsAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    
    
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    
    //   if (flag == ADD_JOBCODE)
    //   {
    httpPostString = [NSString stringWithFormat:@"%@api/v1/datatagmaps", SERVER_URL];
    //  }
    /*  else
     {
     NSString *jobCodeId = [_jobCodeDetails valueForKey:@"id"];
     httpPostString = [NSString stringWithFormat:@"%@api/v1/datatagmaps/%@", SERVER_URL, jobCodeId];
     }
     */
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSError *error;
    
    NSString *jobCodeId = [selectedJobCode valueForKey:@"id"];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *employeeId = [user.userID stringValue];;
    NSString *timeEntryId =  [user.activeTimeEntryId stringValue];
    
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 jobCodeId, @"dataTagId",
                                 employeeId, @"employeeId",
                                 timeEntryId, @"timeEntryId",
                                 nil];
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    //set request body into HTTPBody.
    urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    [urlRequest setHTTPMethod:@"POST"];
    
    // if (flag == ADD_JOBCODE)
    //    [urlRequest setHTTPMethod:@"POST"];
    //else
    //   [urlRequest setHTTPMethod:@"PUT"];
    
    //for archive do a post
    
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
BOOL isEndBreak;

- (void)breakScreenDone;
{
    isEndBreak = true;
    isBreakScreenShowing = false;
    [self doBreakOutSteps];
}

@end
