//
//  LoginPersonalViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 1/31/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//


#import <UIKit/UIKit.h>

@class LoginPersonalViewController;

@protocol LoginPersonalViewControllerDelegate
- (void)loginPersonalViewControllerWasSelected:(LoginPersonalViewController *)controller;
- (void)loginPersonalViewControllerDidFinished:(LoginPersonalViewController *)controller;
- (void)createPersonalViewControllerWasSelected:(LoginPersonalViewController *)controller;

@end

@interface LoginPersonalViewController : UIViewController<NSURLConnectionDataDelegate, UITextFieldDelegate>
{
    NSMutableData *data;
    NSURLConnection *getAuthConnection;
    NSURLConnection *getAccountConnection;

}
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *accountSetupButton;


- (IBAction)revealMenu:(id)sender;

@property (assign, nonatomic) IBOutlet id <LoginPersonalViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuBarItem;
@property (weak, nonatomic) IBOutlet UIView *subView;
@property (weak, nonatomic) IBOutlet UILabel *emailSentLabel;
@property (nonatomic, assign) BOOL hidAccountSetupButton;
- (IBAction)doForgotPassword:(id)sender;
- (IBAction)doLogin:(id)sender;
- (IBAction)doSignUp:(id)sender;

@end
