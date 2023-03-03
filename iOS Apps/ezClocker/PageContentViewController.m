//
//  PageContentViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 8/4/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import "PageContentViewController.h"

@interface PageContentViewController ()

@end

@implementation PageContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.iPhoneView setHidden:YES];
    [self.iPadView setHidden:YES];
#ifdef IPAD_VERSION
    self.iPadbackgroundImageView.image = [UIImage imageNamed:self.imageFile];
    self.iPadlogoImageView.image = [UIImage imageNamed:self.imageLogoFile];
    self.iPadtitleLabel.text = self.titleFile;
    [self.iPadView setHidden:NO];
#else
    self.backgroundImageView.image = [UIImage imageNamed:self.imageFile];
    self.logoImageView.image = [UIImage imageNamed:self.imageLogoFile];
    self.titleLabel.text = self.titleFile;
    self.subTitleLabel.text = self.subTitleFile;
    [self.iPhoneView setHidden:NO];
#endif
}

@end
