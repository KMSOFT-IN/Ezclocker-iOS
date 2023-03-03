//
//  PersonalAppSettingsTableViewController.h
//  ezClocker Personal
//
//  Created by Raya Khashab on 10/3/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"

@interface PersonalAppSettingsTableViewController  : UITableViewControllerEx <UITextFieldDelegate>

- (IBAction)revealMenu:(id)sender;
- (IBAction)doSave:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *accountSettingsTableView;
@property (weak, nonatomic) IBOutlet UILabel *personalAppVersionLabel;
@property (weak, nonatomic) IBOutlet UITextField *hourlyRateTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@end
