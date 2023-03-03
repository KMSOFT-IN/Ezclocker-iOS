//
//  TeamClockViewController.h
//  ezClocker Kiosk
//
//  Created by Raya Khashab on 1/12/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import "ClockWebServices.h"
#import "TimeEntry.h"
#import "JobCodeListViewController.h"
#import "EmailFeedbackViewController.h"
#import "AppStoreRatingWebService.h"
#import <StoreKit/StoreKit.h>

@class TeamClockViewController;

@protocol TeamClockViewControllerDelegate
- (void)TeamcSignOut:(TeamClockViewController *)controller;

@end

@interface TeamClockViewController : UIViewControllerEx<clockWebServicesDelegate, JobCodeListViewDelegate,emailFeedbackViewControllerDelegate, UITextFieldDelegate>
{
    NSDateFormatter *formatterTime;
    NSDateFormatter *formatterDate;
    bool isActiveClockIn;
    bool isActiveBreak;
    NSDate *breakInTime;
    bool allowRecordingOfUnpaidBreaks;
    UIPickerView *pickerViewJobCode;
    NSMutableArray *jobCodesList;
    NSNumber *primaryJobCodeId;
    NSTimer *stopTimer;
    NSDate *startDate;
    BOOL running;
}
@property (assign, nonatomic) IBOutlet id <TeamClockViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *signOutBtn;
@property (weak, nonatomic) IBOutlet UILabel *todayDateLabel;

@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *employeeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastClockInLabel;
@property (weak, nonatomic) IBOutlet UIButton *secondaryActionBtn;

@property (weak, nonatomic) IBOutlet UILabel *lastClockOutLabel;
@property (weak, nonatomic) IBOutlet UIButton *mainActionBtn;
@property (weak, nonatomic) IBOutlet UIView *leftHandView;
@property (weak, nonatomic) IBOutlet UIView *leftHandTopView;
@property (nonatomic, retain) NSDictionary *employeeClockInfo;
@property (nonatomic, retain) TimeEntry *timeEntry;
- (IBAction)doSignOut:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *rightHandView;
- (IBAction)doMainActionBtnClick:(id)sender;
- (IBAction)doSecondaryBtnClick:(id)sender;

- (void)determineClockInOrClockOut:(TimeEntry*)aTimeEntry;
- (IBAction)doJobCodes:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *breakTextLabel;
@property (weak, nonatomic) IBOutlet UIView *breakDurationView;
@property (weak, nonatomic) IBOutlet UITextField *jobCodeTextField;
@property (weak, nonatomic) IBOutlet UIView *jobCodeView;
@property (weak, nonatomic) IBOutlet UILabel *breakDurationLabel;
@property (nonatomic, copy) NSDictionary *selectedJobCode;


@end
