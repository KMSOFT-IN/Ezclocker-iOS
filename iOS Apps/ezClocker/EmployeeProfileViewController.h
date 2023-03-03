//
//  EmployeeProfileViewController.h
//  Created by Raya Khashab on 1/27/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "UIViewControllerEx.h"
#import "user.h"
#import "ClockWebServices.h"
#import "CheckClockStatusWebService.h"
#import "JobCodeListViewController.h"

#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif

// ****************************************************
// NOTE: This is the Clock In/Clock Out View Controller
// that is part of the TimeSheetMasterViewController in
// a UITabBarController
// ****************************************************
@interface EmployeeProfileViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UISplitViewControllerDelegate, clockWebServicesDelegate, checkClockStatusWebServicesDelegate, JobCodeListViewDelegate>
{
    NSNumber *employeeID;
    NSString *employeeName;    
    NSString *employeeEmail;    
    NSMutableData *data;
    bool inviteCalledFlag;
    NSMutableArray *jobsList;
    NSDictionary *selectedJobCode;
    NSDate *lastBreakInTime;
    NSString *strLastBreakInTime;
    NSString *strLastClockInTime;
    NSString *lastJobName;
    bool isActiveBreakIn, isActiveClockIn;
    NSDateFormatter *formatterISO8601DateTime, *formatterDateTime12hr;

}
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *clockInLabel;
@property (weak, nonatomic) IBOutlet UILabel *breakInLabel;
@property (weak, nonatomic) IBOutlet UILabel *jobLabel;

@property (weak, nonatomic) IBOutlet UILabel *clockOutLabel;
@property (weak, nonatomic) IBOutlet UIButton *clockInBtn;
@property (weak, nonatomic) IBOutlet UIButton *clockOutBtn;
- (IBAction)doClockIn:(id)sender;
- (IBAction)doClockOut:(id)sender;

- (IBAction)doInvite:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *employeeImage;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (weak, nonatomic) IBOutlet UILabel *employeeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *inviteInfoLabel;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *clockLabelsView;

@property (weak, nonatomic) IBOutlet UIView *inviteInfoView;
@property (weak, nonatomic) IBOutlet UIView *inviteBtnView;
@property (weak, nonatomic) IBOutlet UIView *clockBtnsView;

@property (nonatomic, retain) NSNumber *employeeID;
@property (nonatomic, retain) NSString *employeeName;
@property (nonatomic, retain) NSString *employeeEmail;
@property (nonatomic, retain) NSString *acceptedInvite;
@property (nonatomic, copy) NSDictionary *primaryJobCode;

-(void) LoadData;

@end
