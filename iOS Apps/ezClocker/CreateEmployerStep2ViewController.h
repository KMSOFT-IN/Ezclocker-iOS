//
//  CreateEmployerStep2ViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 8/14/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
//#import "CreateEmployerAccountViewController.m"

@class CreateEmployerStep2ViewController;

@protocol CreateEmployerAccountStep2Delegate
- (void)CreateEmployerAccountStep2DidFinish:(CreateEmployerStep2ViewController *)controller;
//- (void)loginViewControllerWasSelected:(CreateEmployerAccountViewController *)controller;
- (void)CreateEmployerWasSelected:(CreateEmployerStep2ViewController *)controller;
- (void)createViewControllerFromStep2WasSelected:(CreateEmployerStep2ViewController *)controller;

@end

@interface CreateEmployerStep2ViewController : UIViewControllerEx<NSURLConnectionDataDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
    NSMutableData *data;
    UIToolbar* pickerToolbar;
    UIPickerView *industryPickerView;
    UIView* pickerView;
    NSArray *pickerData;
    UIViewController* popoverContent;
}

- (IBAction)doBackAction:(id)sender;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIView *subview;
- (IBAction)doTermsofService:(id)sender;

- (IBAction)doCreateEmployer:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@property (weak, nonatomic) IBOutlet UIButton *termsOfServiceButton;
@property (assign, nonatomic) IBOutlet id <CreateEmployerAccountStep2Delegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *industryTextField;

@end
