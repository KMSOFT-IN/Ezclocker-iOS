//
//  ShiftDetailsViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 10/17/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "ShiftDetailsViewController.h"
#import "user.h"
#import "CommonLib.h"
#import "MetricsLogWebService.h"
#import "threaddefines.h"
#import "SharedUICode.h"
#import "NSString+Extensions.h"


@interface ShiftDetailsViewController ()

@end

@implementation ShiftDetailsViewController




- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _nameLabel.text = @"";
    _streetAddressLabel.text = @"";
    _cszAddressLabel.text = @"";
    
    UITableView* TV = [[UITableView alloc] init];
    UIColor* separatorColor = [TV separatorColor];
    _separatorLbl1.textColor = separatorColor;
    _separatorLbl2.textColor = separatorColor;
    _separatorLbl3.textColor = separatorColor;
    CALayer *imageLayer = _notesTextView.layer;
    [imageLayer setCornerRadius:10];
    [imageLayer setBorderWidth:2.1];
    imageLayer.borderColor=[[UIColor lightGrayColor] CGColor];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    if ((self.shiftLocId != nil) && ([self.shiftLocId integerValue] != -1))
    {
        _viewMapButton.enabled = YES;
        [self startSpinnerWithMessage:@"Connecting to the server..."];
        [self callGetAddressbyLocationId];
    }
    else{
        _nameLabel.text = @"";
        _streetAddressLabel.text = @"No location address was assigned";
        _viewMapButton.enabled = NO;
    }
    
    _notesTextView.text = self.shiftNotes;
    
    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    [_scrollView setScrollEnabled:YES];
    [_scrollView setContentSize:CGSizeMake(320, 650)];
    _scrollView.delaysContentTouches = NO;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


-(void) callGetAddressbyLocationId {

    [self callGetAddressbyLocationIdAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {

        [self stopSpinner];

        if (aErrorCode != 0) {

            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{

                return;

            }];

        }

        else

        {

            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

            NSError *error = nil;

          //  NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            

         //   NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;

            NSString *resultMessage = [aResults valueForKey:@"message"];

            if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){

                [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from ShiftDetailsViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];

                UIAlertController * alert = [UIAlertController

                                             alertControllerWithTitle:@"ERROR"

                                             message:@"ezClocker is unable to connect to the server at this time. Please try again later"

                                             preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

                [alert addAction:defaultAction];

                [self presentViewController:alert animated:YES completion:nil];

            }

            else {

                NSString *location = [aResults valueForKey:@"location"];

                //keep these variable to be used for the view map url

                NSString *name = [location valueForKey:@"name"];

                streetNum = [location valueForKey:@"streetNumber"];

                streetName = [location valueForKey:@"streetName"];

                city = [location valueForKey:@"city"];

                state = [location valueForKey:@"_state"];

        
                NSString *streetAddress = [NSString stringWithFormat:@"%@ %@", streetNum, streetName];

                if ([NSString isNilOrEmpty:state])
                    state = @"";

                if ([NSString isNilOrEmpty:city])
                    city = @"";

                if ([NSString isNilOrEmpty:streetNum])
                    streetNum = @"";

                if ([NSString isNilOrEmpty:streetName])
                    streetName = @"";

                NSString *csz = [NSString stringWithFormat:@"%@, %@ %@", city, state, [location valueForKey:@"postalCode"]];

                if (![name isEqual:[NSNull null]])
                    _nameLabel.text = name;

                _streetAddressLabel.text = streetAddress;

                _cszAddressLabel.text = csz;

                streetNum = [streetNum stringByReplacingOccurrencesOfString:@" " withString:@""];

                streetName = [streetName stringByReplacingOccurrencesOfString:@" " withString:@"+"];

                city = [city stringByReplacingOccurrencesOfString:@" " withString:@"+"];

                state = [state stringByReplacingOccurrencesOfString:@" " withString:@"+"];

            }

        }

    }];

}

-(void) callGetAddressbyLocationIdAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
//    NSString *request_body;
    UserClass *user = [UserClass getInstance];
    httpPostString = [NSString stringWithFormat:@"%@api/v1/location/%@", SERVER_URL, self.shiftLocId];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    
    //set HTTP Method
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"employerId"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"authToken"];
    
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
    
    
    //set request body into HTTPBody.
    //    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Connection to the server failed"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
        
    }
    */
    
}

/*

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            [self stopSpinner];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //error 503 is when tomcat is down
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
           // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
        }
    }
    
    
    data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self stopSpinner];
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"ERROR"
                                 message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
  //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
   // [alert show];
    
    connection = nil;
    data = nil;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataIn
{
    [data appendData:dataIn];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    //    if (mode == OperationGet)
    //    {
    [self stopSpinner];
    
    NSError *error = nil;
    
  //  NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];
    
    
    if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from ShiftDetailsViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
         //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Server Failure" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
         //   [alert show];
    }
    else {
        
        NSString *location = [results valueForKey:@"location"];
        //keep these variable to be used for the view map url
        NSString *name = [location valueForKey:@"name"];
        streetNum = [location valueForKey:@"streetNumber"];
        streetName = [location valueForKey:@"streetName"];
        city = [location valueForKey:@"city"];
        state = [location valueForKey:@"_state"];
        
        NSString *streetAddress = [NSString stringWithFormat:@"%@ %@", streetNum, streetName];
        NSString *csz = [NSString stringWithFormat:@"%@, %@ %@", city, state, [location valueForKey:@"postalCode"]];
 
        if (![name isEqual:[NSNull null]])
            _nameLabel.text = name;

        _streetAddressLabel.text = streetAddress;
        _cszAddressLabel.text = csz;

        streetNum = [streetNum stringByReplacingOccurrencesOfString:@" " withString:@""];
        streetName = [streetName stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        city = [city stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        state = [state stringByReplacingOccurrencesOfString:@" " withString:@"+"];

    }
    
}
*/

- (IBAction)doViewMap:(id)sender {
    NSString *fullAddr = [NSString stringWithFormat:@"http://maps.apple.com/?address=%@,%@,%@,%@", streetNum, streetName, city, state];
    NSURL *url = [NSURL URLWithString:fullAddr];
  //  [[UIApplication sharedApplication] openURL:url];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    [CommonLib logEvent:@"View location map"];
    //http://maps.apple.com/?ll=50.894967,4.341626
    //http://maps.apple.com/?address=2003,Saint+Anne+drive,Allen,TX
    //http://maps.apple.com/?address=1,Infinite+Loop,Cupertino,California
}

@end
