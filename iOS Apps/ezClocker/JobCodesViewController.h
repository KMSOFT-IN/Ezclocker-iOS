//
//  JobCodesViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 4/7/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"
#import "JobCodeDetailsViewController.h"
#import "ECSlidingViewController.h"
#import <AVKit/AVKit.h>
@interface JobCodesViewController : UITableViewControllerEx<jobCodeDetailViewControllerDelegate>
{
    JobCodeDetailsViewController *jobCodeDetailViewConroller;
    NSMutableArray *jobCodesList;
    UIBarButtonItem *otherEditButton;
    UIBarButtonItem* cancelButton;
}
- (IBAction)revealMenu:(id)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (strong, nonatomic) AVPlayerViewController *playerViewController;

@property (strong, nonatomic) IBOutlet UITableView *jobCodesListTable;
- (IBAction)onAddClick:(id)sender;
- (IBAction)onEditClick:(id)sender;

@end
