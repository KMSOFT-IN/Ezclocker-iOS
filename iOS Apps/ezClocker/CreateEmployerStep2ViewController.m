//
//  CreateEmployerStep2ViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 8/14/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import "CreateEmployerStep2ViewController.h"
#import "user.h"
#import "CommonLib.h"
#import "TermsOfServiceViewController.h"
#import "MetricsLogWebService.h"
#import "AppDelegate.h"
#import "PushNotificationManager.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"
#import "NSDictionary+Extensions.h"
#ifndef PERSONAL_VERSION
#import <iAd/iAd.h>
#endif

@interface CreateEmployerStep2ViewController ()

@end

@implementation CreateEmployerStep2ViewController

int INDUSTRY_LIST_TAG = 1;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_backButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    [_createAccountButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    [_termsOfServiceButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];

    _emailTextField.delegate = (id) self;
    _nameTextField.delegate = (id) self;
    _passwordTextField.delegate = (id) self;
    [_nameTextField setReturnKeyType:UIReturnKeyDone];
    [_passwordTextField setReturnKeyType:UIReturnKeyDone];
    _passwordTextField.tag = 123;
    
  //  UserClass *user = [UserClass getInstance];
  //  _emailTextField.text = user.userEmail;
  //  _emailTextField.enabled = NO;
    
    pickerData = @[@"Catering/Event Planning", @"Construction Company", @"Contracting Svcs/Handyman", @"Freelancer", @"Home Health Care", @"Janitorial/Cleaning Services", @"Landscape/Lawn Care", @"Property Mgmt/Real Estate", @"Security Services", @"Other"];
    
    popoverContent = [[UIViewController alloc] init];
    [self setFramePicker];
//    CGRect pickerFrame;
//#ifndef IPAD_VERSION
//    pickerFrame = CGRectMake(0, 40, 0, 0);
//#else
//    pickerFrame = CGRectMake(0, 0, 0, 0);
//    //pickerFrame = CGRectMake(0, 0, 350, 250);
//#endif

//    industryPickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    industryPickerView.dataSource = self;
    industryPickerView.delegate = self;
    _industryTextField.tag = INDUSTRY_LIST_TAG;
    _industryTextField.delegate = (id) self;
    [self registerForKeyboardNotifications];

}
- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
//    [_scrollView setScrollEnabled:YES];
//    [_scrollView setContentSize:CGSizeMake(320, 650)];
    _scrollView.backgroundColor = UIColorFromRGB(DARK_ORANGE_COLOR);
    
}

// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return pickerData.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return pickerData[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *resultString = pickerData[row];
    
    _industryTextField.text = resultString;
    
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // We are now showing the UIPickerViewer instead
    
    // Close the keypad if it is showing
    
    // Function to show the picker view
    if (textField.tag == INDUSTRY_LIST_TAG)
    {
        [self.view endEditing:YES];
//        [_scrollView setContentOffset:CGPointMake(0,0) animated:YES];
        [self ShowIndustryPickerView];
    // Return no so that no cursor is shown in the text box
        return  NO;
    }
    else
        return YES;
}

- (void)setFramePicker {
    
    CGFloat kbHeight = [NSUserDefaults.standardUserDefaults floatForKey:keyboardHeight];
    
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = screenSize.height;
    
    CGFloat safeAreaTopHeight = 0;
    CGFloat safeAreaBottomHeight = 0;
    if (@available(iOS 11, *)) {
        // safe area constraints already set
        safeAreaTopHeight = UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
        safeAreaBottomHeight = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    } else {
        safeAreaTopHeight = self.view.safeAreaInsets.top;
        safeAreaBottomHeight = self.view.safeAreaInsets.bottom;
    }
    
    CGFloat Y = screenHeight - kbHeight;// + safeAreaBottomHeight + safeAreaTopHeight);
    if (self.tabBarController != nil) {
        CGFloat tabbarHeight = self.tabBarController.tabBar.frame.size.height;
        
        pickerView = [[UIView alloc] initWithFrame:CGRectMake(0, Y - tabbarHeight, self.view.frame.size.width, kbHeight)];
    } else {
        pickerView = [[UIView alloc] initWithFrame:CGRectMake(0, Y, self.view.frame.size.width, kbHeight)];
    }
    
     [pickerView setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    
    //if we are running the iPhone then we start at 44 because of the toolbar
    CGRect pickerFrame;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        pickerFrame = CGRectMake(0, 0, 350, 250);
        industryPickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    } else {
        pickerFrame = CGRectMake(0, 44,  screenSize.width, kbHeight - 44);
        industryPickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    }
    
}

