//
//  CommonLib.m
//  TCS Mobile
//
//  Created by Raya Khashab on 7/21/12.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "CommonLib.h"
#import "Reachability.h"
#import "user.h"
#import <sys/utsname.h>
#import "TimeEntry.h"
#import "coredatadefines.h"
#import "threaddefines.h"
#import "TimeEntry+Extensions.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "PushNotificationManager.h"
#import "DataManager.h"
#import "AppDelegate.h"

@implementation CommonLib


+ (NSString*)errorMsg:(NSInteger)errorCode {
    switch(errorCode) {
        case SERVICE_UNAVAILABLE_ERROR:
            return @"Service is unavailable.  No internet connection.";
        case DATAMANAGER_BUSY:
            return @"Busy, please wait...";
        case DATAMANAGER_EMPLOYEE_NOT_SET:
            return @"No employee has been selected to work with.";
        case DATAMANAGER_NO_PENDING_UPDATES:
            return @"No pending updates exist.";
        case SERVICE_ERRORCODE_SUCCESSFUL:
            return @"Successful";
        case SERVICE_ERRORCODE_SUCCESSFUL_NOTHING_TO_DO:
            return @"It was successful but nothing to do.";
        case SERVICE_ERRORCODE_ALREADY_CLOCKED_IN:
            return @"Already clocked in.";
        case SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT:
            return @"Already clocked out.";
        case SERVICE_ERRORCODE_ALREADY_BREAKED_IN:
            return @"Already breaked in.";
        case SERVICE_ERRORCODE_ALREADY_BREAKED_OUT:
            return @"Already breaked out.";
        case WEB_SERVICE_OUT_OF_RANGE_ERROR:
            return @"Web service is out of range.";
        case WEB_SERVICE_ACCOUNT_EXIST_ERROR:
            return @"Web service account exist error.";
        default:
            return @"Unknown Error.";
    }
}


- (NSString *) loginFilePath
{
    NSArray *path =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    return [[path objectAtIndex:0] stringByAppendingPathComponent:@"savefile.plist"];
    
}


+(BOOL)isVersion6AndBelow{
    
    return floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1;
}

+(BOOL)isProduction{
    NSString *url = SERVER_URL;
    if ([url isEqualToString:@"https://ezclocker.com/" ])
        return YES;
    else
        return NO;
}

+(BOOL)userIsManager
{
    BOOL result = FALSE;
    UserClass *user = [UserClass getInstance];
    if ((user.userAuthorities != nil) && (([user.userAuthorities containsObject:@"ROLE_MANAGER"]) || ([user.userAuthorities containsObject:@"ROLE_PAYROLL_MANAGER"])))
        result = TRUE;
    return result;
}

+(BOOL)userHasPayrollPermission
{
    BOOL result = FALSE;
    UserClass *user = [UserClass getInstance];
    if (([user.userType isEqualToString:@"employer"]) || ((user.userAuthorities != nil) && ([user.userAuthorities containsObject:@"ROLE_PAYROLL_MANAGER"])))
        result = TRUE;
    return result;
}


+(void)logEvent: (NSString*)message {
    
#ifdef DEBUG
#else
    // Set userId
    UserClass *user = [UserClass getInstance];
    [[Amplitude instance] setUserId: [user.realUserId stringValue]];
    // Log an event
    [[Amplitude instance] logEvent:message];
#endif
    
}

+(void) setIndustryProperty: (NSString*)industry {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    [eventProperties setValue:industry forKey:@"industryType"];
    [[Amplitude instance] logEvent:@"signup" withEventProperties:eventProperties];
}

+(BOOL) DoWeHaveNetworkConnection
{
    @synchronized(self) {
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        
        NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
        if (networkStatus == NotReachable) {
            return NO;
            
        } else {
            return YES;
        }
    }
}

+ (BOOL)validateEmail:(NSString *)emailStr {
    bool isValid = true;
    //test for empty emails
    if (emailStr.length == 0)
        isValid = false;
    else{
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,12}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if  ([emailTest evaluateWithObject:emailStr] != YES && [emailStr length]!=0)
            isValid = false;
        //test for whiteoaksoll@browart23
        //test for me@gmail..com or me@gmail.con errors
        else
        {
            if (([emailStr containsString:@".."]) || ([emailStr containsString:@"@."]) || ([emailStr hasSuffix:@".con"]))
                    isValid = false;
        }
        
    }
    return isValid;
}

