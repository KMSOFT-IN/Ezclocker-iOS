//
//  PushNotificationManager.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/21/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "PushNotificationManager.h"
#import "NSString+Extensions.h"
#import "user.h"
#import "debugdefines.h"
#import "threaddefines.h"
#import "CommonLib.h"

@interface PushNotificationManager () {

}


@end

@implementation PushNotificationManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _notifications = [NSMutableArray new];
    }
    return self;

}

- (void)postNotifyGotoSchedule:(NSDictionary*)dict {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(postNotifyGotoSchedule:) withObject:dict waitUntilDone:FALSE];
        return;
    }

    DEBUG_MSG

    NSAssert(nil != dict, @"dict cannot be nil %@", msg);

    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kGotoScheduleNotification object:[dict copy]];
}

- (void)addPushNotification:(NSDictionary *)userInfo {
    DEBUG_MSG
    NSAssert(nil != userInfo, @"userInfo cannot be nil %@", msg);
    if (nil != userInfo) {
        NSDictionary* aps = [userInfo valueForKey:kAPSKey];
        NSAssert(nil != aps, @"%@ must exist in the dictionary %@", kAPSKey, msg);
        NSDictionary* payload = [aps valueForKey:kPayloadKey];
        NSString* action = [payload valueForKey:kActionKey];
        NSString* type = [payload valueForKey:kTypeKey];
        if ([type isEqualToString:kTypeSchedule] && [action isEqualToString:kGotoAction]) {
            if ((nil == self.gotoSchedule) || ![self.gotoSchedule isEquals:aps]) {
                PushNotification* notification = [PushNotification new];
                notification.notificationType = pntGotoSchedule;
                [notification assign:aps];
                self.gotoSchedule = notification;
                [self postNotifyGotoSchedule:userInfo];
            }
        }
    }
}

+ (void)saveDeviceToken:(NSData*)deviceToken {
    NSString * token = [NSString trim:[NSString stringWithFormat:@"%@", deviceToken]];
    [self saveDeviceTokenAsString:token];
}

+ (void)saveDeviceTokenAsString:(NSString*)token {
    if (![NSString isNilOrEmpty:token]) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        token = [token cleanUpDeviceToken];
        [defaults setObject:token forKey:kApnTokenKey]; //save token to resend it if request fails
        [defaults synchronize];
    }
}

+ (NSString*)getDeviceToken {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* deviceToken = [NSString trim:[defaults valueForKey:kApnTokenKey]];
    return deviceToken;
}

- (void)registerForPushNotification:(SuccessfulCompletionBlock)completion {
    DEBUG_MSG    
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);


    if (self.registering) {
        NSError* error = [PushNotificationManager errorWithCode:kErrorInProcessOfRegistering];
        completion(FALSE, error);
        return;
    }

    self.registering = TRUE;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL bIsRegistered = [defaults boolForKey:kApnTokenSentSucessfullyKey];
    if (bIsRegistered) {
        self.registering = FALSE;
        completion(TRUE, nil);
        return;
    }
    
    NSString* deviceToken = [NSString trim:[defaults valueForKey:kApnTokenKey]];
    BOOL bIsDeviceTokenNil = [NSString isNilOrEmpty:deviceToken];
    if (bIsDeviceTokenNil) {
#ifndef RELEASE
        NSLog(@"apnToken is nil or invalid in order to register for push notification");
#endif
        self.registering = FALSE;
        NSError* error = [PushNotificationManager errorWithCode:kErrorInvalidDeviceToken];
        completion(FALSE, error);
        return;
    }

    //Set to NO at first till it's successfully sent to the server
    [defaults setBool:NO forKey:kApnTokenSentSucessfullyKey];
    [defaults synchronize];

    UserClass* user = [UserClass getInstance];


    // Verify EmployerID in order to register
    //if (!user.employerID && (![user.employerID integerValue] || [user.employerID integerValue] <= 0)) {
    if (![user.employerID integerValue] || [user.employerID integerValue] <= 0) {

#ifndef RELEASE
        NSLog(@"user.EmployerID is invalid in order to register for push notification");
#endif
        self.registering = FALSE;
        // User is not logged in yet
        NSError* error = [PushNotificationManager errorWithCode:kErrorUserNotLoggedIn];
        completion(FALSE, error);
        return;
    }

    NSString *tmpAuthToken = [NSString trim:user.authToken];
    // Verify User authToken
    if ([NSString isNilOrEmpty:tmpAuthToken]) {
#ifndef RELEASE
        NSLog(@"user.authToken is nil or invalid in order to register for push notification");
#endif
        self.registering = FALSE;
        NSError* error = [PushNotificationManager errorWithCode:kErrorInvalidAuthToken];
        completion(FALSE, error);
        return;
    }

    PushNotificationManager* manager = [PushNotificationManager sharedManager];
    [manager sendUserToken:completion];
}

