//
//  CommonLib.h
//  TCS Mobile
//
//  Created by Raya Khashab on 7/21/12.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "TimeEntry.h"
#import "NSData+Extensions.h"
#import <Amplitude/Amplitude.h>

typedef enum {
	ClockModeIn = 0,
	ClockModeOut = 1,
    BreakModeIn = 2,
    BreakModeOut = 3
} ClockMode;

typedef enum {
    Feedback_None = -1,
    EnjoyingEzClokcer_dlg = 0,
    CanYouRateUs_dlg = 1,
    GiveUsFeedback_dlg = 2,
} RatingDialogType;

#define TIME_OUT_REQUEST 60 //in seconds
#define keyboardHeight @"keyboardHeight"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#define SERVICE_UNAVAILABLE_ERROR 503
#define SERVICE_FORBIDEN_ERROR 403
#define SERVICE_ACCESSDENIED_ERROR 401
#define UNKNOWN_ERROR -999

#define DATAMANAGER_BUSY -1001
#define DATAMANAGER_EMPLOYEE_NOT_SET -1002
#define DATAMANAGER_NO_PENDING_UPDATES -1003

#define SERVICE_ERRORCODE_SUCCESSFUL 0
#define SERVICE_ERRORCODE_SUCCESSFUL_NOTHING_TO_DO -1
#define SERVICE_ERRORCODE_ALREADY_CLOCKED_IN 1
#define SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT 2
#define SERVICE_ERRORCODE_ALREADY_BREAKED_IN 40
#define SERVICE_ERRORCODE_ALREADY_BREAKED_OUT 41
#define SERVICE_ERRORCODE_UNKNOWN_ERROR 3
#define SERVICE_ERRORCODE_EARLYCLOCKIN 6000
#define SERVICE_KNOWN_ERRORCODE_MIN 6000
#define SERVICE_KNOWN_ERRORCODE_MAX 9999

#define WEB_SERVICE_OUT_OF_RANGE_ERROR 6
//#define WEB_SERVICE_ACCOUNT_EXIST_ERROR 8
#define WEB_SERVICE_ACCOUNT_EXIST_ERROR 88
//#define SERVICE_ERRORCODE_TEAM_PIN_EXIST 400

#define SERVICE_ERRORCODE_TEAM_PIN_ALREADY_EXIST 19

#define SERVICE_ERRORCODE_EMPLOYEE_DOES_NOT_EXIST 404

#define DISABLE_LOCATION_REMINDER_DIALOG_KEY @"DISABLE_LOCATION_REMINDER_DIALOG_KEY"
#define ALERT_DELETE_ACTION 1

#define MAX_TIMES_APP_LAUNCHED 10

//this is production user Id for support@ezclocker.com but it's ok since we don't care about dev admin
#define ADMIN_USERID 21459


#define EMPLOYER_USER_TYPE @"employer"
#define EMPLOYEE_USER_TYPE @"employe"
#define TEAM_USER_TYPE  @"team"

//data tags constants
extern NSString const *DATA_TAG_TYPE_UNKNOWN;
extern NSString const *DATA_TAG_TYPE_RATE;
extern NSString const *DATA_TAG_TYPE_HOURLY;
extern NSString const *DATA_TAG_TYPE_BILLABLE_AMOUNT;
extern NSString const *DATA_TAG_TYPE_NON_BILLABLE_AMOUNT;
extern NSString const *DATA_TAG_TYPE_FLAT_FEE;
extern NSString const *DATA_TAG_TYPE_TIME_MATERIALS_CUSTOMER_HOURLY_RATE;
extern NSString const *DATA_TAG_TYPE_TIME_MATERIALS_CUSTOMER_PERSON_RATE;
extern NSString const *DATA_TAG_TYPE_TIME_MATERIALS_CUSTOMER_TASK_RATE;

//use these to notify the timesheetdetail controller if we are modifying active clock ins or outs
//so the screen can hide some controls or display a message when users try to add a clock out in an active clock in situation
#define NON_ACTIVE_CLOCK 0
#define ACTIVE_CLOCKIN  1
#define ACTIVE_CLOCKOUT 2
#define EDIT_ACTIVE_CLOCK 3

