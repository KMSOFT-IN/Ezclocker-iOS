//
//  JobCodeDetailsViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 4/7/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import "JobCodeDetailsViewController.h"
#import "user.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "SharedUICode.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "NSNumber+Extensions.h"
#import "AssignedEmployeeListViewController.h"

@implementation JobCodeDetailsViewController

int ADD_JOBCODE = 1;
int UPDATE_JOBCODE = 2;

int HOURLY_RATE_TAG = 1;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (_jobCodeDetails == nil)
        _jobCodeDetails = [[NSMutableDictionary alloc] init];
    
    [self addDoneButtonToKeyboards];
    
    UserClass *user = [UserClass getInstance];
    employeeList = [[NSMutableArray alloc] initWithArray:[user.employeeNameIDList allValues]];
    
    selectedEmployees = [[NSMutableArray alloc] init];
  //  if (assignedEmployeeList == nil)
  //      assignedEmployeeList = [NSMutableArray new];
 

    UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(onSaveClick)];
    
    self.navigationItem.rightBarButtonItem = saveButton;

    if ((_jobCodeDetails != nil) && ([_jobCodeDetails count] > 0))
    {
        NSString *jobCodeIdDescription = [_jobCodeDetails valueForKey:@"description"];
        NSString *jobCodeName = [_jobCodeDetails valueForKey:@"name"];
        NSNumber *hourlyRateValue;
        
    
        hourlyRateValue = [_jobCodeDetails valueForKey:@"hourlyRateValue"];
        double dHourlyRateValue = 0;
        if (![NSNumber isNilOrNull:hourlyRateValue])
                dHourlyRateValue = [hourlyRateValue doubleValue];
        if (dHourlyRateValue > 0)
        {
            NSString* strHourlyPayRate = [NSString stringWithFormat:@"$%.02f", dHourlyRateValue];
                 
                 _hourlyRateTextField.text = strHourlyPayRate;
        }
         
         _jobCodeNameTextField.text = jobCodeName;
         _jobCodeIdTextField.text = jobCodeIdDescription;
        
        //figure out if we need to check the assign to all box
        NSNumber *assignToAllEmployees =  [_jobCodeDetails valueForKey:@"assignToAllEmployees"];
        
        if (![NSNumber isNilOrNull:assignToAllEmployees])
            [_assignedAllEmployeesSwitch setOn:YES animated:NO];
        else
        {
            [_assignedAllEmployeesSwitch setOn:NO animated:NO];
            assignedEmployeeList = [[NSMutableArray alloc] initWithArray:[_jobCodeDetails valueForKey:@"assignedEmployeeList"] copyItems:true];

        //    [self getAssignedEmployees];
        
        }


    }

    _hourlyRateTextField.tag = HOURLY_RATE_TAG;
    _hourlyRateTextField.delegate = self;
    
     [self setFramePicker];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];

    [self.navigationController.navigationBar setTitleTextAttributes:
          @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    //for now we don't support hourly rate for the biz app
 #ifndef PERSONAL_VERSION
    _hourlyRateView.hidden = TRUE;
    self.assignedEmployeesTableView.hidden = [_assignedAllEmployeesSwitch isOn];
#endif
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    CGFloat Y = screenHeight - kbHeight;//(kbHeight + safeAreaBottomHeight + safeAreaTopHeight);
    if (self.tabBarController != nil) {
        CGFloat tabbarHeight = self.tabBarController.tabBar.frame.size.height;
        
        pickerMainView = [[UIView alloc] initWithFrame:CGRectMake(0, Y - tabbarHeight, self.view.frame.size.width, kbHeight)];
    } else {
        pickerMainView = [[UIView alloc] initWithFrame:CGRectMake(0, Y, self.view.frame.size.width, kbHeight)];
    }
    
    [pickerMainView setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    
    //if we are running the iPhone then we start at 44 because of the toolbar
    
    CGRect pickerFrame;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        pickerFrame = CGRectMake(0, 0, 350, 250);
    } else {
        pickerFrame = CGRectMake(0, 44,  screenSize.width, kbHeight - 44);
    }
 //   pickerViewEmployeeName = [[UIPickerView alloc] initWithFrame:pickerFrame];
 //   pickerViewEmployeeName.dataSource = self;
 //   pickerViewEmployeeName.delegate = self;
  //  if ((_locationDetails != nil) && ([_locationDetails count] > 0))
        
   //     [self getAssignedEmployees];
}


