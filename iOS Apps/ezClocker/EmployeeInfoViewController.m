//
//  EmployeeInfoViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 3/15/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import "EmployeeInfoViewController.h"
#import "SharedUICode.h"
#import "CommonLib.h"
#import "user.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "RolesListViewController.h"

@interface EmployeeInfoViewController ()

@end

@implementation EmployeeInfoViewController

const int GET_EMPLOYEE_INFO = 1;
const int UPDATE_EMPLOYEE_INFO = 2;

const int EMP_NAME_TAG= 0;
const int EMP_EMAIL_TAG = 1;
const int EMP_PIN_TAG = 2;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(onSaveClick)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    self.navigationItem.title = @"Details";
    
    _nameTextField.tag = EMP_NAME_TAG;
    _emailTextField.tag = EMP_EMAIL_TAG;
    _pinTextField.tag = EMP_PIN_TAG;
    
    if (!CommonLib.userHasPayrollPermission)
    {
        _payRateTextField.enabled = FALSE;
        _payRateTextField.text = @"****";
    }
    
 //   [_blockEmployeeView setHidden: YES];
    _nameTextField.delegate = self;
    [_nameTextField setReturnKeyType:UIReturnKeyDone];
    _emailTextField.delegate = self;
    [_emailTextField setReturnKeyType:UIReturnKeyDone];
    _pinTextField.delegate = self;
    
//#ifndef IPAD_VERSION
 //   [_pinView setHidden:YES];
 //   [_blockEmployeeView setHidden:YES];
//#endif
    [self callGetEmployeeInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) callGetEmployeeInfo
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callEmployeeAPI:GET_EMPLOYEE_INFO withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
                [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                    return;
                }];
        }
        else{
            //save all the values we got back to the employeeDetails object so we can keep track of what changed
            _nameTextField.text = [aResults valueForKey:@"name"];
            [_employeeDetails setValue:[aResults valueForKey:@"name"] forKey:@"name"];
            NSString *email = [aResults valueForKey:@"emailAddress"];
            if (![NSString isNilOrEmpty:email])
            {
                _emailTextField.text = [aResults valueForKey:@"emailAddress"];
                [_employeeDetails setValue:[aResults valueForKey:@"emailAddress"] forKey:@"emailAddress"];
            }
            //check to see if mobilePhone exists or not
            NSString* mobilePhone = [aResults valueForKey:@"mobilePhone"];
            if (![NSString isNilOrEmpty:mobilePhone])
                _phoneTextField.text = [aResults valueForKey:@"mobilePhone"];
            [_employeeDetails setValue:[aResults valueForKey:@"mobilePhone"] forKey:@"mobilePhone"];
            
            if (CommonLib.userHasPayrollPermission)
            {
                NSNumber *hourlyPayRate = [aResults valueForKey:@"hourlyRate"];
                NSString* strHourlyPayRate = [NSString stringWithFormat:@"$%.02f", [hourlyPayRate doubleValue]];
                _payRateTextField.text = strHourlyPayRate;
                [_employeeDetails setValue:hourlyPayRate forKey:@"hourlyRate"];
            }

            _pinTextField.text = [aResults valueForKey:@"teamPin"];
            [_employeeDetails setValue:[aResults valueForKey:@"teamPin"] forKey:@"teamPin"];
            NSArray *authorities = [aResults valueForKey:@"authorities"];
            NSString *empAuthority = @"Employee";
            for (NSDictionary *authority in authorities)
            {
                NSString *authorityType = [authority valueForKey:@"authority"];
                if ([authorityType isEqualToString:@"ROLE_MANAGER"])
                {
                    empAuthority = @"Manager";
                    break;
                }
                else if ([authorityType isEqualToString:@"ROLE_PAYROLL_MANAGER"])
                    {
                        empAuthority = @"Payroll Manager";
                        break;
                    }

            }
            __roleTextField.text = empAuthority;

            NSArray *permissions = [aResults valueForKey:@"permissions"];
  //          [_employeeDetails setValue:@"0" forKey:@"blockEmployeeSwitch"];
            if (permissions != nil)
            {
                for (NSDictionary *permission in permissions){
                    NSString *permissionID = [permission valueForKey:@"permissionId"];
                    //"DISALLOW_EMPLOYEE_TIMEENTRY" is an old permission which we no longer used but need to support for backward compatibility
                    if ([permissionID isEqualToString:@"DISALLOW_EMPLOYEE_TIMEENTRY"])
                    {
                        [_allowMobileSwitch setOn:NO];

                    }
                    else if ([permissionID isEqualToString:@"DISALLOW_EMPLOYEE_MOBILE_TIMEENTRY"])
                    {
                        [_allowMobileSwitch setOn:NO];
                    }
                    else if ([permissionID isEqualToString:@"DISALLOW_EMPLOYEE_WEB_TIMEENTRY"])
                    {
                        [_allowWebsiteSwtich setOn:NO];
                    }

                }

            }

         }
    }];
    
}

