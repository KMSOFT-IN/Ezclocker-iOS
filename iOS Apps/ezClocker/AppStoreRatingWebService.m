//
//  AppStoreRatingWebService.m
//  ezClocker
//
//  Created by Raya Khashab on 5/9/17.
//  Copyright © 2017 ezNova Technologies LLC. All rights reserved.
//

#import "AppStoreRatingWebService.h"
#import "user.h"
#import "CommonLib.h"
#import "SharedUICode.h"
#import "threaddefines.h"


@implementation AppStoreRatingWebService

-(void) LogRatingToServer{
    [self LogRatingAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        }];
}

-(void) LogRatingAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/acceptedReviewPrompt", SERVER_URL];
    //Implement request_body for send request here authToken and clock DateTime set into the body.
    
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          DEV_TOKEN, @"developerToken",
                          user.userEmail, @"userName",
                          @"true", @"accepted",
                          nil];
    
    NSError *error;
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authToken"];
    
    //set request body into HTTPBody.
    urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
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

    
    //set request url to the NSURLConnection
 /*   NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        [SharedUICode messageBox:@"Error" message:@"Connection to the server failed" withCompletion:^{
            return;
        }];

      //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
    }
*/
    
}

/*-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
      NSError *error = nil;
       NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
      NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
   
}
 */

@end
