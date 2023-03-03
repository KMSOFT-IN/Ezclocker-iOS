//
//  EmployerSignUpViewController.m
//  TCS Mobile
//
//  Created by Raya Khashab on 1/13/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "EmployerSignUpViewController.h"
#import "AppDelegate.h"
#import "user.h"
#import "CommonLib.h"
#import "threaddefines.h"
#import "SharedUICode.h"

@interface EmployerSignUpViewController ()

@end

@implementation EmployerSignUpViewController
@synthesize nameLabel;
@synthesize emailLabel;
@synthesize passwordLabel;
@synthesize mainViewController;
@synthesize nameTextField;
@synthesize emailTextField;
@synthesize mainScrollView;
@synthesize passwordTextField;


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        self.title = NSLocalizedString(@"Sign Up", @"Sign Up");
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear: animated];
    //this will help us figure out which service to call
    EmployerAdded = NO;
    mainScrollView.scrollEnabled = YES;
    // set the content size so it can be scrollable
	[mainScrollView setContentSize:CGSizeMake([mainScrollView bounds].size.width, [mainScrollView bounds].size.height+50)];
    
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
 //       if (UIDeviceOrientationIsLandscape(self.interfaceOrientation))
        [self setLabelsForLandscapeOrientation];


}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    originalCenter = self.view.center;
    UIColor *orangeLightOp = UIColorFromRGB(0xdcdcdc);
    mainViewController.backgroundColor = orangeLightOp;
    


}

- (void)viewDidUnload
{
    [self setNameTextField:nil];
    [self setEmailTextField:nil];
    [self setPasswordTextField:nil];
    [self setMainViewController:nil];
    [self setMainScrollView:nil];
    [self setNameLabel:nil];
    [self setEmailLabel:nil];
    [self setPasswordLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:
    (UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self setLabelsOrientation];
}
-(void) setLabelsForLandscapeOrientation{
    nameLabel.frame = CGRectMake(340, nameLabel.frame.origin.y, nameLabel.frame.size.width, nameLabel.frame.size.height);
    passwordLabel.frame = CGRectMake(340, passwordLabel.frame.origin.y, passwordLabel.frame.size.width, passwordLabel.frame.size.height);
    emailLabel.frame = CGRectMake(340, emailLabel.frame.origin.y, emailLabel.frame.size.width, emailLabel.frame.size.height);
    
}

-(void) setLabelsOrientation{
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
//    if (UIDeviceOrientationIsLandscape(self.interfaceOrientation))
        [self setLabelsForLandscapeOrientation ];
    else
    {
        nameLabel.frame = CGRectMake(200, nameLabel.frame.origin.y, nameLabel.frame.size.width, nameLabel.frame.size.height);
        passwordLabel.frame = CGRectMake(200, passwordLabel.frame.origin.y, passwordLabel.frame.size.width, passwordLabel.frame.size.height);
        emailLabel.frame = CGRectMake(200, emailLabel.frame.origin.y, emailLabel.frame.size.width, emailLabel.frame.size.height);
    }

}
- (IBAction)nameEditingDidBegin:(id)sender {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        self.view.center = CGPointMake(originalCenter.x, originalCenter.y - 190);
}

- (IBAction)emailEditingDidBegin:(id)sender {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        self.view.center = CGPointMake(originalCenter.x, originalCenter.y - 200);
    
}
- (IBAction)passwordEditingDidBegin:(id)sender {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        self.view.center = CGPointMake(originalCenter.x, originalCenter.y - 200);
}


- (IBAction)nameEditingDidEnd:(id)sender {
   // self.view.center = originalCenter;
}

-(IBAction)backgroundTouched:(id)sender
{
    [nameTextField resignFirstResponder];
    [emailTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        self.view.center = CGPointMake(originalCenter.x, originalCenter.y - 25);
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

          //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
         //   [alert show];
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
    [CommonLib logEvent:@"Signup new employer"];
    [self stopSpinner];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSError *error = nil;
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];
    if (![resultMessage isEqualToString:@"Success"])
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Operation Failed. Please try again later."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Failure to Add" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
    }

        else {
            UserClass *user = [UserClass getInstance];
            NSArray *AuthTokens = [results valueForKey:@"activeAuthTokens"];
            //if empty array of tokens then the login was incorrect like wrong password
            if ([AuthTokens count] == 0)
            {
                [self showLoginFailureError];
            }

            for (NSDictionary *curAuthToken in AuthTokens){
                
                NSString *authToken   = [curAuthToken valueForKey:@"authToken"];
                user.authToken  = authToken;
                user.employerID     = [curAuthToken valueForKey:@"employerId"];
                
                [[NSUserDefaults standardUserDefaults] setObject:authToken forKey:@"authToken"];
                [[NSUserDefaults standardUserDefaults] setInteger:[user.employerID intValue] forKey:@"employerId"];
                [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
            }
//            AppDelegate *mainDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
//            [mainDelegate RegisterEmployerDidPass];

        }
   // }
    
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

    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
   // [alert show];
    
    connection = nil;
    data = nil;
}

*/
-(void) showLoginFailureError{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"ERROR"
                                 message:@"Login is incorrect!. Please try again."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];

 //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Login is incorrect!. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
 //   [alert show];
}



