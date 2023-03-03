//
//  ScheduleTableViewCell.h
//  ezClocker
//
//  Created by KMSOFT on 28/06/21.
//  Copyright © 2021 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScheduleTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

NS_ASSUME_NONNULL_END
