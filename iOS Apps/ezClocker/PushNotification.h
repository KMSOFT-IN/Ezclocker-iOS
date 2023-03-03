//
//  PushNotification.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/21/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kAPSKey @"aps"            // aps dictionary key
#define kPayloadKey @"payload"    // payload dictionary key
#define kTypeKey @"type"          // type: schedule
#define kActionKey @"action"      // action: goto
#define kDateKey @"date"          // date: date
#define kAlertKey @"alert"        // alert: message
#define kGotoAction @"goto"       // goto
#define kTypeSchedule @"schedule" // schedule

typedef enum __PushNotificationType {
    /*! App was on Foreground */
    pntGotoSchedule,
    /*! App was on Background */
    /*! App was terminated and launched again through Push notification */
} PushNotificationType;

@interface PushNotification : NSObject <NSCopying>

@property (nonatomic, assign) PushNotificationType notificationType;
@property (nonatomic, copy) NSString* type;
@property (nonatomic, copy) NSString* action;
@property (nonatomic, copy) NSString* date;
@property (nonatomic, copy) NSString* alert;

- (BOOL)isEquals:(NSDictionary*)apsDict;
- (void)assign:(NSDictionary*)apsDict;

@end