-(void) callRegisterWebService: (NSString*) userName UserEmail: (NSString *) userEmail Password: (NSString *) userPassword{
    [self callRegisterAPI:userName UserEmail: userEmail Password: userPassword withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
           
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            

        //    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
            NSString *resultMessage = [aResults valueForKey:@"message"];
            if (![resultMessage isEqualToString:@"Success"])
            {
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"Operation Failed. Please try again later."
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];

              }
              else {
//                    [CommonLib logEvent:@"Add Signup"];
            
                    UserClass *user = [UserClass getInstance];
                    NSArray *AuthTokens = [aResults valueForKey:@"activeAuthTokens"];
                    //if empty array of tokens then the login was incorrect like wrong password
                    if ([AuthTokens count] == 0)
                    {
                        [self showLoginFailureError];
                    }

                    for (NSDictionary *curAuthToken in AuthTokens){
                        
                        NSString *authToken   = [curAuthToken valueForKey:@"authToken"];
                        user.authToken  = authToken;
                        user.employerID     = [curAuthToken valueForKey:@"employerId"];
                        
                        [[NSUserDefaults standardUserDefaults] setObject:authToken forKey:@"authToken"];
                        [[NSUserDefaults standardUserDefaults] setInteger:[user.employerID intValue] forKey:@"employerId"];
                        [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
                    }
 
                }
        }
        
    }];
}

-(void) callRegisterAPI:(NSString*) userName UserEmail: (NSString *) userEmail Password: (NSString *) userPassword withCompletion:(ServerResponseCompletionBlock)completion
{
    
    NSString *httpPostString;
    NSString *request_body;
 
//    httpPostString = [NSString stringWithFormat:@"%@employer/add", SERVER_URL];
    httpPostString = [NSString stringWithFormat:@"%@employer/addGetAuth", SERVER_URL];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    
    request_body = [NSString 
                    stringWithFormat:@"developerToken=%@&employerName=%@&emailAddress=%@&password=%@",
                    [DEV_TOKEN        stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [userName     stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [userEmail     stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [userPassword     stringByAddingPercentEncodingWithAllowedCharacters: set]];
    
    
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

    /*
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
    }
    
    */
}

/*-(void) callLoginWebService: (NSString*) userName Password: (NSString *) userPassword EmployerID:(NSString *) employerID {
    
     NSString *httpPostString;
    NSString *request_body;
    
    httpPostString = [NSString stringWithFormat:@"%@account/getAuthToken/%@", SERVER_URL, employerID];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    
    request_body = [NSString 
                    stringWithFormat:@"developerToken=%@",
                    [DEV_TOKEN        stringByAddingPercentEncodingWithAllowedCharacters: set
]];   
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
        
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
    }
    
    
}
*/

- (IBAction)doRegister:(id)sender {
    [self startSpinnerWithMessage:@"Authenticating..."];

    [self callRegisterWebService:self.nameTextField.text UserEmail:self.emailTextField.text Password: self.passwordTextField.text];
}
@end
