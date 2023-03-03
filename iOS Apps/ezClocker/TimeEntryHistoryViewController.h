//
//  TimeEntryHistoryViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 2/27/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif

@class TimeEntryHistoryViewController;

@protocol historyTimeEntryViewControllerDelegate
- (void)historyTimeEntryViewControllerDidFinish:(TimeEntryHistoryViewController *)controller;
@end

@interface TimeEntryHistoryViewController : UIViewControllerEx<UITableViewDelegate, NSURLConnectionDataDelegate>{
    NSDateFormatter *formatterDateTime12, *formatterISO8601DateTime;
    NSMutableData *data;
    NSMutableArray *historyItems;

}

@property (weak, nonatomic) IBOutlet UILabel *clockOutLabel;
@property (assign, nonatomic) IBOutlet id <historyTimeEntryViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *clockInLabel;
@property (weak, nonatomic) IBOutlet UITableView *historyTable;
@property (strong, nonatomic) NSString *timeEntryID;
@property (strong, nonatomic) NSString *clockInDateTime;
@property (strong, retain) NSString *clockOutDateTime;
@property (nonatomic, retain) NSString *employeeName;


@end
