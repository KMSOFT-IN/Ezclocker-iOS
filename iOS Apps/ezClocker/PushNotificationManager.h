//
//  PushNotificationManager.h
//  ezClocker
//
//  Created by Kenneth Lewis on 12/21/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singletondef.h"
#import "PushNotification.h"
#import "completionblockdefines.h"

#define kApnTokenKey @"apnsToken"
#define kApnTokenSentSucessfullyKey @"apnsTokenSentSuccessfully"
#define kServiceAppToken @"killers_sk39Z18-vLeakyleak923l_1112"
#define kGotoScheduleNotification @"GotoScheduleNotification"

#define kErrorUserNotLoggedIn 101
#define kErrorInvalidAuthToken 102
#define kErrorInvalidDeviceToken 103
#define kErrorInProcessOfRegistering 104
#define kPushNotificationDomain @"PushNotificationDomain"

#define ksetJobCodeViewNotification @"setJobCodeView"

@interface PushNotificationManager : NSObject

@property (atomic, copy) PushNotification* gotoSchedule;
@property (retain) NSMutableArray* notifications;
@property (atomic, assign) BOOL registering;

+ (void)saveDeviceToken:(NSData*)deviceToken;
+ (void)saveDeviceTokenAsString:(NSString*)token;
+ (NSString*)getDeviceToken;

- (void)registerForPushNotification:(SuccessfulCompletionBlock)completion;

- (void)addPushNotification:(NSDictionary*)userInfo;

SINGLETON_HEADER_DEF(PushNotificationManager)

@end
