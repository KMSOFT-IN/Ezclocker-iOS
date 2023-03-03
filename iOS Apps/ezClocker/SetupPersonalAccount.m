//
//  SetupPersonalAccount.m
//  ezClocker
//
//  Created by Raya Khashab on 2/16/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "SetupPersonalAccount.h"
#import "CommonLib.h"
#import "Mixpanel.h"
#import "MetricsLogWebService.h"


@implementation SetupPersonalAccount

-(void) setupIndivdualAccount;
{
    [self callAddIndivdualAccountWebService];
}

//call getUserAccount to get the type if they are employer or employee and also to get the id
-(void) callAddIndivdualAccountWebService {
    UIAlertView *alert;
    NSString *httpPostString;
    
    NSString *UUID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/individual", SERVER_URL];

    NSString *phoneType = @"iPhone";
    NSString *source = @"iPhone";
    
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             UUID, @"phoneId",
                              phoneType, @"phoneType",
                              source, @"source",
                              nil];
    

    NSError *error = nil;

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:0
                                                         error:&error];
    NSString *JSONString;
    if (!jsonData) {
    } else {
        
        JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }

     NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];

    //set HTTP Method
    NSData *requestData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:[NSString stringWithFormat:@"%ld", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setHTTPBody: requestData];

    
    
    [urlRequest setValue:DEV_TOKEN forHTTPHeaderField:@"x-ezclocker-developertoken"];

    addIndivdualConnection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (addIndivdualConnection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        
        alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
    
    
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *aResponse = (NSHTTPURLResponse*)response;
#ifndef RELEASE
    NSLog(@"received a response: %ld",(long)[aResponse statusCode] );
#endif
    int statusCode = [((NSHTTPURLResponse *)response) statusCode];
    if (statusCode >= 400){
        NSString *errorMessage = [[NSString alloc] initWithFormat:@"Error from SetupPersonalAccount.m. Error code: %d received from server", statusCode];
        [MetricsLogWebService LogException:errorMessage];

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error connecting to the server. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        //communicate to the calling delegate that an error happened
        [self.delegate RegisterationFailed];


    }
    else

        data = [[NSMutableData alloc] init];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataIn
{
    [data appendData:dataIn];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    UserClass *user = [UserClass getInstance];
    NSError *error = nil;
     UIAlertView *alert;
#ifndef RELEASE
    NSString* newStr = [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding];
     NSLog(@"JSONString is %@", newStr);
#endif
    
     NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;

    NSString *resultMessage = [results valueForKey:@"message"];
     if (![resultMessage isEqualToString:@"Success"])
     {
         [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from SetupPersonalAccount.m JSON Parsing: %@ resultMessage= %@", error.localizedDescription, resultMessage]];
         
         alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error connecting to the server. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];

       [alert show];
        [self.delegate RegisterationFailed];

     }
     else{
         //figure out if we did the call to the getAccount or getAuthToken by checking the connection
         if (connection == addIndivdualConnection){
             user.userEmail = [results valueForKey:@"generatedUserName"];
             user.individualGeneratedPassword = [results valueForKey:@"generatedUserPassword"];
             user.userType = @"employee";
             
             //an array of Indivdual accounts will be returned so pick the first one
             NSArray *indAccounts = [results valueForKey:@"individualAccounts"];
             NSDictionary *curIndAccount = [indAccounts objectAtIndex:0];
             user.userID   = [curIndAccount valueForKey:@"id"];
             NSArray *authTokens = [results valueForKey:@"authTokens"];
             NSDictionary *curAuthToken = [authTokens objectAtIndex:0];
             NSString *tmp   = [curAuthToken valueForKey:@"authToken"];
             user.authToken  = tmp;
             user.employerID = [curAuthToken valueForKey:@"employerId"];

             //save data
             
             [[NSUserDefaults standardUserDefaults] setObject:user.individualGeneratedPassword forKey:@"UserPassword"];
             [[NSUserDefaults standardUserDefaults] setInteger:[user.employerID intValue] forKey:@"employerId"];
             [[NSUserDefaults standardUserDefaults] setInteger:[user.userID intValue] forKey:@"employeeId"];
             [[NSUserDefaults standardUserDefaults] setValue:user.userType forKey:@"userType"];
             
             [[NSUserDefaults standardUserDefaults] setObject:user.authToken forKey:@"authToken"];
             [[NSUserDefaults standardUserDefaults] setObject:user.indivdualName forKey:@"UserName"];
             [[NSUserDefaults standardUserDefaults] setObject:user.userEmail forKey:@"userEmail"];
             [[NSUserDefaults standardUserDefaults] setObject:user.individualGeneratedPassword forKey:@"generatedUserPassword"];

             [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
             //log to mixpanel if we are production
             if ([CommonLib isProduction])
             {
                 Mixpanel *mixpanel = [Mixpanel sharedInstance];
                 
                 [mixpanel track:@"Registered" properties:@{ @"email": user.userEmail}];
             }
             //communicate to the assigned delegate that we registered the individual user
             [self.delegate RegisterationFinished];


             //[self callGetAccountWebService:userName Password:userPassword];

         }
         

     }
     

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
    
    connection = nil;
    data = nil;
}

+ (NSString *)GetUUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}



@end