-(void) callUpdateEmployeeInfo
{
    [self startSpinnerWithMessage:@"Updating, please wait..."];
    
    [self callEmployeeAPI:UPDATE_EMPLOYEE_INFO withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:aResultMessage withCompletion:^{
                return;
            }];
            //add the below code when Jason releases R40 which should give me back the correct Error Code vs. 400
          /*  //check to see if the PIN  number entered already exists
            if (aErrorCode == SERVICE_ERRORCODE_TEAM_PIN_ALREADY_EXIST)
            {
                [SharedUICode messageBox:nil message:aResultMessage withCompletion:^{
                    return;
                }];
            }
            else
            {
                [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                    return;
                }];
            }
           */
        }
        else{
            bool nameWasChanged = false;
            NSString *employeeName = [_employeeDetails valueForKey:@"name"];
            if (![employeeName isEqualToString:_nameTextField.text])
                nameWasChanged = true;
            if (nameWasChanged)
            {
                //pass the new name and ID so we can change the global lists and reload the employeelist
                NSMutableDictionary *empDetailsObj = [[NSMutableDictionary alloc] init];
                [empDetailsObj setValue:[_employeeDetails valueForKey:@"ID"] forKey:@"ID"];
                [empDetailsObj setValue:_nameTextField.text forKey:@"name"];

                [self.delegate EmployeeInfoSaveDidFinish:self EmployeeObj:empDetailsObj];
            }
            else
                [self.delegate EmployeeInfoSaveDidFinish:self EmployeeObj:nil];
        }
    }];
    
}

-(void) callAssignJobCode
{
    [self startSpinnerWithMessage:@"Updating, please wait..."];
    
    [self callJobCodesAssignToEmployeeAPI:UPDATE_EMPLOYEE_INFO withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            bool nameWasChanged = false;
            NSString *employeeName = [_employeeDetails valueForKey:@"name"];
            if (![employeeName isEqualToString:_nameTextField.text])
                nameWasChanged = true;
            if (nameWasChanged)
            {
                //pass the new name and ID so we can change the global lists and reload the employeelist
                NSMutableDictionary *empDetailsObj = [[NSMutableDictionary alloc] init];
                [empDetailsObj setValue:[_employeeDetails valueForKey:@"ID"] forKey:@"ID"];
                [empDetailsObj setValue:_nameTextField.text forKey:@"name"];
                
                [self.delegate EmployeeInfoSaveDidFinish:self EmployeeObj:empDetailsObj];
            }
            else
                [self.delegate EmployeeInfoSaveDidFinish:self EmployeeObj:nil];
        }
    }];
    
}