+ (BOOL)validatePhoneNumber:(NSString *)phoneStr {
    bool isValid = true;
    //test for empty emails
    if (phoneStr.length == 0)
        isValid = false;
    else{
        //this one does xxxxxxxxxx
        NSString *phoneRegex1 = @"[23456789][0-9]{6}([0-9]{3})?";
        //this one does xxx-xxx-xxxx
        NSString *phoneRegex2 = @"^[0-9]{3}-[0-9]{3}-[0-9]{4}$";
        //this one does xxx.xxx.xxxx
        NSString *phoneRegex3 = @"^[0-9]{3}.[0-9]{3}.[0-9]{4}$";
        //this one does (xxx)xxx-xxxx
        NSString *phoneRegex4 = @"^(\\([0-9]{3})\\)[0-9]{3}-[0-9]{4}$";
        NSPredicate *phoneTest1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex1];
        NSPredicate *phoneTest2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex2];
        NSPredicate *phoneTest3 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex3];
        NSPredicate *phoneTest4 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex4];

        //check for phone number first then email
        if  (([phoneTest1 evaluateWithObject:phoneStr] != YES) && ([phoneTest2 evaluateWithObject:phoneStr] != YES) && ([phoneTest3 evaluateWithObject:phoneStr] != YES) && ([phoneTest4 evaluateWithObject:phoneStr] != YES) && [phoneStr length]!=0)
        {
            isValid = false;
        }
    }
    return isValid;
}

+ (BOOL)validateEmailOrPhoneNumber:(NSString *)userNameStr {
    bool isValid = true;
    //test for empty emails
    if (userNameStr.length == 0)
        isValid = false;
    else{
        //this one does xxxxxxxxxx
        NSString *phoneRegex1 = @"[23456789][0-9]{6}([0-9]{3})?";
        //this one does xxx-xxx-xxxx
        NSString *phoneRegex2 = @"^[0-9]{3}-[0-9]{3}-[0-9]{4}$";
        //this one does xxx.xxx.xxxx
        NSString *phoneRegex3 = @"^[0-9]{3}.[0-9]{3}.[0-9]{4}$";
        //this one does (xxx)xxx-xxxx
        NSString *phoneRegex4 = @"^(\\([0-9]{3})\\)[0-9]{3}-[0-9]{4}$";
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,12}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        NSPredicate *phoneTest1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex1];
        NSPredicate *phoneTest2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex2];
        NSPredicate *phoneTest3 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex3];
        NSPredicate *phoneTest4 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex4];

        //check for phone number first then email
        if  (([phoneTest1 evaluateWithObject:userNameStr] != YES) && ([phoneTest2 evaluateWithObject:userNameStr] != YES) && ([phoneTest3 evaluateWithObject:userNameStr] != YES) && ([phoneTest4 evaluateWithObject:userNameStr] != YES) && [userNameStr length]!=0)
        {
            if  ([emailTest evaluateWithObject:userNameStr] != YES && [userNameStr length]!=0)
            isValid = false;
            //test for whiteoaksoll@browart23
            //test for me@gmail..com or me@gmail.con errors
            else
            {
                if (([userNameStr containsString:@".."]) || ([userNameStr containsString:@"@."]) || ([userNameStr hasSuffix:@".con"]))
                    isValid = false;
            }
        }
    }
    return isValid;
}
+ (BOOL) isAdminAccount: (NSNumber*) userId
{
    if ([userId intValue] == ADMIN_USERID)
        return true;
    else
        return false;
}

+ (NSString *)accuracyString:(double)num
{
    //both kAccuracyGood and kAccuracyModerate should appear as 'good'
    if (num < kAccuracyModerate) {
        return @"Good";
    } else {
        return @"Poor";
    }
}

+ (UIImage *)accuracyIcon:(double)num
{
    if (num < kAccuracyGood) {
        return [UIImage imageNamed:@"signalGood.png"];
    } else if (num < kAccuracyModerate) {
        return [UIImage imageNamed:@"signalMedium.png"];
    } else {
        return [UIImage imageNamed:@"signalBad.png"];
    }
}


