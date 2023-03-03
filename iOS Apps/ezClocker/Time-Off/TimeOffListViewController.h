//
//  TimeOffListViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 01/21/23.
//  Copyright © ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"
#import "ECSlidingViewController.h"
#import "TimeOffDetailViewController.h"
#import "TimeOffFiltersViewController.h"
#import <AVKit/AVKit.h>
@interface TimeOffListViewController : UITableViewControllerEx
{
    TimeOffDetailViewController *timeOffDetailViewController;
    TimeOffFiltersViewController *timeOffFiltersViewController;
    NSMutableArray *timeOffList;
    NSMutableArray *pendingTimeOffList;
    NSMutableArray *approvedTimeOffList;
    NSMutableArray *deniedTimeOffList;
    UIBarButtonItem *otherEditButton;
    UIBarButtonItem* cancelButton;
    NSString *filterByDate, *filterByEmployeeName;
    NSNumber *filterByEmployeeId;
}
- (IBAction)revealMenu:(id)sender;

@property (strong, nonatomic) IBOutlet UITableView *timeOffTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (strong, nonatomic) AVPlayerViewController *playerViewController;
- (IBAction)onAddClick:(id)sender;


@end
