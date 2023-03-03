//
//  JobCodeListViewController.h
//  ezClocker
//
//  Created by Logileap on 11/20/19.
//  Copyright © 2019 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol JobCodeListViewDelegate
- (void)searchJobCode: (NSDictionary *) jobCodeObj;
@end

@interface JobCodeListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) id <JobCodeListViewDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *jobCodes;

@end

NS_ASSUME_NONNULL_END
