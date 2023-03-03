//
//  AddPersonInitialViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 11/9/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddEmployeeViewController.h"
#import "UIViewControllerEx.h"
#import <AVKit/AVKit.h>
#import <SafariServices/SafariServices.h>

@class AddPersonInitialViewController;

@protocol newEmployeeAddedDelegate
- (void)newEmployeeAdded:(AddPersonInitialViewController *)controller;
@end


@interface AddPersonInitialViewController : UIViewControllerEx <addEmployeeViewControllerDelegate, SFSafariViewControllerDelegate>
- (IBAction)revealMenu:(id)sender;
- (IBAction)doAddPerson:(UIButton *)sender;
- (IBAction)watchDemoVideo:(UIButton *)sender;

@property (strong, nonatomic) AVPlayerViewController *playerViewController;
@property (assign, nonatomic) IBOutlet id <newEmployeeAddedDelegate> delegate;
@property (assign, nonatomic) IBOutlet UIView* watchDemoView;
@property (assign, nonatomic) IBOutlet UIView* addEmployeeView;

@end
