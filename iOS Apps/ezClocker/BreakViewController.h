//
//  BreakbViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 12/11/21.
//  Copyright © 2021 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonLib.h"

NS_ASSUME_NONNULL_BEGIN
@protocol BreakViewControllerDelegate
- (void)breakScreenDone;
@end

@interface BreakViewController : UIViewController
{
    NSTimer *stopTimer;
    NSDate *startDate;
    BOOL running;
}

@property NSURL* url;


@property (weak, nonatomic) IBOutlet UIButton *breakOutBtn;
+(UINavigationController *) getInstance;
@property (weak, nonatomic) IBOutlet UIButton *clockOutBtn;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (nonatomic, weak) id <BreakViewControllerDelegate> delegate;

@property (nonatomic, strong) NSString *strClockInTime;
@property (nonatomic, strong) NSString *strBreakInTime;
@property (nonatomic, strong) NSDate *breakInTime;

- (IBAction)doEndBreakClick:(id)sender;

- (IBAction)revealMenu:(id)sender;

@end

NS_ASSUME_NONNULL_END
