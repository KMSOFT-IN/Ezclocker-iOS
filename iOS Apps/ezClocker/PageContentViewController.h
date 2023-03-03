//
//  PageContentViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 8/4/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

@interface PageContentViewController : UIViewControllerEx
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *iPhoneView;
@property (weak, nonatomic) IBOutlet UIView *iPadView;


@property (weak, nonatomic) IBOutlet UIImageView *iPadbackgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iPadlogoImageView;
@property (weak, nonatomic) IBOutlet UILabel *iPadtitleLabel;

@property NSUInteger pageIndex;
@property NSString *imageFile;
@property NSString *imageLogoFile;
@property NSString *titleFile;
@property NSString *subTitleFile;
@end
