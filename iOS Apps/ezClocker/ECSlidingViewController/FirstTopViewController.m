//
//  FirstTopViewController.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import "FirstTopViewController.h"
#import "PushNotificationManager.h"
#import "EmployeeClockViewController.h"
#import "TimeSheetMasterViewController.h"
@implementation FirstTopViewController

- (void)viewDidLoad {
    if (_fromCustomerDetail == YES) {
        [self.navigationController setNavigationBarHidden:YES];
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Remove the second tab which is the schedule for Personal app only
#ifdef PERSONAL_VERSION
    NSMutableArray * vcs = [NSMutableArray
                            arrayWithArray:[self viewControllers]];
    if ([vcs count] > 2)
    {
        [vcs removeObjectAtIndex:1];
        if (_fromCustomerDetail == YES) {
            EmployeeClockViewController * viewcontroller = (EmployeeClockViewController *)[vcs[0] viewControllers].firstObject;
            //             UINavigationController *nav = vcs[0];
            //             nav.navigationItem.title = @"Clock in/out";
            viewcontroller.fromCustomerDetail = self.fromCustomerDetail;
            viewcontroller.previousNavigation = self.previousNavigation;
            TimeSheetMasterViewController * secondController = (TimeSheetMasterViewController *)[vcs[1] viewControllers].firstObject;
            secondController.fromCustomerDetail = self.fromCustomerDetail;
            secondController.previousNavigation = self.previousNavigation;
            //             UINavigationController *nav1 = vcs[1];
            //             nav1.navigationItem.title = @"Timesheet";
        
        }
        [self setViewControllers:vcs];
    }
#endif
    // shadowPath, shadowOffset, and rotation is handled by ECSlidingViewController.
    // You just need to set the opacity, radius, and color.
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    if (self.gotoScheduleTab) {
        NSArray* array = self.viewControllers;
        if (array.count > 0) {
            UIViewController* viewController = [array objectAtIndex:1];
            self.selectedViewController = viewController;
        }
        self.gotoScheduleTab = FALSE;
    }
#ifndef PERSONAL_VERSION
    
    PushNotificationManager* manager = [PushNotificationManager sharedManager];
    [manager registerForPushNotification:^(BOOL successful, NSError *error) {
        
    }];
#endif
}

- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)revealUnderRight:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

@end
