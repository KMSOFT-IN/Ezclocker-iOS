//
//  PersonalSubscriptionViewController.h
//  ezClocker Personal
//
//  Created by Raya Khashab on 11/9/19.
//  Copyright © 2019 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import "EZPurchaseManager.h"
#import "CancelSubscriptionViewController.h"
#import "CreatePersonalAccountViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SubscriptionViewControllerDelegate
//This protocol is used when the subscription has been renewed and we want to communicate to the
//initial view controller to slide another view
- (void)subscriptionCheckPassed;

@end


@interface PersonalSubscriptionViewController : UIViewControllerEx <PurchaseDelegate, createAccountViewControllerDelegate, cancelSubscriptionViewControllerDelegate>
- (IBAction)doSubscribe:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *subscriptionBtn;
@property (weak, nonatomic) IBOutlet UILabel *subscriptionPlanValue;
@property (assign, nonatomic) IBOutlet id <SubscriptionViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *upgradeHeaderView;

- (IBAction)doTermsOfUseClick:(id)sender;
- (IBAction)revealMenu:(id)sender;

- (IBAction)doPrivacyClick:(id)sender;
@end

NS_ASSUME_NONNULL_END
