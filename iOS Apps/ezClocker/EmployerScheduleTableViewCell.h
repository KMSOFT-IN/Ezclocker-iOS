//
//  EmployerScheduleTableViewCell.h
//  ezClocker
//
//  Created by Raya Khashab on 8/20/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmployerScheduleTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *empNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *shiftTimeLabel;

@end

NS_ASSUME_NONNULL_END
