//
//  AssignedEmployeeListViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 3/3/20.
//  Copyright © 2020 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol AssignedEmployeeListViewDelegate
- (void)selectedEmployees: (NSMutableArray *) selectedEmployeeList;
@end


@interface AssignedEmployeeListViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
{
    NSMutableArray *employeeList;
    NSMutableArray *filterEmployeeList;
    NSIndexPath *selectedIndexPath;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id <AssignedEmployeeListViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

//@property (nonatomic , strong) NSMutableArray *assignedEmployeeList;
@property (nonatomic, strong) NSMutableDictionary* jobCodeDetails;
- (IBAction)doCancelClick:(id)sender;
- (IBAction)doDoneClick:(id)sender;

@end

NS_ASSUME_NONNULL_END
