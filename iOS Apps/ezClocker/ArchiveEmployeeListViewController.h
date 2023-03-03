//
//  ArchiveEmployeeListViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 8/27/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerEx.h"
#import "UpdateEmployeeListWebService.h"

@interface ArchiveEmployeeListViewController : UITableViewControllerEx<UpdateEmployeeListWebServiceDelegate>{
    NSMutableArray *archiveEmployeeList;
    UIBarButtonItem *editButton;
    UIBarButtonItem* cancelButton;
    BOOL editFlag;
}
- (IBAction)revealMenu:(id)sender;

@property (strong, nonatomic) IBOutlet UITableView *archiveEmployeeTableView;
- (IBAction)onEditClick:(id)sender;
@end
