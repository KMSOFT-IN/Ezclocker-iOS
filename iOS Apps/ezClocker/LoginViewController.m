//
//  LoginViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 10/22/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "LoginViewController.h"
#import "CommonLib.h"
#import "AppDelegate.h"
#import "user.h"
#import "SharedUICode.h"
#import "PushNotificationManager.h"
#import "Mixpanel.h"
#import "LocationEntityFields.h"
#import "MetricsLogWebService.h"
#import "NSString+Extensions.h"
#import "SVProgressHUD.h"
#import "threaddefines.h"
#ifndef PERSONAL_VERSION
#import "CreateEmployerAccountViewController.h"
#endif

@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize delegate = _delegate;
@synthesize emailLabel = _emailLabel;
@synthesize passwordLabel = _passwordLabel;
@synthesize userNameTextField = _userNameTextField;
@synthesize passwordTextField = _passwordTextField;
@synthesize loginButton = _loginButton;
@synthesize loginView = _loginView;
@synthesize scrollView = _scrollView;
@synthesize emailTextField = _emailTextField;




- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    _loginView.backgroundColor = UIColorFromRGB(LOGO_ORANGE_COLOR);

    return self;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //if we only want the app to be a sign in then hide the signup so they can't signup via the app only via the website
    [_scrollView setScrollEnabled:YES];
    _scrollView.delaysContentTouches = NO;
    if (_signinOnly)
        _signUpButton.hidden = YES;
    _scrollView.backgroundColor = UIColorFromRGB(DARK_ORANGE_COLOR);
#ifdef IPAD_VERSION
    [_signUpButton setTitle:@"Don't have an account? Please visit ezclocker.com to create one" forState:UIControlStateNormal];
    [_signUpButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_signUpButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16]];
   // _scrollView.backgroundColor = UIColor.lightGrayColor;
    
    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
#endif
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    //    [_scrollView setScrollEnabled:YES];
    
    //    [_scrollView setContentSize:CGSizeMake(320, 650)];
    //    [self hideKeyboard];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}
// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}
 


// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGPoint kbOrigin = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].origin;
    UIEdgeInsets contentInsets;
    
    contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    if (_passwordView.frame.origin.y + _passwordView.frame.size.height > kbOrigin.y) {
        //            if (!CGRectContainsPoint(aRect, _passwordTextField.frame.origin) ) {
        
        
        CGFloat height = (_signInView.frame.origin.y + _signInView.frame.size.height) - kbOrigin.y;
        CGPoint scrollPoint = CGPointMake(0.0, height);
        //            CGPoint scrollPoint = CGPointMake(0.0, 500);
        [_scrollView setContentOffset:scrollPoint animated:YES];
        //            }
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
}
 

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [_logoImageView setHidden:NO];
//#ifdef IPAD_VERSION
//    UIImage *image = [UIImage imageNamed: @"splash_screen_orange_iPad.png"];
//    [_splashScreenImageView setImage:image];
//    [_logoImageView setHidden:YES];
//#endif
    
 //   [_loginButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    [_forgotPasswordLabel setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    [_signUpButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];

    _userNameTextField.delegate = self;
    _passwordTextField.delegate = self;
    [_userNameTextField setReturnKeyType:UIReturnKeyDone];
    [_passwordTextField setReturnKeyType:UIReturnKeyGo];
    _passwordTextField.tag = 123;

    _mainViewController.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self registerForKeyboardNotifications];
    }

}

- (void)viewDidUnload
{
    [self setUserNameTextField:nil];
    [self setPasswordTextField:nil];
    [self setLoginButton:nil];
    [self setPasswordTextField:nil];
    [self setUserNameTextField:nil];
    [self setPasswordTextField:nil];
    [self setPasswordTextField:nil];
    [self setEmailLabel:nil];
    [self setPasswordLabel:nil];
    [self setPasswordLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if (orientation == UIInterfaceOrientationPortrait) {
            // your code for portrait mode
            
        }
        return NO;
    } else {
        return  YES;
    }

}

- (BOOL)shouldAutorotate {
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait) {
        // your code for portrait mode
        
    }
    
    return NO;
}

