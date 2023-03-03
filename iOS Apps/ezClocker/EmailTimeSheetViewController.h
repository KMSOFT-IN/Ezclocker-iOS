//
//  EmailTimeSheetViewController.h
//  Created by Raya Khashab on 10/6/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
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


@class EmailTimeSheetViewController;

@protocol emailTimeSheetViewControllerDelegate
- (void)emailTimeSheetViewControllerDidFinish:(EmailTimeSheetViewController *)controller;
@end

@interface EmailTimeSheetViewController : UIViewControllerEx<UITextViewDelegate, UITextFieldDelegate, WWCalendarTimeSelectorProtocol>
{
    CGPoint originalCenter;
    UITextView *messageTextView;
    NSMutableData *data;

}
@property (weak, nonatomic) IBOutlet UIView *lastViewSection;
@property (weak, nonatomic) IBOutlet UILabel *MessageLabel;
- (IBAction)doCancel:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *fromTextField;

@property (weak, nonatomic) IBOutlet UITextView *MessageTextView;

- (IBAction)doSubmitEmail:(id)sender;
- (IBAction)doOptionSwitchChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *SubjectLabel;
@property (weak, nonatomic) IBOutlet UITextField *EmailTextEdit;
@property (weak, nonatomic) IBOutlet UIView *bottomViewContainer;
@property (assign, nonatomic) IBOutlet id <emailTimeSheetViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *optionsViewContainer;
@property (weak, nonatomic) IBOutlet UISwitch *decimalOptionSwitch;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewContainerTopConstraint;
@property (weak, nonatomic) IBOutlet UIButton *submitBtn;
@property (strong, nonatomic) NSString *startDate;
@property (strong, nonatomic) NSString *endDate;
@property (nonatomic, retain) NSNumber *employeeID;
@property (nonatomic, retain) NSString *employeeEmail;
@property (nonatomic, retain) NSNumber *totalPay;
@property (nonatomic, assign) BOOL emailAllTimeSheets;

@property (nonatomic, copy) NSString *selectedFromDateValue;
@property (nonatomic, copy )NSString *selectedToDateValue;

- (IBAction)doSetDateRange:(id)sender;
@end
