//
//  CustomerWebservice.h
//  ezClocker
//
//  Created by KMSOFT on 31/01/20.
//  Copyright © 2020 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "user.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "CommonLib.h"
#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif


@interface CustomerWebservice : NSObject
+(void) fetchAllCustomers:(void(^)(NSMutableArray *))callback;
+(void) callGetAllCustomers:(bool)useSavedValues withCompletion:(ServerResponseCompletionBlock)completion;
+(void) callDeleteSelectedCustomer:(NSNumber*)customerId withCompletion:(ServerResponseCompletionBlock)completion;
@end

