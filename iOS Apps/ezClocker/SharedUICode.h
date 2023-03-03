//
//  SharedUICode.h
//  ezClocker
//
//  Created by Kenneth Lewis on 1/11/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "completionblockdefines.h"

@interface SharedUICode : NSObject

+ (void)checkResultsMessageAndDisplayError:(NSString*)resultMessage error:(NSError*)error;

+ (void)displayServiceUnavailableError;
+ (void)displayServiceUnavailableErrorWithMsg:(NSString*)msg;
+ (void)displayServiceUnavailableErrorWithMsg:(NSString*)msg withCompletion:(CompletionBlock)completion;
+ (void)displayServerIsBusy;
+ (void)displayPendingUpdates;

+ (void)messageBox:(NSString*)title message:(NSString*)message;
+ (void)messageBox:(NSString*)title message:(NSString*)message withCompletion:(CompletionBlock)completion;
+ (void)yesNoCancel:(NSString*)title message:(NSString*)message yesBtnTitle:(NSString*)yesBtnTitle noBtnTitle:(NSString*)noBtnTitle cancelBtnTitle:(NSString*)cancelBtnTitle rootControl: (UIView*) rootControl withCompletion:(YesNoCancelCompletionBlock)completion;
+ (void)yesNo:(NSString*)title message:(NSString*)message yesBtnTitle:(NSString*)yesBtnTitle noBtnTitle:(NSString*)noBtnTitle withCompletion:(YesNoCancelCompletionBlock)completion;

+ (void)yesNo:(NSString*)title message:(NSString*)message yesBtnTitle:(NSString*)yesBtnTitle noBtnTitle:(NSString*)noBtnTitle rootControl: (UIView*) rootControl withCompletion:(YesNoCancelCompletionBlock)completion;

+(void) disableButton:(UIButton*) curBtn;

+ (UIViewController*)getRoot;
+(void)CheckRateUsOnAppStoreTrigger:(UIViewController*) viewController :(void(^)(NSInteger))callback;
+(NSString*)getLastDateOfYear;
+(NSInteger)getYear:(NSDate*) date;
+(NSDate*)getDateAfter365Days;
+(NSDate*)add4MonthIntoDate:(NSDate*) date;
+(void)checkPromptCount:(void(^)(NSInteger))promptCallback;
+ (UIViewController*)topViewController;
@end
