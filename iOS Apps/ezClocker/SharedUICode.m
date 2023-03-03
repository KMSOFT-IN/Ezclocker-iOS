//
//  SharedUICode.m
//  ezClocker
//
//  Created by Kenneth Lewis on 1/11/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import "SharedUICode.h"
#import "NSString+Extensions.h"
#import "MetricsLogWebService.h"
#import "debugdefines.h"
#import "CommonLib.h"
#import "user.h"
#import <StoreKit/StoreKit.h>
#import "NSDate+Extensions.h"

@implementation SharedUICode

+ (void)checkResultsMessageAndDisplayError:(NSString *)resultMessage error:(NSError *)error {
    if ([NSString isNilOrEmpty:resultMessage]) {
        [SharedUICode messageBox:nil message:@"Time Entry from Server Failed"];
    } else {
        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from ClockWebServices.m JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
        if (resultMessage.length > 0)
        {
            [SharedUICode messageBox:nil message:resultMessage];
        }
    }
}

+ (void)displayServiceUnavailableError {
    [SharedUICode displayServiceUnavailableErrorWithMsg:nil];
}

+ (void)displayServiceUnavailableErrorWithMsg:(NSString*)msg {
    [SharedUICode displayServiceUnavailableErrorWithMsg:msg withCompletion:nil];
}

+ (void)displayServiceUnavailableErrorWithMsg:(NSString*)msg withCompletion:(CompletionBlock)completion {
    NSString* testMsg = [NSString trim:msg];
    if ([NSString isNilOrEmpty:testMsg]) {
        testMsg = @"Please try again.";
    }
    [SharedUICode messageBox:nil message:[NSString stringWithFormat:@"ezClocker is unable to connect to the server at this time.\n\n%@", testMsg] withCompletion:completion];
}

+ (void)messageBox:(NSString*)title message:(NSString*)message {
    [SharedUICode messageBox:title message:message withCompletion:nil];
}

+ (void)messageBox:(NSString*)title message:(NSString*)message withCompletion:(CompletionBlock)completion {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (nil != completion) {
            completion();
        }
    }];
    [alert addAction:okAction];
    UIViewController* root = [SharedUICode getRoot];
    [root presentViewController:alert animated:YES completion:^{
        
    }];
}

+ (void)yesNoCancel:(NSString*)title message:(NSString*)message yesBtnTitle:(NSString*)yesBtnTitle noBtnTitle:(NSString*)noBtnTitle cancelBtnTitle:(NSString*)cancelBtnTitle rootControl: (UIView*) rootControl withCompletion:(YesNoCancelCompletionBlock)completion {
    DEBUG_MSG
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);
    NSString* testMsg = [NSString trim:message];
    NSAssert(nil != testMsg, @"testMsg cannot be nil or empty %@", msg);
    NSString* testYesBtnTitle = [NSString trim:yesBtnTitle];
    NSAssert(nil != testYesBtnTitle, @"yesBtnTitle cannot be nil or empty %@", msg);
    NSString* testNoBtnTitle = [NSString trim:noBtnTitle];
    NSAssert(nil != testNoBtnTitle, @"noBtnTitle cannot be nil or empty %@", msg);
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:testMsg preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* yesBtn = [UIAlertAction actionWithTitle:testYesBtnTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        completion(resultYes);
        return;
    }];
    [alert addAction:yesBtn];
    UIAlertAction* noBtn = [UIAlertAction actionWithTitle:testNoBtnTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        completion(resultNo);
        return;
    }];
    [alert addAction:noBtn];
    NSString* testCancelBtnTitle = [NSString trim:cancelBtnTitle];
    // cancel can be empty
    if (![NSString isNilOrEmpty:testCancelBtnTitle]) {
        UIAlertAction* cancelBtn = [UIAlertAction actionWithTitle:testCancelBtnTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            completion(resultCancel);
            return;
        }];
        [alert addAction:cancelBtn];
    }
    UIViewController* root = [SharedUICode getRoot];
    
#ifdef IPAD_VERSION
    // The following lines are needed for use with the iPad.
    UIPopoverPresentationController *alertPopoverPresentationController = alert.popoverPresentationController;

    if(rootControl){
        
        CGRect frame= rootControl.frame;
        alertPopoverPresentationController.sourceView = root.view;
//        alertPopoverPresentationController.sourceView = rootControl;
        alertPopoverPresentationController.sourceRect = frame;
    }
    else{
        alertPopoverPresentationController.sourceView = root.view;
    }
#endif
    [root presentViewController:alert animated:YES completion:^{
        
    }];
}

+ (void)yesNo:(NSString*)title message:(NSString*)message yesBtnTitle:(NSString*)yesBtnTitle noBtnTitle:(NSString*)noBtnTitle withCompletion:(YesNoCancelCompletionBlock)completion {
   // [SharedUICode yesNoCancel:title message:message yesBtnTitle:yesBtnTitle noBtnTitle:noBtnTitle cancelBtnTitle:nil rootControl:nil withCompletion:completion];
    [SharedUICode yesNoCancel:title message:message yesBtnTitle:yesBtnTitle noBtnTitle:noBtnTitle cancelBtnTitle:nil rootControl:nil withCompletion:completion];
}

//this one is for iPads we pass the control we want the popup to show next to
+ (void)yesNo:(NSString*)title message:(NSString*)message yesBtnTitle:(NSString*)yesBtnTitle noBtnTitle:(NSString*)noBtnTitle rootControl: (UIView*) rootControl withCompletion:(YesNoCancelCompletionBlock)completion {
    
    [SharedUICode yesNoCancel:title message:message yesBtnTitle:yesBtnTitle noBtnTitle:noBtnTitle cancelBtnTitle:nil rootControl:rootControl withCompletion:completion];
}

