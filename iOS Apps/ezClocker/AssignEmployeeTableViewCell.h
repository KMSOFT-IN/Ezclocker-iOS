//
//  AssignEmployeeTableViewCell.h
//  ezClocker
//
//  Created by Logileap on 16/03/20.
//  Copyright © 2020 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssignEmployeeTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *selectedButton;
@property (weak, nonatomic) IBOutlet UIButton *primaryButton;

@property (weak, nonatomic) IBOutlet UILabel *employeeNameLabel;

@end

NS_ASSUME_NONNULL_END