/*- (void)willAnimateRotationToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft ||
        orientation == UIInterfaceOrientationLandscapeRight)
    {
        _passwordLabel.frame = CGRectMake(450 - _passwordLabel.frame.size.width, _passwordLabel.frame.origin.y, _passwordLabel.frame.size.width, _passwordLabel.frame.size.height);
            [_passwordLabel sizeToFit];
        _emailLabel.frame = CGRectMake(450 - _emailLabel.frame.size.width, _emailLabel.frame.origin.y, _emailLabel.frame.size.width, _emailLabel.frame.size.height);
    }
    else
    {
        _emailLabel.frame = CGRectMake(300 - _emailLabel.frame.size.width, _emailLabel.frame.origin.y, _emailLabel.frame.size.width, _emailLabel.frame.size.height);
        _passwordLabel.frame = CGRectMake(300 - _passwordLabel.frame.size.width, _passwordLabel.frame.origin.y, _passwordLabel.frame.size.width, _passwordLabel.frame.size.height);
    }

}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//    NSString *str = response.textEncodingName;
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
           // [alert show];
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
    
    bool continueSignin = TRUE;
    
    NSError *error = nil;
    UserClass *user = [UserClass getInstance];
    //save the user email
    user.userEmail = _userNameTextField.text;
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];
    
    if (![resultMessage isEqualToString:@"Success"])
    {
        //if the message is not access denied then send the log so we can figure out what's going on otherwise it's a normal error
        if (![resultMessage isEqualToString:@"Access Denied"])
        {
            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from LoginViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
        }
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Error Signing in. Email and/or password is incorrect. Please check the information and try again"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
       // alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error Logging in. Please check your login information and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       // [alert show];
    }
    else {
        //figure out if we did the call to the getAccount or getAuthToken by checking the connection
        if (connection == getAccountConnection){
//            if (connection == getAuthConnection){
            //get the userId of the user
            NSDictionary *userDict = [results valueForKey:@"user"];
            user.realUserId = [userDict valueForKey:@"id"];
            NSArray *accounts = [results valueForKey:@"employerAccounts"];
            NSArray *authoritiesFromServer = [userDict valueForKey:@"userAuthorities"];
            user.userAuthorities = [[NSMutableArray alloc] init];
            for (NSDictionary *authority in authoritiesFromServer)
            {
                NSString *authorityType = [authority valueForKey:@"authority"];
                [user.userAuthorities addObject:authorityType];
            }
 
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

                //pick the first one need to change later
                NSDictionary *curAccount = [accounts objectAtIndex:0];

                NSString *userType   = [curAccount valueForKey:@"type"];
                user.userType = userType;
                if ([userType isEqualToString:@"employer"]) {
                    //this is not the userid this is the employeeId
                    user.userID     = [curAccount valueForKey:@"id"];
                    user.employerID = [curAccount valueForKey:@"id"];
                    user.employerName = [curAccount valueForKey:@"name"];
                    user.userEmail = [curAccount valueForKey:@"username"];


                    }
                else {
                    //if we are running the iPad Kiosk version then we will not allow employees to sign in, an employer or manager has to sign in then switch to team mode so employees can sign in
#ifdef IPAD_VERSION
                    if ((user.userAuthorities != nil) && (![user.userAuthorities containsObject:@"ROLE_MANAGER"]))
                    {
                        [SharedUICode messageBox:nil message:@"Only employers or managers can sign in using the ezClocker Kiosk App. Please try to sign in using an employer account"];
                   
                        continueSignin = false;
                    }
                    else
                    {
                        //this is not the userid this is the employerId
                        user.userID = [curAccount valueForKey:@"id"];
                        user.employerName = [curAccount valueForKey:@"name"];
                        user.employeeName = [curAccount valueForKey:@"name"];
                        user.userEmail = [curAccount valueForKey:@"username"];
                    }
#else
                    //this is not the userid this is the employerId
                    user.userID = [curAccount valueForKey:@"id"];
                    user.employerName = [curAccount valueForKey:@"name"];
                    user.employeeName = [curAccount valueForKey:@"name"];
                    user.userEmail = [curAccount valueForKey:@"username"];
#endif
                }

                if (continueSignin)
                {
                  //retrive location info for employer
                  if ([curAccount valueForKey:LOCATIONS]){
                    NSArray *locations = [curAccount valueForKey:LOCATIONS];
                    NSDictionary* location = nil;
                    for (int i = 0; i < locations.count; i++) {
                        location = [locations objectAtIndex:i];
                        if (location == nil) continue;
                        
                        if ([location valueForKey:GPS_LATITUDE] && [location valueForKey:GPS_LONGITUDE]){
                            double latitude = [[location valueForKey:GPS_LATITUDE] doubleValue];
                            double longitude = [[location valueForKey:GPS_LONGITUDE] doubleValue];
                            user.employerLocation.location = CLLocationCoordinate2DMake(latitude, longitude);
                        } // if lat and lon
                        
                        if ([location valueForKey:EMPLOYER_ID])
                            user.employerLocation.employerID = [location valueForKey:EMPLOYER_ID];
                        
                        if ([location valueForKey:LOCATION_NAME])
                            user.employerLocation.name = [location valueForKey:LOCATION_NAME];
                        
                    }//for each location
                    
                    //persist employer location info
                    [[NSUserDefaults standardUserDefaults] setValue:user.employerLocation.name forKey:LOCATION_NAME];
                    [[NSUserDefaults standardUserDefaults] setValue:user.employerLocation.employerID forKey:EMPLOYER_ID];
                    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:user.employerLocation.location.latitude] forKey:GPS_LATITUDE];
                    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:user.employerLocation.location.longitude] forKey:GPS_LONGITUDE];
                    
                }// if we have locations
                
                
                   //call to get the AuthToken
                [self callGetAuthTokensWebService:self.userNameTextField.text Password: self.passwordTextField.text UserID:[user.userID stringValue] UserType: user.userType];

                }
                
            }
        }
        //else the getAuthToken connection was called
        else if (connection == getAuthConnection){
             NSArray *authTokens = [results valueForKey:@"activeAuthTokens"];
             NSDictionary *curAuthToken = [authTokens objectAtIndex:0];
             NSString *tmp   = [curAuthToken valueForKey:@"authToken"];
             user.authToken  = tmp;
             user.employerID = [curAuthToken valueForKey:@"employerId"];
            if ([user.employerID intValue] == PERSONAL_EMPLOYERID)
            {
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"This login email is tied to a Personal Account. If you are an employee of a business that is using ezClocker please contact support@ezclocker.com to fix your account. If you need this app for personal use then please use the ezClocker Personal App instead."
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];
                
              //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"This login email is tied to a Personal Account. If you are an employee of a business that is using ezClocker please contact support@ezclocker.com to fix your account. If you need this app for personal use then please use the ezClocker Personal App instead." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                
               // [alert show];

            }
            else{
            
                //save data
           
                [[NSUserDefaults standardUserDefaults] setInteger:[user.employerID intValue] forKey:@"employerId"];
                [[NSUserDefaults standardUserDefaults] setInteger:[user.realUserId intValue] forKey:@"userId"];
                [[NSUserDefaults standardUserDefaults] setInteger:[user.userID intValue] forKey:@"employeeId"];
                [[NSUserDefaults standardUserDefaults] setValue:user.userType forKey:@"userType"];
                
                if ([user.userAuthorities count] > 0)
                {
                    [[NSUserDefaults standardUserDefaults] setObject: user.userAuthorities forKey:@"userAuthorities"];
                }
            
                [[NSUserDefaults standardUserDefaults] setObject:user.employerName forKey:@"name"];
                
                if (![NSString isNilOrEmpty:user.employeeName])
                    [[NSUserDefaults standardUserDefaults] setObject:user.employeeName forKey:@"employeeName"];

                [[NSUserDefaults standardUserDefaults] setObject:user.userEmail forKey:@"userEmail"];


                [[NSUserDefaults standardUserDefaults] setObject:tmp forKey:@"authToken"];
                [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
            

                //log to mixpanel if we are production
                if ([CommonLib isProduction])
                {
                 //   Mixpanel *mixpanel = [Mixpanel sharedInstance];
            
                 //   [mixpanel track:@"Login" properties:@{ @"email": self.userNameTextField.text}];
            }
                
                NSString* deviceToken = AppDelegate.sharedInstance.appToken;
                if (deviceToken != NULL) {
                    [PushNotificationManager saveDeviceTokenAsString:deviceToken];
                }
#ifndef PERSONAL_VERSION
                //if its came from the signup page then just dismiss this screen and go back to the signup page
                if ([_source isKindOfClass:[CreateEmployerAccountViewController class]]){
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
#endif
                //only check license for employers
                if ([user.userType isEqualToString:@"employer"])
                {
                    SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
                    [subscriptionWebService checkValidLicense];
                }
                
                [self.delegate loginViewControllerDidFinish:self];


        //tell the App Delegate to launch the main view controller
  //          AppDelegate *mainDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
   //         [mainDelegate loginDidPass];
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

 //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
  //  [alert show];
    
    connection = nil;
    data = nil;
}
 */

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

