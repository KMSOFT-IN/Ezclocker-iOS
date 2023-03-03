//
//  CancelSubscriptionViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 5/14/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import "CancelSubscriptionViewController.h"
#import "MetricsLogWebService.h"
#import "user.h"
#import "CommonLib.h"

@interface CancelSubscriptionViewController ()

@end

@implementation CancelSubscriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _reasonTextView.delegate = self;
    //put a borde on the text view
    _reasonTextView.text = @"";
    CALayer *imageLayer = _reasonTextView.layer;
    [imageLayer setCornerRadius:10];
    [imageLayer setBorderWidth:2.1];
    imageLayer.borderColor=[[UIColor lightGrayColor] CGColor];
    
    _mainView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboardAction)];
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:flexSpace, doneDateBarBtn, nil];
    
    keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    keyboardToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [keyboardToolbar sizeToFit];
    
    
    [keyboardToolbar setItems:itemArray animated:YES];
    
    [_reasonTextView setInputAccessoryView:keyboardToolbar];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    [_scrollView setScrollEnabled:YES];
    [_scrollView setContentSize:CGSizeMake(320, 650)];
    _scrollView.contentOffset = CGPointZero;
    
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)goToiTunesStore:(id)sender {
    UserClass *user = [UserClass getInstance];
    //send an email to the team with the info
    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Somebody canceled from iTunes email= %@ Reason= %@", user.userEmail, _reasonTextView.text]];

    //send a message to the parent view that we are done
    [self.delegate cancelSubscriptionViewControllerDidFinish:self.parentViewController BackBtnWasSelected: FALSE];
  //  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://apps.apple.com/account/subscriptions"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://apps.apple.com/account/subscriptions"]options:@{} completionHandler:nil];

    
}

- (IBAction)doCancelViewAction:(id)sender {
    [self.delegate cancelSubscriptionViewControllerDidFinish:self.parentViewController BackBtnWasSelected: TRUE];
}


-(void)dismissKeyboardAction{
    [_reasonTextView resignFirstResponder];
    
}
-(void)removeKeyboard{
    [_reasonTextView resignFirstResponder];
}


@end