+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate = nil;
    NSDate *toDate = nil;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

+(NSString*)remaningTime:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSDateComponents *components;
    NSInteger days;
    NSInteger hour;
    NSInteger minutes;
    NSString *durationString;

    components = [[NSCalendar currentCalendar] components: NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate: startDate toDate: endDate options: 0];

    days = [components day];
    hour = [components hour];
    minutes = [components minute];

    if(days>0)
    {
        if(days>1)
            durationString=[NSString stringWithFormat:@"%ld days",(long)days];
        else
            durationString=[NSString stringWithFormat:@"%ld day",(long)days];
        return durationString;
    }
    if(hour>0)
    {
        if(hour>1)
            durationString=[NSString stringWithFormat:@"%ld hours",(long)hour];
        else
            durationString=[NSString stringWithFormat:@"%ld hour",(long)hour];
        return durationString;
    }
    if(minutes>0)
    {
        if(minutes>1)
            durationString = [NSString stringWithFormat:@"%ld minutes",(long)minutes];
        else
            durationString = [NSString stringWithFormat:@"%ld minute",(long)minutes];

        return durationString;
    }
    return @"";
}

static UIColor* hatchedBackColor = nil;

+ (UIColor*)getHatchedBackColor {
    if (nil == hatchedBackColor) {
//        UIImage* backImage = [UIImage imageNamed:@"HatchedColor.png"];
//        hatchedBackColor = [[UIColor alloc] initWithPatternImage:backImage];
        hatchedBackColor = UIColorFromRGB(LIGHT_RED_COLOR);
    }
    return hatchedBackColor;
}