//call getUserAccount to get the type if they are employer or employee and also to get the id
-(void) callGetAccountWebService: (NSString*) userName Password: (NSString *) userPassword{
    [self callGetAccountAPI:userName Password: userPassword withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            if (aErrorCode == SERVICE_ACCESSDENIED_ERROR)
            {
                [SharedUICode messageBox:nil message:@"Error Signing in. Username and/or password is incorrect. Please check the information and try again" withCompletion:^{
                return;
                }];

            }
            else
            {
                [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
                }];
            }
        }
        else
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            NSError *error = nil;
            UserClass *user = [UserClass getInstance];
            //save the user email
            user.userEmail = _userNameTextField.text;
          //  NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
            NSString *resultMessage = [aResults valueForKey:@"message"];
            
            if (![resultMessage isEqualToString:@"Success"])
            {
                //if the message is not access denied then send the log so we can figure out what's going on otherwise it's a normal error
                if (![resultMessage isEqualToString:@"Access Denied"])
                {
                    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from LoginViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                }
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"Error Signing in. Email and/or password is incorrect. Please check the information and try again"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];
                
 
            }
            else{
            NSDictionary *userDict = [aResults valueForKey:@"user"];
            user.realUserId = [userDict valueForKey:@"id"];
            NSArray *accounts = [aResults valueForKey:@"employerAccounts"];
            NSArray *authoritiesFromServer = [userDict valueForKey:@"userAuthorities"];
            user.userAuthorities = [[NSMutableArray alloc] init];
            for (NSDictionary *authority in authoritiesFromServer)
            {
                NSString *authorityType = [authority valueForKey:@"authority"];
                [user.userAuthorities addObject:authorityType];
            }
 
            //if empty array then to see if the user is an employee
           if ([accounts count] == 0)
            {
                accounts = [aResults valueForKey:@"employeeAccounts"];
            }
            
            if ([accounts count] == 0){
                self.loginButton.enabled = true;
                [self showLoginFailureError];
            }
            else {
                bool continueSignin = TRUE;

                //pick the first one need to change later
                NSDictionary *curAccount = [accounts objectAtIndex:0];

                NSString *userType   = [curAccount valueForKey:@"type"];
                user.userType = userType;
                if ([userType isEqualToString:@"employer"]) {
                    //this is not the userid this is the employeeId
                    user.userID     = [curAccount valueForKey:@"id"];
                    user.employerID = [curAccount valueForKey:@"id"];
                    user.employerName = [curAccount valueForKey:@"name"];
                    user.userEmail = [curAccount valueForKey:@"username"];


                    }
                else {
                    //if we are running the iPad Kiosk version then we will not allow employees to sign in, an employer or manager has to sign in then switch to team mode so employees can sign in
#ifdef IPAD_VERSION
                    if (!CommonLib.userIsManager)//((user.userAuthorities != nil) && (![user.userAuthorities containsObject:@"ROLE_MANAGER"]))
                    {
                        [SharedUICode messageBox:nil message:@"Only employers or managers can sign in using the ezClocker Kiosk App. Please try to sign in using an employer account"];
                   
                        continueSignin = false;
                    }
                    else
                    {
                        //this is not the userid this is the employerId
                        user.userID = [curAccount valueForKey:@"id"];
                        user.employerName = [curAccount valueForKey:@"name"];
                        user.employeeName = [curAccount valueForKey:@"name"];
                        user.userEmail = [curAccount valueForKey:@"username"];
                    }
#else
                    //this is not the userid this is the employerId
                    user.userID = [curAccount valueForKey:@"id"];
                    user.employerName = [curAccount valueForKey:@"name"];
                    user.employeeName = [curAccount valueForKey:@"name"];
                    user.userEmail = [curAccount valueForKey:@"username"];
#endif
                }

                if (continueSignin)
                {
                  //retrive location info for employer
                  if ([curAccount valueForKey:LOCATIONS]){
                    NSArray *locations = [curAccount valueForKey:LOCATIONS];
                    NSDictionary* location = nil;
                    for (int i = 0; i < locations.count; i++) {
                        location = [locations objectAtIndex:i];
                        if (location == nil) continue;
                        
                        if ([location valueForKey:GPS_LATITUDE] && [location valueForKey:GPS_LONGITUDE]){
                            double latitude = [[location valueForKey:GPS_LATITUDE] doubleValue];
                            double longitude = [[location valueForKey:GPS_LONGITUDE] doubleValue];
                            user.employerLocation.location = CLLocationCoordinate2DMake(latitude, longitude);
                        } // if lat and lon
                        
                        if ([location valueForKey:EMPLOYER_ID])
                            user.employerLocation.employerID = [location valueForKey:EMPLOYER_ID];
                        
                        if ([location valueForKey:LOCATION_NAME])
                            user.employerLocation.name = [location valueForKey:LOCATION_NAME];
                        
                    }//for each location
                    
                    //persist employer location info
                    [[NSUserDefaults standardUserDefaults] setValue:user.employerLocation.name forKey:LOCATION_NAME];
                    [[NSUserDefaults standardUserDefaults] setValue:user.employerLocation.employerID forKey:EMPLOYER_ID];
                    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:user.employerLocation.location.latitude] forKey:GPS_LATITUDE];
                    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:user.employerLocation.location.longitude] forKey:GPS_LONGITUDE];
                    
                }// if we have locations
                
                
                   //call to get the AuthToken
                [self callGetAuthTokensWebService:self.userNameTextField.text Password: self.passwordTextField.text UserID:[user.userID stringValue] UserType: user.userType];

                }
                
            }
        }

            
        }
        
    }];
    
}

