//
//  AppDelegate.h
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubscriptionWebService.h"
#import "LocationManager.h"
#import <UserNotifications/UserNotifications.h>

@import Firebase;

@interface AppDelegate : UIResponder <UIApplicationDelegate,LocationManagerDelegate, UIAlertViewDelegate, UNUserNotificationCenterDelegate>

//@property (nonatomic) BOOL isPortrait;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SubscriptionWebService *subscriptionWebService;
@property (strong, nonatomic) NSString *appToken;
@property (nonatomic, assign) bool isBackgroundFetching;
@property (nonatomic, assign) bool callForegroundFunction;
@property (strong, nonatomic) UIStoryboard *storyboard;
@property (strong, nonatomic) UINavigationController *navigationController;

+ (AppDelegate *)sharedInstance;

@end
