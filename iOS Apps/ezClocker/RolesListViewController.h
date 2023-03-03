//
//  RolesListViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 01/13/21.
//  Copyright © 2021 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"

NS_ASSUME_NONNULL_BEGIN
@protocol RolesListViewDelegate
- (void)roleWasSelected: (NSString *) roleType;
@end

@interface RolesListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id <RolesListViewDelegate> delegate;
- (IBAction)cancelButtonClick:(id)sender;
@property (nonatomic, retain) NSMutableArray *jobCodes;

@end

NS_ASSUME_NONNULL_END
