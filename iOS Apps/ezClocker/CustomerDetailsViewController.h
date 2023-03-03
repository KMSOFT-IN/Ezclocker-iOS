//
//  CustomerDetailsViewController.h
//  ezClocker Personal
//
//  Created by Raya Khashab on 11/29/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class CustomerDetailsViewController;

@protocol addCustomerViewControllerDelegate
- (void)CustomerDetailsDidFinish:(CustomerDetailsViewController *)controller CancelWasSelected:(bool)cancelWasSelected;
@end

@interface CustomerDetailsViewController : UIViewControllerEx

@property (assign, nonatomic) IBOutlet id <addCustomerViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic, strong) NSMutableDictionary* customerDetails;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@end

NS_ASSUME_NONNULL_END
