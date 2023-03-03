//
//  AddTimeEntryViewController.h
//  TCS Mobile
//
//  Created by Raya Khashab on 11/10/12.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import "JobCodeListViewController.h"
#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif

@class AddTimeEntryViewController;

@protocol addTimeEntryViewControllerDelegate
- (void)addTimeEntryViewControllerDidFinish:(AddTimeEntryViewController *)controller;
@end

@interface AddTimeEntryViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UITableViewDelegate, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, JobCodeListViewDelegate>{
    NSDate *clockInPickerDate;
    UIDatePicker *pickDate;
    NSString *clockInTime;
    NSString *clockOutTime;
    NSString* description;
    NSDateFormatter *formatterDateTime12, *formatterISO8601DateTime;
    int TextFieldMode;
    UIDatePicker *theDatePicker;
    UIToolbar* pickerToolbar;
    UIView* pickerView;
    UIViewController* popoverContent;
    UIToolbar* keyboardToolbar;
    UIPickerView *pickerViewJobCode;
    NSDictionary *selectedJobCode;
    
}
@property (weak, nonatomic) IBOutlet UILabel *notesLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextView *reasonTextView;

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIView *clockInView;
@property (weak, nonatomic) IBOutlet UIView *clockOutView;

@property (weak, nonatomic) IBOutlet UILabel *clockInLabel;
@property (weak, nonatomic) IBOutlet UILabel *clockOutLabel;
@property (weak, nonatomic) IBOutlet UITextField *clockInField;
@property (weak, nonatomic) IBOutlet UITextField *clockOutField;
@property (weak, nonatomic) IBOutlet UITextField *jobCodeField;
@property (weak, nonatomic) IBOutlet UIView *jobCodeView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *jobCodeViewHeight;
@property (nonatomic, retain) NSNumber *employeeID;
@property (assign, nonatomic) IBOutlet id <addTimeEntryViewControllerDelegate> delegate;
- (IBAction)doTimeEntrySave:(id)sender;
- (IBAction)doTimeEntryCancel:(id)sender;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePickerView;
@property (weak, nonatomic) IBOutlet UIDatePicker *clockOutDatePicker;

@property (nonatomic, copy) NSMutableArray *jobCodes;
@property (nonatomic, copy) NSMutableDictionary *primaryJobCode;


@end
