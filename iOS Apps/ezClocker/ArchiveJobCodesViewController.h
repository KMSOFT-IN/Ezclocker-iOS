//
//  ArchiveJobCodesViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 12/13/20.
//  Copyright © 2020 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"

@interface ArchiveJobCodesViewController : UITableViewControllerEx{
    NSMutableArray *archiveJobList;
    UIBarButtonItem *editButton;
    UIBarButtonItem* cancelButton;
    BOOL editFlag;
}
- (IBAction)revealMenu:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *archiveJobsTableView;

- (IBAction)onEditClick:(id)sender;
@end
