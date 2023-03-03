//
//  user.h
//  TCS Mobile
//
//  Created by Raya Khashab on 9/2/12.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EmployerLocation.h"
#import <UserNotifications/UserNotifications.h>
#ifdef PERSONAL_VERSION
#import "Reminder.h"
#endif

@protocol StartEndDateInterface <NSObject>

- (void)setStartdate:(NSString*)value;
- (void)setEnddate:(NSString*)value;

@end

@interface UserClass : NSObject <UNUserNotificationCenterDelegate>

@property (nonatomic, retain) NSNumber *employerID;
@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSNumber *realUserId;
@property (nonatomic, retain) NSNumber *availableEmployeeSlots;
@property (nonatomic, retain) NSString *employerName;
@property (nonatomic, retain) NSString *employeeName;
@property (nonatomic, retain) NSString *userType;
@property (nonatomic, retain) NSMutableArray *userAuthorities;
@property (nonatomic, retain) NSString *userEmail;
@property (nonatomic, retain) NSString *lastEmailToSent;
@property (nonatomic, retain) NSString *payrollStartDate;
@property (nonatomic, retain) NSString *payrollEndDate;
@property int currentClockMode;
@property (nonatomic, retain) NSString *lastClockIn;
@property (nonatomic, retain) NSString *lastClockOut;
@property (nonatomic, retain) NSNumber *activeTimeEntryId;
//this will keep track of which time entry is part of an active clock in
@property (nonatomic, retain) NSNumber *activeClockInId;
@property (nonatomic, retain) NSString *authToken;
@property (nonatomic, retain) NSString *userPin;
//@property (nonatomic, retain) NSMutableArray *timeHistory;
@property (nonatomic, retain) EmployerLocation *employerLocation;
@property (nonatomic, retain) NSString *subscription_PlanPrice;
@property (nonatomic, retain) NSString *subscription_PlanExpireDate;
@property (nonatomic, retain) NSString *subscription_planStartDate;
@property (nonatomic, retain) NSString *subscription_planProvider;
@property (nonatomic, retain) NSMutableArray *subscription_enabledFeatures;
@property (nonatomic, retain) NSNumber *subscription_freeTrialDaysLeft;
@property (nonatomic, retain) NSNumber *subscription_IsValid;
//When freePlanActive = TRUE that means they are on the free plan
@property BOOL subscription_freePlanActive;
@property BOOL subscription_HasActivePaidPlan;
@property (nonatomic, retain) NSDate *appInstallDate;
@property (nonatomic, retain) NSNumber *employeeCount;

@property (nonatomic, retain) NSMutableDictionary *employeePermissions;
@property (nonatomic, retain) NSMutableDictionary *employerOptions;

@property (nonatomic, retain) NSMutableArray *clockInReminders;
@property (nonatomic, retain) NSMutableArray *clockOutReminders;

@property (nonatomic, retain) NSMutableDictionary *employeeNameIDList;
@property (nonatomic, retain) NSMutableArray *employeeList;
@property (nonatomic, retain) NSMutableArray *locationNameAddressList;
@property (nonatomic, retain) NSMutableArray *customerNameIDList;
@property (nonatomic, retain) NSMutableArray *jobCodesList;


//this is service of the rating dialog
//only show the please rate us dialog after a certain amount of times they have launched the app
//and after they chose to rate us or not save that so we don't bug them again
@property (nonatomic, retain) NSNumber *userGaveUsRatingFeedback;
@property (nonatomic, retain) NSNumber *appLaunchCounter;

@property (nonatomic, assign) int disableTimeEntryEditing;
@property (nonatomic, assign) int requireLocationForClockInOut;
@property (nonatomic, assign) int seeCoworkersScheduleAllowed;
@property (nonatomic, assign) int pushNotificationsEnabled;

@property (nonatomic, assign) double totalDuration;

@property (nonatomic, assign) bool showTotalPay;

@property (nonatomic, retain) NSNumber *curCustomerId;

//@property (nonatomic, assign) double hourlyPayRate;

#ifdef PERSONAL_VERSION
@property (nonatomic, retain) NSString *hasAccount;
@property (nonatomic, retain) NSString *indivdualName;
@property (nonatomic, retain) NSString *individualGeneratedPassword;
@property (nonatomic, assign) double individualHourlyPayRate;


#endif

@property BOOL remindersSet;
//@property BOOL passCodeSet;

+(UserClass*)getInstance;
+(void)releaseInstance;

- (void) scheduleNotificationOn:(NSDate*) fireDate
                           text:(NSString*) alertText
                         action:(NSString*) alertAction
                          sound:(NSString*) soundfileName
                    launchImage:(NSString*) launchImage
                        andInfo:(NSDictionary*) userInfo;

- (NSString*)getModifiedBy;
- (void)checkPayrollStartDate:(id<StartEndDateInterface>)datesInterface;


@end
