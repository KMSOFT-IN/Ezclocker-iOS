//
//  CreateEmployerAccountViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 2/28/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

@class CreateEmployerAccountViewController;

@protocol CreateEmployerAccountViewControllerDelegate
- (void)CreateEmployerAccountViewControllerDidFinish:(CreateEmployerAccountViewController *)controller;
- (void)loginViewControllerWasSelected:(CreateEmployerAccountViewController *)controller;
- (void)CreateEmployerStep2WasSelected:(CreateEmployerAccountViewController *)controller;
- (void)showConfirmationDlg:(CreateEmployerAccountViewController *)controller;

@end

@interface CreateEmployerAccountViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UITextFieldDelegate, UIAlertViewDelegate>
{
    NSMutableData *data;
}

- (IBAction)doContinueAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *splashImage;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UIImageView *FirstContainer;
@property (assign, nonatomic) IBOutlet id <CreateEmployerAccountViewControllerDelegate> delegate;
- (IBAction)doSignIn:(id)sender;
- (IBAction)doSwitchChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UIView *subView;
@property (weak, nonatomic) IBOutlet UILabel *areYouEmployerLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchOption;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segControl;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end
