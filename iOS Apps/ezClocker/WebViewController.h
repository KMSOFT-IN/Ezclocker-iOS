//
//  WebViewController.h
//  ezClocker
//
//  Created by Logileap on 25/10/21.
//  Copyright © 2021 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : UIViewController

@property NSURL* url;
@property WKWebView *wkWebView;

+(UINavigationController *) getInstance;


@end

NS_ASSUME_NONNULL_END
