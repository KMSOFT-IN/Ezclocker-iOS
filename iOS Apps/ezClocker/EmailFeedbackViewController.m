//
//  EmailFeedbackViewController.m
//  Created by Raya Khashab on 10/14/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "EmailFeedbackViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "user.h"
#import "CommonLib.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"

@interface EmailFeedbackViewController ()

@end

@implementation EmailFeedbackViewController

@synthesize thankyouLabel;
@synthesize submitBtn;
@synthesize MessageTextView= _MessageTextView;
@synthesize scrollView = _scrollView;


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
 
    //this will prevent the screens to overlap the navigation bar for iOS 7
//    self.navigationController.navigationBar.translucent = NO;
    
 /*   // Override point for customization after application launch.
    //make all the navigation bars light blue from the header_background image
    UIImage *image = [UIImage imageNamed:@"header_background_iOS7.jpeg"];
    [[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    //make all bar buttons clear with no borders
    [[UIBarButtonItem appearance] setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    //   self.window.tintColor = [UIColor whiteColor];
    
    
    
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0.0, -1.0);
    //this is the one that sets the back button's to white
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    
    // Navigation bar buttons appearance
    
    
    [[UINavigationBar appearance]setShadowImage:[[UIImage alloc] init]];


	// Do any additional setup after loading the view.
    UIBarButtonItem* menuButton = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStylePlain target:self action:@selector(menuButtonAction)];
    
    
    self.navigationItem.leftBarButtonItem = menuButton;
    */
    thankyouLabel.hidden = YES;
    
 //   messageTextField.delegate = self;
 //   [messageTextField setReturnKeyType:UIReturnKeyDone];
    originalCenter = self.view.center;
    _MessageTextView.delegate = self;

    
    _MessageTextView.text = @"";
    CALayer *imageLayer = _MessageTextView.layer;
    [imageLayer setCornerRadius:10];
    [imageLayer setBorderWidth:2.1];
    imageLayer.borderColor=[[UIColor lightGrayColor] CGColor];
    
    _mainView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _submitBtnViewController.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    
    [self registerForKeyboardNotifications];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboardAction)];
    

    NSArray *itemArray = [[NSArray alloc] initWithObjects:flexSpace, doneDateBarBtn, nil];
    
    keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    keyboardToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [keyboardToolbar sizeToFit];

    
    [keyboardToolbar setItems:itemArray animated:YES];
    
    [_MessageTextView setInputAccessoryView:keyboardToolbar];



}

-(void)dismissKeyboardAction{
    [_MessageTextView resignFirstResponder];
    
}


-(void) menuButtonAction
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];

    //if the slidingViewController is null then that means it didn't come from the menu selection it
    //came from the rating dialog
    if (self.slidingViewController != nil)
    {

        if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
            self.slidingViewController.underLeftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
        }
        self.slidingViewController.underRightViewController = nil;
        
        [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    }
    else{
        UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonAction)];
        
        self.navigationItem.leftBarButtonItem = cancelButton;
        
        UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonAction)];
        
        
        self.navigationItem.rightBarButtonItem = doneButton;

        
       
    }

    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    [_scrollView setScrollEnabled:YES];
    [_scrollView setContentSize:CGSizeMake(320, 650)];
   // [_scrollView setContentOffset:CGPointMake(0,0)];
    _scrollView.contentOffset = CGPointZero;

  //  _scrollView.delaysContentTouches = NO;
    
    //if we have a valid email not ezclocker56 as an example then display it
    UserClass *user = [UserClass getInstance];
    if ([CommonLib validateEmail:user.userEmail])
        _fromEmailTextField.text = user.userEmail;
    

    

}

- (IBAction)cancelButtonAction
{
    [self.delegate emailFeedbackViewControllerDidFinish:self];

}

- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
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
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
  //  if (!CGRectContainsPoint(aRect, submitBtn.frame.origin) ) {
  //      [self.scrollView scrollRectToVisible:submitBtn.frame animated:YES];
  //  }
    if (!CGRectContainsPoint(aRect, _MessageTextView.frame.origin) ) {
        [self.scrollView scrollRectToVisible:_MessageTextView.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
}

/*
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //error 503 is when tomcat is down
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            
         //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    //do nothing with the data since we don't want to wait for it to go through or not
   //    NSString* JSONStr = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        NSError *error = nil;
     NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
     NSString *resultMessage = [results valueForKey:@"message"];
     if (![resultMessage isEqualToString:@"Success"])
     {
         UIAlertController * alert = [UIAlertController
                                      alertControllerWithTitle:@"ERROR"
                                      message:@"Failure to Add"
                                      preferredStyle:UIAlertControllerStyleAlert];
         
         UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
         
         [alert addAction:defaultAction];
         
         [self presentViewController:alert animated:YES completion:nil];
         

       //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Failure to Add" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       //  [alert show];
     }
     
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
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

*/

- (IBAction)doSubmitEmail:(id)sender {
    if (![CommonLib validateEmail:_fromEmailTextField.text])
    {
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
    else if ([_MessageTextView.text length] == 0) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a Message"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        

      //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a Message" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
    }

    else{
        [self removeKeyboard];
        

        thankyouLabel.hidden = NO;
        submitBtn.enabled = NO;
        submitBtn.alpha = 0.5;
        
        //call webservice to send the email
        [self emailFeedback];
        
        
    }

}

-(void) emailFeedback{
    [self emailFeedbackAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [ErrorLogging logErrorWithDomain:@"SERVER_ERROR" code:aErrorCode description:@"SERVER_ERROR" error:aError];
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
            //do nothing with the data since we don't want to wait for it to go through or not
           //    NSString* JSONStr = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";

           //  NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
             NSString *resultMessage = [aResults valueForKey:@"message"];
             if (![resultMessage isEqualToString:@"Success"])
             {
                 UIAlertController * alert = [UIAlertController
                                              alertControllerWithTitle:@"ERROR"
                                              message:@"Failure to Send Feedback"
                                              preferredStyle:UIAlertControllerStyleAlert];
                 
                 UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                 
                 [alert addAction:defaultAction];
                 
                 [self presentViewController:alert animated:YES completion:nil];
                 

             }

        }
    }];
}

-(void) emailFeedbackAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
//    user.userEmail = @"rayantx@gmail.com";
    NSString *httpPostString;
    NSString *request_body;
    
    NSDateFormatter *formatterDateTime = [[NSDateFormatter alloc] init];
    [formatterDateTime setDateFormat:@"MM/dd/yyyy h:mm:ss"];
    NSDate *currentClockInTime = [NSDate date];
    NSString *strCurrentDateTime = [formatterDateTime stringFromDate:currentClockInTime];
    
    NSString *source =@"IPHONE";
    NSString *appVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *fromEmail = _fromEmailTextField.text;
    if ([fromEmail length] == 0)
        fromEmail = user.userEmail;
#ifdef PERSONAL_VERSION
    appVer = [NSString stringWithFormat:@"%@ %@", @"iPHONE PERSONAL", appVer];
#elif defined IPAD_VERSION
    appVer = [NSString stringWithFormat:@"%@ %@", @"iPAD BUSINESS", appVer];
#else
    appVer = [NSString stringWithFormat:@"%@ %@", @"iPHONE BUSINESS", appVer];
#endif
    //add 
    NSString *message = [NSString stringWithFormat:@"From: %@\nDate: %@\nAppVersion: %@\nEmployerID: %@\nEmployeeID: %@\rMessage: %@", fromEmail, strCurrentDateTime, appVer, user.employerID, user.userID, _MessageTextView.text];
    // ProgramConstants.SERVER_URL + "/email/csvReport/" + employerID + "/" + employeeID;
    httpPostString = [NSString stringWithFormat:@"%@feedback/send", SERVER_URL];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    request_body = [NSString
                    stringWithFormat:@"developerToken=%@&toEmail=%@&fromEmail=%@&source=%@&message=%@",
                    [DEV_TOKEN              stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [_EmailToLabel.text     stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [@"no-reply@ezclocker.com"          stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [source     stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [message     stringByAddingPercentEncodingWithAllowedCharacters: set
                     ]];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    
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



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setMessageTextView:nil];
    [self setEmailToLabel:nil];
    [self setThankyouLabel:nil];
    [self setSubmitBtn:nil];
    [super viewDidUnload];
}

-(void)removeKeyboard{
    [_MessageTextView resignFirstResponder];
    [_fromEmailTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self removeKeyboard];
    return YES;
}


-(void)textViewDidBeginEditing:(UITextView *)textView{
    
    
}

@end
