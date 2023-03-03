//
//  PersonalAppSettingsTableViewController.m
//  ezClocker Personal
//
//  Created by Raya Khashab on 10/3/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import "PersonalAppSettingsTableViewController.h"
#import "ECSlidingViewController.h"
#import "user.h"
#import "NSString+Extensions.h"
#import "SharedUICode.h"
#import "CommonLib.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"

@interface PersonalAppSettingsTableViewController ()

@end

@implementation PersonalAppSettingsTableViewController 
const int MAX_PERSONALAPP_OPTIONS = 4;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    _personalAppVersionLabel.text = appVersionString;
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];
    
    UserClass *user = [UserClass getInstance];
    if (user.individualHourlyPayRate > 0)
    {
        NSString* strHourlyPayRate = [NSString stringWithFormat:@"$%.02f", user.individualHourlyPayRate];

        _hourlyRateTextField.text = strHourlyPayRate;
    }
    
    _hourlyRateTextField.delegate = self;
    _nameTextField.delegate = self;
    _emailTextField.delegate = self;
    
    [_nameTextField setReturnKeyType:UIReturnKeyDone];
    
    _accountSettingsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    
    if (![NSString isNilOrEmpty: user.indivdualName])
    {
        _nameTextField.text = user.indivdualName;
        _nameTextField.enabled = true;
    }
    else
        _nameTextField.enabled = false;
    
    //make sure the email is not a temporary one that gets created when the personal account is first established
    if ((![NSString isNilOrEmpty: user.userEmail]) && ([user.userEmail containsString: @"@"]))
    {
         _emailTextField.text = user.userEmail;
        _emailTextField.enabled = true;
    }
    else
    {
        _emailTextField.enabled = false;
    }

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return true;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{

    return 40;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return MAX_PERSONALAPP_OPTIONS;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)doSave:(id)sender {
    UserClass *user = [UserClass getInstance];
    
    if (![NSString isNilOrEmpty:_hourlyRateTextField.text]) {
        NSString *tmp = _hourlyRateTextField.text;
        tmp = [tmp substringFromIndex:1];
        double dHourlyPayRate = [tmp doubleValue];
        
        if (dHourlyPayRate > 0)
        {
            user.individualHourlyPayRate = dHourlyPayRate;
            user.showTotalPay = true;
        }
        else
        {
            user.individualHourlyPayRate = dHourlyPayRate;
            user.showTotalPay = false;
        }
    }
    else{
        user.showTotalPay = false;
    }
    
    if (![NSString isNilOrEmpty:_emailTextField.text])
    {
        if ([CommonLib validateEmail:_emailTextField.text])
        {
            [self callSaveEmployeeInfo];

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
          //  [alert show];
        
        }
    }
    //the email can be empty if they never created an account
    else
    {
        [self callSaveEmployeeInfo];
    }


}

/*-(NSString*) currencyInputFormatting: (NSString*) str{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyAccountingStyle];
    formatter.currencySymbol = @"$";
    formatter.maximumFractionDigits = 2;
    formatter.minimumFractionDigits = 2;
    
    double amountWithPrefix;
    NSError  *error = nil;
    
    // remove from String: "$", ".", ","
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"[^0-9]" options:0 error:&error];
    
    NSTextCheckingResult *tokenizationKeyMatch = [regex firstMatchInString:str options:0 range: NSMakeRange(0, str.length)];

    
    double amountWithPrefixDbl = ((NSString) tokenizationKeyMatch).doub* double.doubleValue
    number = NSNumber(value: (double / 100))
    
    // if first number is 0 or all numbers were deleted
    guard number != 0 as NSNumber else {
        return ""
    }

    
    NSString *resultStr = [formatter stringFromNumber:num];
    return resultStr;

}
*/

-(NSString*) formatPayRate: (NSString*) payRateString replacementString:(NSString *)string
{
    NSString* formatedResult;
    NSString *cleanCentString = [[payRateString componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
    NSInteger centValue= cleanCentString.integerValue;
    
    if (string.length > 0)
    {
        centValue = centValue * 10 + string.integerValue;
    }
    else
    {
        centValue = centValue / 10;
    }
    
    NSNumber *formatedValue;
    formatedValue = [[NSNumber alloc] initWithFloat:(float)centValue / 100.0f];
    NSNumberFormatter *_currencyFormatter = [[NSNumberFormatter alloc] init];
    [_currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    formatedResult = [_currencyFormatter stringFromNumber:formatedValue];

    return formatedResult;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == 1){
      //  textField.text = [self formatPayRate: textField.text replacementString: string];
        NSString *cleanCentString = [[textField.text componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
        NSInteger centValue= cleanCentString.integerValue;
        
        if (string.length > 0)
        {
            centValue = centValue * 10 + string.integerValue;
        }
        else
        {
            centValue = centValue / 10;
        }
        
        NSNumber *formatedValue;
        formatedValue = [[NSNumber alloc] initWithFloat:(float)centValue / 100.0f];
        NSNumberFormatter *_currencyFormatter = [[NSNumberFormatter alloc] init];
        [_currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        textField.text = [_currencyFormatter stringFromNumber:formatedValue];
        return NO;
    }
    
    if (textField.tag == 2){
        // Nothing for now
    }
    
    return YES;
}

-(void) callSaveEmployeeInfo
{
    [self startSpinnerWithMessage:@"Saving, please wait..."];
    
    [self callEmployeeAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            //success save the option and show message
            UserClass *user = [UserClass getInstance];
            
            [[NSUserDefaults standardUserDefaults] setDouble: user.individualHourlyPayRate  forKey:@"individualHourlyPayRate"];
 
            if (![NSString isNilOrEmpty: _nameTextField.text])
            {
                user.indivdualName = _nameTextField.text;
                [[NSUserDefaults standardUserDefaults] setObject: user.indivdualName  forKey:@"UserName"];
            }
            
            if (![NSString isNilOrEmpty: _emailTextField.text])
            {
                user.userEmail = _emailTextField.text;
                [[NSUserDefaults standardUserDefaults] setObject: user.userEmail  forKey:@"userEmail"];
            }
            
    //        [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Confirmation"
                                         message:@"Information Saved Successfully!"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

           // UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Information Saved Successfully!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
           // [alert show];
        }
    }];
    
}


-(void) callEmployeeAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;

    NSString *employeeID = [user.userID stringValue];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/employer/employee/%@", SERVER_URL, employeeID];

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSError *error;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
    NSString *name = _nameTextField.text;
    if (![NSString isNilOrEmpty: name])
        [dict setValue:name forKey:@"name"];
        
    NSString *email = _emailTextField.text;
    if (![NSString isNilOrEmpty: email])
        [dict setValue:email forKey:@"emailAddress"];
        
    NSString *hourlyRate = _hourlyRateTextField.text;
    if (![NSString isNilOrEmpty: hourlyRate])
    {
        //since user.hourlyPayRate already has the correct value use that for the API call
        NSNumber *nHourlyPayRate = [NSNumber numberWithDouble:user.individualHourlyPayRate];
        [dict setValue:nHourlyPayRate forKey:@"hourlyRate"];
    }
    
        /*  NSMutableDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
         name, @"name",
         email, @"emailAddress",
         pin, @"teamPin",
         permissionsArray, @"permissions",
         nil];
         */
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                           options:NSJSONWritingPrettyPrinted error:&error];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //set request body into HTTPBody.
        urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        
    
    

        [urlRequest setHTTPMethod:@"PUT"];
    
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


@end
