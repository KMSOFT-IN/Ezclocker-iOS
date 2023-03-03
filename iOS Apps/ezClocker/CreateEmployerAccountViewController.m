//
//  CreateEmployerAccountViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 2/28/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "CreateEmployerAccountViewController.h"
#import "user.h"
//#import "mixpanel.h"
#import "CommonLib.h"
#import "TermsOfServiceViewController.h"
#import "LoginViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "MetricsLogWebService.h"
#import "threaddefines.h"
#import "SharedUICode.h"

@interface CreateEmployerAccountViewController ()

@end

@implementation CreateEmployerAccountViewController

//constants for the seg choices of employer or employee

int const EMPLOYER_SELECTED = 0;

int const EMPLOYEE_SELECTED = 1;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    [_emailTextField setReturnKeyType:UIReturnKeyDone];
     _emailTextField.delegate = (id) self;
    
    [_continueButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    [_signupButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    
    [_segControl setSelectedSegmentIndex:0];
    
    [_logoImageView setHidden:NO];
#ifdef IPAD_VERSION
    UIImage *image = [UIImage imageNamed: @"splash_screen_orange_iPad.png"];
    [_splashImage setImage:image];
     [_logoImageView setHidden:YES];
#endif
    
    [self registerForKeyboardNotifications];


}
- (void)viewDidUnload
{
    [super viewDidUnload];

}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
//    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
//        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
  //  }
    
    
  //  [self.view addGestureRecognizer:self.slidingViewController.panGesture];

    [_scrollView setScrollEnabled:YES];
    
//    [_scrollView setContentSize:CGSizeMake(320, 650)];
    _scrollView.backgroundColor = UIColorFromRGB(DARK_ORANGE_COLOR);
    
//    _emailLabel.frame = CGRectMake(12, 201, 64, 43);
//    _FirstContainer.frame = CGRectMake(0, 201, 320, 70);
    

}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
//    CGPoint kbOrigin = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].origin;
    UIEdgeInsets contentInsets;
    
    if (_scrollView.contentInset.bottom < -180) {
        return;
    }
    
    contentInsets = UIEdgeInsetsMake(0.0, 0.0, -kbSize.height, 0.0);
    
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    int keyBoardY = [[UIScreen mainScreen] bounds].size.height - kbSize.height;
    if (self.subView.frame.origin.y + self.subView.frame.size.height > keyBoardY) {
        
        CGFloat height = (self.subView.frame.origin.y + self.subView.frame.size.height) - keyBoardY;
        CGPoint scrollPoint = CGPointMake(0.0, height);
        [_scrollView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
}

/*// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
   // CGRect aRect = self.view.frame;
  //  aRect.size.height -= kbSize.height;
 //   if (!CGRectContainsPoint(aRect, _continueButton.frame.origin) ) {
 //      [self.scrollView scrollRectToVisible:_continueButton.frame animated:YES];
 // }
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [_scrollView setContentOffset:CGPointMake(0,0) animated:YES];
}*/


-(void) hideKeyboard{
   // [_nameTextField resignFirstResponder];
    [_emailTextField resignFirstResponder];
   // [_passwordTextField resignFirstResponder];
}

-(void)removeKeyboard{
  //  [_nameTextField resignFirstResponder];
    [_emailTextField resignFirstResponder];
  //  [_passwordTextField resignFirstResponder];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*- (IBAction)doCreateAccount:(id)sender {
    [self hideKeyboard];
    
    if ([_emailTextField.text length] == 0) {
        UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter an Email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
    else
    {

        UserClass *user = [UserClass getInstance];
        user.userEmail = _emailTextField.text;
        [self.delegate CreateEmployerStep2WasSelected:self];
    }
 
    if ([_nameTextField.text length] == 0) {
        UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a Name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
    else{
        if ([_emailTextField.text length] == 0) {
            UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter an Email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
        }
        else{
            if ([_passwordTextField.text length] == 0) {
                UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a Password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                
            }
            else{
                
                if ([CommonLib validateEmail:_emailTextField.text])
                {
                    [self startSpinner ];
                    [self callAddGetAuthWebService];
                }
                else{
                    UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a valid email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            }

        }
    }
 

}*/

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
//    if (theTextField.tag == 123)
//        [self doCreateAccount:self];
    [self removeKeyboard];
    return YES;
    
}


- (IBAction)doSignIn:(id)sender {
    
//    [self.delegate loginViewControllerWasSelected:self];

//    LoginViewController *loginController = [self.storyboard instantiateViewControllerWithIdentifier:@"Login"];
    //pass the delegate so when login finishes it calls back the delegate (initialslidingviewcontroller)
//    loginController.delegate = (id) self.delegate;
//    loginController.source = self;
    [self.delegate loginViewControllerWasSelected:self];
    //[self presentViewController:loginController animated:YES completion:nil];
}

/*- (IBAction)doTermsofService:(id)sender {
    TermsOfServiceViewController *termsOfServiceViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TermsOfService"];

    UINavigationController *termsOfServiceNavigationController = [[UINavigationController alloc] initWithRootViewController:termsOfServiceViewController];

    termsOfServiceViewController.delegate = (id) self;

    termsOfServiceNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    
    [self presentViewController:termsOfServiceNavigationController animated:YES completion:nil];

}
*/
- (IBAction)doSwitchChanged:(id)sender {
    
}

-(void) callDoesAccountExists{
    [self callDoesAccountExistsAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
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
            UserClass *user = [UserClass getInstance];
            //save the user email
            user.userEmail = _emailTextField.text;
         //   user.employerName = _nameTextField.text;
          //check for error code 8
        //    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        //    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
            NSString *resultMessage = [aResults valueForKey:@"message"];
           
            int errorValue = [[aResults valueForKey:@"errorCode"] intValue];

            
            if ((errorValue > 0) && (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])))
            {
                //if the account already exists show the message that the service sends back else give them a generic message
                if (errorValue == WEB_SERVICE_ACCOUNT_EXIST_ERROR){
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"ERROR"
                                                 message:resultMessage
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:defaultAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];

                  //  alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                }
                else{
                    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from CreateEmployerAccountViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];

         //           alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error Checking Account!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                }
               // [alert show];
            }
            else {

                NSNumber *exits = [aResults valueForKey:@"exists"];
                if ([exits intValue] == 1)
                {
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"ERROR"
                                                 message:@"Your account already exists in our system. Please sign in"
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:defaultAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];

                 //   alert = [[UIAlertView alloc] initWithTitle:nil message:@"Your account already exists in our system. Please sign in" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    
                    [self.delegate loginViewControllerWasSelected:self];
                    
                  //  [alert show];
                    
                }
                else
                {
                    //if they chose employee and we can't find them in our system then block them fro signing up
                    if (_segControl.selectedSegmentIndex == EMPLOYEE_SELECTED)
                    {
                        //       UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Please Confirm"
                        //                                                      message:@"Does your employer use ezClocker?"
                        //                                                     delegate:self
                        //                                            cancelButtonTitle:@"No"
                        //                                            otherButtonTitles:@"Yes",nil];
                        UIAlertController * alert = [UIAlertController
                                                     alertControllerWithTitle:@"Employee Signup"
                                                     message:@"If your employer is using ezClocker, ask them to send you an invite and then check your email for additional steps. Otherwise, you should use ezClocker Personal available for free in the App Store."
                                                     preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                        
                        [alert addAction:defaultAction];
                        
                        [self presentViewController:alert animated:YES completion:nil];

                      }
                    else
                    {
                        
                        [self.delegate CreateEmployerStep2WasSelected:self];
                        
                    }
                }

             }

        }
    }];
}

