//
//  CustomersMgmtViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 7/27/19.
//  Copyright © 2019 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"
#import "CustomerDetailsViewController.h"
#import <AVKit/AVKit.h>
#import <SafariServices/SafariServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomersMgmtViewController : UITableViewControllerEx <addCustomerViewControllerDelegate, SFSafariViewControllerDelegate>
{
    CustomerDetailsViewController *customerDetailViewConroller;
   // UIBarButtonItem *addButton;
   // UIBarButtonItem *editButton;
    UIBarButtonItem* cancelButton;
    NSMutableArray *curCustomerNameIDList;
}

- (IBAction)revealMenu:(id)sender;
- (IBAction)onAddClick:(id)sender;
- (IBAction)onEditClick:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *customersListTableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (strong, nonatomic) AVPlayerViewController *playerViewController;
@property bool isAlertShown;
@end

NS_ASSUME_NONNULL_END
