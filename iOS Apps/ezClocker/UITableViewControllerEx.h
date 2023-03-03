//
//  UITableViewControllerEx.h
//  ezClocker
//
//  Created by Kenneth Lewis on 6/14/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVProgressHUD.h"

@interface UITableViewControllerEx : UITableViewController

- (void) startSpinnerWithMessage:(NSString*)msg;
- (void) stopSpinner;
@end
