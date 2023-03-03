//
//  UpdateEmployeeListWebService.h
//  ezClocker
//
//  Created by Raya Khashab on 8/28/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "completionblockdefines.h"

@class UpdateEmployeeListWebService;

@protocol UpdateEmployeeListWebServiceDelegate
- (void)EmployeeListUpdateServiceCallDidFinish:(UpdateEmployeeListWebService *)controller ErrorCode: (int) errorValue;
@end

@interface UpdateEmployeeListWebService : NSObject


-(void)updateActiveEmployeeList;

@property (assign, nonatomic) IBOutlet id <UpdateEmployeeListWebServiceDelegate> delegate;

@end
