//
//  completionblockdefines.h
//  ezClocker
//
//  Created by Kenneth Lewis on 1/8/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#ifndef completionblockdefines_h
#define completionblockdefines_h

typedef enum __ActionResult {
    resultYes,
    resultNo,
    resultCancel
} YesNoCancelResult;

typedef void (^CompletionBlock)();
typedef void (^SuccessfulCompletionBlock)(BOOL successful, NSError* __nullable error);
typedef void (^ServerCompletionBlock)(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error);
typedef void (^ServerResponseCompletionBlock)(NSInteger errorCode, NSString* __nullable resultMessage, NSDictionary* __nullable results, NSError* __nullable error);
typedef void (^YesNoCancelCompletionBlock)(YesNoCancelResult Result);
typedef void (^UIBackgroundFetchResultCompletionBlock)(UIBackgroundFetchResult result, NSInteger errorCode, NSError* __nullable error);

#endif /* completionblockdefines_h */
