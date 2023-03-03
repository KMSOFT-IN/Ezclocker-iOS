//
//  MenuViewController.h
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECSlidingViewController.h"
#import "LoginViewController.h"
#import "CreatePersonalAccountViewController.h"
#import "user.h"
#import "ViewAccountViewController.h"
#import "UIViewControllerEx.h"
#import "TeamModeViewController.h"

@interface MenuViewController : UIViewControllerEx <UITableViewDataSource, UITabBarControllerDelegate, LoginViewControllerDelegate, createAccountViewControllerDelegate, viewPersonalAccountViewControllerDelegate, TeamModeViewControllerDelegate>
{
}
@property (weak, nonatomic) IBOutlet UITableView *MenuTableView;
@property (weak, nonatomic) IBOutlet UILabel *NameLabel;
-(void)signOutCompletely;

@end

