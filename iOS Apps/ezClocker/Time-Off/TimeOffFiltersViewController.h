//
//  TimeOffFiltersViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 2/26/23.
//  Copyright (c) ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

@class TimeOffFiltersViewController;

@protocol TimeOffFiltersViewControllerDelegate
- (void)TimeOffFiltersViewControllerDidFinish:(TimeOffFiltersViewController *)controller;
- (void)timeOffFiltersDidFinish:(BOOL)cancelSelected employeeName:(NSString*)employeeName dateSelected: (NSString*) dateFilter;

@end

@interface TimeOffFiltersViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate>{
 //   UIDatePicker *theDatePicker;
    UIToolbar* pickerToolbar;
    UIView* pickerViewDate;
    UIPickerView *pickerViewRequestTypes;
    UIPickerView *pickerViewEmployeeName;
    NSArray *requestTypeList;
    NSMutableData *data;
    NSMutableArray *employeeList;
    NSDateFormatter *formatterISO8601DateTime, *formatterTime12, *formatterDate, *formatterDateTime12;
    UIViewController* popoverContent;
    UIToolbar* keyboardToolbar;
    
}
@property (strong, nonatomic) IBOutlet UIView *dateView;
@property (weak, nonatomic) IBOutlet UITextField *startTimeField;


@property (strong, nonatomic) IBOutlet UIView *mainView;

- (IBAction)doEmployeeFieldClick:(id)sender;

- (IBAction)doSave:(UIBarButtonItem *)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;
@property (weak, nonatomic) IBOutlet UIView *startTimeView;
- (IBAction)doSelectEmployee:(id)sender;

- (IBAction)doCancelView:(id)sender;

@property (weak, nonatomic) IBOutlet UIDatePicker *startDatePicker;


@property (assign, nonatomic) IBOutlet id <TimeOffFiltersViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *statusView;

@property (weak, nonatomic) IBOutlet UITextField *employeeNameField;
- (IBAction)doSelectEmployeeNameField:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) NSDictionary *selectedTimeOff;

@property (weak, nonatomic) IBOutlet UIView *employeeView;


@end
