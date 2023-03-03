//
//  EmailFeedbackViewController.h
//  Created by Raya Khashab on 10/14/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif

@protocol emailFeedbackViewControllerDelegate
- (void)emailFeedbackViewControllerDidFinish:(UIViewController *)controller;
@end

@interface EmailFeedbackViewController : UIViewControllerEx<UITextFieldDelegate, UITextViewDelegate, NSURLConnectionDataDelegate>
{
    NSMutableData *data;
    CGPoint originalCenter;
    UIToolbar* keyboardToolbar;
}
@property (weak, nonatomic) IBOutlet UITextField *fromEmailTextField;
@property (weak, nonatomic) IBOutlet UILabel *EmailToLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *thankyouLabel;
@property (weak, nonatomic) IBOutlet UIButton *submitBtn;
@property (weak, nonatomic) IBOutlet UIView *submitBtnViewController;
@property (assign, nonatomic) IBOutlet id <emailFeedbackViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextView *MessageTextView;
- (IBAction)revealMenu:(id)sender;
- (IBAction)doSubmitEmail:(id)sender;

@end