//got from https://www.theiphonewiki.com/wiki/Models
+ (NSString*) getDeviceName
{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    
    static NSDictionary* deviceNamesByCode = nil;
    
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{@"i386"      :@"Simulator",
                              @"x86_64"    :@"Simulator",
                              @"iPod1,1"   :@"iPod Touch",        // (Original)
                              @"iPod2,1"   :@"iPod Touch",        // (Second Generation)
                              @"iPod3,1"   :@"iPod Touch",        // (Third Generation)
                              @"iPod4,1"   :@"iPod Touch",        // (Fourth Generation)
                              @"iPod7,1"   :@"iPod Touch",        // (6th Generation)
                              @"iPhone1,1" :@"iPhone",            // (Original)
                              @"iPhone1,2" :@"iPhone",            // (3G)
                              @"iPhone2,1" :@"iPhone",            // (3GS)
                              @"iPad1,1"   :@"iPad",              // (Original)
                              @"iPad2,1"   :@"iPad 2",            //
                              @"iPad3,1"   :@"iPad",              // (3rd Generation)
                              @"iPhone3,1" :@"iPhone 4",          // (GSM)
                              @"iPhone3,3" :@"iPhone 4",          // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" :@"iPhone 4S",         //
                              @"iPhone5,1" :@"iPhone 5",          // (model A1428, AT&T/Canada)
                              @"iPhone5,2" :@"iPhone 5",          // (model A1429, everything else)
                              @"iPad3,4"   :@"iPad",              // (4th Generation)
                              @"iPad2,5"   :@"iPad Mini",         // (Original)
                              @"iPad2,6"   :@"iPad Mini",         // (Original)
                              @"iPad2,7"   :@"iPad Mini",         // (Original)
                              @"iPhone5,3" :@"iPhone 5c",         // (model A1456, A1532 | GSM)
                              @"iPhone5,4" :@"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" :@"iPhone 5s",         // (model A1433, A1533 | GSM)
                              @"iPhone6,2" :@"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" :@"iPhone 6 Plus",     //
                              @"iPhone7,2" :@"iPhone 6",          //
                              @"iPhone8,1" :@"iPhone 6S",         //
                              @"iPhone8,2" :@"iPhone 6S Plus",    //
                              @"iPhone8,4" :@"iPhone SE",         //
                              @"iPhone9,1" :@"iPhone 7",          //
                              @"iPhone9,3" :@"iPhone 7",          //
                              @"iPhone9,2" :@"iPhone 7 Plus",     //
                              @"iPhone9,4" :@"iPhone 7 Plus",     //
                              @"iPhone10,1" :@"iPhone 8",     
                              @"iPhone10,4" :@"iPhone 8",
                              @"iPhone10,2" :@"iPhone 8 Plus",
                              @"iPhone10,5" :@"iPhone 8 Plus",
                              @"iPhone10,3" :@"iPhone X",
                              @"iPhone10,6" :@"iPhone X",
                              @"iPhone11,2" :@"iPhone XS",
                              @"iPhone11,8" :@"iPhone XR",
                              @"iPhone11,6" :@"iPhone XS Max",

                              @"iPad4,1"   :@"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   :@"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   :@"iPad Mini 2",         // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   :@"iPad Mini 2",         // (2nd Generation iPad Mini - Cellular)
                              @"iPad4,6"   :@"iPad Mini 2",
                              @"iPad4,7"   :@"iPad Mini 3",         // (3rd Generation iPad Mini - Wifi (model A1599))
                              @"iPad4,8"   :@"iPad Mini 3",
                              @"iPad4,9"   :@"iPad Mini 3",
                              
                              @"iPad5,1"   :@"iPad Mini 4",
                              @"iPad5,2"   :@"iPad Mini 4",

                              @"iPad6,7"   :@"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584)
                              @"iPad6,8"   :@"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652)
                              @"iPad6,3"   :@"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
                              @"iPad6,4"   :@"iPad Pro (9.7\")",   // iPad Pro 9.7 inches - (models A1674 and A1675)
                              @"iPad6,11"  :@"iPad (2017)",
                              @"iPad6,12"  :@"iPad (2017)",
                              @"iPad7,1"   :@"iPad Pro 2G",
                              @"iPad7,2"   :@"iPad Pro 2G",
                              @"iPad7,3"   :@"iPad Pro 10.5-inch",
                              @"iPad7,4"   :@"iPad Pro 10.5-inch",
                              @"iPad7,5"   :@"iPad (6th generation)",
                              @"iPad7,6"   :@"iPad (6th generation)",
                              
                              @"iPad8,1"   :@"iPad Pro (11-inch)",
                              @"iPad8,2"   :@"iPad Pro (11-inch)",
                              @"iPad8,3"   :@"iPad Pro (11-inch)",
                              @"iPad8,4"   :@"iPad Pro (11-inch)",
                              
                              @"iPad8,5"   :@"iPad Pro (12.9-inch) (3rd generation)",
                              @"iPad8,6"   :@"iPad Pro (12.9-inch) (3rd generation)",
                              @"iPad8,7"   :@"iPad Pro (12.9-inch) (3rd generation)",
                              @"iPad8,8"   :@"iPad Pro (12.9-inch) (3rd generation)",
                              
                              @"iPad11,1"   :@"iPad mini (5th generation)",
                              @"iPad11,2"   :@"iPad mini (5th generation)",

                              @"iPad11,3"   :@"iPad Air (3rd generation)",
                              @"iPad11,4"   :@"iPad Air (3rd generation)"

                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
        else {
            deviceName = @"Unknown";
        }
    }
    
    return deviceName;
}

+(NSString*) earlyClockInShortDescription:(int)selectedOption
{
    NSString* description;

    if (selectedOption == 0)
    {
        description = @"At scheduled time";
    }
    else if (selectedOption == 5)
    {
        description = @"5 mins";
    }
    else if (selectedOption == 10)
    {
        description = @"10 mins";
    }
    else if (selectedOption == 15)
    {
        description = @"15 mins";
    }
    else if (selectedOption == 30)
    {
        description = @"30 mins";
    }
    else
        description = @"OFF";

    return description;
}

+(NSString*) roundingTimeClockDescription:(int)selectedOption
{
    NSString* description;
    if (selectedOption == 0)
    {
        description = @"OFF";

    }
    else if (selectedOption == 1)
    {
        description = @"5 mins";
    }
    else if (selectedOption == 2)
    {
        description = @"6 mins";
    }
    else if (selectedOption == 3)
    {
        description = @"15 mins";
    }
    else
        description = @"OFF";

    return description;
}

