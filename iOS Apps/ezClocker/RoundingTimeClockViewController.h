//
//  RoundingTimeClockViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 7/29/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

NS_ASSUME_NONNULL_BEGIN
@protocol RoundingTimeClockDelegate
- (void)roundingOptionWasSelected: (int) selectedOption;
@end

@interface RoundingTimeClockViewController : UIViewControllerEx <UITableViewDelegate, UITableViewDataSource>
- (IBAction)doCancelClick:(UIBarButtonItem *)sender;
@property (weak, nonatomic) IBOutlet UITableView *roundingOptionsTable;
@property (nonatomic, weak) id <RoundingTimeClockDelegate> delegate;
@property (nonatomic, retain) NSNumber *selectedOptionIndex;
@end

NS_ASSUME_NONNULL_END