-(void) callGetAccountAPI:(NSString*) userName Password: (NSString *) userPassword withCompletion:(ServerResponseCompletionBlock)completion
{
    
    NSString *httpPostString;
 //   NSString *request_body;
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/authenticate", SERVER_URL];

 //   httpPostString = [NSString stringWithFormat:@"%@account/getUserAccounts", SERVER_URL];

   /* request_body = [NSString
                    stringWithFormat:@"developerToken=%@&userName=%@&password=%@",
                    [DEV_TOKEN        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [userName     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [userPassword     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding                    ]];
 
    */
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
   
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    

    //set request body into HTTPBody.
    urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
 //   [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
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

  //      alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  //      [alert show];
        
    }
*/
    
}

-(void) callGetAuthTokensWebService: (NSString*) userName Password: (NSString *) userPassword UserID: (NSString *) userID UserType: (NSString *) userType{
    
    [self callGetAuthTokensAPI:userName Password: userPassword UserID: userID UserType: userType withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
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
            user.userEmail = _userNameTextField.text;
         //   NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
            NSString *resultMessage = [aResults valueForKey:@"message"];
            
            if (![resultMessage isEqualToString:@"Success"])
            {
                //if the message is not access denied then send the log so we can figure out what's going on otherwise it's a normal error
                if (![resultMessage isEqualToString:@"Access Denied"])
                {
                    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from LoginViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                }
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"Error Signing in. Email and/or password is incorrect. Please check the information and try again"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];
            }

            NSArray *authTokens = [aResults valueForKey:@"activeAuthTokens"];
            NSDictionary *curAuthToken = [authTokens objectAtIndex:0];
            NSString *tmp   = [curAuthToken valueForKey:@"authToken"];
            user.authToken  = tmp;
            user.employerID = [curAuthToken valueForKey:@"employerId"];
           if ([user.employerID intValue] == PERSONAL_EMPLOYERID)
           {
               UIAlertController * alert = [UIAlertController
                                            alertControllerWithTitle:@"ERROR"
                                            message:@"This login email is tied to a Personal Account. If you are an employee of a business that is using ezClocker please contact support@ezclocker.com to fix your account. If you need this app for personal use then please use the ezClocker Personal App instead."
                                            preferredStyle:UIAlertControllerStyleAlert];
               
               UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
               
               [alert addAction:defaultAction];
               
               [self presentViewController:alert animated:YES completion:nil];
               
             //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"This login email is tied to a Personal Account. If you are an employee of a business that is using ezClocker please contact support@ezclocker.com to fix your account. If you need this app for personal use then please use the ezClocker Personal App instead." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
               
              // [alert show];

           }
           else{
           
               //save data
          
               [[NSUserDefaults standardUserDefaults] setInteger:[user.employerID intValue] forKey:@"employerId"];
               [[NSUserDefaults standardUserDefaults] setInteger:[user.realUserId intValue] forKey:@"userId"];
               [[NSUserDefaults standardUserDefaults] setInteger:[user.userID intValue] forKey:@"employeeId"];
               [[NSUserDefaults standardUserDefaults] setValue:user.userType forKey:@"userType"];
               
               if ([user.userAuthorities count] > 0)
               {
                   [[NSUserDefaults standardUserDefaults] setObject: user.userAuthorities forKey:@"userAuthorities"];
               }
           
               [[NSUserDefaults standardUserDefaults] setObject:user.employerName forKey:@"name"];
               
               if (![NSString isNilOrEmpty:user.employeeName])
                   [[NSUserDefaults standardUserDefaults] setObject:user.employeeName forKey:@"employeeName"];

               [[NSUserDefaults standardUserDefaults] setObject:user.userEmail forKey:@"userEmail"];


               [[NSUserDefaults standardUserDefaults] setObject:tmp forKey:@"authToken"];
               [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
           

               //log to mixpanel if we are production
               if ([CommonLib isProduction])
               {
                //   Mixpanel *mixpanel = [Mixpanel sharedInstance];
           
                //   [mixpanel track:@"Login" properties:@{ @"email": self.userNameTextField.text}];
           }
               
               NSString* deviceToken = AppDelegate.sharedInstance.appToken;
               if (deviceToken != NULL) {
                   [PushNotificationManager saveDeviceTokenAsString:deviceToken];
               }
#ifndef PERSONAL_VERSION
               //if its came from the signup page then just dismiss this screen and go back to the signup page
               if ([_source isKindOfClass:[CreateEmployerAccountViewController class]]){
                   [self dismissViewControllerAnimated:YES completion:nil];
               }
#endif
               //only check license for employers
               if ([user.userType isEqualToString:@"employer"])
               {
                   SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
                   [subscriptionWebService checkValidLicense];
               }
               
               [self.delegate loginViewControllerDidFinish:self UserName:userName Password: userPassword];


           }

        }
    }];
}

