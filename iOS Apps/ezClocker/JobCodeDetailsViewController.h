//
//  JobCodeDetailsViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 4/7/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerEx.h"
#import "AssignedEmployeeListViewController.h"

@class JobCodeDetailsViewController;

@protocol jobCodeDetailViewControllerDelegate
- (void)JobCodeDetailsDidFinish:(JobCodeDetailsViewController *)controller CancelWasSelected:(bool)cancelWasSelected;
@end

@interface JobCodeDetailsViewController : UIViewControllerEx<UITextFieldDelegate, AssignedEmployeeListViewDelegate>
{
    NSMutableArray *assignedEmployeeList;
    NSMutableArray *selectedEmployees;
    UIButton *editButton;
    UIButton *cancelButton;
    UIButton *addButton;
    UIPickerView *pickerViewEmployeeName;
    UIToolbar* pickerToolbar;
    UIView* pickerMainView;
    NSMutableArray *employeeList;
    UIViewController* popoverContent;

}

@property (assign, nonatomic) IBOutlet id <jobCodeDetailViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *jobCodeIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *jobCodeNameTextField;
@property (weak, nonatomic) IBOutlet UITableView *assignedEmployeesTableView;
@property (weak, nonatomic) IBOutlet UITextField *hourlyRateTextField;
@property (weak, nonatomic) IBOutlet UIView *hourlyRateView;
@property (weak, nonatomic) IBOutlet UISwitch *assignedAllEmployeesSwitch;
- (IBAction)doEmployeesSwitchChanged:(id)sender;
@property (nonatomic, strong) NSMutableDictionary* jobCodeDetails;
@property (strong, nonatomic) IBOutlet UIView *mainView;

@end