-(void) callEmployeeAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    // NSString *request_body;
    
    NSString *employeeID = [_employeeDetails valueForKey:@"ID"];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/employer/employee/%@", SERVER_URL, employeeID];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSError *error;

    //if we are calling the update API hen pass the dict payload
    if (flag == UPDATE_EMPLOYEE_INFO)
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        NSString *name = _nameTextField.text;
        [dict setValue:name forKey:@"name"];
        
        NSString *email = _emailTextField.text;
        if ((![NSString isNilOrEmpty:email]) && (![email isEqualToString:[_employeeDetails valueForKey:@"emailAddress"]]))
            [dict setValue:email forKey:@"emailAddress"];
        
        NSString *phoneNumber = _phoneTextField.text;
        if (![phoneNumber isEqualToString:[_employeeDetails valueForKey:@"mobilePhone"]])
            [dict setValue:phoneNumber forKey:@"mobilePhone"];
        
        if (CommonLib.userHasPayrollPermission)
        {
            NSString *hourlyRate = _payRateTextField.text;
            hourlyRate = [hourlyRate substringFromIndex:1];
            if (![NSString isNilOrEmpty: hourlyRate])
            {
                double dHourlyPayRate = [hourlyRate doubleValue];
                NSNumber *nHourlyPayRate = [NSNumber numberWithDouble:dHourlyPayRate];
                [dict setValue:nHourlyPayRate forKey:@"hourlyRate"];
            }
        }
        NSString *pin = _pinTextField.text;
        if (![pin isEqualToString:[_employeeDetails valueForKey:@"teamPin"]])
            [dict setValue:pin forKey:@"teamPin"];
        
        NSString *empRole = __roleTextField.text;
        if (![empRole isEqualToString:[_employeeDetails valueForKey:@"authority"]])
        {
            NSArray *authorities;
            if ([empRole isEqualToString:@"Manager"])
                authorities = @[@"ROLE_MANAGER", @"ROLE_EMPLOYEE"];
            else if ([empRole isEqualToString:@"Payroll Manager"])
                authorities = @[@"ROLE_PAYROLL_MANAGER", @"ROLE_EMPLOYEE"];
            else
                authorities = @[@"ROLE_EMPLOYEE"];

            [dict setValue:authorities forKey:@"authorities"];
        }

        NSMutableArray *permissionsArray = [[NSMutableArray alloc] init];
        if (![_allowMobileSwitch isOn])
            [permissionsArray addObject:@"DISALLOW_EMPLOYEE_MOBILE_TIMEENTRY"];
        if (![_allowWebsiteSwtich isOn])
            [permissionsArray addObject:@"DISALLOW_EMPLOYEE_WEB_TIMEENTRY"];

        [dict setValue:permissionsArray forKey:@"permissions"];
    
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //set request body into HTTPBody.
        urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

    
    }
    
    //set HTTP Method
    if (flag == GET_EMPLOYEE_INFO)
        [urlRequest setHTTPMethod:@"GET"];
    else
        [urlRequest setHTTPMethod:@"PUT"];
    //for archive do a post
    //[urlRequest setHTTPMethod:@"POST"];
     
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
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

-(void) callJobCodesAssignToEmployeeAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    // NSString *request_body;
    
    NSString *employeeID = [_employeeDetails valueForKey:@"ID"];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/employee/%@/datatags", SERVER_URL, employeeID];

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSError *error;
    
    //if we are calling the update API hen pass the dict payload
    if (flag == UPDATE_EMPLOYEE_INFO)
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        NSString *dataTagId = @"3";
        [dict setValue:dataTagId forKey:@"dataTagId"];
        
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                           options:NSJSONWritingPrettyPrinted error:&error];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //set request body into HTTPBody.
        urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        
    }
    
    //set HTTP Method
    if (flag == GET_EMPLOYEE_INFO)
        [urlRequest setHTTPMethod:@"GET"];
    else
        [urlRequest setHTTPMethod:@"POST"];
    //for archive do a post
    //[urlRequest setHTTPMethod:@"POST"];
    
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
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



-(void) onSaveClick
{
    if ([_nameTextField.text length] == 0) {
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
 /*   else if ([_emailTextField.text length] == 0) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter Employee Email"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

     //   UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter Employee Email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
        
    }
  */
    else if ([_pinTextField.text length] > 4)
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a 4 digit passcode."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a 4 digit passcode." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
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
    else if (_emailTextField.text.length > 0){
        if ([CommonLib validateEmail:_emailTextField.text])
        {
            [self callUpdateEmployeeInfo];
        }
        else {
            UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a valid email"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
            [alert addAction:defaultAction];
        
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else
    {
        [self callUpdateEmployeeInfo];
    }

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
    if (textField.tag != EMP_PIN_TAG)
        return YES;
    //stop them from typing after 4 digits
    if (textField.text.length >=4)
        return NO;
    
    NSCharacterSet *nonNumberSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    if ([string stringByTrimmingCharactersInSet:nonNumberSet].length > 0)return YES;
    
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)doSelectRole:(id)sender {
    UINavigationController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"rolesListNav"];
    RolesListViewController * controller = viewController.viewControllers.firstObject;
    controller.delegate = self;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)roleWasSelected: (NSString *) roleType
{
    __roleTextField.text = roleType;
}

@end
