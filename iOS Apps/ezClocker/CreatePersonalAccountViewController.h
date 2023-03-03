//
//  CreatePersonalAccountViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 2/19/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

@class CreatePersonalAccountViewController;

@protocol createAccountViewControllerDelegate
- (void)loginPersonalViewControllerWasSelected:(CreatePersonalAccountViewController *)controller;
- (void)createAccountViewControllerDidFinish:(CreatePersonalAccountViewController *)controller;
@end


@interface CreatePersonalAccountViewController : UIViewControllerEx <NSURLConnectionDataDelegate, UITextFieldDelegate, UITableViewDelegate>
{
    NSMutableData *data;
}
//@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subViewBottom;
@property (assign, nonatomic) IBOutlet id <createAccountViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
- (IBAction)doLogin:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
- (IBAction)revealMenu:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *CreateButton;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
- (IBAction)doCreateAccount:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
- (IBAction)doViewTermsofService:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageTrailing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageLeading;
@property (nonatomic, retain) NSNumber* hideLoginButton;
@property (weak, nonatomic) IBOutlet UIView *subview;

@end
