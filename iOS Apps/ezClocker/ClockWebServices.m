//
//  ClockWebServices.m
//  ezClocker
//
//  Created by Raya Khashab on 11/5/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClockWebServices.h"
#import "CommonLib.h"

#import <QuartzCore/QuartzCore.h>

#import "user.h"

#import "ECSlidingViewController.h"

#import "MenuViewController.h"

//#import "Mixpanel.h"

#import "CommonLib.h"
#import "MetricsLogWebService.h"
#import "TimeEntry+Extensions.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "debugdefines.h"
#import "DataManager.h"
#import "SharedUICode.h"
#import "NSDictionary+Extensions.h"
#ifdef IPAD_VERSION
#import "ezClocker_Kiosk-Swift.h"
#elif defined PERSONAL_VERSION
#import "ezClocker_personal-Swift.h"
#else
#import "ezClocker-Swift.h"
#endif

@implementation ClockWebServices

- (void) callTCSWebService:(ClockMode)clockMode timeEntryObjectID:(NSManagedObjectID*)timeEntryObjectID dateTime:(NSDate*) currentDateTime jobCodeId: (NSNumber *) selectedJobCodeId employeeID: (NSNumber*) selEmployeeID locOverride:(bool) bOverrideLocationCheck{
    
    //get job Code
    
#ifndef PERSONAL_VERSION
    CLLocation *loc = [LocationManager defaultLocationManager].lastKnownLocation;
#else
    CLLocation* loc = nil;
#endif
    DataManager* manager = [DataManager sharedManager];
    [manager clockInOrClockOut:clockMode timeEntryObjectID:timeEntryObjectID currentDate:currentDateTime jobCodeId: selectedJobCodeId location:loc source:kIPHONE locOverride:bOverrideLocationCheck withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        switch (errorCode) {
            case DATAMANAGER_BUSY: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:DATAMANAGER_BUSY description:@"DATAMANAGER_BUSY" error:error];
                [SharedUICode displayServerIsBusy];
                [self.delegate clockServiceCallDidFinish:self timeEntryRec:nil ErrorCode:DATAMANAGER_BUSY resultMessage: resultMessage ClockMode:clockMode];
                return;
            }
            case SERVICE_UNAVAILABLE_ERROR: {
  //              [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_UNAVAILABLE_ERROR description:@"SERVICE_UNAVAILABLE_ERROR" error:error];
                //for some reason this message messes up showing the break screens so only show it if they are clocking in/out offline
                if ((clockMode == ClockModeIn) || (clockMode == ClockModeOut))
                {
                    [SharedUICode displayServiceUnavailableErrorWithMsg:@"NOTE: You can continue to clock in/clock out and we will save to the server later."];
                }
                [self.delegate clockServiceCallDidFinish:self timeEntryRec:results ErrorCode:SERVICE_UNAVAILABLE_ERROR resultMessage: resultMessage ClockMode:clockMode];
                return;
            }
            case SERVICE_ERRORCODE_EMPLOYEE_DOES_NOT_EXIST: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_EMPLOYEE_DOES_NOT_EXIST description:@"SERVICE_ERRORCODE_EMPLOYEE_DOES_NOT_EXIST" error:error];
                [SharedUICode messageBox:@"" message:@"This account has either been un-archived or deleted. Please sign out of the app and sign back in to sync the account." withCompletion:^{
                    [self.delegate clockServiceCallDidFinish:self timeEntryRec:results ErrorCode:SERVICE_ERRORCODE_EMPLOYEE_DOES_NOT_EXIST resultMessage: resultMessage ClockMode:clockMode];
                }];
                return;
            }
            case SERVICE_ERRORCODE_ALREADY_CLOCKED_IN: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_ALREADY_CLOCKED_IN description:@"SERVICE_ERRORCODE_ALREADY_CLOCKED_IN" error:error];
 //               [SharedUICode messageBox:@"" message:@"You are already clocked in.  Please clock out." withCompletion:^{
                    [self.delegate clockServiceCallDidFinish:self timeEntryRec:results ErrorCode:SERVICE_ERRORCODE_ALREADY_CLOCKED_IN resultMessage: resultMessage ClockMode:clockMode];
   //             }];
                return;
            }
            case SERVICE_ERRORCODE_EARLYCLOCKIN: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_EARLYCLOCKIN description:@"SERVICE_ERRORCODE_EARLYCLOCKIN" error:error];

  //             [SharedUICode messageBox:@"" message:resultMessage withCompletion:^{
                    [self.delegate clockServiceCallDidFinish:self timeEntryRec:results ErrorCode:SERVICE_ERRORCODE_EARLYCLOCKIN resultMessage: resultMessage ClockMode:clockMode];
  //              }];
                return;
              
            }
            case SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT description:@"SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT" error:error];
 //               [SharedUICode messageBox:@"" message:@"You are already clocked out." withCompletion:^{
                    [self.delegate clockServiceCallDidFinish:self timeEntryRec:results ErrorCode:SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT resultMessage: resultMessage ClockMode:clockMode];
  //              }];
                return;
            }
            case SERVICE_ERRORCODE_ALREADY_BREAKED_IN: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_ALREADY_BREAKED_IN description:@"SERVICE_ERRORCODE_ALREADY_BREAKED_IN" error:error];

                    [self.delegate clockServiceCallDidFinish:self timeEntryRec:results ErrorCode:SERVICE_ERRORCODE_ALREADY_BREAKED_IN resultMessage: resultMessage ClockMode:clockMode];

                return;
            }
            case SERVICE_ERRORCODE_ALREADY_BREAKED_OUT: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_ALREADY_BREAKED_OUT description:@"SERVICE_ERRORCODE_ALREADY_BREAKED_OUT" error:error];

                    [self.delegate clockServiceCallDidFinish:self timeEntryRec:results ErrorCode:SERVICE_ERRORCODE_ALREADY_BREAKED_OUT resultMessage: resultMessage ClockMode:clockMode];

                return;
            }
            case SERVICE_ACCESSDENIED_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ACCESSDENIED_ERROR description:@"SERVICE_ACCESSDENIED_ERROR" error:error];
 //               [SharedUICode messageBox:@"" message:@"You are already clocked out." withCompletion:^{
                    [self.delegate clockServiceCallDidFinish:self timeEntryRec:results ErrorCode:SERVICE_ACCESSDENIED_ERROR resultMessage: resultMessage ClockMode:clockMode];
  //              }];
                return;
            }
            case SERVICE_ERRORCODE_SUCCESSFUL: {
                NSDictionary *timeEntryRec = [results valueForKey:ktimeEntryKey];
                if ([NSDictionary isNilOrNull:timeEntryRec]) {
                    timeEntryRec = nil;
                    //Should we set this to nil?
                    //user.activeTimeEntryId = nil;
                } else {
                    NSNumber *timeEntryId = [timeEntryRec valueForKey:kidKey];
                    UserClass *user = [UserClass getInstance];
                    user.activeTimeEntryId = timeEntryId;
                    bool isActiveClockIn = [[timeEntryRec valueForKey:@"isActiveClockIn"] boolValue];
                    if (isActiveClockIn)
                        user.activeClockInId = timeEntryId;
                    else
                        user.activeClockInId = nil;
                }
                [self.delegate clockServiceCallDidFinish:self timeEntryRec:timeEntryRec ErrorCode:SERVICE_ERRORCODE_SUCCESSFUL resultMessage: resultMessage ClockMode:clockMode];
                return;
            }
            default: { // If no resultMessage then we will display please try again
                if ([NSString isNilOrEmpty:resultMessage]) {
                    [SharedUICode messageBox:nil message:@"The App was not able to connect to the ezClocker cloud.  Please try again." withCompletion:^{
                        [self.delegate clockServiceCallDidFinish:self timeEntryRec:nil ErrorCode:(int)errorCode resultMessage: resultMessage ClockMode:clockMode];
                    }];
                } else { // otherwise display the message from the server
                    [SharedUICode checkResultsMessageAndDisplayError:resultMessage error:error];
                    [self.delegate clockServiceCallDidFinish:self timeEntryRec:results ErrorCode:(int)errorCode resultMessage: resultMessage ClockMode:clockMode];
                }
                break;
            }
        }
        return;
    }];
    
}

@end