-(void) callGetAuthTokensAPI:(NSString*) userName Password: (NSString *) userPassword UserID: (NSString *) userID UserType: (NSString *) userType withCompletion:(ServerResponseCompletionBlock)completion
{
    
    NSString *httpPostString;
    
    if ([userType isEqualToString:@"employer"]){
        httpPostString = [NSString stringWithFormat:@"%@api/v1/account/authenticate/employer/%@", SERVER_URL, userID];

    }
    else{
        httpPostString = [NSString stringWithFormat:@"%@api/v1/account/authenticate/employee/%@", SERVER_URL, userID];

//        httpPostString = [NSString stringWithFormat:@"%@account/getEmployeeAuthTokens/%@", SERVER_URL, userID];
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
    getAuthConnection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (getAuthConnection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Connection to the server failed."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
    }
    */
    
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
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
            {
                // do something with the data
            }];
    [dataTask resume];
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
    [self callResetPasswordAPI:email withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
            [SharedUICode messageBox:nil message:@"Thank you! If we find an account that matches the email address or mobile phone number you entered we will send either an email or text message with the reset password link." withCompletion:^{
                return;
            }];
        }
    }];
}

-(void) callResetPasswordAPI:(NSString*) userName withCompletion:(ServerResponseCompletionBlock)completion
{
    
    NSString *httpPostString;
    NSString *request_body;
    
    httpPostString = [NSString stringWithFormat:@"%@account/resetPassword", SERVER_URL];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
 //   request_body = [NSString
  //                  stringWithFormat:@"developerToken=%@&emailAddress=%@",
  //                  [DEV_TOKEN stringByAddingPercentEncodingWithAllowedCharacters: set],
  //                  [email     stringByAddingPercentEncodingWithAllowedCharacters: set]
  //];
    //check to see if an @ is in the text to figure out if we are using an email
    if ([userName containsString:@"@"])
    {
        request_body = [NSString
                    stringWithFormat:@"emailAddress=%@",
                    [userName     stringByAddingPercentEncodingWithAllowedCharacters: set]
                    ];

    }
    else
    {
        request_body = [NSString
                    stringWithFormat:@"mobilePhoneNumber=%@",
                    [userName     stringByAddingPercentEncodingWithAllowedCharacters: set]
                    ];

    }
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
                                     message:@"Connection to the server failed"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

     //   alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
        
    }
     */
}


