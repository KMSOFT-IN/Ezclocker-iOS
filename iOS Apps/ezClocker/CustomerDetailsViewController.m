//
//  CustomerDetailsViewController.m
//  ezClocker Personal
//
//  Created by Raya Khashab on 11/29/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import "CustomerDetailsViewController.h"
#import "user.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"

@interface CustomerDetailsViewController ()

@end

@implementation CustomerDetailsViewController

int CREATE_CUSTOMER = 1;
int UPDATE_CUSTOMER = 2;
int CHANGE_CUSTOMER = 3;

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Customer Info";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(onSaveClick)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    if (_customerDetails == nil)
        _customerDetails = [[NSMutableDictionary alloc] init];
    
    if ((_customerDetails != nil) && ([_customerDetails count] > 0))
    {
        NSString *name = [_customerDetails valueForKey:@"name"];
        _nameTextField.text = name;
        NSString *email = [_customerDetails valueForKey:@"email"];
        if (![NSString isNilOrEmpty:email])
            _emailTextField.text = email;
    }

}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void) onSaveClick
{
    BOOL isEmpty = [NSString isNilOrEmpty: _nameTextField.text];
    
    if (isEmpty)
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a customer name"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a location name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //  [alert show];
    }
    else{
        [self startSpinnerWithMessage:@"Saving, please wait..."];
        int mode = CREATE_CUSTOMER;
        //if we have a customer ID then this is an edit not create
        if ((_customerDetails) && ([_customerDetails objectForKey:@"id"]) )
            mode = UPDATE_CUSTOMER;
        //if we do not have an id then this is the default customer so need to call the change-customer API which will create a customer Id for us and convert any time entries with customer id of null to customer id
        else if ((_customerDetails) && ([_customerDetails count] > 0))
            mode = CHANGE_CUSTOMER;
        [self callCustomerBatchAPI:mode withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
            [self stopSpinner];
            if (aErrorCode != 0) {
                [ErrorLogging logError:aError];
                [SharedUICode messageBox:nil message:@"There was an issue saving the customer information. Please try again later" withCompletion:^{
                    return;
                }];
                
            }
            [self.delegate CustomerDetailsDidFinish:self CancelWasSelected:NO];
            
        }];
        
        
    }
    
}

-(void) callCustomerBatchAPI:(int)operation withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    NSString *curEmployeeID = [user.userID stringValue];
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    NSString *httpPostString;
    NSString *customerId = [[_customerDetails valueForKey:@"id"] stringValue];
    NSMutableDictionary *dict = nil;
    
    if (operation == CREATE_CUSTOMER)
        httpPostString = [NSString stringWithFormat:@"%@api/v1/customers", SERVER_URL];
    else if (operation == CHANGE_CUSTOMER)
        httpPostString = [NSString stringWithFormat:@"%@api/v2/timeentry/change-customer", SERVER_URL];
    else
        httpPostString = [NSString stringWithFormat:@"%@api/v1/customers/%@", SERVER_URL, customerId];

    NSString *_name = _nameTextField.text;
    
    NSString *_email = _emailTextField.text;

    
    if (operation == CHANGE_CUSTOMER)
    {
        NSMutableDictionary* toCustomerDict;
        toCustomerDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     curEmployerID, @"employerId",
                                     curEmployeeID, @"employeeId",
                                     @"", @"description",
                                     _name, @"name",
                                     nil];
        
        if (![NSString isNilOrEmpty:_email])
           [ toCustomerDict setValue:_email forKey:@"emailAddress"];

        dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     curEmployerID, @"employerId",
                                     curEmployeeID, @"employeeId",
                                   //  customerId, @"fromCustomerId",
                                     toCustomerDict, @"toCustomer",
                                     nil];
    }
    else{
        dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                curEmployerID, @"employerId",
                curEmployeeID, @"employeeId",
                @"", @"description",
                _name, @"name",
                nil];
        
        if (![NSString isNilOrEmpty:_email])
           [ dict setValue:_email forKey:@"emailAddress"];

    }
    

    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    

    NSString *JSONString = @"";
    
    if (!jsonData) {
    } else {
        
        JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    request.HTTPBody = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    if (operation == CREATE_CUSTOMER)
    {
        [request setHTTPMethod:@"POST"];
        
    }
    else //we are doing a customer update
    {
        [request setHTTPMethod:@"PUT"];
        
    }
    
    [request setValue:curEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [request setValue:curAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
    
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






@end