+ (NSError*)errorWithCode:(NSInteger)code {
    NSError* error = [[NSError alloc] initWithDomain:kPushNotificationDomain code:code userInfo:nil];
    return error;
}

- (void)sendUserToken:(SuccessfulCompletionBlock)completion {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kApnTokenSentSucessfullyKey]) {
        self.registering = FALSE;
        completion(TRUE, nil);
#ifndef RELEASE
        NSLog(@"apnsTokenSentSuccessfully already");
#endif
        return;
    }

#ifndef RELEASE
    NSLog(@"Registering device token");
#endif

    NSString* urlRequest = [NSString stringWithFormat:@"%@api/v1/push", SERVER_URL];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlRequest]];

    NSString* apnsToken = [[NSUserDefaults standardUserDefaults] objectForKey:kApnTokenKey];

    request.HTTPMethod = @"POST";
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    UserClass* user = [UserClass getInstance];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpEmployeeID = [user.userID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [request setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [request setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authToken"];
    
    NSString *deviceType = [CommonLib getDeviceName];
    
    NSDictionary* dict = nil;

    //if employer login then pass a -1 as the employee ID
    if ([user.userType isEqualToString:@"employer"]) {
        tmpEmployeeID = @"-1";
    }
        
/*        dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                              apnsToken ?: [NSNull null], @"deviceToken",
                              tmpEmployerID ?: [NSNull null], @"employerId",
                              @"-1" ?: [NSNull null], @"employeeId",
                              @"APNS" ?: [NSNull null], @"platformId",
                              deviceType ?: [NSNull null], @"deviceId",
                              @"true" ?: [NSNull null], @"enabled",
                              nil];
 */
//    }
//    else{
        NSString *UUID = [UIDevice currentDevice].identifierForVendor.UUIDString;
        dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                              apnsToken ?: [NSNull null], @"deviceToken",
                              tmpEmployerID ?: [NSNull null], @"employerId",
                              tmpEmployeeID ?: [NSNull null], @"employeeId",
                              @"APNS" ?: [NSNull null], @"platformId",
                              deviceType ?: [NSNull null], @"deviceId",
                              UUID ?: [NSNull null], @"uniqueId",
                              @"true" ?: [NSNull null], @"enabled",
                              nil];
        
//    }
//employeeID
    NSError* error = nil;
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
 //   NSString* newStr = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
    request.HTTPBody = postData;

    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];

    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            self.registering = FALSE;
            MAINTHREAD_BLOCK_START()
                completion(FALSE, error);
            THREAD_BLOCK_END()
#ifndef RELEASE
            NSLog(@"error: %@", error);
#endif
            return;
        }
//        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary* dict = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
        if (dict) {
            NSString *resultMessage = [dict valueForKey:@"message"];
            
            if ((![resultMessage isEqual:[NSNull null]]) && ([resultMessage isEqualToString:@"Success"])){

#ifndef RELEASE
                NSLog(@"Token has been sent successfully");
#endif
                // Now mark NSUserDefaults as successfully sending APN Token to server so you don't
                // have to register with it again
                NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES forKey:kApnTokenSentSucessfullyKey];
                [defaults synchronize];
                self.registering = FALSE;
                MAINTHREAD_BLOCK_START()
                    completion(TRUE, nil);
                THREAD_BLOCK_END()
            } else {
#ifndef RELEASE
                NSLog(@"Failed to register device token!!!");
#endif
                self.registering = FALSE;
                MAINTHREAD_BLOCK_START()
                    completion(FALSE, error);
                THREAD_BLOCK_END()
            }
        }
        return;
    }];
    [dataTask resume];
}

- (void)releaseAll {

}

SINGLETON_IMPLEMENTATION_DEF(PushNotificationManager)

@end
