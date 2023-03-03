//
//  Reminder.h
//  ezClocker
//
//  Created by Raya Khashab on 4/12/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Reminder : NSObject
@property (nonatomic, retain) NSString *ID;
@property (nonatomic, retain) NSString *time;
@property (nonatomic, retain) NSString *days;
@property (nonatomic, retain) NSString *daysIndex;

@end
