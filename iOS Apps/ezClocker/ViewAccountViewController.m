//
//  ViewAccountViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 2/20/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "ViewAccountViewController.h"
#import "ECSlidingViewController.h"
#import "user.h"
#import "CommonLib.h"
#import "threaddefines.h"
#import "SharedUICode.h"
#import "UpdateAccountViewController.h"

@interface ViewAccountViewController ()

@end

@implementation ViewAccountViewController
@synthesize emailLabel = _emailLabel;
@synthesize nameLabel = _nameLabel;
@synthesize mainView = _mainView;

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
    UserClass *user = [UserClass getInstance];
    _emailLabel.text = user.userEmail;
    
    _editBarBtn.style = UIBarButtonItemStylePlain;
    _editBarBtn.enabled = false;
    _editBarBtn.title = nil;
    self.navigationItem.rightBarButtonItem = nil;

#ifdef PERSONAL_VERSION
    _nameLabel.text = user.indivdualName;
#endif
    _mainView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);

    
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    [_signInButton setTitleColor:UIColorFromRGB(EZCLOCKER_BLUE_COLOR) forState:UIControlStateNormal];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];

}

-(void) callEmployeeAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    // NSString *request_body;
    
    
//    httpPostString = [NSString stringWithFormat:@"%@api/v1/employer/", SERVER_URL];
    httpPostString = [NSString stringWithFormat:@"%@api/v1/employee/personal", SERVER_URL];

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSError *error;

/*Payload:
{
    "employerUsername": "string: employer's username",
    "employerPassword": "string: employer's password",
    "returnDeleteLog": boolean (false by default, not required)
}
 */
    

        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        
        NSString *email = @"ez.test.signup77.2@mailinator.com";
        [dict setValue:email forKey:@"employerUsername"];
        
        NSString *password = @"1234";
        [dict setValue:password forKey:@"employerPassword"];
        

    
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //set request body into HTTPBody.
     //   urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    

    [urlRequest setHTTPMethod:@"DELETE"];

     
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *personalId = [user.userID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [urlRequest setValue:personalId forHTTPHeaderField:@"x-ezclocker-personal-id"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    
    
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
    
}

-(void) deleteAccount
{
    [self startSpinnerWithMessage:@"Deleting, please wait..."];
    
    [self callEmployeeAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
                [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                    return;
                }];
        }
        else{
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Alert"
                                         message:@"Your Account has been deleted"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                
                [alert dismissViewControllerAnimated:YES completion:nil];
                
            }];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

              }

         
    }];
    
}

- (IBAction)doDeleteAccount:(id)sender {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Alert"
                                 message:@"Are you sure you want to delete your account?. All information will be lost"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

        [self deleteAccount];
    }];
    
    [alert addAction:defaultAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        [alert dismissViewControllerAnimated:YES completion:nil];
        
    }];
    
    [alert addAction:cancelAction];
    

    
    [self presentViewController:alert animated:YES completion:nil];

}

- (IBAction)updateAccount:(id)sender {
    UpdateAccountViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"UpdatePersonalAccount"];
    
    UINavigationController *addEmployeeNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    
    controller.delegate = (id) self;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:addEmployeeNavigationController animated:YES completion:nil];

}
- (IBAction)doSignOut:(id)sender {
    [self.delegate loginPersonalWasSelectedFromViewAccount:self];

}

@end
