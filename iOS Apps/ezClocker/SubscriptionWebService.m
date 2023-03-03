//
//  SubscriptionWebService.m
//  ezClocker
//
//  Created by Raya Khashab on 11/5/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "SubscriptionWebService.h"
#import "MetricsLogWebService.h"
#import "user.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "NSNumber+Extensions.h"
#import "SharedUICode.h"
#import "CommonLib.h"


@implementation SubscriptionWebService
@synthesize delegate = _delegate;

-(void)checkValidLicense {
 
    [self callGetLicensesWebServiceAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
 //       [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            NSNumber *isValid = [NSNumber numberWithInt:1];
            UserClass *user = [UserClass getInstance];
            NSError *error = nil;
            // NSNumber *freeTrialDaysLeft;
           // NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
            NSString *resultMessage = [results valueForKey:@"message"];
            
            
            if ([resultMessage isEqualToString:@"Success"])
            {
                isValid = [results valueForKey:@"valid"];
                user.subscription_IsValid = isValid;
                
                user.availableEmployeeSlots = [results valueForKey:@"availableEmployeeSlots"];
                //since JSON returns boolean values as NSNumber
                NSNumber *value = [results valueForKey:@"hasPaidPlan"];
                user.subscription_planProvider = [results valueForKey:@"planProvider"];
                value = [results valueForKey:@"paidPlanActive"];
                
                //        bool *tmpFreePlanActive = [[results valueForKey:@"freePlanActive"] boolValue];
                
                NSDictionary *tmpPlan = [results valueForKey:@"subscriptionPlan"];
                user.subscription_enabledFeatures = [tmpPlan valueForKey:@"enabledFeatures"];

                NSNumber *monthlyFee = [tmpPlan valueForKey:@"monthlyFee"];
                //Apple shows the subscription as 4.99 not 5 which is what we get from the server.
                if ([monthlyFee intValue] > 0){
                    double monthlyFee1 = [monthlyFee doubleValue] - 0.01;
                    NSString *appleMonthlyFee = [NSString stringWithFormat:@"$%.02f",monthlyFee1];
                    user.subscription_PlanPrice = appleMonthlyFee;
                    user.subscription_freePlanActive = false;
                }
                else
                {
                    user.subscription_PlanPrice = [NSString stringWithFormat:@"$%.2d",0];
                     user.subscription_freePlanActive = true;
                    
                }
                
            //    NSNumber *freeTrialDaysLeft = [results valueForKey:@"freeTrialDaysLeft"];
            //    if ([freeTrialDaysLeft integerValue] > 0){
            //        user.subscription_freePlanActive = true;
            //    }
            //    else
            //        user.subscription_freePlanActive = false;
                
                NSDateFormatter *formatterDate, *formatterISO8601DateTime;
                
                formatterISO8601DateTime = [[NSDateFormatter alloc] init];
                [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                formatterDate = [[NSDateFormatter alloc] init];
                [formatterDate setDateFormat:@"MM/dd/yyyy"];
                NSDate *DateValue;
                NSString *planStartDate = [results valueForKey:@"planStartDate"];
                if (![planStartDate isEqual: [NSNull null]])
                {
                    
                    planStartDate  = [planStartDate stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                    DateValue = [formatterISO8601DateTime dateFromString:planStartDate];
                    
                    planStartDate = [formatterDate stringFromDate:DateValue];
                    if (planStartDate== nil) {
                        planStartDate = @"n/a";
                    }
                    
                    
                }
                else
                    planStartDate = @"n/a";
                
                user.subscription_planStartDate = planStartDate;
                
                
                NSString *planExpireDate = [results valueForKey:@"planExpireDate"];
                
                if (![planExpireDate isEqual: [NSNull null]])
                {
                    
                    
                    planExpireDate  = [planExpireDate stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                    
                    DateValue = [formatterISO8601DateTime dateFromString:planExpireDate];
                    
                    planExpireDate = [formatterDate stringFromDate:DateValue];
                    
                    if (planExpireDate == nil) {
                        planExpireDate = @"n/a";
                    }
                }
                else
                {
                    planExpireDate = @"n/a";
                    
                }
                user.subscription_PlanExpireDate = planExpireDate;
                
                user.subscription_HasActivePaidPlan = NO;
                
                //we are not saving freeTrialDaysLeft to NSUserDefaults since it changes every day and we'll get it from the API call
                user.subscription_freeTrialDaysLeft = [results valueForKey:@"freeTrialDaysLeft"];

                
                if ([isValid intValue] == 0)
                {
                    [self.delegate subscriptionNotValid];
                }
                else
                {
                    [self.delegate subscriptionValid];
                }
 /*               freeTrialDaysLeft = [results valueForKey:@"freeTrialDaysLeft"];
                if (([freeTrialDaysLeft intValue] == 0) && hasPaidPlan && !(paidPlanActive)){
                    user.subscription_HasActivePaidPlan = YES;
                    
                    [self.delegate subscriptionExpired];
                }
                else
                    
                    [self.delegate subscriptionValid];
                */
             
                //save everything
                if ([user.subscription_enabledFeatures count] > 0)
                {
                    [[NSUserDefaults standardUserDefaults] setObject: user.subscription_enabledFeatures forKey:@"subscription_enabledFeatures"];
                }
                [[NSUserDefaults standardUserDefaults] setObject: user.subscription_planProvider forKey:@"subscription_planProvider"];

                [[NSUserDefaults standardUserDefaults] setObject: user.subscription_PlanPrice forKey:@"subscription_PlanPrice"];
                [[NSUserDefaults standardUserDefaults] setObject: user.subscription_planStartDate forKey:@"subscription_planStartDate"];
                [[NSUserDefaults standardUserDefaults] setObject: user.subscription_PlanExpireDate forKey:@"subscription_PlanExpireDate"];
                [[NSUserDefaults standardUserDefaults] setValue: user.subscription_IsValid forKey:@"subscription_IsValid"];
                
    //            [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data

            }
            else
            {
                
                //let them in and send us back a metric message (something went wrong)
                [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from SubscriptionWebService.m. Jason FIX IT!! JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                [self.delegate subscriptionError];
                
            }
        }
    }];
}

-(void) callHasValidLicenseWebServiceAPI: (int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    
    NSString *httpPostString;
    NSString *request_body;
    
    
    httpPostString = [NSString stringWithFormat:@"%@subscriptionPlan/hasValidLicense/%@", SERVER_URL, user.employerID];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    
    request_body = [NSString
                    stringWithFormat:@"authToken=%@",
                    [user.authToken  stringByAddingPercentEncodingWithAllowedCharacters: set    ]
                    ];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];

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

-(void) callGetLicensesWebServiceAPI: (int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    
    NSString *httpPostString;
    NSString *request_body;
    
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/licenses", SERVER_URL];

    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
#ifdef PERSONAL_VERSION
        NSString *personalId = [user.userID stringValue];
        [urlRequest setValue:personalId forHTTPHeaderField:@"x-ezclocker-personal-id"];
#endif
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];

    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];

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


/*-(void) callHasValidLicenseWebService{
    UserClass *user = [UserClass getInstance];
    
    NSString *httpPostString;
    NSString *request_body;
    
    
    httpPostString = [NSString stringWithFormat:@"%@subscriptionPlan/hasValidLicense/%@", SERVER_URL, user.employerID];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    
    request_body = [NSString
                    stringWithFormat:@"authToken=%@",
                    [user.authToken  stringByAddingPercentEncodingWithAllowedCharacters: set    ]
                    ];
    

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    
    if (connection){
    }
    
    
}
 

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    data = [[NSMutableData alloc] init];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataIn
{
    [data appendData:dataIn];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    UserClass *user = [UserClass getInstance];
    NSError *error = nil;
   // NSNumber *freeTrialDaysLeft;
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];


    if ([resultMessage isEqualToString:@"Success"])
    {
        user.availableEmployeeSlots = [results valueForKey:@"availableEmployeeSlots"];
        //since JSON returns boolean values as NSNumber
        NSNumber *value = [results valueForKey:@"hasPaidPlan"];
        user.subscription_planProvider = [results valueForKey:@"planProvider"];
        bool hasPaidPlan = value.boolValue;
        value = [results valueForKey:@"paidPlanActive"];
        bool paidPlanActive = value.boolValue;
        
//        bool *tmpFreePlanActive = [[results valueForKey:@"freePlanActive"] boolValue];

        NSDictionary *tmpPlan = [results valueForKey:@"subscriptionPlan"];
        NSNumber *monthlyFee = [tmpPlan valueForKey:@"monthlyFee"];
        //Apple shows the subscription as 4.99 not 5 which is what we get from the server.
        if ([monthlyFee intValue] > 0){
            double monthlyFee1 = [monthlyFee doubleValue] - 0.01;
            NSString *appleMonthlyFee = [NSString stringWithFormat:@"$%.02f",monthlyFee1];
            user.subscription_PlanPrice = appleMonthlyFee;
            user.subscription_freePlanActive = false;
        }
        else
        {
            user.subscription_PlanPrice = [NSString stringWithFormat:@"$%.2d",0];
            user.subscription_freePlanActive = true;

        }
        
        NSNumber *freeTrialDaysLeft = [results valueForKey:@"freeTrialDaysLeft"];
      //  if ([freeTrialDaysLeft integerValue] > 0){
      //      user.subscription_freePlanActive = true;
      //  }
      //  else
      //      user.subscription_freePlanActive = false;
        
        NSDateFormatter *formatterDate, *formatterISO8601DateTime;
        
        formatterISO8601DateTime = [[NSDateFormatter alloc] init];
        [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatterISO8601DateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        formatterDate = [[NSDateFormatter alloc] init];
        [formatterDate setDateFormat:@"MM/dd/yyyy"];
        NSDate *DateValue;
        NSString *planStartDate = [results valueForKey:@"planStartDate"];
        if (![planStartDate isEqual: [NSNull null]])
        {
    
            planStartDate  = [planStartDate stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
            DateValue = [formatterISO8601DateTime dateFromString:planStartDate];
            
            planStartDate = [formatterDate stringFromDate:DateValue];
            if (planStartDate== nil) {
                planStartDate = @"n/a";
            }


        }
        else
            planStartDate = @"n/a";
        
        user.subscription_planStartDate = planStartDate;
        
       
        NSString *planExpireDate = [results valueForKey:@"planExpireDate"];

        if (![planExpireDate isEqual: [NSNull null]])
        {

        
            planExpireDate  = [planExpireDate stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
        
            DateValue = [formatterISO8601DateTime dateFromString:planExpireDate];
        
            planExpireDate = [formatterDate stringFromDate:DateValue];

            if (planExpireDate == nil) {
                planExpireDate = @"n/a";
            }
        }
        else
        {
            planExpireDate = @"n/a";
            
        }
        user.subscription_PlanExpireDate = planExpireDate;

        user.subscription_HasActivePaidPlan = NO;
        
        [[NSUserDefaults standardUserDefaults] setObject: user.subscription_PlanPrice forKey:@"user.subscription_PlanPrice"];
        [[NSUserDefaults standardUserDefaults] setObject: user.subscription_planStartDate forKey:@"subscription_planStartDate"];
        [[NSUserDefaults standardUserDefaults] setObject: user.subscription_PlanExpireDate forKey:@"subscription_PlanExpireDate"];
        [[NSUserDefaults standardUserDefaults] setBool: user.subscription_freePlanActive forKey:@"subscription_freePlanActive"];
        //we are not saving freeTrialDaysLeft since it changes every day and we'll get it from the API call
        user.subscription_freeTrialDaysLeft = [results valueForKey:@"freeTrialDaysLeft"];
     //   [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
        
        freeTrialDaysLeft = [results valueForKey:@"freeTrialDaysLeft"];
        if (([freeTrialDaysLeft intValue] == 0) && hasPaidPlan && !(paidPlanActive)){
            user.subscription_HasActivePaidPlan = YES;
            
            [self.delegate subscriptionExpired];
        }
        else
 
            [self.delegate subscriptionValid];


    }
    else
    {
 
        //let them in and send us back a metric message (something went wrong)
        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from SubscriptionWebService.m. Jason FIX IT!! JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
        [self.delegate subscriptionError];

    }
    
}
*/

@end