-(void)ShowIndustryPickerView
{
    
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    pickerToolbar.barStyle=UIBarStyleBlackOpaque;
    
    [pickerToolbar sizeToFit];
    
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 100, 20.0f)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    titleLabel.text = @"Select Industry";
    
    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(industryPickerDoneClick)];
    
    
    NSArray *itemArray = [[NSArray alloc] initWithObjects:flexSpace, titleButton, flexSpace, doneDateBarBtn, nil];
    
    [pickerToolbar setItems:itemArray animated:YES];
//    CGRect screenBound = [[UIScreen mainScreen] bounds];
//    CGSize screenSize = screenBound.size;
//    CGFloat screenHeight = screenSize.height;
    
//    popoverContent = [[UIViewController alloc] init];
//    if (self.tabBarController != nil) {
//        CGFloat tabbarHeight = self.tabBarController.tabBar.frame.size.height;
//        
//        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, (screenHeight-(320 + tabbarHeight)), self.view.frame.size.width, 320)];
//    } else {
//        pickerViewDate = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight-320, self.view.frame.size.width, 320)];
//    }
  //  pickerView = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight-200, 320, 246)];
    
//    pickerView = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight-170, UIScreen.mainScreen.bounds.size.width, industryPickerView.frame.size.height + 64)];
//    [pickerView setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
//    [self setFramePicker];
#ifdef IPAD_VERSION
    
    [pickerView addSubview:industryPickerView];
    UIViewController *V2 = [[UIViewController alloc] init];
    V2.view = pickerView;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:V2];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    V2.preferredContentSize = CGSizeMake(350, 250);
    V2.navigationItem.rightBarButtonItem = doneDateBarBtn;
 //   V2.navigationItem.leftBarButtonItem = cancelBtn;
    [self presentViewController:navController animated:YES completion:nil];
    navController.view.superview.center = self.view.center;
#else
    [pickerView addSubview:pickerToolbar];
    [pickerView addSubview:industryPickerView];
    [self.view.superview addSubview:pickerView];
    
    CGSize vSize = pickerView.frame.size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, vSize.height, 0.0);
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    // scroll up by 100 points if terms of service button is under the picker view so the whole picker view can show
//    CGRect aRect = self.view.frame;
//    aRect.size.height -= vSize.height;

    
    CGRect aRect = self.subview.frame;
    int pickerY = [[UIScreen mainScreen] bounds].size.height - vSize.height;
    int y = pickerY - (aRect.origin.y + 203) ;
    [_scrollView setContentOffset:CGPointMake(0,abs(y) + 92) animated:YES];
    
   // [self.scrollView scrollRectToVisible:_termsOfServiceButton.frame animated:YES];
//    if (!CGRectContainsPoint(aRect, _termsOfServiceButton.frame.origin) ) {
//        [_scrollView setContentOffset:CGPointMake(0,100) animated:YES];
//    }

#endif
}


-(IBAction)industryPickerDoneClick{
    NSInteger row = [industryPickerView selectedRowInComponent:0];
    _industryTextField.text = [pickerData objectAtIndex:row];
    
    [self closeIndustryListPicker:self];
    //scroll the screen back to the top
    [_scrollView setContentOffset:CGPointMake(0,0) animated:YES];
}

-(BOOL)closeIndustryListPicker:(id)sender{
 //   [industryPickerView removeFromSuperview];
    [pickerView removeFromSuperview];
    return YES;
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWillBeHidden:)
//                                                 name:UIKeyboardDidHideNotification object:nil];
    
}
// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    //close the Select Industry Picker just in case it was open
    [self closeIndustryListPicker:self];
    NSDictionary* info = [aNotification userInfo];
    CGRect kbSize =  [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.subview.frame;
//    aRect.size.height -= kbSize.height;
    int keyBoardY = [[UIScreen mainScreen] bounds].size.height - kbSize.size.height;
    int y = keyBoardY - (aRect.origin.y + 203) ;
    [_scrollView setContentOffset:CGPointMake(0,abs(y)) animated:YES];
//    if (!CGRectContainsPoint(aRect, _nameTextField.frame.origin) ) {
//           [self.scrollView scrollRectToVisible:_industryTextField.frame animated:YES];
//      }
}

// Called when the UIKeyboardWillHideNotification is sent
//- (void)keyboardWillBeHidden:(NSNotification*)aNotification
//{
//    [_scrollView setContentOffset:CGPointMake(0,0) animated:YES];
//}


- (IBAction)doTermsofService:(id)sender {
    TermsOfServiceViewController *termsOfServiceViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TermsOfService"];
    
    UINavigationController *termsOfServiceNavigationController = [[UINavigationController alloc] initWithRootViewController:termsOfServiceViewController];
    
    termsOfServiceViewController.delegate = (id) self;
    
    termsOfServiceNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:termsOfServiceNavigationController animated:YES completion:nil];

}