+ (void)displayPendingUpdates {
    [SharedUICode messageBox:nil message:@"You currently have pending updates.  Please wait for those to be sent to the server.  Try again in a few."];
}

+ (void)displayServerIsBusy {
    [SharedUICode messageBox:@"Busy" message:@"Please wait for process to finish and try again."];
}

+ (UIViewController*)topViewController {
    return [SharedUICode topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [SharedUICode topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [SharedUICode topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [SharedUICode topViewControllerWithRootViewController:presentedViewController];
    } else {
        while (rootViewController.presentedViewController) {
            rootViewController = rootViewController.presentedViewController;
        }
        return rootViewController;
    }
}

+ (UIViewController*)getRoot {
    UIViewController* _topViewController = [SharedUICode topViewController];
    if (nil != _topViewController) {
        return _topViewController;
    }
    UIApplication* application = [UIApplication sharedApplication];
    UIWindow* keyWindow = [application keyWindow];
    UIViewController* topController = keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}

+(void) disableButton:(UIButton*) curBtn{
    //[[clockInBtn layer] setMasksToBounds:YES];
    [[curBtn layer] setCornerRadius:7.0f];
    [[curBtn layer] setBorderWidth:0.5f];
    curBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    
    //remove the Gradient layer which gave use the blue color shades
    CALayer* layer = [curBtn.layer valueForKey:@"GradientLayer"];
    [layer removeFromSuperlayer];
    [curBtn.layer setValue:nil forKey:@"GradientLayer"];
    
    //diable the button
    curBtn.enabled = FALSE;
    curBtn.alpha = 0.5f;
    [curBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
}
+(void)CheckRateUsOnAppStoreTrigger:(UIViewController*) viewController :(void(^)(NSInteger))callback {
    
    UserClass *user= [UserClass getInstance];
    //launch the review dialog if they haven't given us a review before
    int didUserGiveRatingFeedback = (int) [user.userGaveUsRatingFeedback integerValue];
    if (didUserGiveRatingFeedback)
        return;
    int visitCounter = (int) [user.appLaunchCounter integerValue];
    //only launch if the counter is a certain number and we haven't asked him before and it's been 21 since they installed the app so they've been using it for a while now
    NSDate *todaysDate = [NSDate date];
    NSInteger numOfDaysSinceInstall = [CommonLib daysBetweenDate:user.appInstallDate andDate:todaysDate];
    [self checkPromptCount:^(NSInteger index) {
        BOOL isShow = NO;
        if (index != 0) {
            isShow = YES;
        }
        
        //if (true)
        if (isShow && (visitCounter >= MAX_TIMES_APP_LAUNCHED) && (didUserGiveRatingFeedback == 0) && numOfDaysSinceInstall > 14)
        {
            user.userGaveUsRatingFeedback = [NSNumber numberWithInt:1];
            [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            /*UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@""
                                         message:@"Enjoying ezClocker?"
                                         preferredStyle:UIAlertControllerStyleAlert];
             */
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@""
                                         message:@"Are you having a great experience with ezClocker?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Yes!"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action){
                                                                  callback(1);
                                                              }];
            
            UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"Not really"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action){
                                                                 callback(0);
                                                             }];
            
            [alert addAction:yesButton];
            [alert addAction:noButton];
            [viewController presentViewController:alert animated:YES completion:nil];
        } else {
            callback(2);
        }
    }];
}

+(void)checkPromptCount:(void(^)(NSInteger))promptCallback  {
    NSInteger totalCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalCount"];
    NSDate *currentDate = [NSDate date];
    NSDate *dateAfter365 = [SharedUICode getDateAfter365Days];
    
    if ((totalCount == 3) && (([currentDate compare:dateAfter365] == NSOrderedDescending) || ([currentDate compare:dateAfter365] == NSOrderedSame))) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"totalCount"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    totalCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalCount"];
    if (totalCount == 0) {
        promptCallback(1);
    } else {
        NSDate *firstDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"firstDate"];
        NSDate *secondDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"secondDate"];
        
        if ((([currentDate compare:firstDate] == NSOrderedDescending) || ([currentDate compare:firstDate] == NSOrderedSame)) &&
            (([currentDate compare:secondDate] == NSOrderedAscending) || ([currentDate compare:secondDate] == NSOrderedSame))) {
            NSInteger totalCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalCount"];
            if (totalCount != 2) {
                promptCallback(2);
            } else {
                promptCallback(0);
            }
        } else if ((([currentDate compare:secondDate] == NSOrderedDescending) || ([currentDate compare:secondDate] == NSOrderedSame)) &&
                   (([currentDate compare:dateAfter365] == NSOrderedAscending) || ([currentDate compare:dateAfter365] == NSOrderedSame))) {
            if (totalCount != 3) {
                promptCallback(3);
            } else {
                promptCallback(0);
            }
        } else {
            promptCallback(0);
        }
    }
}
+(NSString*)getLastDateOfYear
{
    NSInteger currentYear = [self getYear:[NSDate date]];
    NSInteger lastMonth = 12;
    NSInteger lastDate = 31;
    NSString *date = [NSString stringWithFormat:@"%ld-%ld-%ld 00:00:00 +0000", lastMonth, lastDate, currentYear];
    return date;
}

+(NSDate*)getDateAfter365Days
{
    NSDate *currentDate = [NSDate date];
    NSDate *date = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear
                                                            value:1
                                                           toDate:currentDate
                                                          options:0];
    return date;
}

+(NSDate*)add4MonthIntoDate:(NSDate*) date
{
    NSDate *addMonthDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitMonth
                                                                    value:4
                                                                   toDate:date
                                                                  options:0];
    return addMonthDate;
}

+(NSInteger)getYear:(NSDate*) date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    return [components year];
}
@end
