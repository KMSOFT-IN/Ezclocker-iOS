//
//  PushNotification.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/21/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "PushNotification.h"
#import "debugdefines.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"

@implementation PushNotification

- (BOOL)isEquals:(NSDictionary*)apsDict {
    if (nil == apsDict) {
        return FALSE;
    }
    DEBUG_MSG
    NSDictionary* payload = [apsDict valueForKey:kPayloadKey];
    NSAssert((payload != (NSDictionary*)[NSNull null] && (nil != payload)), @"%@ must exist in apsDict %@", kPayloadKey, msg);
    NSString* aAction = [NSString trim:[payload valueForKey:kActionKey]];
    NSAssert(nil != aAction, @"%@ must exist in the %@ of %@", kActionKey, kPayloadKey, msg);
    if (![aAction isEqualToString:self.action]) {
        return FALSE;
    }
    NSString* aType = [NSString trim:[payload valueForKey:kTypeKey]];
    NSAssert(nil != aType, @"%@ must exist in the %@ of %@", kTypeKey, kPayloadKey, msg);
    if (![aType isEqualToString:self.type]) {
        return FALSE;
    }
    NSString* aDate = [NSString trim:[payload valueForKey:kDateKey]];
    NSAssert(nil != aDate, @"%@ must exist in the %@ of %@", kDateKey, kPayloadKey, msg);
    if (![aDate isEqualToString:self.date]) {
        return FALSE;
    }
    NSString* aAlert = [NSString trim:[apsDict valueForKey:kAlertKey]];
    NSAssert(nil != aAlert, @"%@ must exist in the %@ of %@", kAlertKey, kAPSKey, msg);
    if (![aAlert isEqualToString:self.alert]) {
        return aAlert;
    }
    return TRUE;
}

- (void)assign:(NSDictionary*)apsDict {
    DEBUG_MSG
    NSAssert(nil != apsDict, @"apsDict cannot be nil %@", msg);
    if (nil == apsDict) {
        return;
    }
    // Alert in aps portion
    self.alert = [NSString trim:[apsDict valueForKey:kAlertKey]];
    // Get payload values
    NSDictionary* payload = [apsDict valueForKey:kPayloadKey];
    NSAssert((payload != (NSDictionary*)[NSNull null] && (nil != payload)), @"%@ must exist in apsDict %@", kPayloadKey, msg);
    self.action = [NSString trim:[payload valueForKey:kActionKey]];
    self.type = [NSString trim:[payload valueForKey:kTypeKey]];
    self.date = [NSString trim:[payload valueForKey:kDateKey]];
}

- (id)copyWithZone:(NSZone *)zone {
    PushNotification* cpy = [[[self class]allocWithZone:zone] init];
    [cpy setAlert:self.alert];
    [cpy setType:self.type];
    [cpy setAction:self.action];
    [cpy setDate:self.date];
    [cpy setNotificationType:self.notificationType];
    return cpy;
}

@end
