//
//  user.m
//  TCS Mobile
//
//  Created by Raya Khashab on 9/2/12.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "user.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"


@implementation UserClass

//there are 2 userIDs because userID is an old way of doing things while realUserId is the one that is in the database as userId
@synthesize employerID, userID, realUserId, userType, userAuthorities, authToken, currentClockMode, lastClockIn, lastClockOut, userPin, employerName, employeeName,
            remindersSet, userEmail, availableEmployeeSlots,
subscription_PlanPrice, subscription_PlanExpireDate, subscription_planStartDate, subscription_IsValid,  userGaveUsRatingFeedback, appLaunchCounter, subscription_freePlanActive, subscription_HasActivePaidPlan, clockInReminders, clockOutReminders, employeeCount, payrollStartDate, payrollEndDate, lastEmailToSent, disableTimeEntryEditing, requireLocationForClockInOut, pushNotificationsEnabled, customerNameIDList;

static UserClass *instance = nil;

+(UserClass*)getInstance{
    if (instance == nil)
    {
        instance = [UserClass new];
        instance.employerLocation = [[EmployerLocation alloc] init];
        instance.subscription_planStartDate = @"";
        instance.subscription_PlanExpireDate = @"";
        instance.clockInReminders = [[NSMutableArray alloc] init];
        instance.clockOutReminders = [[NSMutableArray alloc] init];
        instance.userAuthorities = [[NSMutableArray alloc] init];
        instance.employeeNameIDList = [[NSMutableDictionary alloc] init];
        instance.employeeList = [[NSMutableArray alloc] init];
        instance.jobCodesList = [[NSMutableArray alloc] init];
        instance.employeePermissions = [[NSMutableDictionary alloc] init];
        instance.employerOptions = [[NSMutableDictionary alloc] init];
        instance.locationNameAddressList = [[NSMutableArray alloc] init];
        instance.customerNameIDList = [[NSMutableArray alloc] init];
        
    }
    return instance;
}


- (void)checkPayrollStartDate:(id<StartEndDateInterface>)datesInterface {
    NSString* testPayrollStartDate = [NSString trim:self.payrollStartDate];
    NSString* testPayrollEndDate = [NSString trim:self.payrollEndDate];
    
    if (!([NSString isNilOrEmpty:testPayrollStartDate] && [NSString isNilOrEmpty:testPayrollEndDate]))
    {
        return;
    }
    
    NSTimeInterval secondsPerDay = 24 * 60 * 60;
    NSDate *today = [NSDate date];
    NSDate *oneWeek;
    
    oneWeek = [today dateByAddingTimeInterval: secondsPerDay * 7];
    self.payrollStartDate =[today toDefaultDateString];
    self.payrollEndDate = [oneWeek toDefaultDateString];
    
    // allow setting the startDate and endDate properties such as properties in TimeSheetsMasterViewController
    if (datesInterface) {
        [datesInterface setStartdate:self.payrollStartDate];
        [datesInterface setEnddate:self.payrollEndDate];
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    //save dates
    [defaults setObject:self.payrollStartDate forKey:@"payrollStartDate"];
    [defaults setObject:self.payrollEndDate forKey:@"payrollEndDate"];
    [defaults synchronize]; //write out the data
}

+(void)releaseInstance{
    instance = nil;
}

- (NSString*)getModifiedBy {
    NSString *modifiedBy;
    if ([self.userType isEqualToString:@"employer"])
        modifiedBy = [NSString trim:self.employerName];
    else
#ifdef PERSONAL_VERSION
        modifiedBy = [NSString trim:self.indivdualName];
#else
        modifiedBy = [NSString trim:self.employeeName];
#endif
    if ([NSString isNilOrEmpty:modifiedBy]) {
        modifiedBy = [NSString trim:self.userEmail];
    }
    return modifiedBy;
}
/*
- (void) scheduleNotificationOn:(NSDate*) fireDate
                           text:(NSString*) alertText
                         action:(NSString*) alertAction
                          sound:(NSString*) soundfileName
                    launchImage:(NSString*) launchImage
                        andInfo:(NSDictionary*) userInfo

{
	UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = fireDate;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];	
    
    localNotification.alertBody = alertText;
    localNotification.alertAction = alertAction;
	localNotification.repeatInterval = NSCalendarUnitDay;
    
	if(soundfileName == nil)
	{
		localNotification.soundName = UILocalNotificationDefaultSoundName;
	}
	else
	{
		localNotification.soundName = soundfileName;
	}
    
	localNotification.alertLaunchImage = launchImage;
    
	//self.badgeCount ++;
    localNotification.applicationIconBadgeNumber = -1;//self.badgeCount;
    localNotification.userInfo = userInfo;
    
	// Schedule it with the app
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

}
*/
- (void) scheduleNotificationOn:(NSDate*) fireDate
                           text:(NSString*) alertText
                         action:(NSString*) alertAction
                          sound:(NSString*) soundfileName
                    launchImage:(NSString*) launchImage
                        andInfo:(NSDictionary*) userInfo {
    
   
        
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = [NSString localizedUserNotificationStringForKey:@"Reminder"
                                                        arguments:nil];
    content.body = [NSString localizedUserNotificationStringForKey:alertText
                                                       arguments:nil];
    
    if(soundfileName == nil)
    {
        content.sound = [UNNotificationSound defaultSound];
    }
    else
    {
        content.sound = [UNNotificationSound soundNamed:soundfileName];
    }
    
    
    content.categoryIdentifier = alertAction;
    
    content.userInfo = userInfo;
    
    content.launchImageName = launchImage;
//    content.badge = [NSNumber numberWithInt:-1];
    
    // Create trigger
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components: NSCalendarUnitYear|
                                    NSCalendarUnitMonth|
                                    NSCalendarUnitDay
                                               fromDate:fireDate];
    
    
    UNCalendarNotificationTrigger *notificationTrigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:NO];

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:NSUUID.UUID.UUIDString
                                                                        content:content
                                                                        trigger:notificationTrigger];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"add NotificationRequest succeeded!");
        }
    }];
}

// MARK:- Receive Notifications

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
        willPresentNotification:(UNNotification *)notification
        withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
 
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
           didReceiveNotificationResponse:(UNNotificationResponse *)response
           withCompletionHandler:(void (^)(void))completionHandler {

    NSLog(@"User Info : %@",response.notification.request.content.userInfo);
     completionHandler();
}


@end
