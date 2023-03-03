//
//  ScheduleStartDaysViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 7/31/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
NS_ASSUME_NONNULL_BEGIN

@protocol ScheduleStartDayDelegate
- (void)dayOptionWasSelected: (int) selectedOption;
@end

@interface ScheduleStartDaysViewController : UIViewControllerEx <UITableViewDelegate, UITableViewDataSource>
- (IBAction)doCancel:(UIBarButtonItem *)sender;
@property (weak, nonatomic) IBOutlet UITableView *scheduleDaysTable;
@property (nonatomic, weak) id <ScheduleStartDayDelegate> delegate;
@property (nonatomic, retain) NSNumber *selectedOptionIndex;
@end

NS_ASSUME_NONNULL_END
