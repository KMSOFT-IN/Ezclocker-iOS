//
//  CustomersViewController.h
//  ezClocker Personal
//
//  Created by Raya Khashab on 11/28/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"
#import "CustomerDetailsViewController.h"
#import "EmployeeProfileViewController.h"
#import "TimeSheetMasterViewController.h"
#import "EmployeeClockViewController.h"
#import "SubscriptionWebService.h"

NS_ASSUME_NONNULL_BEGIN


@interface CustomersViewController : UITableViewControllerEx<addCustomerViewControllerDelegate, SubscriptionDelegate>
{
    CustomerDetailsViewController *customerDetailViewConroller;
    UIBarButtonItem *editButton;
    UIBarButtonItem* cancelButton;
    NSMutableArray *curCustomerNameIDList;
    UINavigationController *clockInOutNavViewController;
   // UINavigationController *timesheetNavViewController;
    EmployeeClockViewController *employeeClockViewController;
    TimeSheetMasterViewController *timeSheetViewController;
}

- (IBAction)revealMenu:(id)sender;

@property (strong, nonatomic) IBOutlet UITableView *customersListTableView;

@property (strong, nonatomic) UINavigationController *timeSheetNavigationController;
@property (strong, nonatomic) UITabBarController *tabBarController;

@end

NS_ASSUME_NONNULL_END
