//
//  EarlyClockInTableViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 7/19/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

NS_ASSUME_NONNULL_BEGIN
@protocol EarlyClockInTableViewDelegate
- (void)optionWasSelected: (int) selectedOption;
@end

@interface EarlyClockInTableViewController : UIViewControllerEx <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *optionsTableView;
- (IBAction)doCancelBtnClick:(UIBarButtonItem *)sender;
@property (nonatomic, weak) id <EarlyClockInTableViewDelegate> delegate;
@property (nonatomic, retain) NSNumber *selectedOptionIndex;
@end

NS_ASSUME_NONNULL_END
