//
//  ScheduleDetailViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 1/19/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import "LocationsWebService.h"

@class ScheduleDetailViewController;

@protocol scheduleDetailViewControllerDelegate
- (void)scheduleDetailViewControllerDidFinish:(ScheduleDetailViewController *)controller;
@end

@interface ScheduleDetailViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate, LocationsWebServicesDelegate>{
    UIDatePicker *theDatePicker;
    UIToolbar* pickerToolbar;
    UIView* pickerViewDate;
    UIPickerView *pickerViewEmployeeName;
    UIPickerView *pickerViewLocations;
    NSMutableData *data;
    NSMutableArray *employeeList;
    NSMutableArray *assignedLocationList;
    NSMutableArray *locationList;
    NSDateFormatter *formatterISO8601DateTime, *formatterTime12, *formatterDate;
    UILabel *locationPickerViewtitle;
    UIViewController* popoverContent;
    UIToolbar* keyboardToolbar;
    
}
@property (strong, nonatomic) IBOutlet UIView *dateView;
@property (weak, nonatomic) IBOutlet UITextField *startTimeField;
@property (weak, nonatomic) IBOutlet UITextField *endTimeField;
@property (weak, nonatomic) IBOutlet UITextField *locationField;

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl1;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl2;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl3;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl4;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl5;

@property (weak, nonatomic) IBOutlet UIView *endTimeView;
@property (weak, nonatomic) IBOutlet UIView *startTimeView;

@property (weak, nonatomic) IBOutlet UIDatePicker *endDatePicker;
@property (weak, nonatomic) IBOutlet UIDatePicker *startDatePicker;


@property (assign, nonatomic) IBOutlet id <scheduleDetailViewControllerDelegate> delegate;
- (IBAction)doScheduleSave:(id)sender;
- (IBAction)doScheduleCancel:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *employeeNameField;
- (IBAction)doSelectEmployeeNameField:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;
@property (strong, nonatomic) NSDictionary *selectedSchedule;

@property (weak, nonatomic) IBOutlet UIView *noteView;
@end