//this sets what is considered a 'good', bad, etc. accuracy for the EmployeeClockViewController GPS signal indicator.
//note that good is less than kAccuracyGood, moderate is any value between kAccuracyGood to kAccuracyModerate, and bad is anything above the kAccuracyModerate value
#define kAccuracyGood 70.0
#define kAccuracyModerate 120.0

#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad

extern NSString const *PASSCODE_SYMBOL;

extern int const BLUE_TOOLBAR_COLOR;

extern int const NAVY_WEBSITE_COLOR;

extern int const GRAY_TEXT_COLOR;

extern int const GRAY_BACKGROUND_COLOR;

extern int const GRAY_BACKGROUND_DARK_COLOR;

extern int const GREEN_CLOCKEDIN_COLOR;

extern int const ORANGE_COLOR;

extern int const LOGO_ORANGE_COLOR;

extern int const BABY_BLUE_COLOR;

extern int const BUTTON_BLUE_COLOR;

extern int const BREAK_BLUE_COLOR;

extern int const LIGHT_RED_COLOR;

extern int const EZCLOCKER_BLUE_COLOR;

extern int const DARK_ORANGE_COLOR;

extern int const GRAY_WEBSITE_COLOR;

@interface CommonLib : NSObject

+(BOOL)isProduction;

+(void)logEvent: (NSString*)message;

+(void) setIndustryProperty: (NSString*)industry;

+(BOOL)DoWeHaveNetworkConnection;

+ (BOOL)validateEmail:(NSString *)emailStr;

+ (BOOL)validatePhoneNumber:(NSString *)phoneStr;

+ (BOOL)validateEmailOrPhoneNumber:(NSString *)userNameStr;

+ (BOOL) onFreePlan;

+ (BOOL) isAdminAccount: (NSNumber*) userId;

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

+(NSString*)remaningTime:(NSDate*)startDate endDate:(NSDate*)endDate;

+ (NSString*)errorMsg:(NSInteger)errorCode;

+ (UIColor*)getHatchedBackColor;

+ (NSString*) getDeviceName;

+(NSString*) earlyClockInShortDescription:(int)selectedOption;

+(NSString*) roundingTimeClockDescription:(int)selectedOption;

+ (UIImage *)accuracyIcon:(double)num;

+ (NSString *)accuracyString:(double)num;

+(NSString*) getDayOfTheWeek:(int)selectedDay;

+(void) signOutCompletely:(int)flag withCompletion:(ServerResponseCompletionBlock)completion;

+(BOOL) userIsManager;

+(BOOL)userHasPayrollPermission;

+(void) callJobCodesAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion;


#define CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(CLOCK_IN_OUT_STR) \
DataManager* manager = [DataManager sharedManager]; \
NSError* error = nil; \
NSInteger __block count = [manager doesCurrentEmployeeNeedingSubmission:&error]; \
if (count > 0) { \
if ([CommonLib DoWeHaveNetworkConnection]) { \
if (manager.isBackgroundProcessing) { \
NSString* msg = [NSString stringWithFormat:@"Pending Updates are currently syncing to the server.  Please try %@ later.", CLOCK_IN_OUT_STR]; \
[SharedUICode messageBox:nil message:msg withCompletion:nil]; \
return; \
} \
if (manager.isBusy) { \
NSString* msg = [NSString stringWithFormat:@"Please wait for process to finish and try %@ later.", CLOCK_IN_OUT_STR]; \
[SharedUICode messageBox:nil message:msg withCompletion:nil]; \
return; \
} \
[self startSpinnerWithMessage:@"Syncing, please wait..."]; \
[manager forceSyncWithCompletion:^(UIBackgroundFetchResult result, NSInteger errorCode, NSError * _Nullable error) { \
[self stopSpinner]; \
if (errorCode != SERVICE_ERRORCODE_SUCCESSFUL) { \
NSString* msg = [NSString stringWithFormat:@"There was an error Syncing Pending Changes.  Please try %@ later.", CLOCK_IN_OUT_STR]; \
[SharedUICode messageBox:nil message:msg withCompletion:nil]; \
return; \
} else { \
count = [manager doesCurrentEmployeeNeedingSubmission:&error]; \
if (count > 0) { \
[SharedUICode displayPendingUpdates]; \
return; \
} \
} \
}]; \
return; \
} \
} \
if ([manager isBusy]) { \
[SharedUICode displayServerIsBusy]; \
return; \
}

@end
