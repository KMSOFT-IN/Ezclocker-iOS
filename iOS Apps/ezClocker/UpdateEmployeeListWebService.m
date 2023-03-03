//
//  UpdateEmployeeListWebService.m
//  ezClocker
//
//  Created by Raya Khashab on 8/28/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import "UpdateEmployeeListWebService.h"
#import "user.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "NSData+Extensions.h"

@implementation UpdateEmployeeListWebService

-(void) callGetEmployees:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    UserClass *user = [UserClass getInstance];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/thin/employee", SERVER_URL];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    urlRequest.timeoutInterval = TIME_OUT_REQUEST;
    
    
    //set HTTP Method
    //  [urlRequest setHTTPMethod:@"POST"];
    
    [urlRequest setHTTPMethod:@"GET"];
    //    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:[user.employerID stringValue] forHTTPHeaderField:@"x-ezclocker-employerId"];
    [urlRequest setValue:user.authToken forHTTPHeaderField:@"x-ezclocker-authToken"];
    
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            MAINTHREAD_BLOCK_START()
            completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            MAINTHREAD_BLOCK_START()
            completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        @autoreleasepool {
            [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                
                //                [self stopSpinner];
                
                //               if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                MAINTHREAD_BLOCK_START()
                completion(errorCode, resultMessage, results, aError);
                THREAD_BLOCK_END()
                return;
                //                }
            }];
        }
    }];
    [dataTask resume];
}


-(void) updateActiveEmployeeList
{
 //   [self startSpinnerWithMessage:@"Updating, please wait..."];
    
    [self callGetEmployees:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
 //       [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            UserClass *user = [UserClass getInstance];
            [user.employeeList removeAllObjects];
            [user.employeeNameIDList removeAllObjects];
            NSArray *employees = [results valueForKey:@"employees"];
            int employeeCnt = (int) employees.count;
            user.employeeCount = [NSNumber numberWithInt: employeeCnt];
            //persist selection
            [[NSUserDefaults standardUserDefaults] setObject:user.employeeCount forKey:@"employeeCount"];
        //    [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSString *name;

            NSNumber *employeeID;
             NSString *pin;
            NSMutableDictionary *employeeObj;
//            NSMutableDictionary *item;
            
 //           if (employees.count > 0)
 //               [employeeList removeAllObjects];
            for (NSDictionary *employee in employees){
                
                name = [employee valueForKey:@"employeeName"];
                employeeID = [employee valueForKey:@"id"];
                
                pin = [employee valueForKey:@"teamPin"];
                
                NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc]init];
                [mutableDict setObject:name forKey:[employeeID stringValue]];
                
                [user.employeeNameIDList  setValue:name forKey:[employeeID stringValue]];
                
                employeeObj = [[NSMutableDictionary alloc] init];
                [employeeObj setValue:name forKey:@"Name"];
                [employeeObj setValue:employeeID forKey:@"ID"];
                
                [user.employeeList addObject:employeeObj];
                
 /*               acceptedInvite = [employee valueForKey:@"acceptedInvite"];
                NSObject *tmpJson = [employee valueForKey:@"activeTimeEntry"];
                isClockedIn = 0;
                if (![tmpJson isEqual:[NSNull null]])
                    isClockedIn = [NSNumber numberWithInt:1];
                
                employeeEmail = [employee valueForKey:@"employeeContactEmail"];
                
                item = [[NSMutableDictionary alloc] init];
                
                [item setValue:name forKey:@"Name"];
                [item setValue:employeeID forKey:@"ID"];
                [item setValue:pin forKey:@"pin"];
                [item setValue:acceptedInvite forKey:@"acceptedInvite"];
                [item setValue:isClockedIn forKey:@"isClockedIn"];
                [item setValue:employeeEmail forKey:@"Email"];
             */
                
            }
            
 //           employeeList = [[NSMutableArray alloc] initWithArray: user.employeeList];
//            [_employeesTableViewController reloadData];
        }
        [self.delegate EmployeeListUpdateServiceCallDidFinish:self ErrorCode:SERVICE_ERRORCODE_SUCCESSFUL];

    }];
    
}

@end
