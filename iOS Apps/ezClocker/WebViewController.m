//
//  WebViewController.m
//  ezClocker
//
//  Created by Logileap on 25/10/21.
//  Copyright © 2021 ezNova Technologies LLC. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    self.wkWebView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
    //wkWebView.navigationDelegate = self;
    [self.view addSubview:self.wkWebView];
    [self load];
}

-(void) load {
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:_url]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

+(UINavigationController *) getInstance {
    UINavigationController* webViewContrtoller = [[UIStoryboard storyboardWithName:@"Web" bundle:nil] instantiateViewControllerWithIdentifier:@"WebNavigation"];
    return webViewContrtoller;
}

- (IBAction)doneButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:true completion:NULL];
}

- (IBAction)refreshButtonTapped:(id)sender {
    [self.wkWebView reload];
}

@end
