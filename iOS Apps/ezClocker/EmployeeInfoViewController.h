//
//  EmployeeInfoViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 3/15/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import "RolesListViewController.h"

@class EmployeeInfoViewController;

@protocol employeeInfoViewControllerDelegate
- (void)EmployeeInfoSaveDidFinish:(EmployeeInfoViewController *)controller EmployeeObj:(NSMutableDictionary*) empDetailsObj;
@end

@interface EmployeeInfoViewController : UIViewControllerEx<UITextFieldDelegate, RolesListViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *pinTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIView *pinView;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
//@property (weak, nonatomic) IBOutlet UISwitch *blockEmployeeSwitch;
@property (weak, nonatomic) IBOutlet UIView *blockEmployeeView;
- (IBAction)doSelectRole:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *_roleTextField;
@property (weak, nonatomic) IBOutlet UITextField *payRateTextField;
@property (nonatomic, strong) NSMutableDictionary* employeeDetails;
@property (assign, nonatomic) IBOutlet id <employeeInfoViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UISwitch *allowMobileSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *allowWebsiteSwtich;
@end
