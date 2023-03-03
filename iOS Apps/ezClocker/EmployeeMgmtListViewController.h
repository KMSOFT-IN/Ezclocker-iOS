//
//  EmployeeMgmtListViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 9/27/17.
//  Copyright © 2017 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"
#import "SubscriptionWebService.h"
#import "AddEmployeeViewController.h"
#import "EmployeeInfoViewController.h"

@interface EmployeeMgmtListViewController : UITableViewControllerEx<addEmployeeViewControllerDelegate, SubscriptionDelegate, employeeInfoViewControllerDelegate>
{
    NSMutableArray *employeeList;
    UIBarButtonItem *editButton;
    UIBarButtonItem* cancelButton;
    BOOL editFlag;
}
- (IBAction)revealMenu:(id)sender;
- (IBAction)onEditClick:(id)sender;
- (IBAction)onAddClick:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *employeesTableViewController;

@end
