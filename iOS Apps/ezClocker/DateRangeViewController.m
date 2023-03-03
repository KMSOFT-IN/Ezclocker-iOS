//
//  DateRangeViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 12/30/17.
//  Copyright © 2017 ezNova Technologies LLC. All rights reserved.
//

#import "DateRangeViewController.h"
#import "NSDate+Extensions.h"
#import "NSString+Extensions.h"
#import <QuartzCore/QuartzCore.h>


@interface DateRangeViewController ()

@end

@implementation DateRangeViewController

int FROM_DATE_TAG = 1;
int TO_DATE_TAG = 2;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //tag the text field so we know which one was clicked in the delegate
    _fromDateTextField.tag = FROM_DATE_TAG;
    _toDateTextField.tag = TO_DATE_TAG;
    TextFieldMode = FROM_DATE_TAG;
    
    _fromDateTextField.text = _fromDateValue;
    _toDateTextField.text = _toDateValue;
    
    //default uipicker to the from date
    BOOL isEmpty = [NSString isNilOrEmpty:_fromDateValue];
    
    if (! isEmpty)
        _theDatePicker.date = [_fromDateValue toDefaultDate];
    
    _fromDateTextField.delegate = self;
    _toDateTextField.delegate = self;

    _fromDateTextField.layer.cornerRadius=8.0f;
    _fromDateTextField.layer.masksToBounds=YES;
    _fromDateTextField.layer.borderColor=[[UIColor blueColor]CGColor];
    _fromDateTextField.layer.borderWidth= 1.0f;

    _toDateTextField.layer.cornerRadius=8.0f;
    _toDateTextField.layer.masksToBounds=YES;
    _toDateTextField.layer.borderColor=[[UIColor clearColor]CGColor];
    _toDateTextField.layer.borderWidth= 1.0f;

    
    // Do any additional setup after loading the view.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {

    // Close the keypad if it is showing
    [self.view.superview endEditing:YES];
    
    UITextField *curField;
    if (textField.tag == 1)
    {
        _fromDateTextField.layer.borderColor=[[UIColor blueColor]CGColor];
        _toDateTextField.layer.borderColor=[[UIColor clearColor]CGColor];
        curField = _fromDateTextField;
        TextFieldMode = FROM_DATE_TAG;
    }
    else
    {
        _fromDateTextField.layer.borderColor=[[UIColor clearColor]CGColor];
        _toDateTextField.layer.borderColor=[[UIColor blueColor]CGColor];
        curField = _toDateTextField;
        TextFieldMode = TO_DATE_TAG;
    }
    
    BOOL isEmpty = [NSString isNilOrEmpty:curField.text];
    
    if (! isEmpty)
        _theDatePicker.date = [curField.text toDefaultDate];
    else
        curField.text = [_theDatePicker.date toDefaultDateString];
    // [curButton setTitle:[theDatePicker.date toLongDateTimeString] forState:UIControlStateNormal];


    // Return no so that no cursor is shown in the text box
    return  NO;
}

- (IBAction)datePickerValueChanged:(id)sender {
    if (TextFieldMode == FROM_DATE_TAG)
    {
        _fromDateTextField.text = [[_theDatePicker date] toDefaultDateString];
        _fromDateValue = _fromDateTextField.text;
    }
    else
    {
        _toDateTextField.text = [[_theDatePicker date] toDefaultDateString];
        _toDateValue = _toDateTextField.text;
    }

}
@end
