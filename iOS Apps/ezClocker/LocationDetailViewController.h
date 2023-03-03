//
//  LocationDetailViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 12/12/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"

@class LocationDetailViewController;

@protocol addLocationViewControllerDelegate
- (void)LocationDetailsDidFinish:(LocationDetailViewController *)controller CancelWasSelected:(bool)cancelWasSelected;
@end

@interface LocationDetailViewController : UIViewControllerEx <UIPickerViewDelegate, UIPickerViewDataSource>
{
    NSString *streetNumber;
    NSString *streetName;
    NSString *city;
    NSString *state;
    NSString *zipCode;
    NSString *country;
    NSMutableArray *assignedEmployeeList;
    UIButton *editButton;
    UIButton *cancelButton;
    UIButton *addButton;
    UIPickerView *pickerViewEmployeeName;
    UIToolbar* pickerToolbar;
    UIView* pickerMainView;
    NSMutableArray *employeeList;
    UIViewController* popoverContent;

}
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl2;
@property (weak, nonatomic) IBOutlet UILabel *cityStateZipLabel;
@property (weak, nonatomic) IBOutlet UILabel *separatorLbl1;
@property (strong, nonatomic) IBOutlet UITableView *locationDetailsTable;
@property (weak, nonatomic) IBOutlet UITextField *phoneLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (assign, nonatomic) IBOutlet id <addLocationViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar1;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar2;
@property (nonatomic, strong) NSMutableDictionary* locationDetails;
-(void) onSaveClick;

@end
