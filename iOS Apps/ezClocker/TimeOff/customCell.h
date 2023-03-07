//
//  customCell.h
//  ezClocker
//
//  Created by iMac on 04/03/23.
//  Copyright © 2023 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimeOffTotalsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface customCell : NSObject
@property(strong,nonatomic)NSString *empName;
@property(strong,nonatomic)NSString *pto;
@property(strong,nonatomic)NSString *sick;
@property(strong,nonatomic)NSString *holiday;
@property(strong,nonatomic)NSString *unPaid;


@end

NS_ASSUME_NONNULL_END