-(bool)isJobCodeExist: jobCodeName
{
        bool alreadyExists = false;
        NSString *selectedJobCodeName;
      //  NSString *selectedJobCodeDisplayValue;
        UserClass *user = [UserClass getInstance];
        for (NSDictionary *jobCodeObj in user.jobCodesList )
        {
            selectedJobCodeName = [[jobCodeObj valueForKey:@"name"] uppercaseString];
         //   selectedJobCodeDisplayValue = [[jobCodeObj valueForKey:@"displayValue"] uppercaseString];
            //check the jobCodeTagId
            if ([selectedJobCodeName isEqualToString:[jobCodeName uppercaseString]])
                 return true;
            //check the display value
  //          else if ((![NSString isNilOrEmpty:jobCodeDisplayValue]) && [selectedJobCodeDisplayValue isEqualToString:[jobCodeDisplayValue uppercaseString]])
                
        //        return true;

        }
    return alreadyExists;
}

-(void) saveJobCode
{
    BOOL isEmpty = [NSString isNilOrEmpty:_jobCodeNameTextField.text];
    
    if (isEmpty)
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a name for the job"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    }
    else{
        int mode = ADD_JOBCODE;
        //if we have a jobCode ID then this is an edit not create
        if ((_jobCodeDetails) && ([_jobCodeDetails objectForKey:@"id"]) )
            mode = UPDATE_JOBCODE;
        bool alreadyExists = false;
        
        if (mode == ADD_JOBCODE)
        {
            //check to make sure it's not already in the list
 //           NSString* jcDisplayValue = _jobCodeNameTextField.text;
            alreadyExists = [self isJobCodeExist:_jobCodeNameTextField.text];
        }
        
        if (alreadyExists)
        {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"ERROR"
                                         message:@"The job name already exists. Please enter a unique job name"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];

        }
        else
        {
            [self startSpinnerWithMessage:@"Saving, please wait..."];

            [self callJobCodesAPI:mode withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
                
                [self stopSpinner];
                if (aErrorCode != 0) {
                    [SharedUICode messageBox:nil message:@"There was an issue saving the job. Please try again later" withCompletion:^{
                    return;
                }];
                
                }
                
                [self.delegate JobCodeDetailsDidFinish:self CancelWasSelected:NO];
            
            }];
        
        }
    }

}

-(void) onSaveClick
{
    //if we are not running the personal app then force them to assign at least one employee to a job code
#ifdef PERSONAL_VERSION
    [self saveJobCode];
#else
    //force them to either turn on the AssignAllEmployee switch to be on or at least one employee assigned
    if (![_assignedAllEmployeesSwitch isOn] && [assignedEmployeeList count] == 0)
    {
        [SharedUICode messageBox:nil message:@"Please assign at least one employee to the job or assign it to all employees." withCompletion:^{
            return;
        }];
    }
    else
        [self saveJobCode];
#endif
}


#ifdef PERSONAL_VERSION
-(void) callJobCodesAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    
    
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    
    if (flag == ADD_JOBCODE)
    {
        httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags", SERVER_URL];
    }
    else
    {
        NSString *jobCodeId = [_jobCodeDetails valueForKey:@"id"];
        httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags/%@", SERVER_URL, jobCodeId];

 }
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSError *error;

    NSString *jobCodeName = _jobCodeNameTextField.text;
    NSString *jobCodeIdDescription = _jobCodeIdTextField.text;

 //    if ([NSString isNilOrEmpty:displayValue])
  //       displayValue = tagId;
    NSString *tagType = @"JOB_CODE";
    NSString *hourlyRate = _hourlyRateTextField.text;
    double dHourlyPayRate = 0;
    NSString *employeeID = [user.userID stringValue];
    
    if (![NSString isNilOrEmpty: hourlyRate])
    {
        hourlyRate = [hourlyRate substringFromIndex:1];
        dHourlyPayRate = [hourlyRate doubleValue];
   }
    

     NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
     employeeID, @"personalId",
     jobCodeName, @"tagName",//tagId
 //    displayValue, @"displayValue",
     jobCodeIdDescription, @"description",
     tagType, @"ezDataTagType",//dataTagType
