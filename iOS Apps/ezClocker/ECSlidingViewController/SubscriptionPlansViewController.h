//
//  SubscriptionPlansViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 2/22/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import "EZPurchaseManager.h"
#import "CancelSubscriptionViewController.h"
#import "UIViewControllerEx.h"

@interface SubscriptionPlansViewController : UIViewControllerEx <UITableViewDelegate, PurchaseDelegate, cancelSubscriptionViewControllerDelegate>
{
    NSString *selectedPlanPrice;
    NSMutableArray *subscriptionPlansList;
    BOOL isExpired;
    BOOL flagTap;
}
- (IBAction)doCancel:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITableView *currentSubscriptionTable;
@property (weak, nonatomic) IBOutlet UITableView *subscriptionPlansTable;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subscriptionTableHeight;

- (IBAction)revealMenu:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *purchaseDescLabel;
- (IBAction)doTermsOfUse:(id)sender;
- (IBAction)doPrivacyPolicy:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;

@end
