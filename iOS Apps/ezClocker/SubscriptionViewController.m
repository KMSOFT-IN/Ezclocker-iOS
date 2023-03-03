//
//  SubscriptionViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 11/6/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "SubscriptionViewController.h"
#import "CommonLib.h"

@interface SubscriptionViewController ()

@end

@implementation SubscriptionViewController
@synthesize TitleLabel;
@synthesize MainInfoLabel;
@synthesize delegate;
@synthesize MainViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIColor *orangeLightOp = UIColorFromRGB(0xdcdcdc);
    MainViewController.backgroundColor = orangeLightOp;
    subscriptionWebService = [[SubscriptionWebService alloc] init];
    TitleLabel.numberOfLines = 0; // Dynamic number of lines
    TitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    TitleLabel.text = @"Your Free Trial or Subsription has Expired!";
    MainInfoLabel.numberOfLines = 0; // Dynamic number of lines
    MainInfoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    MainInfoLabel.text = @"Please visit our website to update your account then press the Try Again button";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doTryAgainClick:(id)sender {
    [subscriptionWebService checkValidLicense];
    //assign self as the delegate so you get the subscription expired/renewed call backs
    subscriptionWebService.delegate = (id) self;
}
- (void)subscriptionExpired{
    //since we are already on the subscription page. Show an alert message
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"ERROR"
                                 message:@"Your subsription is still expired. Please visit our website to update your account"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Your subsription is still expired. Please visit our website to update your account" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    // [alert show];
    
}
- (void)subscriptionValid{
    //communicate to the assigned delegate that the subscription has passed so we can let them in
    //and change the view
    [self.delegate subscriptionCheckPassed];
    
}
- (void)subscriptionNotValid{
    
}

- (void)subscriptionError { 
    
}





- (void)encodeWithCoder:(nonnull NSCoder *)coder { 
    
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection { 
    
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container { 
    
}


- (CGSize)sizeForChildContentContainer:(nonnull id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
    return CGSizeZero;
}


- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container { 
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator { 
    
}

- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator { 
    
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator { 
    
}

- (void)setNeedsFocusUpdate { 
    
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    return FALSE;
}


- (void)updateFocusIfNeeded { 
    
}

@end
