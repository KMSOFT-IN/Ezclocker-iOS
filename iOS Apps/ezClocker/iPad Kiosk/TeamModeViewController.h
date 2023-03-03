//
//  TeamModeViewController.h
//  ezClocker Kiosk
//
//  Created by Raya Khashab on 1/8/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import "TeamClockViewController.h"

@class TeamModeViewController;

@protocol TeamModeViewControllerDelegate
- (void)adminModeWasSelected:(TeamModeViewController *)controller;
@end

@interface TeamModeViewController : UIViewControllerEx<UICollectionViewDelegate, UICollectionViewDataSource, TeamClockViewControllerDelegate>
{
    NSArray *numPadImages;
    NSArray *numPadValues;
    NSMutableArray *pinValue;
    UITabBarController *tabBarController;
    NSDateFormatter *formatterTime, *formatterISO8601DateTime, *formatterDate;
}
@property (weak, nonatomic) IBOutlet UIView *bottomviewController;
@property (weak, nonatomic) IBOutlet UIView *topViewController;
@property (weak, nonatomic) IBOutlet UIView *pin1View;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *pinViewController;

@property (weak, nonatomic) IBOutlet UICollectionView *pinPadCollectionView;

@property (weak, nonatomic) IBOutlet UILabel *pinLabel1;
@property (weak, nonatomic) IBOutlet UILabel *pinLabel2;
@property (weak, nonatomic) IBOutlet UILabel *pinLabel3;
@property (weak, nonatomic) IBOutlet UILabel *pinLabel4;
@property (weak, nonatomic) IBOutlet UILabel *currentDateLabel;

@property (weak, nonatomic) IBOutlet UIView *leftHandView;
@property (assign, nonatomic) IBOutlet id <TeamModeViewControllerDelegate> delegate;

@end
