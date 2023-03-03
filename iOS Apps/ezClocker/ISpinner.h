//
//  ISpinner.h
//  ezClocker
//
//  Created by Kenneth Lewis on 6/14/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#ifndef ISpinner_h
#define ISpinner_h

@protocol ISpinner <NSObject>

- (void)startSpinner;
- (void)stopSpinner;
- (void)startSpinnerWithMessage:(NSString*)msg;

@end

#define ISPINNER_HEADER_DECLARATION() \
@property (strong, nonatomic) MBProgressHUD *spinner; \
 \
- (void)startSpinner; \
- (void)stopSpinner; \
- (void)startSpinnerWithMessage:(NSString*)msg;

#define ISPINNER_FOOTER_IMPLEMENTATION() \
@synthesize spinner; \
 \
- (void) startSpinner { \
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE; \
    if (!self.spinner) { \
        self.spinner = [[MBProgressHUD alloc] initWithView:self.view]; \
        [self.view addSubview:self.spinner]; \
    } \
    [self.spinner show:YES]; \
    self.view.userInteractionEnabled = FALSE; \
    if (self.tabBarController) { \
        self.tabBarController.view.userInteractionEnabled = FALSE; \
    } \
} \
 \
- (void)startSpinnerWithMessage:(NSString*)msg { \
    [self startSpinner]; \
    spinner.labelText = msg; \
} \
 \
- (void) stopSpinner { \
    if (self.spinner) { \
        [self.spinner hide:YES]; \
    } \
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; \
    self.view.userInteractionEnabled = TRUE; \
    if (self.tabBarController) { \
        self.tabBarController.view.userInteractionEnabled = TRUE; \
    } \
}

#endif /* ISpinner_h */
