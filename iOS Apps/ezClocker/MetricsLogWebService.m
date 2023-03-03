//
//  MetricsLogWebService.m
//  ezClocker
//
//  Created by Raya Khashab on 3/3/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "MetricsLogWebService.h"

#import "user.h"
#import "CommonLib.h"

@implementation MetricsLogWebService

+(void) LogException:(NSString*) message{
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    NSString *request_body;
    httpPostString = [NSString stringWithFormat:@"%@metric/write", SERVER_URL];
    //Implement request_body for send request here authToken and clock DateTime set into the body.
    NSString *appVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

#ifdef PERSONAL_VERSION
    NSString *mKeyEvent = [NSString stringWithFormat:@"%@ App Version: %@", @"EXCEPTION.IPHONE.PERSONAL", appVer];
#else
    NSString *mKeyEvent = [NSString stringWithFormat:@"%@ App Version: %@", @"EXCEPTION.IPHONE.BUSINESS", appVer];

#endif
    NSString *mDetailEvent = message;
    NSString *instance = @"Mobile";
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    request_body = [NSString
                    stringWithFormat:@"developerToken=%@&event=%@&details=%@&userName=%@&instance=%@&source=%@",
                    [DEV_TOKEN   stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [mKeyEvent  stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [mDetailEvent  stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [user.userEmail  stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [instance  stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [@"iPhone" stringByAddingPercentEncodingWithAllowedCharacters: set]
                    ];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];

}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
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
   // NSError *error = nil;
   // NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
   // NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];


}

@end
