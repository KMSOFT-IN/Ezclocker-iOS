//
//  CustomerWebservice.m
//  ezClocker
//
//  Created by KMSOFT on 31/01/20.
//  Copyright © 2020 ezNova Technologies LLC. All rights reserved.
//

#import "CustomerWebservice.h"

@implementation CustomerWebservice

+(void) fetchAllCustomers:(void(^)(NSMutableArray *))callback
{
    [self callGetAllCustomers:YES withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        if (aErrorCode != 0) {
            [ErrorLogging logError:aError];
            [SharedUICode messageBox:nil message:@"There was an issue fetching the customers from the server. Please try again later" withCompletion:^{
                return;
            }];
            callback([[NSMutableArray alloc] init]);
        }
        else{
            NSString *name;
            NSNumber *customerID;
            NSString *email;

            UserClass *user = [UserClass getInstance];
            NSArray *customers = [aResults valueForKey:@"customers"];
            if (customers.count > 0)
            {
//                [curCustomerNameIDList removeAllObjects];
                [user.customerNameIDList removeAllObjects];
            }
            for (NSDictionary *customer in customers){
                name = [customer valueForKey:@"name"];
                customerID = [customer valueForKey:@"id"];
                email = [customer valueForKey:@"emailAddress"];

                NSMutableDictionary *customerObj = [[NSMutableDictionary alloc] init];
                [customerObj setValue:name forKey:@"name"];
                [customerObj setValue:customerID forKey:@"id"];
                [customerObj setValue:email forKey:@"email"];

                [user.customerNameIDList addObject:customerObj];
            }
            NSMutableArray *curCustomerNameIDList =  [NSMutableArray arrayWithArray:user.customerNameIDList];
            if ([curCustomerNameIDList count] == 0)
            {
                NSMutableDictionary *customerObj = [[NSMutableDictionary alloc] init];
                [customerObj setValue:@"default" forKey:@"name"];
                [customerObj setValue:nil forKey:@"id"];
                [curCustomerNameIDList addObject:customerObj];
            }
            else
            {
                [[NSUserDefaults standardUserDefaults] setObject:user.customerNameIDList forKey:@"customerNameIDList"];
                
   //             [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            callback(curCustomerNameIDList);
        }
    }];
}


+(void) callGetAllCustomers:(bool)useSavedValues withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curEmployeeID = [user.userID stringValue];
    NSString *curAuthToken = user.authToken;
    
    NSString *httpPostString = [NSString stringWithFormat:@"%@api/v1/customers?employeeId=%@", SERVER_URL, curEmployeeID];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:curEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    [request setValue:curAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
                
                //[self stopSpinner];
                
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


+(void) callDeleteSelectedCustomer:(NSNumber*)customerId withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    NSString *request_body;
    UserClass *user = [UserClass getInstance];
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/customers/%@", SERVER_URL, customerId];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    request_body = [NSString
                    stringWithFormat:@"authToken=%@",
                    [user.authToken  stringByAddingPercentEncodingWithAllowedCharacters: set]
                    ];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    urlRequest.timeoutInterval = TIME_OUT_REQUEST;
    
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"DELETE"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setValue:curEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [urlRequest setValue:curAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
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
    //    [self stopSpinner];
    
}
@end
