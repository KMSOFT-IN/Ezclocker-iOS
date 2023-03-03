//
//  DateRangeViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 12/30/17.
//  Copyright © 2017 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

@interface DateRangeViewController : UIViewControllerEx<UITextFieldDelegate>
{
    int TextFieldMode;
}


@property (weak, nonatomic) IBOutlet UIView *datePickerView;
@property (weak, nonatomic) IBOutlet UITextField *fromDateTextField;
@property (weak, nonatomic) IBOutlet UITextField *toDateTextField;
@property (weak, nonatomic) IBOutlet UIDatePicker *theDatePicker;
@property (nonatomic, copy) NSString* fromDateValue;
@property (nonatomic, copy) NSString* toDateValue;
- (IBAction)datePickerValueChanged:(id)sender;


@end