//-(void) startSpinner{
//    [SVProgressHUD showWithStatus:@"Authenticating"];//
//}

//-(void) stopSpinner{
//    [SVProgressHUD dismiss];/
//}


- (IBAction)doTheLogin:(id)sender {
    [self hideKeyboard];
    if ([_userNameTextField.text length] == 0) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter an E-mail or Phone number"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

       // UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter an E-mail" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
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

          //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a Password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
           // [alert show];
            
        }
        else{
            if ([CommonLib validateEmailOrPhoneNumber:_userNameTextField.text])
            {
                [self startSpinnerWithMessage:@"Authenticating..."];
                [self callGetAccountWebService:self.userNameTextField.text Password: self.passwordTextField.text];
            }
            else{
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"Please enter a valid email or phone number"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];

             //   UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a valid email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
              //  [alert show];
               
            }
        }
    }
}

- (IBAction)doSignup:(id)sender {
//only show the create screen if we are the biz app so not personal and not iPad
#if !defined(PERSONAL_VERSION) && !defined(IPAD_VERSION)
    //if its came from the signup page then just dismiss this screen and go back to the signup page
/*    if ([_source isKindOfClass:[CreateEmployerAccountViewController class]]){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        CreateEmployerAccountViewController *createAccountController = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateEmployerAccount"];
        
        [self presentViewController:createAccountController animated:YES completion:nil];
        
    }
 */
    [self.delegate createViewControllerWasSelected:self];

#endif

}

