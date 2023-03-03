//
//  EmployerStartScreenViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 3/26/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class EmployerStartScreenViewController;

@protocol EmployerStartScreenViewControllerDelegate
- (void)EmployerStartScreenSignupSelected:(EmployerStartScreenViewController *)controller;
- (void)EmployerStartScreenSignInSelected:(EmployerStartScreenViewController *)controller;

@end


@interface EmployerStartScreenViewController : UIViewController
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYConstraint;
@property (weak, nonatomic) IBOutlet UIButton *signUpBtn;
@property (weak, nonatomic) IBOutlet UIButton *signInBtn;
@property (weak, nonatomic) IBOutlet UIView *signInView;
@property (weak, nonatomic) IBOutlet UIView *signUpView;
- (IBAction)doSignUp:(id)sender;
- (IBAction)showInformation:(id)sender;
- (IBAction)doSignIn:(id)sender;
@property (assign, nonatomic) IBOutlet id <EmployerStartScreenViewControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
