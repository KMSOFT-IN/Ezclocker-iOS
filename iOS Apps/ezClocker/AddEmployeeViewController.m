//
//  AddEmployeeViewController.m
//  TCS Mobile
//
//  Created by Raya Khashab on 1/19/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "AddEmployeeViewController.h"
#import "user.h"
#import "CommonLib.h"
#import "MetricsLogWebService.h"
#import "threaddefines.h"
#import "SharedUICode.h"
#import "NSString+Extensions.h"
#import "RolesListViewController.h"

@interface AddEmployeeViewController ()

@end

@implementation AddEmployeeViewController
@synthesize emailTextField;
@synthesize nameTextField;
@synthesize mainViewController;
@synthesize InviteBtn;
@synthesize delegate;
@synthesize scrollView;

const int NAME_TAG= 0;
const int EMAIL_TAG = 1;
const int PIN_TAG = 2;
CGRect viewFrame;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"checkbox_new" ofType:@"png"];
        checkboxImage = [UIImage imageWithContentsOfFile:imagePath];
        imagePath = [[NSBundle mainBundle] pathForResource:@"uncheck_new" ofType:@"png"];
        uncheckboxImage = [UIImage imageWithContentsOfFile:imagePath];
   }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear: animated];
    //this will help us figure out which service to call
    EmployeeAdded = NO;
    EmployeeInvited = NO;
    boxChecked = TRUE;
    
    mainViewController.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _TopViewController.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _inviteViewController.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _blockEmployeeView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _addEmployeeViewController.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);

    [scrollView setScrollEnabled:YES];
    [scrollView setContentSize:CGSizeMake(320, 650)];
    scrollView.delaysContentTouches = NO;

    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];


}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Hide the block employees choice on the first version
    nameTextField.tag = NAME_TAG;
    emailTextField.tag = EMAIL_TAG;
    _passcodeTextField.tag = PIN_TAG;
    
   // [_blockEmployeeView setHidden: YES];
    nameTextField.delegate = self;
    [nameTextField setReturnKeyType:UIReturnKeyDone];
    
    emailTextField.delegate = self;
    [emailTextField setReturnKeyType:UIReturnKeyDone];
    
    _passcodeTextField.delegate = self;
    
    [_phoneTextField setReturnKeyType:UIReturnKeyDone];
    _phoneTextField.delegate = self;
    //ios 7
    self.navigationController.navigationBar.translucent = NO;
    _inviteTopConstraint.constant = 69;
    
    if (!CommonLib.userHasPayrollPermission)
    {
        _hourlyRateView.hidden = true;
    }
    
    
//#ifdef IPAD_VERSION
//    NSLog(@"sdsds ipad");
//    [_blockEmployeeView setHidden: NO];
//#else
//    NSLog(@"sdsds iphone");
    
  //    [_blockEmployeeView setHidden: YES];
  //    [_passcodeView setHidden: YES];
  //    [_passcodeViewImage setHidden: YES];
      _inviteTopConstraint.constant = 24; // 69-(40+5)
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
//#endif

}

- (void)viewDidAppear:(BOOL)animated {
    viewFrame = self.view.frame;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGFloat screenWidth = self.view.frame.size.width; //[UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = self.view.frame.size.height; //[UIScreen mainScreen].bounds.size.height;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view setFrame:CGRectMake(0,-50,screenWidth,screenHeight)];
    }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        [self.view setFrame:viewFrame];
        [self.view layoutIfNeeded];
    }];
}

- (void)viewDidUnload
{
    [self setEmailTextField:nil];
    [self setNameTextField:nil];
    [self setMainViewController:nil];
    [self setInviteBtn:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

         //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //    [alert show];
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
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
#ifndef RELEASE
    NSString* JSONStr = [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding];
    NSLog(@"JSONStr result is %@", JSONStr);
#endif

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

               // alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                EmployeeAdded = NO;
            }
            else{
                [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from AddEmployeeViewController JSON Parsing Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
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
    else{
        
        //to prevent the intital employee screen from showing put a one in user.employeeCount
        UserClass *user = [UserClass getInstance];
        user.employeeCount = [NSNumber numberWithInt: 1];

        //persist selection
        [[NSUserDefaults standardUserDefaults] setObject:user.employeeCount forKey:@"employeeCount"];
  //      [[NSUserDefaults standardUserDefaults] synchronize];

        [self.delegate addEmployeeViewControllerDidFinish:self.parentViewController CancelWasSelected:NO];
    }

    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [self stopSpinner];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
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


-(void) callAddEmployeeAPI: (NSString*) userName UserEmail: (NSString *) userEmail withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
   // NSString *request_body;
    NSString *teamPin = _passcodeTextField.text;
    
    NSString *phoneNumber = _phoneTextField.text;
 
   // NSArray *permissionsArray;

    NSArray *authorities;
    if ([_roleTextField.text isEqualToString:@"Manager"])
        authorities = @[@"ROLE_EMPLOYEE", @"ROLE_MANAGER"];
    else if ([_roleTextField.text isEqualToString:@"Payroll Manager"])
        authorities = @[@"ROLE_PAYROLL_MANAGER", @"ROLE_EMPLOYEE"];
    else
        authorities = @[@"ROLE_EMPLOYEE"];
    
    NSString *sendInvite = @"false";
    if ([_inviteSwitch isOn])
        sendInvite = @"true";
    

  //  if ([_blockPermissionSwitch isOn]) {
  //      permissionsArray = @[@"DISALLOW_EMPLOYEE_TIMEENTRY"];
  //  }
    
    NSMutableArray *permissionsArray = [[NSMutableArray alloc] init];
    if (![_allowMobileSwitch isOn])
        [permissionsArray addObject:@"DISALLOW_EMPLOYEE_MOBILE_TIMEENTRY"];
    if (![_allowWebsiteSwtich isOn])
        [permissionsArray addObject:@"DISALLOW_EMPLOYEE_WEB_TIMEENTRY"];
    //check if the value changed then pass it else pass a nil which means to change
 
    httpPostString = [NSString stringWithFormat:@"%@api/v1/employer/employee", SERVER_URL];

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          userName, @"name",
                          userEmail, @"emailAddress",
                          phoneNumber, @"mobilePhone",
                          teamPin, @"teamPin",
                          authorities, @"authorities",
                          sendInvite, @"sendInvite",
                          permissionsArray, @"permissions",
                          nil];
    
    if (CommonLib.userHasPayrollPermission)
    {
        NSString *hourlyRate = _hourlyRateTextField.text;
        if (![NSString isNilOrEmpty:hourlyRate])
        {
   //         hourlyRate = [hourlyRate substringFromIndex:1];
            if (![NSString isNilOrEmpty: hourlyRate])
            {
                double dHourlyPayRate = [hourlyRate doubleValue];
                NSNumber *nHourlyPayRate = [NSNumber numberWithDouble:dHourlyPayRate];
                [dict setValue:nHourlyPayRate forKey:@"hourlyRate"];
            }
        }
    }

    NSError *error;
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSData *requestData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"POST"];
    

    
    //set request body into HTTPBody.
//    urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    UserClass *user = [UserClass getInstance];
    NSString *employerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:employerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];

    [urlRequest setValue:[NSString stringWithFormat:@"%ld", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setHTTPBody: requestData];
    
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
                
                //[self stopSpinner];
                
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




-(void)removeKeyboard{
    [nameTextField resignFirstResponder];
    [emailTextField resignFirstResponder];
}
// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
}