- (IBAction)doCreateEmployer:(id)sender {
    [self hideKeyboard];

    if ([_nameTextField.text length] == 0) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a Name"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    //    UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a Name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //    [alert show];
        
    }
    else{
 //       if ([_emailTextField.text length] == 0) {
 //           UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter an Email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  //          [alert show];
            
  //      }
  //      else{
  
            if ([_passwordTextField.text length] == 0) {
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"Please enter a Password"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];

              //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a Password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
             //   [alert show];
                
            }
            else{
  
                if ([_industryTextField.text length] == 0) {
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"ERROR"
                                                 message:@"Please pick your business industry"
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:defaultAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];

                  //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please pick your business industry" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                  //  [alert show];
                    
                }
                else{
                    [self startSpinnerWithMessage:@"Creating Account..." ];
                    [self callAddGetAuthWebService];
                }
 
           }


    }
 
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

          //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
        }
    }
    
    
    data = [[NSMutableData alloc] init];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataIn
{
    [data appendData:dataIn];
}
*/
#if !defined(PERSONAL_VERSION) && !defined(IPAD_VERSION)
-(void) saveiAdAttribution
{
    // Check for iOS 10 attribution implementation
    if ([[ADClient sharedClient] respondsToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        NSLog(@"iOS 10 call exists");
        [[ADClient sharedClient] requestAttributionDetailsWithBlock:^(NSDictionary *attributionDetails, NSError *error) {
            // Look inside of the returned dictionary for all attribution detailsN
            if (![NSDictionary isNilOrNull:attributionDetails])
            {
                NSDictionary *iadValues = [attributionDetails valueForKey: @"Version3.1"];
                if (![NSDictionary isNilOrNull:iadValues])
                {
                    [self sendiAdAttribution: iadValues];
                }
                NSLog(@"Attribution Dictionary: %@", attributionDetails);
            }
        }];
    }
 
}
#endif
/*
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self stopSpinner];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    NSError *error = nil;
    UserClass *user = [UserClass getInstance];
    //save the user email
//    user.userEmail = _emailTextField.text;
       user.employerName = _nameTextField.text;
    //check for error code 8
   // NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];
    
    int errorValue = [[results valueForKey:@"errorCode"] intValue];
    
    
    if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"]))
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

 //           alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
        else{
            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from CreateEmployerAccountViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"Error Creating Account!"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

           // alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error Creating Account!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
       // [alert show];
    }
    else {
        
        NSDictionary *employerObj = [results valueForKey:@"employer"];
        user.realUserId = [employerObj valueForKey:@"userId"];
        NSArray *authTokens = [results valueForKey:@"activeAuthTokens"];
        //pick the first one need to change later
        NSDictionary *authToken = [authTokens objectAtIndex:0];
        user.authToken = [authToken valueForKey:@"authToken"];
        user.employerID = [authToken valueForKey:@"employerId"];
        //since this is the employer set the userid to employerid
        user.userID = user.employerID;
        user.userType = @"employer";
        
        
        //save data
        
        [[NSUserDefaults standardUserDefaults] setInteger:[user.employerID intValue] forKey:@"employerId"];
        [[NSUserDefaults standardUserDefaults] setInteger:[user.realUserId intValue] forKey:@"userId"];
        [[NSUserDefaults standardUserDefaults] setInteger:[user.userID intValue] forKey:@"employeeId"];
        [[NSUserDefaults standardUserDefaults] setValue:user.userType forKey:@"userType"];
        
        [[NSUserDefaults standardUserDefaults] setValue:user.employerName forKey:@"name"];
        
        [[NSUserDefaults standardUserDefaults] setObject:user.authToken forKey:@"authToken"];
        [[NSUserDefaults standardUserDefaults] setObject:user.userEmail forKey:@"userEmail"];
        [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
        
        
        //log to mixpanel if we are production
        if ([CommonLib isProduction])
        {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            
            [mixpanel track:@"Registered" properties:@{ @"email": user.userEmail}];
        }
        
        //check to see if this came from iAd
        
        NSString* oldToken = AppDelegate.sharedInstance.appToken;
        if (oldToken != NULL) {
            [PushNotificationManager saveDeviceTokenAsString:oldToken];
        }
        
#if !defined(PERSONAL_VERSION) && !defined(IPAD_VERSION)
        [self saveiAdAttribution];
#endif
        [self.delegate CreateEmployerAccountStep2DidFinish:self];
        
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
*/
-(void) sendInfoToServer:(NSDictionary *) iAdValues withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    
    NSString *httpPostString = [NSString stringWithFormat:@"%@api/v1/apple-iad", SERVER_URL];
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:iAdValues
                                                       options:0
                                                         error:&error];
    NSString *JSONString;
    if (!jsonData) {
    } else {
        
        JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    request.HTTPBody = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:curEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    [request setValue:curAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
    
}

-(void) sendiAdAttribution: (NSDictionary *) iAdValues
{
    [self sendInfoToServer:iAdValues withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        //do nothing since it's for analytics tracking only, we send it to the server if it works great if not we don't want to display a message to the user bc they won't care
        
    }];
}

