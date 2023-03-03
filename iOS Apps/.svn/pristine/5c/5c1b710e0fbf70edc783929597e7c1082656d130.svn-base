//
//  EmployerSignUpViewController.h
//  TCS Mobile
//
//  Created by Raya Khashab on 1/13/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

@interface EmployerSignUpViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UITextFieldDelegate>{
    CGPoint originalCenter;
    NSMutableData *data;
    bool EmployerAdded;

}

- (IBAction)backgroundTouched:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (strong, nonatomic) IBOutlet UIControl *mainViewController;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
- (IBAction)passwordEditingDidBegin:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
- (IBAction)emailEditingDidBegin:(id)sender;

- (IBAction)nameEditingDidBegin:(id)sender;
- (IBAction)nameEditingDidEnd:(id)sender;
- (IBAction)doRegister:(id)sender;

@end