//     DATA_TAG_TYPE_HOURLY, @"valueType",//tagValueType
     DATA_TAG_TYPE_HOURLY, @"valueName",
     hourlyRate, @"value",//needs to be string //tagValue
     nil];
     
     
     NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
     options:NSJSONWritingPrettyPrinted error:&error];
     
     NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
     
     //set request body into HTTPBody.
     urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    

    if (flag == ADD_JOBCODE)
        [urlRequest setHTTPMethod:@"POST"];
    else
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
#else
-(void) callJobCodesAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    
    
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    
    if (flag == ADD_JOBCODE)
    {
        httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags/bulk", SERVER_URL];
    }
    else
    {
        NSString *jobCodeId = [_jobCodeDetails valueForKey:@"id"];
        httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags/%@/bulk", SERVER_URL, jobCodeId];
      //  httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags/archive/%@", SERVER_URL, jobCodeId];

    }
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSError *error;

    NSString *jobCodeName = _jobCodeNameTextField.text;
    NSString *jobCodeIdDescription = _jobCodeIdTextField.text;

    NSString *tagType = @"JOB_CODE";
    NSString *hourlyRate = _hourlyRateTextField.text;
    double dHourlyPayRate = 0;
    
    if (![NSString isNilOrEmpty: hourlyRate])
    {
        hourlyRate = [hourlyRate substringFromIndex:1];
        dHourlyPayRate = [hourlyRate doubleValue];
   }
    

     NSMutableDictionary *dataTagDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
     jobCodeName, @"tagName",//tagId
  //   displayValue, @"displayValue",
     jobCodeIdDescription, @"description",
     tagType, @"ezDataTagType",//dataTagType
   //  DATA_TAG_TYPE_HOURLY, @"tagValueType",
  //   hourlyRate, @"tagValue",
     nil];
    
 //   NSMutableArray *assignedEmployeesList = [[NSMutableArray alloc] init];
//    for (NSDictionary *employeeObj in assignedEmployeeList)
//    {
 //       [assignedEmployeesList addObject:employeeObj ];
//    }
 //   NSNumber *curEmployeeId = [NSNumber numberWithInt:491];//employee ez.comp33.emp1
 
    /*NSDictionary *employeeObj = [NSDictionary dictionaryWithObjectsAndKeys:
                                curEmployeeId, @"employeeId",
                                @"false", @"primary",
                                nil];
    [assignedEmployeesList addObject:employeeObj];
    */
    
//    if ([assignedEmployeeList count] > 0)
//        [dataTagDict setValue:@"-1" forKey:@"employeeId"];
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              dataTagDict, @"dataTag",
                              assignedEmployeeList, @"assignedEmployees",
                              nil];
     
     NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
     options:NSJSONWritingPrettyPrinted error:&error];
     
     NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
     
     //set request body into HTTPBody.
     urlRequest.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    

    if (flag == ADD_JOBCODE)
        [urlRequest setHTTPMethod:@"POST"];
    else
        [urlRequest setHTTPMethod:@"PUT"];
    
    //for archive do a post
    
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
#endif

-(void) callAssignedEmployeesAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    
    
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    

    NSString *jobCodeId = [_jobCodeDetails valueForKey:@"id"];
        httpPostString = [NSString stringWithFormat:@"%@/api/v1/employee-data-tag-maps/assigned/%@", SERVER_URL, jobCodeId];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
   // NSError *error;

    [urlRequest setHTTPMethod:@"GET"];

    //for archive do a post
    
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