+(NSString*) getDayOfTheWeek:(int)selectedDay
{
    NSString *dayOftheWeek;
    switch (selectedDay) {
        case 0:
            dayOftheWeek = @"Sunday";
            break;
        case 1:
            dayOftheWeek = @"Monday";
            break;
        case 2:
            dayOftheWeek = @"Tuesday";
            break;
        case 3:
            dayOftheWeek = @"Wednesday";
            break;
        case 4:
            dayOftheWeek = @"Thursday";
            break;
        case 5:
            dayOftheWeek = @"Friday";
            break;
        case 6:
            dayOftheWeek = @"Saturday";
            break;
        default:
            dayOftheWeek = @"Sunday";
    }
    return dayOftheWeek;

}

+(void) signOutCompletely:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
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
//        [ErrorLogging logError:error];
#endif
    }
    [DataManager closeManager];
    
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
    
    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);

}

+(void) callJobCodesAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{

    
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    NSString *employeeID = [user.userID stringValue];
    // NSString *request_body;
    
   // NSString *employeeID = [_employeeDetails valueForKey:@"ID"];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/employee/%@/datatags", SERVER_URL, employeeID];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
      
    [urlRequest setHTTPMethod:@"GET"];
 
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *tmpEmployerID = [user.employerID stringValue];
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

NSString const *UNKNOWN = @"UNKNOWN";
NSString const *DATA_TAG_TYPE_RATE = @"RATE";
NSString const *DATA_TAG_TYPE_HOURLY = @"HOURLY";
NSString const *DATA_TAG_TYPE_BILLABLE_AMOUNT = @"BILLABLE_AMOUNT";
NSString const *DATA_TAG_TYPE_NON_BILLABLE_AMOUNT = @"NON_BILLABLE_AMOUNT";
NSString const *DATA_TAG_TYPE_FLAT_FEE = @"FLAT_FEE";
NSString const *DATA_TAG_TYPE_TIME_MATERIALS_CUSTOMER_HOURLY_RATE = @"TIME_MATERIALS_CUSTOMER_HOURLY_RATE";
NSString const *DATA_TAG_TYPE_TIME_MATERIALS_CUSTOMER_PERSON_RATE = @"TIME_MATERIALS_CUSTOMER_PERSON_RATE";
NSString const *DATA_TAG_TYPE_TIME_MATERIALS_CUSTOMER_TASK_RATE = @"TIME_MATERIALS_CUSTOMER_TASK_RATE";

NSString const *PASSCODE_SYMBOL = @"•";

int const EZCLOCKER_BLUE_COLOR = 0x2419b2;

int const ORANGE_COLOR = 0xFF9900;
int const LOGO_ORANGE_COLOR = 0xF68C2B;
int const DARK_ORANGE_COLOR = 0xB26218;
//int const GRAY_BACKGROUND_COLOR = 0xDCDCDC;
//this one seems the sam
//int const GRAY_BACKGROUND_COLOR = 0xE9E9E9;
int const GRAY_TEXT_COLOR = 0x808080;
int const GRAY_BACKGROUND_COLOR = 0xF1F1F1;
int const GRAY_BACKGROUND_DARK_COLOR = 0xDCDCDC;

int const GREEN_CLOCKEDIN_COLOR = 0x58B100;

int const BLUE_TOOLBAR_COLOR = 0x63a8cc;
int const NAVY_WEBSITE_COLOR = 0xF4777;
int const GRAY_WEBSITE_COLOR = 0x6d6e70;

//int const BABY_BLUE_COLOR = 0x6599FF;
int const BABY_BLUE_COLOR = 0x66CCFF;

int const BREAK_BLUE_COLOR = 0x00aeec;

int const BUTTON_BLUE_COLOR = 0x007AFF;

int const LIGHT_RED_COLOR = 0xdd7e6b;//0xCC4125;


//int const BABY_BLUE_COLOR = 0x34BFF3;

+(bool) onFreePlan
{
    UserClass *user = [UserClass getInstance];
    bool isOnFreePlan = true;
        isOnFreePlan = (![NSString isNilOrEmpty:user.subscription_planProvider]) && [user.subscription_planProvider isEqualToString:@"EZCLOCKER_SUBSCRIPTION"];
    return isOnFreePlan;
}

@end