-(void) hideKeyboard{
    [_nameTextField resignFirstResponder];
    [_emailTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
    [self closeIndustryListPicker:self];
    
}

-(void)removeKeyboard{
    [_nameTextField resignFirstResponder];
    [_emailTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];

}

//call getUserAccount to get the type if they are employer or employee and also to get the id
-(void) callAddGetAuthWebService{
    [self callAddGetAuthAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [CommonLib logEvent:@"Add Signup"];
            [CommonLib setIndustryProperty:_industryTextField.text];
           
            NSError *error = nil;
            UserClass *user = [UserClass getInstance];
            //save the user email
            user.userEmail = _emailTextField.text;
               user.employerName = _nameTextField.text;
            //check for error code 8
           // NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         //   NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
            NSString *resultMessage = [aResults valueForKey:@"message"];
            
            int errorValue = [[aResults valueForKey:@"errorCode"] intValue];
            
            
            if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"]))
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

         //           alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                }
                else{
                    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from CreateEmployerAccountViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                    
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@"ERROR"
                                                 message:@"Error Creating Account!"
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:defaultAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];

                   // alert = [[UIAlertView alloc] initWithTitle:nil message:@"Error Creating Account!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                }
               // [alert show];
            }
            else {
                
                NSDictionary *employerObj = [aResults valueForKey:@"employer"];
                user.realUserId = [employerObj valueForKey:@"userId"];
                NSArray *authTokens = [aResults valueForKey:@"activeAuthTokens"];
                //pick the first one need to change later
                NSDictionary *authToken = [authTokens objectAtIndex:0];
                user.authToken = [authToken valueForKey:@"authToken"];
                user.employerID = [authToken valueForKey:@"employerId"];
                //since this is the employer set the userid to employerid
                user.userID = user.employerID;
                user.userType = @"employer";
                
                
                //save data
                
                [[NSUserDefaults standardUserDefaults] setInteger:[user.employerID intValue] forKey:@"employerId"];
                [[NSUserDefaults standardUserDefaults] setInteger:[user.realUserId intValue] forKey:@"userId"];
                [[NSUserDefaults standardUserDefaults] setInteger:[user.userID intValue] forKey:@"employeeId"];
                [[NSUserDefaults standardUserDefaults] setValue:user.userType forKey:@"userType"];
                
                [[NSUserDefaults standardUserDefaults] setValue:user.employerName forKey:@"name"];
                
                [[NSUserDefaults standardUserDefaults] setObject:user.authToken forKey:@"authToken"];
                [[NSUserDefaults standardUserDefaults] setObject:user.userEmail forKey:@"userEmail"];
                [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
                
                
                //check to see if this came from iAd
                
                NSString* oldToken = AppDelegate.sharedInstance.appToken;
                if (oldToken != NULL) {
                    [PushNotificationManager saveDeviceTokenAsString:oldToken];
                }
                
        #if !defined(PERSONAL_VERSION) && !defined(IPAD_VERSION)
                [self saveiAdAttribution];
        #endif
                [self.delegate CreateEmployerAccountStep2DidFinish:self];
                
            }

        }
    }];
}

-(void) callAddGetAuthAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    
    UserClass *user = [UserClass getInstance];
    

    NSString *httpPostString;
    NSString *userName = _nameTextField.text;
    NSString *userEmail = _emailTextField.text;
    NSString *userPassword = _passwordTextField.text;
    NSString *userBusinessType = _industryTextField.text;
    
 //   httpPostString = [NSString stringWithFormat:@"%@employer/addGetAuth", SERVER_URL];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/sign-up", SERVER_URL];
    
/*
    request_body = [NSString
                    stringWithFormat:@"developerToken=%@&employerName=%@&emailAddress=%@&password=%@",
                    [DEV_TOKEN        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [userName     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [userEmail     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [userPassword     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding                    ]];
    */
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          userName, @"employerName",
                          userEmail, @"emailAddress",
                         userPassword, @"password",
                          userBusinessType, @"businessType",
                          @"iPHONE", @"source",
                          nil];
    
    NSError *error;
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];    
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:DEV_TOKEN forHTTPHeaderField:@"x-ezclocker-developertoken"];

    //set request body into HTTPBody.
    //[urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

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
    NSURLConnection *connection  = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
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
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
   // if (theTextField.tag == 123)
   //     [self doCreateEmployer:self];
    [self removeKeyboard];
    return YES;
    
}

- (void)termsOfServiceControllerDidFinishViewing:(TermsOfServiceViewController *)controller
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (IBAction)doBackAction:(id)sender {
    [self.delegate createViewControllerFromStep2WasSelected:self];
}
@end
