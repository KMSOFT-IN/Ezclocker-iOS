//
//  ViewAccountViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 2/20/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"


@class ViewAccountViewController;

@protocol viewPersonalAccountViewControllerDelegate
- (void)loginPersonalWasSelectedFromViewAccount:(ViewAccountViewController *)controller;
@end

@interface ViewAccountViewController : UIViewControllerEx
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarBtn;
@property (strong, nonatomic) IBOutlet UIView *mainView;
- (IBAction)doSignOut:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
- (IBAction)revealMenu:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (assign, nonatomic) IBOutlet id <viewPersonalAccountViewControllerDelegate> delegate;

- (IBAction)updateAccount:(id)sender;
- (IBAction)doDeleteAccount:(id)sender;

@end
