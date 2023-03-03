//
//  FirstTopViewController.h
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ECSlidingViewController.h"
#import "MenuViewController.h"

@interface FirstTopViewController : UITabBarController

@property (nonatomic, assign) BOOL gotoScheduleTab;
@property (nonatomic, assign) BOOL fromCustomerDetail;
@property (nonatomic, assign) UINavigationController* previousNavigation;

- (IBAction)revealMenu:(id)sender;
- (IBAction)revealUnderRight:(id)sender;

@end
