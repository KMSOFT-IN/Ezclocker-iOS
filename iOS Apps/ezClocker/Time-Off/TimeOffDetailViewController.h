//
//  TimeOffDetailViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 1/29/23.
//  Copyright (c) ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

@class TimeOffDetailViewController;

@protocol timeOffDetailViewControllerDelegate
- (void)timeOffDetailViewControllerDidFinish:(TimeOffDetailViewController *)controller;
@end

@interface TimeOffDetailViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate>{
    UIDatePicker *theDatePicker;
    UIToolbar* pickerToolbar;
    UIView* pickerViewDate;
    UIPickerView *pickerViewEmployeeName;
    UIPickerView *pickerViewRequestTypes;
    NSMutableData *data;
    NSMutableArray *employeeList;
    NSArray *requestTypeList;
    NSDictionary *serverRequestTypeList;
    NSDateFormatter *formatterISO8601DateTime, *formatterTime12, *formatterDate, *formatterDateTime12;
    UIViewController* popoverContent;
    UIToolbar* keyboardToolbar;
    
}
@property (strong, nonatomic) IBOutlet UIView *dateView;
@property (weak, nonatomic) IBOutlet UITextField *startTimeField;
@property (weak, nonatomic) IBOutlet UITextField *endTimeField;

@property (weak, nonatomic) IBOutlet UITextField *reqTypeField;

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl1;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl2;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl3;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl4;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl5;
@property (weak, nonatomic) IBOutlet UIButton *denyBtn;
@property (weak, nonatomic) IBOutlet UIButton *approveBtn;
- (IBAction)doDenyBtnClick:(id)sender;
- (IBAction)doApproveBtnClick:(id)sender;
- (IBAction)doEmployeeFieldClick:(id)sender;
- (IBAction)doRequestTypesClick:(id)sender;

- (IBAction)doSave:(UIBarButtonItem *)sender;
@property (weak, nonatomic) IBOutlet UIView *endTimeView;
@property (weak, nonatomic) IBOutlet UIButton *middleBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;
@property (weak, nonatomic) IBOutlet UIView *startTimeView;
- (IBAction)doSelectEmployee:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *BtnsView;
- (IBAction)doCancelView:(id)sender;
@property (weak, nonatomic) IBOutlet UIDatePicker *endDatePicker;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIDatePicker *startDatePicker;


@property (assign, nonatomic) IBOutlet id <timeOffDetailViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UISwitch *allDaySwitch;
@property (weak, nonatomic) IBOutlet UIView *statusView;
- (IBAction)doAllDaySwitchChange:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *employeeNameField;
- (IBAction)doSelectEmployeeNameField:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;
@property (strong, nonatomic) NSDictionary *selectedTimeOff;
@property (weak, nonatomic) IBOutlet UIView *allDayView;
- (IBAction)doChangeHours:(UITextField *)sender;
- (IBAction)doMiddleBtnClick:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UIView *noteView;
@property (weak, nonatomic) IBOutlet UIView *employeeView;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (weak, nonatomic) IBOutlet UITextField *hoursPerDayField;

@end
