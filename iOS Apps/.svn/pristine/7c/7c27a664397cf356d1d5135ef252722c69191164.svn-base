//
//  SubscriptionViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 11/6/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubscriptionWebService.h"
#import "UIViewControllerEx.h"

@protocol SubscriptionViewControllerDelegate
//This protocol is used when the subscription has been renewed and we want to communicate to the
//initial view controller to slide another view
- (void)subscriptionCheckPassed;
@end

@interface SubscriptionViewController : UIViewControllerEx<SubscriptionDelegate>
{
   SubscriptionWebService *subscriptionWebService;
}
@property (strong, nonatomic) IBOutlet UIView *MainViewController;
@property (weak, nonatomic) IBOutlet UILabel *TitleLabel;
@property (assign, nonatomic) IBOutlet id <SubscriptionViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *MainInfoLabel;
- (IBAction)doTryAgainClick:(id)sender;

@end
