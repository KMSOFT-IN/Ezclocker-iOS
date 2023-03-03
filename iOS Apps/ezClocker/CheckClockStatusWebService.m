//
//  CheckClockStatusWebService.m
//  ezClocker
//
//  Created by Raya Khashab on 11/6/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "user.h"
#import "CheckClockStatusWebService.h"
#import "CommonLib.h"
#import "MetricsLogWebService.h"
#import "NSDictionary+Extensions.h"
#import "SharedUICode.h"
#import "threaddefines.h"

@implementation CheckClockStatusWebService

-(void) checkClockStatus: (NSNumber*) employeeId{
    [self checkClockStatusAPI:employeeId withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
            NSError *error = nil;
         //   NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
            
            
            NSString *resultMessage = [aResults valueForKey:@"message"];
            int errorValue = [[aResults valueForKey:@"errorCode"] intValue];
            
               //if message is null or <> Success then the call failed
            if ((![resultMessage isEqualToString:@"false"]) && (![resultMessage isEqualToString:@"true"]))
            {
                
                if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
                    if ([resultMessage isEqual:[NSNull null]])
                    {

                    }
                    
                    else{
                        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from CheckClockStatusWebService.m JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                        if (resultMessage.length > 0)
                        {
                            [SharedUICode messageBox:@"Error" message:resultMessage withCompletion:^{
                                return;
                            }];

   
                        }
                        
                    }
                    //pass back to the call back that there was an error
                    errorValue = 3;
                    [self.delegate checkClockStatusServiceCallDidFinish:self timeEntryRec:nil ErrorCode:errorValue];

                }
            }
            else{
                NSDictionary *timeEntryRec = [aResults valueForKey:@"timeEntry"];
                if ([NSDictionary isNilOrNull:timeEntryRec]) {
                    timeEntryRec = nil;
                    //Should we set this to nil?
                    //user.activeTimeEntryId = nil;
                }
                
                [self.delegate checkClockStatusServiceCallDidFinish:self timeEntryRec:timeEntryRec ErrorCode:errorValue];
            }
            
         }
    }];
}

-(void) checkClockStatusAPI:(NSNumber*) employeeId withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
//    UIAlertView *alert;
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    
    NSString *employeeIDStr = [employeeId stringValue];
  //  NSString *httpPostString = [NSString stringWithFormat:@"%@api/v1/timeentry/active/%@?timezone=%@&source=%@", SERVER_URL, employeeIDStr, timeZoneId, @"iPhone"];
    NSString *httpPostString = [NSString stringWithFormat:@"%@api/v1/account/state/employee/%@?timezone=%@", SERVER_URL, employeeIDStr, timeZoneId];

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authToken"];
    
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

/*
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        else {
            
            [SharedUICode messageBox:@"Error" message:@"Connection to the server failed" withCompletion:^{
                return;
            }];
            
       //     alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //    [alert show];
        }
    */
}
     
 /*
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        int statusCode = (int)[(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            //            [self stopSpinner];
            //           [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //error 503 is when tomcat is down
            [SharedUICode messageBox:@"Error" message:@"ezClocker is unable to connect to the server at this time. Please try again later" withCompletion:^{
                return;
            }];

           // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
            [self.delegate checkClockStatusServiceCallDidFinish:self timeEntryRec:nil ErrorCode:3];
        }
    }
    
    
    data = [[NSMutableData alloc] init];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataIn
{
    [data appendData:dataIn];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
 //   UIAlertView *alert;
    NSError *error = nil;
    //        UserClass *user = [UserClass getInstance];
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    
    
    NSString *resultMessage = [results valueForKey:@"message"];
    int errorValue = [[results valueForKey:@"errorCode"] intValue];
    
       //if message is null or <> Success then the call failed
    if ((![resultMessage isEqualToString:@"false"]) && (![resultMessage isEqualToString:@"true"]))
    {
        
        if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
            if ([resultMessage isEqual:[NSNull null]])
            {
 //              alert = [[UIAlertView alloc] initWithTitle:nil message:@"Call to Server Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                [alert show];
            }
            
            else{
                [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from CheckClockStatusWebService.m JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                if (resultMessage.length > 0)
                {
                    [SharedUICode messageBox:@"Error" message:resultMessage withCompletion:^{
                        return;
                    }];

                  //  alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                   // [alert show];
                }
                
            }
            //pass back to the call back that there was an error
            errorValue = 3;
            [self.delegate checkClockStatusServiceCallDidFinish:self timeEntryRec:nil ErrorCode:errorValue];

        }
    }
    else{
        NSDictionary *timeEntryRec = [results valueForKey:@"timeEntry"];
        if ([NSDictionary isNilOrNull:timeEntryRec]) {
            timeEntryRec = nil;
            //Should we set this to nil?
            //user.activeTimeEntryId = nil;
        }
        
        [self.delegate checkClockStatusServiceCallDidFinish:self timeEntryRec:timeEntryRec ErrorCode:errorValue];
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    //    [self stopSpinner];
    
    [SharedUICode messageBox:@"Error" message:@"ezClocker is unable to connect to the server at this time. Please try again later" withCompletion:^{
        return;
    }];

 //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
 //   [alert show];
    
    connection = nil;
    data = nil;
    //call the callback so we can stop the spinner
    [self.delegate checkClockStatusServiceCallDidFinish:self timeEntryRec:nil ErrorCode:3];
    
}
*/

@end
