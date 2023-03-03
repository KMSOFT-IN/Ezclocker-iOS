//
//  CreatePersonalAccountViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 2/19/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "CreatePersonalAccountViewController.h"
#import "user.h"
#import "ECSlidingViewController.h"
#import "CommonLib.h"
#import "MixPanel.h"
#import "MetricsLogWebService.h"
#import "TermsOfServiceViewController.h"

@interface CreatePersonalAccountViewController ()

@end

@implementation CreatePersonalAccountViewController
@synthesize scrollView = _scrollView;
@synthesize emailTextField = _emailTextField;
@synthesize passwordTextField = _passwordTextField;


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
	// Do any additional setup after loading the view.
    _nameTextField.delegate = self;
    _emailTextField.delegate = self;
    _passwordTextField.delegate = self;
    [_nameTextField setReturnKeyType:UIReturnKeyDone];
    [_emailTextField setReturnKeyType:UIReturnKeyDone];
    [_passwordTextField setReturnKeyType:UIReturnKeyGo];
    _passwordTextField.tag = 123;
    
    
    [self registerForKeyboardNotifications];
    if (UIScreen.mainScreen.bounds.size.height < 600 ) {
        self.imageLeading.constant = 16;
        self.imageTrailing.constant = 16;
    } else {
        self.imageLeading.constant = 0;
        self.imageTrailing.constant = 0;
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    if ([_hideLoginButton intValue] == 1)
        _loginButton.hidden = YES;
    
    [_CreateButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    [_loginButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];

    _scrollView.backgroundColor = UIColorFromRGB(DARK_ORANGE_COLOR);
//    [_scrollView setScrollEnabled:YES];
//    [_scrollView setContentSize:CGSizeMake(320, 650)];
}

- (void)viewDidUnload
{
    [self setEmailTextField:nil];
    [self setPasswordTextField:nil];
    [super viewDidUnload];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (self.subview.frame.origin.y + self.subview.frame.size.height > keyBoardY) {
        
        CGFloat height = (self.subview.frame.origin.y + self.subview.frame.size.height) - keyBoardY;
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
                                         message:@"ezClocker is unable to connect to the server at this time. Please try again later."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

         //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
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
    
    UIAlertView *alert;
    NSError *error = nil;
    UserClass *user = [UserClass getInstance];
    
#ifndef RELEASE

    NSString* newStr = [[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding];

    NSLog(@"JSONStr is %@", newStr);
#endif

    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];
    int errorValue = [[results valueForKey:@"errorCode"] intValue];

    
    if (![resultMessage isEqualToString:@"Success"])
    {
        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from Create PersonalAccount JSON Parsing: %@ resultMessage= %@", error.localizedDescription, resultMessage]];

        if (errorValue == WEB_SERVICE_ACCOUNT_EXIST_ERROR) {
            //if the account already exist show the customer a meesage
            [self showAccountExistDialog:resultMessage];
            return;
        }
        else{
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"Error Creating Account. Please try again later."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];


           // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error Creating Account. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
        }
    }
    else {
        user.hasAccount = @"YES";
        user.userEmail = _emailTextField.text;
        user.indivdualName = _nameTextField.text;
        //save the new data
        [[NSUserDefaults standardUserDefaults] setObject:user.indivdualName forKey:@"UserName"];
        [[NSUserDefaults standardUserDefaults] setObject:user.userEmail forKey:@"userEmail"];
        [[NSUserDefaults standardUserDefaults] setObject:user.hasAccount forKey:@"HasAccount"];

        [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data

        //log to mixpanel if we are production
        if ([CommonLib isProduction])
        {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            
            [mixpanel track:@"Created Account" properties:@{ @"email": user.userEmail}];
        }

        [self.delegate createAccountViewControllerDidFinish:self];

        
        
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
    
  //  [alert show];
    
    connection = nil;
    data = nil;
}


-(void) showAccountExistDialog:resultMessage{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"ERROR"
                                 message:resultMessage
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];

  //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  //  [alert show];

}

-(void) callUpdateIndivdualAccountWebService{
    
    UserClass *user = [UserClass getInstance];
    UIAlertView *alert;
    NSString *httpPostString;
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/individual", SERVER_URL];

    NSString *oldUserName = user.userEmail;
    NSString *oldPassword = user.individualGeneratedPassword;
    NSString *newUserName = _nameTextField.text;
    NSString *newUserEmail = _emailTextField.text;
    NSString *newUserPassword = _passwordTextField.text;
    NSString *source = @"iPhone";
    
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              oldUserName, @"currentUserName",
                              oldPassword, @"currentPassword",
                              newUserName, @"individualName",
                              newUserEmail, @"newUserName",
                              newUserPassword, @"newPassword",
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
    
    [urlRequest setHTTPMethod:@"PUT"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:[NSString stringWithFormat:@"%ld", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setHTTPBody: requestData];
    
    
    
    [urlRequest setValue:DEV_TOKEN forHTTPHeaderField:@"x-ezclocker-developertoken"];
    
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

-(void) hideKeyboard{
    [_nameTextField resignFirstResponder];
    [_emailTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
}


-(void)removeKeyboard{
    [_nameTextField resignFirstResponder];
    [_emailTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField.tag == 123)
        [self doCreateAccount:self];
    [self removeKeyboard];
    return YES;
    
}



- (IBAction)doCreateAccount:(id)sender {
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

          //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a Password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
            
        }
        else{            
            if ([CommonLib validateEmail:_emailTextField.text])
            {
                [self startSpinnerWithMessage:@"Creating Account..."];
                [self callUpdateIndivdualAccountWebService];
            }
            else{
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"Please enter a valid email"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];

             //   UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a valid email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
             //   [alert show];
               
            }
        }
    }

}

- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}
- (IBAction)doLogin:(id)sender {
    [self.delegate loginPersonalViewControllerWasSelected:self];

}
- (IBAction)doViewTermsofService:(id)sender {
    TermsOfServiceViewController *termsOfServiceViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TermsOfService"];
    
    UINavigationController *termsOfServiceNavigationController = [[UINavigationController alloc] initWithRootViewController:termsOfServiceViewController];
    
    termsOfServiceViewController.delegate = (id) self;
    
    termsOfServiceNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    
    [self presentViewController:termsOfServiceNavigationController animated:YES completion:nil];

}

- (void)termsOfServiceControllerDidFinishViewing:(TermsOfServiceViewController *)controller
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
