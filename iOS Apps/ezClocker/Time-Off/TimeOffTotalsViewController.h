//
//  TimeOffTotalsViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 02/12/23.
//  Copyright © ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"
#import "ECSlidingViewController.h"
#import <AVKit/AVKit.h>
@interface TimeOffTotalsViewController : UITableViewControllerEx
{
    NSMutableArray *timeOffTotalsList;
}
- (IBAction)revealMenu:(id)sender;

@property (strong, nonatomic) IBOutlet UITableView *timeOffTableView;
@property (strong, nonatomic) AVPlayerViewController *playerViewController;


@end
