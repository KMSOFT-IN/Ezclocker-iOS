//
//  UpdateAccountViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 3/17/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

@class UpdateAccountViewController;

@protocol UpdateAccountViewControllerDelegate
- (void)UpdateAccountViewControllerDidFinish:(UIViewController *)controller;
@end

@interface UpdateAccountViewController : UIViewControllerEx<NSURLConnectionDataDelegate>{
        NSMutableData *data;
}

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
- (IBAction)updateAccount:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (assign, nonatomic) IBOutlet id <UpdateAccountViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end