-(void) getAssignedEmployees
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    [self callAssignedEmployeesAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue in retrieving data from server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        
        NSArray *employees = [aResults valueForKey:@"entities"];
        NSString *employeeName = @"";
        NSString *employeeId = @"";
        NSString *isPrimary;
        [assignedEmployeeList removeAllObjects];
        
        if ([employees count] > 0)
        {
            for (NSDictionary *employeeObj in employees){
                isPrimary = [employeeObj valueForKey:@"isPrimary"];
                employeeName = [employeeObj valueForKey:@"employeeName"];
                employeeId = [employeeObj valueForKey:@"employeeId"];
                BOOL isEmpty = [NSString isNilOrEmpty:employeeName];

                if (!isEmpty){
                   NSDictionary *employeeObj = [[NSMutableDictionary alloc] init];
                    [employeeObj setValue:employeeName forKey:@"employeeName"];
                    [employeeObj setValue:employeeId forKey:@"employeeId"];
                    [employeeObj setValue:isPrimary forKey:@"isPrimary"];
                    [assignedEmployeeList addObject:employeeObj];
                }

            }
            @try{
                
            [_assignedEmployeesTableView reloadData];
                
            }@catch (NSException *theException) {
                NSLog(@"%@ doClockOutBtnClick check error!", [theException name]);

            }
        }
        
    }];
    
}