-(void) callDoesAccountExistsAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    

    NSString *httpPostString;
    NSString *userEmail = _emailTextField.text;
    NSString *source =@"IPHONE";
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/exists?emailAddress=%@&source=%@", SERVER_URL, userEmail, source];

     NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:DEV_TOKEN forHTTPHeaderField:@"x-ezclocker-developertoken"];
    
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

    //    alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
    }
    
    */
}

/*
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        int statusCode = (int)[(NSHTTPURLResponse*) response statusCode];
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

       //     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //      [alert show];
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
    [self stopSpinner];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSError *error = nil;
    UserClass *user = [UserClass getInstance];
    //save the user email
    user.userEmail = _emailTextField.text;
 //   user.employerName = _nameTextField.text;
  //check for error code 8
//    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];
   
    int errorValue = [[results valueForKey:@"errorCode"] intValue];

    
    if ((errorValue > 0) && (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])))
    {
        //if the account already exists show the message that the service sends back else give them a generic message
        if (errorValue == WEB_SERVICE_ACCOUNT_EXIST_ERROR){
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:resultMessage
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

          //  alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
        else{
            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from CreateEmployerAccountViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];

 //           alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error Checking Account!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
       // [alert show];
    }
    else {

        NSNumber *exits = [results valueForKey:@"exists"];
        if ([exits intValue] == 1)
        {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"Your account already exists in our system. Please sign in"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

         //   alert = [[UIAlertView alloc] initWithTitle:nil message:@"Your account already exists in our system. Please sign in" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            
            [self.delegate loginViewControllerWasSelected:self];
            
          //  [alert show];
            
        }
        else
        {
            //if they chose employee and we can't find them in our system then block them fro signing up
            if (_segControl.selectedSegmentIndex == EMPLOYEE_SELECTED)
            {
                //       UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Please Confirm"
                //                                                      message:@"Does your employer use ezClocker?"
                //                                                     delegate:self
                //                                            cancelButtonTitle:@"No"
                //                                            otherButtonTitles:@"Yes",nil];
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"Employee Signup"
                                             message:@"If your employer is using ezClocker, ask them to send you an invite and then check your email for additional steps. Otherwise, you should use ezClocker Personal available for free in the App Store."
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];

            }
            else
            {
                
                [self.delegate CreateEmployerStep2WasSelected:self];
                
            }
        }

     }
    
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
    
 //   [alert show];
    
    connection = nil;
    data = nil;
}

*/

- (void)termsOfServiceControllerDidFinishViewing:(TermsOfServiceViewController *)controller
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)doContinueAction:(id)sender {
    [self hideKeyboard];
    
    if ([_emailTextField.text length] == 0) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter an Email"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

     //   UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter an Email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
        
    }
    else{
        
        if ([CommonLib validateEmail:_emailTextField.text])
        {
            [self startSpinnerWithMessage:@"Checking Account..."];
            [self callDoesAccountExists];
        }
        else{
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"Please enter a valid email"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

           // UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a valid email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
        }
    }
    
}




@end