- (IBAction)doAddEmployee:(id)sender {
    if ([nameTextField.text length] == 0) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter Employee Name"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter Employee Name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
    }
    else if (([emailTextField.text length] == 0) && ([_phoneTextField.text length] == 0)) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter Employee Email or Phone"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

        
    }
    else if ([_passcodeTextField.text length] > 4)
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a 4 digit passcode."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

       // UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a 4 digit passcode." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       // [alert show];

    }
    else if ((_phoneTextField.text.length > 0) && (![CommonLib validatePhoneNumber:_phoneTextField.text]) )
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a valid phone number and do not enter a 1 in front of the number"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    }
    else if (([emailTextField.text length] > 0) && (![CommonLib validateEmail:emailTextField.text])) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a valid email or phone"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

       // UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a valid email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       // [alert show];
            
    }
    else
        {
            //if the invite button is turned on then call the invite API which will add an employee and send an invite email else call the add employee API which only ads an employee

                 [self removeKeyboard];
                [self startSpinnerWithMessage:@"Adding Employee..."];
                [self callAddEmployeeAPI:self.nameTextField.text UserEmail:self.emailTextField.text withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
                    [self stopSpinner];
  //                  if (errorCode == WEB_SERVICE_ACCOUNT_EXIST_ERROR){
                    if (errorCode != 0 ){
                        UIAlertController * alert = [UIAlertController
                                                     alertControllerWithTitle:@"ERROR"
                                                     message:resultMessage
                                                     preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                        
                        [alert addAction:defaultAction];
                        
                        [self presentViewController:alert animated:YES completion:nil];

                       // alert = [[UIAlertView alloc] initWithTitle:nil message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        EmployeeAdded = NO;
                    }
 
                    else
                    {
                        [CommonLib logEvent:@"Add employee"];
                        //to prevent the intital employee screen from showing put a one in user.employeeCount
                        UserClass *user = [UserClass getInstance];
                        user.employeeCount = [NSNumber numberWithInt: 1];

                        //persist selection
                        [[NSUserDefaults standardUserDefaults] setObject:user.employeeCount forKey:@"employeeCount"];
                  //      [[NSUserDefaults standardUserDefaults] synchronize];

                        [self.delegate addEmployeeViewControllerDidFinish:self.parentViewController CancelWasSelected:NO];
                    }
                }];
                

            }

 //       }



    
}

- (IBAction)selectRoles:(id)sender {
    UINavigationController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"rolesListNav"];
    RolesListViewController * controller = viewController.viewControllers.firstObject;
    controller.delegate = self;
    [self presentViewController:viewController animated:YES completion:nil];
}


- (IBAction)doCancelAddEmployee:(id)sender {
    [self.delegate addEmployeeViewControllerDidFinish:self.parentViewController CancelWasSelected: TRUE];
}


- (IBAction)nameEditingDidBegin:(id)sender {

}

-(void)touchesBegan:(NSSet*)trigger withEvent:(UIEvent*)event{
 //   [emailTextField resignFirstResponder];
 //   [nameTextField resignFirstResponder];
 
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self removeKeyboard];
    return YES;
}

//prevent users from entering none numberic characters in the PIN field
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string length] == 0 && range.length > 0)
    {
        textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        return NO;
    }
    
    //if textfield is not the PIN field then don't check
    if (textField.tag != PIN_TAG)
        return YES;
    //stop them from typing after 4 digits
    if (textField.text.length >=4)
        return NO;
    
    NSCharacterSet *nonNumberSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    if ([string stringByTrimmingCharactersInSet:nonNumberSet].length > 0)return YES;
    
    return NO;
}

- (void)roleWasSelected: (NSString *) roleType
{
    _roleTextField.text = roleType;
}
@end
