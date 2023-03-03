//
//  ShiftDetailsViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 10/17/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
@class ShiftDetailsViewController;

@protocol ShiftDetailsViewControllerDelegate
- (void)shiftDetailsViewDidFinish:(ShiftDetailsViewController *)controller;
@end

@interface ShiftDetailsViewController : UIViewControllerEx<NSURLConnectionDataDelegate>{
    NSMutableData *data;
    NSString *streetNum;
    NSString *streetName;
    NSString *city;
    NSString *state;

}
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *streetAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *cszAddressLabel;
- (IBAction)doViewMap:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *viewMapButton;
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl1;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl2;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl3;

@property (assign, nonatomic) IBOutlet id <ShiftDetailsViewControllerDelegate> delegate;
@property (strong, nonatomic) NSNumber *shiftLocId;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) NSString *shiftNotes;

@end
