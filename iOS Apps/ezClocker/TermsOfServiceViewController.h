//
//  TermsOfServiceViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 3/1/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@class TermsOfServiceViewController;

@protocol termsOfServiceViewControllerDelegate
- (void)termsOfServiceControllerDidFinishViewing:(TermsOfServiceViewController *)controller;
@end

@interface TermsOfServiceViewController : UIViewController
@property (assign, nonatomic) IBOutlet id <termsOfServiceViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet WKWebView *mainWebView;
- (IBAction)doBackBtnClick:(id)sender;


@end