- (void)addDoneButtonToKeyboards {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self.view action:@selector(endEditing:)];
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    _jobCodeIdTextField.inputAccessoryView = keyboardToolbar;
    _jobCodeNameTextField.inputAccessoryView = keyboardToolbar;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
     return [assignedEmployeeList count];
        
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 37.f;
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect mainFrame = self.view.frame;
    
    UIView *tempView=[[UIView alloc]initWithFrame:CGRectMake(0,200,mainFrame.size.width,244)];
    tempView.backgroundColor = UIColorFromRGB(GRAY_WEBSITE_COLOR);
    
    UILabel *tempLabel=[[UILabel alloc]initWithFrame:CGRectMake(16,0,(mainFrame.size.width - 86),36)];
    tempLabel.backgroundColor=[UIColor clearColor];
    tempLabel.textColor = [UIColor whiteColor];
    tempLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0f];
    tempLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    tempLabel.text =  @"Employees Who Do This Job";
    tempLabel.numberOfLines = 0;

    if (addButton == nil)
    {
        addButton = [[UIButton alloc] initWithFrame:CGRectMake(tempLabel.frame.size.width, 0, 30, 33)];
        [addButton setTitle:@"+" forState:UIControlStateNormal];
        addButton.titleLabel.font = [UIFont systemFontOfSize:30];
        [addButton addTarget:self action:@selector(employeesAddBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (editButton == nil)
    {
        CGRect editFrame = CGRectMake((tempLabel.frame.size.width + 30), 0, 40, 37);
        editButton = [[UIButton alloc] initWithFrame:editFrame];
        [editButton setTitle:@"Edit" forState:UIControlStateNormal];
        editButton.titleLabel.font = tempLabel.font;// [UIFont systemFontOfSize:20];
        [editButton addTarget:self action:@selector(employeesEditBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (cancelButton == nil)
    {
        CGRect cancelFrame = CGRectMake(tempLabel.frame.size.width, 0, 70, 37);
        cancelButton = [[UIButton alloc] initWithFrame:cancelFrame];
        [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        cancelButton.titleLabel.font = tempLabel.font;// [UIFont systemFontOfSize:20];
        [cancelButton addTarget:self action:@selector(employeesCancelBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [tempView addSubview:tempLabel];
    
    [tempView addSubview:addButton];
    
    [tempView addSubview:editButton];

    [tempView addSubview:cancelButton];
    
    //when we start we only show the editButton
    cancelButton.hidden = YES;
    
    return tempView;
}

- (void)employeesAddBtnClick:(id)sender {
//    if ([employeeList count] > 1) {
        [self showEmployeePicker];
//    }

}

- (void)employeesCancelBtnClick:(id)sender {
    [self cancelEditing];

}


- (void)cancelEditing {
    if (_assignedEmployeesTableView.editing) {
        [_assignedEmployeesTableView setEditing:NO animated:TRUE];
    }
    [self showEditButtons];
}


- (void)showEditButtons {
    
    //hide the edit button and show the cancel button
    editButton.hidden = NO;
    addButton.hidden = NO;
    cancelButton.hidden = YES;
    
}


- (void)employeesEditBtnClick:(id)sender {
    [self setEditState];
}

- (void)setEditState {
    if (self.editing) { // Not editing go into edit mode
        [_assignedEmployeesTableView setEditing:NO animated:YES];
        return;
    }
    
    //    [self beforeEditingBegins];
    [_assignedEmployeesTableView setEditing:YES animated:YES];
    
    //hide the edit button and show the cancel button
    editButton.hidden = YES;
    addButton.hidden = YES;
    cancelButton.hidden = NO;
    
    
}

/*- (void)setEditState {
    if (nil == self.navigationItem.leftBarButtonItem) {
        return;
    }
    if (self.editing) { // Not editing go into edit mode
        [self setEditing:NO animated:YES];
//        [self __cancelEditing];
        return;
    }
    
//    [self beforeEditingBegins];
    [self setEditing:YES animated:YES];
    
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelClick:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.navigationItem.rightBarButtonItems = nil;
    
}
 */

- (void)setCancelState {
    if (self.editing) { // Not editing go into edit mode
        [_assignedEmployeesTableView setEditing:NO animated:YES];
        return;
    }
    
    //    [self beforeEditingBegins];
    [_assignedEmployeesTableView setEditing:YES animated:YES];
    
    //hide the edit button and show the cancel button
    editButton.hidden = YES;
    addButton.hidden = YES;
    cancelButton.hidden = NO;
    
    
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
     [self deleteAssignedEmployeeAtIndexPath:indexPath];
    
   // [self cancelEditing];
    
}

- (void)deleteAssignedEmployeeAtIndexPath:(NSIndexPath*)indexPath {
    
    //[_assignedEmployeesTableView setEditing:NO animated: YES];
    
    
    
    [assignedEmployeeList removeObjectAtIndex:indexPath.row];
    // Delete the row from the data source
    [_assignedEmployeesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
//    [self deleteAssignedEmployees: employeeID];
    


}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if ([assignedEmployeeList count] > 0)
    {
        NSDictionary *employeeObj = [assignedEmployeeList objectAtIndex:indexPath.row];
        NSString *employeeName =  [employeeObj valueForKey:@"employeeName"];
        NSNumber *isPrimaryNumber = employeeObj[@"isPrimary"];
        BOOL isPrimary = [isPrimaryNumber boolValue];
        if (isPrimary) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ (Primary)", employeeName];
        } else {
            cell.textLabel.text = employeeName;
        }
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //only asslow selection when we are in the options section and Address row was selected
/*    if ((indexPath.section == SECTION_OPTIONS) && (indexPath.row == ADDRESS_ROW))
    {
        GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
        acController.delegate = self;
        [self presentViewController:acController animated:YES completion:nil];
    }
 */
}

-(void) showEmployeePicker{
    UINavigationController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AssignedEmployeeList"];
      AssignedEmployeeListViewController * controller = viewController.viewControllers.firstObject;
      //controller.assignedEmployeeList = selectedEmployees;//assignedEmployeeList;
   //   controller.assignedEmployeeList = assignedEmployeeList;
      controller.jobCodeDetails = _jobCodeDetails;
      controller.delegate = self;
      [self presentViewController:viewController animated:YES completion:nil];
    /*
#ifdef IPAD_VERSION
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
#else
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
#endif
    
    [pickerToolbar sizeToFit];
    
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                      target:self action:@selector(EmployeePickerCancelClick)];

    

    UIBarButtonItem *doneDateBarBtn = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(EmployeePickerDoneClick)];

    


#ifdef IPAD_VERSION
   // [pickerMainView addSubview:pickerToolbar];
    [pickerMainView addSubview:pickerViewEmployeeName];
    UIViewController *V2 = [[UIViewController alloc] init];
    V2.view = pickerMainView;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:V2];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    V2.preferredContentSize = CGSizeMake(350, 250);
    V2.navigationItem.rightBarButtonItem = doneDateBarBtn;
    V2.navigationItem.leftBarButtonItem = cancelBtn;
    [self presentViewController:navController animated:YES completion:nil];
     navController.view.superview.center = self.view.center;
#else
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, 80, 20.0f)];
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    [pickerToolbar setItems:@[cancelBtn, flexBarButton, titleButton, flexBarButton, doneDateBarBtn]];
    
//
//    [pickerViewEmployeeName setFrame:CGRectMake(0, UIScreen.mainScreen.bounds.size.height-(246+20), self.view.frame.size.width, 216)];
    [pickerMainView addSubview:pickerToolbar];
    [pickerMainView addSubview:pickerViewEmployeeName];
    [_mainView addSubview:pickerMainView];
#endif
*/
    
}
-(IBAction)EmployeePickerCancelClick{
    [self closeEmployeePicker:self];
}

-(BOOL)closeEmployeePicker:(id)sender{
#ifdef IPAD_VERSION
    [pickerMainView removeFromSuperview];
    [self dismissViewControllerAnimated:NO completion:nil];
    return YES;
#else
    [pickerMainView removeFromSuperview];
    return YES;
#endif
}

- (IBAction)doEmployeesSwitchChanged:(id)sender {
    if ([_assignedAllEmployeesSwitch isOn])
        _assignedEmployeesTableView.hidden = TRUE;
    else
        _assignedEmployeesTableView.hidden = FALSE;
}

-(void) callAssignedEmployeesJobCodeAPI:(int)operation jobCodeId: currJobCodeId withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    NSString *httpPostString;
  //  NSString *locID = [_locationDetails valueForKey:@"id"];
  //  httpPostString = [NSString stringWithFormat:@"%@api/v1/location/%@/assigned_employees", SERVER_URL, locID];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/location/%@/assigned_employees", SERVER_URL, @""];


    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    

    [request setHTTPMethod:@"GET"];

    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:curEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [request setValue:curAuthToken forHTTPHeaderField:@"x-ezclocker-authToken"];
    
    
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

- (void)selectedEmployees: (NSMutableArray *) selectedEmployeeList
{
    if (assignedEmployeeList == nil)
          assignedEmployeeList = [NSMutableArray new];
    
       selectedEmployees = selectedEmployeeList;
    [assignedEmployeeList removeAllObjects];
   /*     if ([assignedEmployeeList count] > 0) {
            
            for (NSDictionary *employee in selectedEmployeeList)
            {
                NSString *string = [employee valueForKey:@"employeeId"];
                BOOL isExit = NO;

                for (int i = 0; i < [assignedEmployeeList count]; i++)
                {
                    NSDictionary *empObj = [assignedEmployeeList objectAtIndex: i];
                    NSString *empId = [empObj valueForKey:@"employeeId"];
                    if (string == empId) {
                        isExit = YES;
                        NSNumber *numObj = employee[@"isSelected"];
                        BOOL isSelect = [numObj boolValue];
                        if (isSelect) {
                            [assignedEmployeeList removeObject:empObj];
                            [assignedEmployeeList addObject:employee];
                        } else {
                              [assignedEmployeeList removeObject:empObj];
                        }
                        break;
                    }
                }
                if (!isExit) {
                    NSNumber *numObj = employee[@"isSelected"];
                    BOOL isSelect = [numObj boolValue];
                    if (isSelect) {
                        [assignedEmployeeList addObject:employee];
                    }
                }
            }
        } else {
            */
            for (NSDictionary *employee in selectedEmployeeList)
            {
                BOOL isPrimary = [employee[@"isPrimary"] boolValue];
                NSInteger isPrimaryNumber = 0;
                if (isPrimary) {
                    isPrimaryNumber = 1;
                }
                
                NSNumber *numObj = employee[@"isSelected"];
                BOOL isSelect = [numObj boolValue];
                if (isSelect) {
    //                [assignedEmployeeList addObject:employee];
                    NSMutableDictionary *obj = [[NSMutableDictionary alloc] init];
                    [obj setValue:employee[@"employeeId"] forKey:@"employeeId"];
                    [obj setValue:employee[@"employeeName"] forKey:@"employeeName"];
                    [obj setValue:[NSNumber numberWithInteger:isPrimaryNumber] forKey:@"isPrimary"];
                    [assignedEmployeeList addObject:obj];
                }
                
    //            NSMutableDictionary *obj = [[NSMutableDictionary alloc] init];
    //            [obj setValue:employee[@"employeeId"] forKey:@"employeeId"];
    //            [obj setValue:employee[@"employeeName"] forKey:@"employeeName"];
    //            [obj setValue:[NSNumber numberWithInteger:isPrimaryNumber] forKey:@"isPrimary"];
    //            [assignedEmployeeList addObject:obj];
            }
      //  }

    [_assignedEmployeesTableView reloadData];
}
 
@end
