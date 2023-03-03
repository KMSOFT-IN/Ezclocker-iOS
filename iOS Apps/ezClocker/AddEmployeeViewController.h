//
//  AddEmployeeViewController.h
//  TCS Mobile
//
//  Created by Raya Khashab on 1/19/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import "RolesListViewController.h"

@class AddEmployeeViewController;

@protocol addEmployeeViewControllerDelegate
//- (void)addEmployeeViewControllerDidFinish:(AddEmployeeViewController *)controller;
- (void)addEmployeeViewControllerDidFinish:(UIViewController *)controller CancelWasSelected:(bool)cancelWasSelected;
@end

@interface AddEmployeeViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UITextFieldDelegate, RolesListViewDelegate>{
    NSMutableData *data;
    bool EmployeeAdded;
    bool EmployeeInvited;
    bool boxChecked;
    UIImage *checkboxImage;
    UIImage *uncheckboxImage;
}

@property (strong, nonatomic) IBOutlet UIView *mainViewController;
- (IBAction)nameEditingDidBegin:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (assign, nonatomic) IBOutlet id <addEmployeeViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *TopViewController;
@property (weak, nonatomic) IBOutlet UIView *inviteViewController;
@property (weak, nonatomic) IBOutlet UIView *addEmployeeViewController;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *InviteBtn;
@property (weak, nonatomic) IBOutlet UIView *blockEmployeeView;
@property (weak, nonatomic) IBOutlet UIImageView *passcodeViewImage;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passcodeTextField;
@property (weak, nonatomic) IBOutlet UISwitch *inviteSwitch;
//@property (weak, nonatomic) IBOutlet UISwitch *blockPermissionSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *allowMobileSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *allowWebsiteSwtich;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIView *hourlyRateView;
@property (weak, nonatomic) IBOutlet UIView *passcodeView;
@property (weak, nonatomic) IBOutlet UITextField *roleTextField;
@property (weak, nonatomic) IBOutlet UITextField *hourlyRateTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inviteTopConstraint;

- (IBAction)selectRoles:(id)sender;

- (IBAction)doAddEmployee:(id)sender;

- (IBAction)doCancelAddEmployee:(id)sender;

@end
