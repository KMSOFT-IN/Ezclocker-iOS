//
//  CancelSubscriptionViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 5/14/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol cancelSubscriptionViewControllerDelegate
- (void)cancelSubscriptionViewControllerDidFinish:(UIViewController *)controller BackBtnWasSelected:(bool)cancelWasSelected;
@end

@interface CancelSubscriptionViewController : UIViewController<UITextViewDelegate>
{
    UIToolbar* keyboardToolbar;
}
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (assign, nonatomic) IBOutlet id <cancelSubscriptionViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextView *reasonTextView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
- (IBAction)goToiTunesStore:(id)sender;
- (IBAction)doCancelViewAction:(id)sender;

@end