-(void) hideKeyboard{
    [_userNameTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
}


-(void)removeKeyboard{
    [_userNameTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField.tag == 123)
        [self doTheLogin:self];
    [self removeKeyboard];
    return YES;

}


- (IBAction)doForgotPassword:(id)sender {
    [self removeKeyboard];
 //   UIAlertView *recoverPasswordAlert = [[UIAlertView alloc] initWithTitle:@"Forgot Password" message:@"Enter email" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Forgot Password"
                                 message:@""
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Enter email or phone number";
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        textField.text = _emailTextField.text;
        [textField setDelegate:self];

    }];
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        NSString *userName = [[alert textFields][0] text];
        if ([CommonLib validateEmailOrPhoneNumber:userName])
        {

            [self startSpinnerWithMessage:@"Please wait..."];

            [ self callResetPasswordWebService: userName];
        }
        else
        {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"Please enter a valid email or phone number"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

        }
        
    }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
    }];

    [alert addAction:cancelAction];
    [alert addAction:okAction];
    
    
    [self presentViewController:alert animated:YES completion:nil];
    
 //   [recoverPasswordAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
 //   recoverPasswordAlert.tag = 1234;
  //  UITextField *textField = [recoverPasswordAlert textFieldAtIndex:0];
   // [recoverPasswordAlert show];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{	
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellSignUp";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    cell.textLabel.text = @"Sign Up for an Account";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *signup_url = [NSString stringWithFormat:@"%@%@", SERVER_URL, EMPLOYER_SIGNUP_URL];
 //   [[UIApplication sharedApplication] openURL:[NSURL URLWithString: signup_url]];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: signup_url] options:@{} completionHandler:nil];
    // Navigation logic may go here. Create and push another view controller.
/*    if (!self.signUpChoiceViewController){
        self.signUpChoiceViewController = [[SignUpChoiceViewController alloc] initWithNibName:@"SignUpChoiceViewController" bundle:nil];
//        self.signUpChoiceViewController.delegate = (id) self;
    }
    // ...
    // Pass the selected object to the new view controller.
        [self.navigationController pushViewController:self.signUpChoiceViewController animated:YES];
    */
}




@end
