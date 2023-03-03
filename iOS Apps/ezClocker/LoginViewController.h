//
//  LoginViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CreateEmployerAccountViewController.h"
#import "UIViewControllerEx.h"

@class LoginViewController;

@protocol LoginViewControllerDelegate
//- (void)loginViewControllerDidFinish:(LoginViewController *)controller Name:(NSString *) userName Password: (NSString *) userPassword;
- (void)loginViewControllerDidFinish:(LoginViewController *)controller UserName:(NSString*) userName Password: (NSString *) userPassword;
- (void)createViewControllerWasSelected:(LoginViewController *)controller;

@end

@protocol GetUserAccountDelegate
- (void)getUserAccountCallDidFinish:(LoginViewController *)controller Name:(NSString *) userName Password: (NSString *) userPassword;
@end

@interface LoginViewController : UIViewControllerEx <NSURLConnectionDataDelegate, UITextFieldDelegate, UITableViewDelegate>
{
    NSMutableData *data;
    AppDelegate *appDelegate;
    CGPoint originalCenter;
    NSURLConnection *getAuthConnection;
    NSURLConnection *getAccountConnection;
}

@property (assign, nonatomic) IBOutlet id <LoginViewControllerDelegate> delegate;
//source is the controller that called login which could be the signup screen or the initialviewcontroller
@property (assign, nonatomic) IBOutlet UIViewController *source;
@property (weak, nonatomic) IBOutlet UIImageView *splashScreenImageView;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *learnMoreButton;
@property (weak, nonatomic) IBOutlet UIView *loginView;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordLabel;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (nonatomic, assign) BOOL signinOnly;
@property (weak, nonatomic) IBOutlet UIView *signInView;

- (IBAction)doForgotPassword:(id)sender;

- (IBAction)doTheLogin:(id)sender;
- (IBAction)doSignup:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *mainViewController;
@property (weak, nonatomic) IBOutlet UIView *emailView;
@property (weak, nonatomic) IBOutlet UIView *passwordView;



@end
