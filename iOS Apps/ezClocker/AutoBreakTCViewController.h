//
//  AutoBreakTCViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 7/18/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

NS_ASSUME_NONNULL_BEGIN
@class AutoBreakTCViewController;

@protocol AutoBreakTCViewControllerDelegate
- (void)autoBreaksTandCDidFinish:(BOOL)userAgreed;
@end

@interface AutoBreakTCViewController : UIViewControllerEx
@property (nonatomic, weak) id <AutoBreakTCViewControllerDelegate> delegate;
- (IBAction)declinedBtnClick:(UIButton *)sender;
- (IBAction)agreedBtnClick:(UIButton *)sender;
@end

NS_ASSUME_NONNULL_END
