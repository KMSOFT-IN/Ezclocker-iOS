//
//  LoginPersonalViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 1/31/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import "LoginPersonalViewController.h"
#import "user.h"
#import "ECSlidingViewController.h"
#import "CommonLib.h"
//#import "MixPanel.h"
#import "MetricsLogWebService.h"
#import "SubscriptionWebService.h"

@implementation LoginPersonalViewController

- (IBAction)doForgotPassword:(id)sender {
    UIAlertView *recoverPasswordAlert = [[UIAlertView alloc] initWithTitle:@"Forgot Password" message:@"Enter email" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [recoverPasswordAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    recoverPasswordAlert.tag = 1234;
    UITextField *textField = [recoverPasswordAlert textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeEmailAddress;
    textField.text = _emailTextField.text;
    [textField setDelegate:self];
    [recoverPasswordAlert show];
}

-(void) hideKeyboard{
    [_emailTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _emailTextField.delegate = self;
    _passwordTextField.delegate = self;
    [_emailTextField setReturnKeyType:UIReturnKeyDone];
    [_passwordTextField setReturnKeyType:UIReturnKeyGo];
    self.navigationItem.leftBarButtonItem = _menuBarItem;
    self.navigationItem.rightBarButtonItem = nil;
    _passwordTextField.tag = 123;
    [self registerForKeyboardNotifications];
}

- (void)viewDidUnload
{
    [self setEmailTextField:nil];
    [self setPasswordTextField:nil];
 //   spinner = nil;
    [self setLoginButton:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    [_scrollView setScrollEnabled:YES];
//    [_scrollView setContentSize:CGSizeMake(320, 650)];
    _emailSentLabel.hidden = YES;
    [_forgotPasswordButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    [_loginButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    [_accountSetupButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    if (_hidAccountSetupButton)
        _accountSetupButton.hidden = YES;
    
    _scrollView.backgroundColor = UIColorFromRGB(DARK_ORANGE_COLOR);
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

/*
// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, _accountSetupButton.frame.origin) ) {
        [self.scrollView scrollRectToVisible:_accountSetupButton.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
/ *- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
}
 * /

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [_scrollView setContentOffset:CGPointMake(0,0) animated:YES];
}*/


- (IBAction)doLogin:(id)sender {
    [self hideKeyboard];
    if ([_emailTextField.text length] == 0) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter an E-mail"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

       // UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter an E-mail" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       // [alert show];
        
    }
    else{
        if ([_passwordTextField.text length] == 0) {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"Please enter a Password"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

         //   UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a Password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
         //   [alert show];
            
        }
        else{
            if ([CommonLib validateEmail:_emailTextField.text])
            {
                [self startSpinner ];
                [self callGetAccountWebService:_emailTextField.text Password: self.passwordTextField.text];
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
               // [alert show];
                
            }
        }
    }

}
//call getUserAccount to get the type if they are employer or employee and also to get the id
-(void) callGetAccountWebService: (NSString*) userName Password: (NSString *) userPassword{
    

    NSString *httpPostString;
    
    UserClass *user = [UserClass getInstance];
    NSString *currentEmployeeId = [user.userID stringValue];
    
    //httpPostString = [NSString stringWithFormat:@"%@account/getUserAccounts", SERVER_URL];

    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/individual/authenticate", SERVER_URL];

   /* request_body = [NSString
                    stringWithFormat:@"developerToken=%@&userName=%@&password=%@",
                    [DEV_TOKEN        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [userName     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [userPassword     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding                    ]];
    */
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          currentEmployeeId, @"currentEmployeeId",
                          userName, @"userName",
                          userPassword, @"password",
                          @"iPHONE", @"source",
                          nil];
    
    
    NSError *error;
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    //set request body into HTTPBody.
    urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:DEV_TOKEN forHTTPHeaderField:@"x-ezclocker-developertoken"];
    
    
    //set request url to the NSURLConnection
    getAccountConnection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (getAccountConnection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Connection to the server failed"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

        //alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       // [alert show];
        
    }
    
    
}

-(void) callGetAuthTokensWebService: (NSString*) userName Password: (NSString *) userPassword UserID: (NSString *) userID UserType: (NSString *) userType{
    
    NSString *httpPostString;
    NSString *request_body;
    
    if ([userType isEqualToString:@"employer"]){
        httpPostString = [NSString stringWithFormat:@"%@account/getEmployerAuthTokens/%@", SERVER_URL, userID];
    }
    else{
        httpPostString = [NSString stringWithFormat:@"%@api/v1/account/authenticate/employee/%@", SERVER_URL, userID];

     //   httpPostString = [NSString stringWithFormat:@"%@account/getEmployeeAuthTokens/%@", SERVER_URL, userID];
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          userName, @"userName",
                          userPassword, @"password",
                          @"iPHONE", @"source",
                          nil];
    
    
    NSError *error;
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:DEV_TOKEN forHTTPHeaderField:@"x-ezclocker-developertoken"];

    //set request url to the NSURLConnection
    getAuthConnection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (getAuthConnection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Connection to the server failed"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

       // alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       // [alert show];
        
    }
    
    
}
//call getUserAccount to get the type if they are employer or employee and also to get the id
/*-(void) callGetEmployerInfoWebService{
 
    NSString *httpPostString;
    NSString *request_body;
    UserClass *user = [UserClass getInstance];
    
    httpPostString = [NSString stringWithFormat:@"%@/employer/get/%@", SERVER_URL, user.employerID];
    //    httpPostString = [NSString stringWithFormat:@"%@account/getAuthTokensForEmployee", SERVER_URL];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    request_body = [NSString
                    stringWithFormat:@"authToken=%@",
                    [user.authToken  stringByAddingPercentEncodingWithAllowedCharacters: set]];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
    getAccountConnection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (getAccountConnection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Connection to the server failed"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

       // alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       // [alert show];
        
    }
    
    
}
*/
//call Reset Password web service which will send the user an email to reset password
-(void) callResetPasswordWebService: (NSString*) email{
    
    NSString *httpPostString;
    NSString *request_body;
    
    httpPostString = [NSString stringWithFormat:@"%@account/resetPassword", SERVER_URL];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    request_body = [NSString
                    stringWithFormat:@"developerToken=%@&emailAddress=%@",
                    [DEV_TOKEN stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [email     stringByAddingPercentEncodingWithAllowedCharacters: set]
                    ];
    
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
                                     message:@"Connection to the server failed"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
    }
    
    
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        int statusCode = [(NSHTTPURLResponse*) response statusCode];
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

        //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
    [self stopSpinner];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    NSError *error = nil;
    UserClass *user = [UserClass getInstance];
    //save the user email
    user.userEmail = _emailTextField.text;
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];
    
    
    
    if (![resultMessage isEqualToString:@"Success"])
    {
        
        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from LoginViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Error Logging in. Please check your login information and try again"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error Logging in. Please check your login information and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
    }
    else {
        //figure out if we did the call to the getAccount or getAuthToken by checking the connection
        if (connection == getAccountConnection){
            //            if (connection == getAuthConnection){
            NSArray *accounts = [results valueForKey:@"employerAccounts"];
            //if empty array then to see if the user is an employee
            if ([accounts count] == 0)
            {
                accounts = [results valueForKey:@"employeeAccounts"];
            }
            
            if ([accounts count] == 0){
                self.loginButton.enabled = true;
                [self showLoginFailureError];
            }
            else {
                //get the customers for personal app
                NSArray *accountCustomers = [accounts valueForKey:@"customers"];
                if ([accountCustomers count] > 0)
                {
                    NSArray* customers = [accountCustomers objectAtIndex:0];
                    NSString* name;
                    NSString *email;
                    NSNumber *customerID;
                    [user.customerNameIDList removeAllObjects];
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
                    if ([user.customerNameIDList count] > 0)
                    {
                        [[NSUserDefaults standardUserDefaults] setObject:user.customerNameIDList forKey:@"customerNameIDList"];

                        [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
                    }

                }
                //pick the first one need to change later
                NSDictionary *curAccount = [accounts objectAtIndex:0];
                
                NSString *tmp   = [curAccount valueForKey:@"type"];
                user.userType = tmp;
                if ([tmp isEqualToString:@"employer"]) {
                    //this is bad because they are using a login that is employer with the personal app
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"ERROR"
                                                 message:@"This Login is an Employer Login. Please use our other app ezClocker Employee Time Track for Employer Accounts"
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:defaultAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];

                  //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"This Login is an Employer Login. Please use our other app ezClocker for Business for Employer Logins" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                  //  [alert show];

                }
                else {
                    user.userID = [curAccount valueForKey:@"id"];
                    user.indivdualName = [curAccount valueForKey:@"name"];
                    user.userEmail = [curAccount valueForKey:@"username"];
                    user.hasAccount = @"YES";
                    
                    //call to get the AuthToken
                    [self callGetAuthTokensWebService:_emailTextField.text Password: self.passwordTextField.text UserID:[user.userID stringValue] UserType: user.userType];

                }
                
            }
        }
        //else the getAuthToken connection was called
        else if (connection == getAuthConnection){
            NSArray *authTokens = [results valueForKey:@"activeAuthTokens"];
            NSDictionary *curAuthToken = [authTokens objectAtIndex:0];
         //   NSString *tmp   = [curAuthToken valueForKey:@"authToken"];
         //   user.authToken  = tmp;
         //   user.employerID = [curAuthToken valueForKey:@"employerId"];
            if ([[curAuthToken valueForKey:@"employerId"] integerValue] != PERSONAL_EMPLOYERID)
            {
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"WARNING"
                                             message:@"You are signing into the wrong app. You need to use our other app titled ezClocker Employee Time Track so your employer can see your time sheet. Please install our other app"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];

              //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"WARNING! you are using the wrong app. You need to use the ezClocker for Business app so your employer can see your time sheet. Please install our other app" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
              //  [alert show];
            }
            else
            {
                NSString *tmp   = [curAuthToken valueForKey:@"authToken"];
                user.authToken  = tmp;
                user.employerID = [curAuthToken valueForKey:@"employerId"];
            //save data
            
            [[NSUserDefaults standardUserDefaults] setInteger:[user.employerID intValue] forKey:@"employerId"];
            [[NSUserDefaults standardUserDefaults] setInteger:[user.userID intValue] forKey:@"employeeId"];
            [[NSUserDefaults standardUserDefaults] setObject:user.indivdualName forKey:@"UserName"];
            [[NSUserDefaults standardUserDefaults] setObject:user.userEmail forKey:@"userEmail"];
            [[NSUserDefaults standardUserDefaults] setObject:user.hasAccount forKey:@"HasAccount"];
            [[NSUserDefaults standardUserDefaults] setObject:tmp forKey:@"authToken"];
            [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
            
            
            //log to mixpanel if we are production
            if ([CommonLib isProduction])
            {
//                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                
//                [mixpanel track:@"Personal Login" properties:@{ @"email": _emailTextField.text}];
            }
            //check to see if we have a subscription
            SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
            [subscriptionWebService checkValidLicense];
            
            [self.delegate loginPersonalViewControllerDidFinished:self];
            
            
            //tell the App Delegate to launch the main view controller
            //          AppDelegate *mainDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
            //         [mainDelegate loginDidPass];
        }
        }
    }
    
}

-(void) showLoginFailureError{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"ERROR"
                                 message:@"Email or password is incorrect!. Please try again."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];

   // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Email or password is incorrect!. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
   // [alert show];
}

-(void) startSpinner{
    [SVProgressHUD showWithStatus:@"Authenticating"];
}

-(void) stopSpinner{
    [SVProgressHUD dismiss];
}

-(void)removeKeyboard{
    [_emailTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField.tag == 123)
        [self doLogin:self];
    [self removeKeyboard];
    return YES;
    
}

- (IBAction)doSignUp:(id)sender {
    [self.delegate createPersonalViewControllerWasSelected:self];
}
- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1234) {
        UITextField *emailTextField = [alertView textFieldAtIndex: 0];
        //check if the OK button (index 1) was selected
        if (buttonIndex == 1)
        {
            if ([emailTextField.text length] > 0)
            {
                if ([CommonLib validateEmail:emailTextField.text])
                {
                    [self callResetPasswordWebService:emailTextField.text];
                    UIAlertView *confirmationDialog = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Instructions for accessing your account has been sent to the email you provided." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    
                    [confirmationDialog show];
                }
                else{
                    NSString *errorMessage= [NSString stringWithFormat:@"Email %@ is invalid. Please try again", emailTextField.text];
                    UIAlertView *confirmationDialog = [[UIAlertView alloc] initWithTitle:@"Error" message: errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    
                    [confirmationDialog show];
                    
                }
            }
        }
    }

    
/*    if (alertView.tag == 1234) {
        UITextField *emailTextField = [alertView textFieldAtIndex: 0];
        //check if the OK button (index 1) was selected
        if (buttonIndex == 1)
        {
            if ([emailTextField.text length] > 0)
            {
                _emailSentLabel.hidden = NO;
                [self callResetPasswordWebService:emailTextField.text];
            }
        }
    }*/
}



@end
