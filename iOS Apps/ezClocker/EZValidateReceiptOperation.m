//
//  EZValidateReceiptOperation.m
//  IAPSubscription
//
//  Created by Derek Stutsman on 2/16/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "EZValidateReceiptOperation.h"
#import "MetricsLogWebService.h"
#import "CommonLib.h"
#import "user.h"
#import "SharedUICode.h"

@interface EZValidateReceiptOperation()
@property (strong, nonatomic) NSData* receiptData;
@property (strong, nonatomic) NSDictionary* userInfo;
@property (copy, nonatomic) EZReceiptValidationResponse responseBlock;
@end


@implementation EZValidateReceiptOperation

#pragma mark - Init/Dealloc
- (id)initWithPurchaseReceipt:(NSData*)purchaseReceipt userInfo:(NSDictionary*)userInfo response:(EZReceiptValidationResponse)responseBlock;
{
    self = [super init];
    if (self)
    {
        self.receiptData = purchaseReceipt;
        self.userInfo = userInfo;
        self.responseBlock = responseBlock;
    }
    return self;
}

#pragma mark - Private Helpers
- (NSString*)base64StringForData:(NSData*)data
{
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}


-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        int statusCode = (int)[(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
 
            //not sure if we want to show an error to the user
            //error 503 is when tomcat is down
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  //          [alert show];
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
 //   UIAlertView *alert;
    NSError *error = nil;
    //save the user email
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
#ifndef RELEASE
    NSString *JSONString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    NSLog(@"Response I got back:%@", JSONString);
#endif

    NSString *resultMessage = [results valueForKey:@"message"];
    
    
    
    if (![resultMessage isEqualToString:@"Success"])
    {
        
        [SharedUICode messageBox:@"Error" message:@"Error Logging in. Please check your login information and try again" withCompletion:^{
            return;
        }];
        
      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error Logging in. Please check your login information and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
    }
    else {
    }
    
}

//call getUserAccount to get the type if they are employer or employee and also to get the id
/*-(void) callCheckReceiptWebService: (NSString*) receipt{
    
    NSString *httpPostString;
    NSString *request_body;
    
    
    httpPostString = SERVER_URL_SUBSCRIPTION;//[NSString stringWithFormat:@"%@account/getUserAccounts", SERVER_URL];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];

    request_body = [NSString
                    stringWithFormat:@"receipt=%@",
                    [receipt  stringByAddingPercentEncodingWithAllowedCharacters: set]];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
 //   NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    
    
    
    
}
 */

#pragma mark - NSOperation
- (void)main
{
    
    //Set up the payload as JSON
    NSError* jsonError = nil;
    NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
    payload[@"receipt"] = [self base64StringForData:self.receiptData];
    
  //  NSString *receiptStr = [self base64StringForData:self.receiptData];
    
  //  [self callCheckReceiptWebService:receiptStr];

    
    NSData* jsonPayload = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jsonError];
#ifndef RELEASE

    NSString *JSONString = [[NSString alloc] initWithBytes:[jsonPayload bytes] length:[jsonPayload length] encoding:NSUTF8StringEncoding];

    NSLog(@"JSON I sent:%@", JSONString);
#endif
    
#ifndef RELEASE
    if (jsonError != nil)
    {
        NSLog(@"JSON Encoding of payload failed: %@ %@", jsonError, jsonPayload);
    }
#endif
    //Set up an HTTP POST
    NSMutableURLRequest* postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SERVER_URL_SUBSCRIPTION]];
    postRequest.HTTPMethod = @"POST";
    postRequest.HTTPBody = jsonPayload;
    [postRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [postRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [postRequest setValue:DEV_TOKEN forHTTPHeaderField:@"x-ezclocker-developertoken"];
#ifndef RELEASE
    NSLog(@"SENDING JSON: %@", [[NSString alloc] initWithData:jsonPayload encoding:NSUTF8StringEncoding]);
#endif

    //Fire it off (OK to block here, we are backgrounded)
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:postRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        //        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary* receiptValues = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
        if (receiptValues) {
            NSString *resultMessage = [receiptValues valueForKey:@"message"];
            int errorValue = [[receiptValues valueForKey:@"errorCode"] intValue];
            if (errorValue > 0){
                UserClass *user = [UserClass getInstance];
                [MetricsLogWebService LogException: [NSString stringWithFormat:@"Yikes! server purchase validation Error from EZValidateReceiptOperation employerId= %@ errorCode = %@ resultMessage= %@", user.employerID, [receiptValues valueForKey:@"errorCode"], resultMessage]];
            }
            //Fire the response block on the main thread
            [[NSOperationQueue mainQueue] addOperationWithBlock:^
            {
                BOOL succeeded = receiptValues != nil && error == nil && [receiptValues[@"status"] intValue] == 0;
                if (self.responseBlock != nil)
                {
                    self.responseBlock(succeeded, receiptValues, error);
                }
            }];

        }
    }];
    [dataTask resume];
}


@end
