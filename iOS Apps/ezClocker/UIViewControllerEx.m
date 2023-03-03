//
//  UIViewControllerEx.m
//  ezClocker
//
//  Created by Kenneth Lewis on 6/14/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import "UIViewControllerEx.h"

@interface UIViewControllerEx ()

@end

@implementation UIViewControllerEx

//ISPINNER_FOOTER_IMPLEMENTATION()

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) startSpinnerWithMessage:(NSString*)msg {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
    [SVProgressHUD showWithStatus:msg];
    self.view.userInteractionEnabled = FALSE;
    if (self.tabBarController) {
        self.tabBarController.view.userInteractionEnabled = FALSE;
    }
}

- (void) stopSpinner {
    [SVProgressHUD dismiss];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.view.userInteractionEnabled = TRUE;
    if (self.tabBarController) {
        self.tabBarController.view.userInteractionEnabled = TRUE;
    }
}

@end
