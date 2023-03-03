//
//  EmployeeListViewController.h
//  Created by Raya Khashab on 1/19/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "user.h"
#import "EmployeeProfileViewController.h"
#import "ECSlidingViewController.h"
#import "TimeSheetMasterViewController.h"
#import "AddEmployeeViewController.h"
#import "SubscriptionWebService.h"
#import "UITableViewControllerEx.h"

typedef enum {
    OperationNone = 0,
    OperationGet = 1,
    OperationDelete = 2,
} OperationMode;


@interface EmployeeListViewController :UITableViewControllerEx <NSURLConnectionDataDelegate, UIActionSheetDelegate, addEmployeeViewControllerDelegate, SubscriptionDelegate>{
//    UserClass *user;
    NSMutableData *data;
    NSArray *sampleItems;
    BOOL editFlag;
    OperationMode mode;
    UIBarButtonItem* cancelButton;
    EmployeeProfileViewController *empProfileViewController;
    TimeSheetMasterViewController *empTimeSheetViewController;
    UIViewController *modalViewController;

}
@property (strong, nonatomic) IBOutlet UITableView *employeeListTableViewController;
- (IBAction)emailAllTimeSheets:(id)sender;
@property (nonatomic, retain) NSMutableArray *employeesList;
//@property (strong, nonatomic) EmployeeProfileViewController *employeeProfileViewController;
@property (strong, nonatomic) UINavigationController *timeSheetNavigationController;
@property (strong, nonatomic) UITabBarController *tabBarController;
@property (strong, nonatomic) UINavigationController *employeeDetailNavigationController;


- (IBAction)revealMenu:(id)sender;

@end
