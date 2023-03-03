//
//  EmployeeProfileViewController.m
//  Created by Raya Khashab on 1/27/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "EmployeeProfileViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CommonLib.h"
#import "user.h"
#import "ClockWebServices.h"
#import "CheckClockStatusWebService.h"
#import "DataManager.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "TimeEntry.h"
#import "TimeEntry+CoreDataProperties.h"
#import "ClockInfo.h"
#import "ClockInfo+CoreDataProperties.h"
#import "debugdefines.h"
#import "coredatadefines.h"
#import "SharedUICode.h"
#import "NSNumber+Extensions.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"
#import "NSDictionary+Extensions.h"
#import "JobCodeListViewController.h"

#pragma mark - Clock In/Clock Out View (This is where Clock In and Clock Out happens)

@interface EmployeeProfileViewController()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (nonatomic, retain) ClockWebServices* clockWebServices;
@property (nonatomic, retain, readonly) TimeEntry* timeEntry;
@property (nonatomic, copy) NSManagedObjectID* timeEntryObjectID;

@end

@implementation EmployeeProfileViewController
@synthesize employeeImage;
@synthesize inviteButton;
@synthesize employeeNameLabel;
@synthesize inviteInfoLabel;
@synthesize employeeID;
@synthesize employeeName;
@synthesize employeeEmail;
@synthesize acceptedInvite;
@synthesize masterPopoverController;

#define kReinviteTag 0
#define kClockInClockOutTag 1

- (TimeEntry*)timeEntry {
    if (nil == _timeEntryObjectID) {
        return nil;
    }
    DataManager* manager = [DataManager sharedManager];
    NSError* error = nil;
    TimeEntry* result = (TimeEntry*)[manager existingObjectByID:_timeEntryObjectID error:&error];
    if (nil != error) {
        return nil;
    }
    return result;
}


-(void) LoadData{
    inviteCalledFlag = NO;
    employeeNameLabel.text = employeeName;
    _emailLabel.text = employeeEmail;
    
    //if the invite is accepted no need to show a different message
    inviteInfoLabel.textColor=[UIColor lightGrayColor];
    if ([acceptedInvite boolValue]) {
        inviteInfoLabel.text = [[NSString alloc] initWithFormat:@"%@", @"employee has accepted the invite"];
    }
    else{
        inviteInfoLabel.text = [[NSString alloc] initWithFormat:@"%@", @"employee has not accepted the invite"];
        
    }
    //reset the inivte button
    inviteButton.enabled = YES;
    [inviteButton setTitle:@"Re-invite employee to the app" forState:UIControlStateDisabled];
    inviteButton.alpha = 1;
    
    ABRecordRef aContact = ABPersonCreate();
    if(ABPersonHasImageData(aContact))
    {
        UIImage *image = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageData(aContact)];
        employeeImage.image = image;
    }
    
    
    //   ABAddressBookRef addressBook = ABAddressBookCreate();
    // Search for the person named "Appleseed" in the address book
    //	NSArray *people = (__bridge NSArray *)ABAddressBookCopyPeopleWithName(addressBook, CFSTR("employeeName"));
    // Display "Appleseed" information if found in the address book 
    //	if ((people != nil) && [people count])
    //	{
    //		ABRecordRef person = (__bridge ABRecordRef)[people objectAtIndex:0];
    //       UIImage  *img = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail)];
    //        employeeImage.image = img;
    //    }
    
    //dismiss popover if you are iPad
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (self.masterPopoverController != nil){
            [self.masterPopoverController dismissPopoverAnimated:YES];
        }
    }
    
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.title = NSLocalizedString(@"Manage", @"Manage");
        self.tabBarItem.image = [UIImage imageNamed:@"user"];
    }
    
    return self;
}


- (void)viewDidLoad
{
    self.view.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    
    _topView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _inviteBtnView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _inviteInfoView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _clockBtnsView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
#ifdef IPAD_VERSION
    _clockLabelsView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
#endif
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //color the buttons
    
    _clockInBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    _clockOutBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    _clockInLabel.hidden = YES;
    _clockOutLabel.hidden = YES;
    _breakInLabel.hidden = YES;
    _jobLabel.hidden = YES;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClockStatusNotification:)
     
                                                 name:kCheckClockStatusNotification object:nil];
    
    
}
- (void)checkClockStatusNotification:(NSNotification*)notification {
    [self checkClockStatus];
}

- (void)viewDidUnload
{
    [self setEmployeeNameLabel:nil];
    //    [self setinviteInfoLabel:nil];
    [self setEmployeeImage:nil];
    [self setInviteButton:nil];
    [self setEmailLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    self.parentViewController.navigationItem.rightBarButtonItems = nil;
    [self.parentViewController.navigationItem setTitle:employeeName];
    
    [self LoadData];
    
    [self checkClockStatus];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


-(void)doBreakInSteps{
    [self startSpinnerWithMessage:@"Recording Break.."];
    NSNumber* _selectedJobCodeId = nil;
    //if the employee has a primary job code then send that else send the one they selected which should  be the value of the job text field
 /*   if (![NSNumber isNilOrNull:primaryJobCodeId])
        _selectedJobCodeId = primaryJobCodeId;
    else
    {
        //if we have a job code selected
        if (![NSString isNilOrEmpty:_jobCodeTextField.text])
            [self getSelectedJobCode];
        if (![NSDictionary isNilOrNull:selectedJobCode])
            _selectedJobCodeId = [selectedJobCode valueForKey:@"id"];
    }
    */
    lastBreakInTime =  [NSDate date];
   // strLastBreakInTime = [formatterDateTime12hr stringFromDate:lastBreakInTime];
    if (![NSDictionary isNilOrNull:_primaryJobCode])
        _selectedJobCodeId = [selectedJobCode valueForKey:@"id"];

    _clockWebServices = [[ClockWebServices alloc] init];
    _clockWebServices.delegate = self;
    UserClass *user = [UserClass getInstance];
    [_clockWebServices callTCSWebService:BreakModeIn timeEntryObjectID:nil dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];
    

}

-(void)doBreakOutSteps{
    NSNumber* _selectedJobCodeId = nil;
    //if the employee has a primary job code then send that else send the one they selected which should  be the value of the job text field
    if (![NSDictionary isNilOrNull:_primaryJobCode])
        _selectedJobCodeId = [selectedJobCode valueForKey:@"id"];

    _clockWebServices = [[ClockWebServices alloc] init];
    _clockWebServices.delegate = self;
    UserClass *user = [UserClass getInstance];
    

    [self startSpinnerWithMessage:@"Connecting to Server.."];
    DataManager* manager = [DataManager sharedManager];
    NSError* error = nil;
    NSManagedObjectID* __timeEntryObjectID;
    __timeEntryObjectID = _timeEntryObjectID;
    //make sure the timeEntry we pass on is a break
    if (nil != _timeEntryObjectID)
    {
        TimeEntry* __timeEntry = (TimeEntry*)[manager existingObjectByID:_timeEntryObjectID error:&error];
        if ((![NSString isNilOrEmpty:__timeEntry.timeEntryType]) && (![NSString isEquals:__timeEntry.timeEntryType dest: kBreakTimeEntryType]))
        {
            __timeEntry = [manager fetchMostRecentTimeEntry:&error];
            //check again
            if ((![NSString isNilOrEmpty:__timeEntry.timeEntryType]) && (![NSString isEquals:__timeEntry.timeEntryType dest: kBreakTimeEntryType]))
                __timeEntryObjectID = nil;
            else
            __timeEntryObjectID = __timeEntry.objectID;
            
        }
        
    }
    [_clockWebServices callTCSWebService:BreakModeOut timeEntryObjectID:__timeEntryObjectID dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];

}

- (IBAction)doClockIn:(id)sender {
    if ([_clockInBtn.titleLabel.text isEqualToString:@"Break"])
    {
         [self doBreakInSteps];
    }
    else
        if ([_clockInBtn.titleLabel.text isEqualToString:@"End Break"])
        {
             [self doBreakOutSteps];
        }
        else
        {
            //if the employee does not have a primary job code
            if ([NSDictionary isNilOrNull:_primaryJobCode] && ([jobsList count] > 0))
                [self showJobCodesPicker];
            else
                [self doClockInSteps];
        }
}

- (IBAction)doClockOut:(id)sender {
    [self doClockOutSteps];
    
}

- (IBAction)doInvite:(id)sender {
    inviteCalledFlag = YES;
    [self startSpinnerWithMessage:@""];
    [self callEmployeeReInviteWebService];
}




/*-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
 {
 if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
 NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
 if (statusCode == SERVICE_UNAVAILABLE_ERROR){
 [self stopSpinner];
 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
 
 //error 503 is when tomcat is down
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
 [alert show];
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
 //just assume it went through
 //    [self stopSpinner];
 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
 
 UIAlertView *alert;
 NSError *error = nil;
 NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
 NSString *resultMessage = [results valueForKey:@"message"];
 if (![resultMessage isEqualToString:@"Success"])
 {
 alert = [[UIAlertView alloc] initWithTitle:nil message:@"Failure to Send Invite Message" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
 [alert show];
 }
 
 
 }
 - (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
 {
 // release the connection, and the data object
 // receivedData is declared as a method instance elsewhere
 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
 [self stopSpinner];
 
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
 
 [alert show];
 
 connection = nil;
 data = nil;
 }
 */

-(void) callEmployeeReInviteWebService{
    [self callEmployeeReInviteAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
        [self stopSpinner];
        if (aErrorCode != 0) {
            [ErrorLogging logErrorWithDomain:@"EMAIL" code:UNKNOWN_ERROR description:@"ERROR_SENDING_EMAIL" error:aError];
            [SharedUICode messageBox:nil message:@"There was an error sending the email. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        else
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            [inviteButton setTitle:@"An invite email has been sent" forState:UIControlStateDisabled];
            inviteButton.enabled = NO;
            inviteButton.alpha = 0.5;
        }
        
    }];
    
}

-(void) callEmployeeReInviteAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    NSString *request_body;
    
    //need to change it to this
    /*
     UserClass *user = [UserClass getInstance];
       httpPostString = [NSString stringWithFormat:@"%@api/v1/employee/reinvite/%@/%@", SERVER_URL, employeeID, user.employerID];
       
       NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
       request_body = [NSString
                       stringWithFormat:@"authToken=%@&emailAddress=%@",
                       [user.authToken  stringByAddingPercentEncodingWithAllowedCharacters: set],
                       [ employeeEmail  stringByAddingPercentEncodingWithAllowedCharacters: set
                        ]];
    
     
     */
    UserClass *user = [UserClass getInstance];
    httpPostString = [NSString stringWithFormat:@"%@employee/reinvite/%@/%@", SERVER_URL, employeeID, user.employerID];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    request_body = [NSString
                    stringWithFormat:@"authToken=%@&emailAddress=%@",
                    [user.authToken  stringByAddingPercentEncodingWithAllowedCharacters: set],
                    [ employeeEmail  stringByAddingPercentEncodingWithAllowedCharacters: set
                     ]];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    //set HTTP Method
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    
    //set request body into HTTPBody.
    [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    
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
/*-(void) callEmployeeReInviteWebService{
 
 NSString *httpPostString;
 NSString *request_body;
 
 httpPostString = [NSString stringWithFormat:@"%@employee/reinvite/%@/%@", SERVER_URL, employeeID, user.employerID];
 
 NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
 request_body = [NSString 
 stringWithFormat:@"authToken=%@&emailAddress=%@",
 [user.authToken  stringByAddingPercentEncodingWithAllowedCharacters: set],
 [ employeeEmail  stringByAddingPercentEncodingWithAllowedCharacters: set
 ]];   
 
 
 NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
 
 
 //set HTTP Method
 [urlRequest setHTTPMethod:@"POST"];
 [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
 
 //set request body into HTTPBody.
 [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
 
 //set request url to the NSURLConnection
 NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
 if (connection)
 {
 [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
 [inviteButton setTitle:@"An invite email has been sent" forState:UIControlStateDisabled];
 inviteButton.enabled = NO;
 inviteButton.alpha = 0.5;
 }
 else {
 UIAlertController * alert = [UIAlertController
 alertControllerWithTitle:@"ERROR"
 message:@"ezClocker is unable to connect to the server at this time. Please try again later"
 preferredStyle:UIAlertControllerStyleAlert];
 
 UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
 
 [alert addAction:defaultAction];
 
 [self presentViewController:alert animated:YES completion:nil];
 
 // alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
 //[alert show];
 
 }
 
 
 }
 */

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Employees", @"Employees");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

-(void) enableButton:(UIButton*) curBtn {
    //make sure the button is set to enabled
    curBtn.enabled = TRUE;
    curBtn.alpha = 1.0f;
    [[curBtn layer] setCornerRadius:4.0f];
    if ([curBtn.titleLabel.text isEqualToString:@"Break"] || ([curBtn.titleLabel.text isEqualToString:@"End Break"]))
        curBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);
    else
        curBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    
  
}

-(void) disableButton:(UIButton*) curBtn{
    //[[clockInBtn layer] setMasksToBounds:YES];
    [[curBtn layer] setCornerRadius:7.0f];
    [[curBtn layer] setBorderWidth:0.5f];
    curBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    
    //remove the Gradient layer which gave use the blue color shades
    CALayer* layer = [curBtn.layer valueForKey:@"GradientLayer"];
    [layer removeFromSuperlayer];
    [curBtn.layer setValue:nil forKey:@"GradientLayer"];
    
    //diable the button
    curBtn.enabled = FALSE;
    curBtn.alpha = 0.5f;
    [curBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
}


#pragma mark - Clock In and Clock Out Methods for sending information to the server
-(void)doClockInSteps{
    CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking in")
    
    [self startSpinnerWithMessage:@"Clocking in.."];
    
    _clockWebServices = [[ClockWebServices alloc] init];
    _clockWebServices.delegate = self;
    
    NSNumber *jobCodeId = [_primaryJobCode valueForKey:@"id"];
    if ([NSNumber isNilOrNull:jobCodeId])
    {
        //if the employee has a list of assigned jobs then pick the one they selected
        if ([jobsList count] > 0)
            jobCodeId = [selectedJobCode valueForKey:@"id"];
        else
            jobCodeId = nil;
    }
    [CommonLib logEvent:@"Clock in"];
    [_clockWebServices callTCSWebService:ClockModeIn timeEntryObjectID:nil dateTime:[NSDate date] jobCodeId: jobCodeId employeeID: employeeID locOverride:YES];
    
}

-(void) doClockOutSteps{
    CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking out")
    
    [self startSpinnerWithMessage:@"Clocking out.."];
    
    _clockWebServices = [[ClockWebServices alloc] init];
    _clockWebServices.delegate = self;
    
    [CommonLib logEvent:@"Clock out"];
    

    NSManagedObjectID* __timeEntryObjectID;
    __timeEntryObjectID = _timeEntryObjectID;
    //make sure the timeEntry we pass on is a normal time entry and not a break
    if (nil != _timeEntryObjectID)
    {
        TimeEntry* __timeEntry = (TimeEntry*)[manager existingObjectByID:_timeEntryObjectID error:&error];
        if ((![NSString isNilOrEmpty:__timeEntry.timeEntryType]) && ([NSString isEquals:__timeEntry.timeEntryType dest: kBreakTimeEntryType]))
        {
            __timeEntry = [manager fetchMostRecentNormalTimeEntry:&error];
            if (__timeEntry != nil)
                __timeEntryObjectID = __timeEntry.objectID;
        }
    }

    [_clockWebServices callTCSWebService:ClockModeOut timeEntryObjectID:__timeEntryObjectID dateTime:[NSDate date] jobCodeId: nil employeeID: employeeID  locOverride:YES];
    
}
//this is the callback that comes from the clock in/out web service. The error code will tell us what to do
- (void)clockServiceCallDidFinish:(ClockWebServices *)controller timeEntryRec:(NSDictionary*)timeEntryRec ErrorCode: (int) errorValue resultMessage: (NSString *) resultMessage ClockMode: (ClockMode) clockMode
{
    [self stopSpinner];
    UserClass *user = [UserClass getInstance];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (errorValue == SERVICE_ERRORCODE_SUCCESSFUL){
        TimeEntry* aTimeEntry = nil;
        if (nil != timeEntryRec) {
            DEBUG_MSG
            NSNumber *timeEntryId = [timeEntryRec valueForKey:@"id"];
            NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);
            NSError* error = nil;
            user.activeTimeEntryId = timeEntryId;
            DataManager* dataManager = [DataManager sharedManager];
            aTimeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];
            if (clockMode == BreakModeIn)
            {
                strLastBreakInTime = [aTimeEntry.clockIn.dateTimeEntry toLongDateTimeString];
                isActiveBreakIn = TRUE;
            }
            else if (clockMode == BreakModeOut)
            {
                isActiveBreakIn = FALSE;
                strLastBreakInTime = @"";
            }
            else if (clockMode == ClockModeIn)
                isActiveClockIn = TRUE;
            else
                isActiveClockIn = FALSE;
        }
        [self determineClockInOrClockOut:aTimeEntry];
    }
    //if error code = 1 that means that person has already clocked in from the website so
    else if (errorValue  == SERVICE_ERRORCODE_ALREADY_CLOCKED_IN){
        [ErrorLogging logErrorWithDomain:@"CLOCK_SERVICE" code:SERVICE_ERRORCODE_ALREADY_CLOCKED_IN description:@"SERVICE_ERRORCODE_ALREADY_CLOCKED_IN" error:nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Employee is already clocked in."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self checkClockStatus];
            
        }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    //if error code = 2 that means that person has already clocked out from the website so
    else if (errorValue  == SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT){
        [ErrorLogging logErrorWithDomain:@"CLOCK_SERVICE" code:SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT description:@"SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT" error:nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Employee is already clocked out."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self checkClockStatus];
        }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    //if error code = 8 that means that person has already taken a break from the website so
    else if (errorValue  == SERVICE_ERRORCODE_ALREADY_BREAKED_IN){
        [ErrorLogging logErrorWithDomain:@"CLOCK_SERVICE" code:SERVICE_ERRORCODE_ALREADY_BREAKED_IN description:@"SERVICE_ERRORCODE_ALREADY_BREAKED_IN" error:nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Employee is already on break."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self checkClockStatus];
            
        }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    //if error code = 9 that means that person has already ended their break from the website so
    else if (errorValue  == SERVICE_ERRORCODE_ALREADY_BREAKED_OUT){
        [ErrorLogging logErrorWithDomain:@"CLOCK_SERVICE" code:SERVICE_ERRORCODE_ALREADY_BREAKED_OUT description:@"SERVICE_ERRORCODE_ALREADY_BREAKED_OUT" error:nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Employee has already ended their break."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self checkClockStatus];
        }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }

    else if (errorValue == SERVICE_ERRORCODE_EARLYCLOCKIN) {
        [ErrorLogging logErrorWithDomain:@"CLOCK_SERVICE" code:SERVICE_ERRORCODE_EARLYCLOCKIN description:@"SERVICE_ERRORCODE_EARLYCLOCKIN" error:nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:resultMessage
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    
    else {
        //else if (errorValue == SERVICE_UNAVAILABLE_ERROR) {
        [self determineClockInOrClockOut:nil];
    }
    _clockWebServices = nil;
}

static BOOL checkingClockStatus = false;

-(void) checkClockStatus{
    if (checkingClockStatus) { // prevent multiple calls to checkClockStatus being called within this view because checkClockStatus below is async
        return;
    }
    UserClass *user = [UserClass getInstance];
    checkingClockStatus = TRUE;
    [self startSpinnerWithMessage:@"Connecting to Server.."];
    
    DataManager* manager = [DataManager sharedManager];
    while ([manager isBusy]) {
        sleep(1);
    }
    [manager checkClockStatus:employeeID withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
        [self stopSpinner];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        //if no error
        if ((errorCode == SERVICE_ERRORCODE_SUCCESSFUL) && (![NSDictionary isNilOrNull:results]))
        {
            NSDictionary *activeBreakRec = [results valueForKey:@"activeBreak"];
            if (![NSDictionary isNilOrNull:activeBreakRec]){
                NSString *breakInTime = [activeBreakRec valueForKey:@"clockInIso8601"];
                breakInTime  = [breakInTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                
                formatterISO8601DateTime = [[NSDateFormatter alloc] init];
                [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                [formatterISO8601DateTime setTimeZone:[NSTimeZone localTimeZone]];
                formatterDateTime12hr = [[NSDateFormatter alloc] init];
                [formatterDateTime12hr setDateFormat:kLongDateTimeFormat];
                [formatterDateTime12hr setTimeZone:[NSTimeZone localTimeZone]];
                
                lastBreakInTime = [formatterISO8601DateTime dateFromString:breakInTime];
                strLastBreakInTime = [formatterDateTime12hr stringFromDate:lastBreakInTime];
                isActiveBreakIn = [[activeBreakRec valueForKey:@"isActiveBreak"] boolValue];
            }
           
            else
                isActiveBreakIn = FALSE;

            NSDictionary *timeEntryRec;
            timeEntryRec = [results valueForKey:@"clockInOutState"];
            if ([NSDictionary isNilOrNull:timeEntryRec])
            {
                timeEntryRec = [results valueForKey:@"latestTwoWeeksTimeEntry"];

            }

            NSArray *jobCodesFromServer = [results valueForKey:@"dataTags"];
            jobsList = [[NSMutableArray alloc] init];
            NSNumber *jobCodeId;
            NSString *jobCodeName;
            NSMutableDictionary *_jobCode;
            
            for (NSDictionary *jobCode in jobCodesFromServer){
                
                jobCodeId = [jobCode valueForKey:@"id"];
                jobCodeName = [jobCode valueForKey:@"tagName"];//tagId
                
                _jobCode = [[NSMutableDictionary alloc] init];
                @try{
                    [_jobCode setValue:jobCodeId forKey:@"id"];
                    [_jobCode setValue:jobCodeName forKey:@"name"];
                }
                @catch(NSException* ex) {
                    NSLog(@"Exception in setting JobCodes from Server: %@", ex);
                }
                
                [jobsList addObject:_jobCode];
                
            }
            
            //  if (![NSDictionary isNilOrNull:timeEntryRec]) {
            
            if (![NSDictionary isNilOrNull:timeEntryRec]) {
                DEBUG_MSG
                isActiveClockIn = [[timeEntryRec valueForKey:@"isActiveClockIn"] boolValue];
//                if (isActiveClockIn)
//                    strLastClockInTime =
                    //        strLastClockInTime = [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString];
                
                NSString *clockInTime = [timeEntryRec valueForKey:@"clockInIso8601"];
                clockInTime  = [clockInTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                
                formatterISO8601DateTime = [[NSDateFormatter alloc] init];
                [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                [formatterISO8601DateTime setTimeZone:[NSTimeZone localTimeZone]];
                
                formatterDateTime12hr = [[NSDateFormatter alloc] init];
                [formatterDateTime12hr setDateFormat:kLongDateTimeFormat];
                [formatterDateTime12hr setTimeZone:[NSTimeZone localTimeZone]];
                
                NSDate *lastClockInTime = [formatterISO8601DateTime dateFromString:clockInTime];
                strLastClockInTime = [formatterDateTime12hr stringFromDate:lastClockInTime];
                
                lastJobName = [timeEntryRec valueForKey:@"jobName"];
                if ([NSString isNilOrEmpty:lastJobName])
                    lastJobName = @"";
                
                NSNumber *timeEntryId = [timeEntryRec valueForKey:@"id"];
                NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);
                user.activeTimeEntryId = timeEntryId;
                
                NSError* error = nil;
                DataManager* dataManager = [DataManager sharedManager];
                
                TimeEntry* aTimeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];
                [self determineClockInOrClockOut:aTimeEntry];
            } else {
                [self determineClockInOrClockOut:nil];
            }
        } else {
            [self determineClockInOrClockOut:nil];
        }
        checkingClockStatus = FALSE;
    }];
}

//this gets called after you select a job from the jobs list
- (void)searchJobCode:(NSDictionary *)jobCodeObj {
    
    selectedJobCode = jobCodeObj;
    [self doClockInSteps];
    /*    _jobCodeTextField.text = [jobCodeObj valueForKey:@"name"];
     selectedJobCode = jobCodeObj;
     //if clock out button is enabled then that means we are in active clock in and we need to update the selected job code on the server
     if (clockOutBtn.enabled)
     [self assignSelectedJobCode ];
     else
     [self doClockInSteps];
     */
}

-(void) showJobCodesPicker{
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    UINavigationController *viewController = [story instantiateViewControllerWithIdentifier:@"jobCodeList"];
    JobCodeListViewController * controller = viewController.viewControllers.firstObject;
    controller.jobCodes = jobsList;
    controller.delegate = self;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)determineClockInOrClockOut:(TimeEntry*)aTimeEntry {
    UserClass *user = [UserClass getInstance];
    TimeEntry* __timeEntry = aTimeEntry;
    if (nil == __timeEntry) {
        DataManager* manager = [DataManager sharedManager];
        NSError* error = nil;
        __timeEntry = [manager fetchMostRecentTimeEntry:&error];
        if (nil != error) {
#ifndef RELEASE
            NSLog(@"error fetching most recent time entry - %@", error.localizedDescription);
            [ErrorLogging logError:error];
#endif
            __timeEntry = nil;
        }
    }
    if ((nil == __timeEntry) || (!__timeEntry.clockIn && !__timeEntry.clockOut)) {
        user.lastClockIn = @"";
        user.lastClockOut = @"";
        [self enableClockIn];
        user.currentClockMode = ClockModeIn;
        user.activeTimeEntryId = nil;
        self.timeEntryObjectID = nil;
        return;
    }
    self.timeEntryObjectID = __timeEntry.objectID;
    NSNumber* timeEntryID = __timeEntry.timeEntryID;
    if ([NSNumber isNilOrNull:timeEntryID]) {
        user.activeTimeEntryId = nil;
    } else if ((user.activeTimeEntryId == nil) || (![NSNumber isEquals:timeEntryID dest:user.activeTimeEntryId])) {
        user.activeTimeEntryId = timeEntryID;
    }
    //bug
    // Check clockOut if there is one enable clock in
    if (!isActiveClockIn)
    {
        [self enableClockIn];
        user.lastClockIn = @"";
        user.lastClockOut = [__timeEntry.clockOut.dateTimeEntry toLongDateTimeString];
        user.currentClockMode = ClockModeIn;
    }
    else
    {
        user.lastClockOut = @"";
        //check to see if we are on Break by checking if the time entry is of type Break and if it is not then get the strLastClockIntime value
        if (([NSString isNilOrEmpty:__timeEntry.timeEntryType]) || (![__timeEntry.timeEntryType isEqualToString:kBreakTimeEntryType]))
        {
            strLastClockInTime = [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString];
            user.lastClockIn = strLastClockInTime;


            NSNumber *selectedJobId = __timeEntry.jobCodeId;
            NSNumber *jobIdFromList;
            if (!([NSNumber isNilOrNull:selectedJobId]) && selectedJobId > 0 && ([jobsList count] > 0))
            {
                for (NSDictionary *jobCode in jobsList){
                    jobIdFromList = [jobCode valueForKey:@"id"];
                    if ([jobIdFromList intValue] == [selectedJobId intValue])
                    {
                        lastJobName = [jobCode valueForKey:@"name"];
                        break;
                    }
                }
            }
            [self enableClockOut:strLastClockInTime];
        }
        if (isActiveBreakIn)
        {
            [_clockInBtn setTitle:@"End Break" forState:UIControlStateNormal];
            [self enableBreakOut];
        }
        else{
            NSNumber *isBreaksAllowed = user.employerOptions[@"ALLOW_RECORDING_OF_UNPAID_BREAKS"];
            if ([isBreaksAllowed boolValue])
            {
                [_clockInBtn setTitle:@"Break" forState:UIControlStateNormal];
                [self enableBreakIn];
            }
        }
        user.currentClockMode = ClockModeOut;
    }
 /*   if (__timeEntry.clockIn && __timeEntry.clockOut) {
        [self enableClockIn];
        user.lastClockIn = @"";
        user.lastClockOut = [__timeEntry.clockOut.dateTimeEntry toLongDateTimeString];
        user.currentClockMode = ClockModeIn;
    } else if (__timeEntry.clockIn) {
        user.lastClockOut = @"";
        NSString* strLastClockInTime = [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString];
        user.lastClockIn = strLastClockInTime;
        [self enableClockOut:strLastClockInTime];
        
        if (isActiveBreakIn)
        {
            [_clockInBtn setTitle:@"End Break" forState:UIControlStateNormal];
            [self enableBreakOut];
        }
        else{
            NSNumber *isBreaksAllowed = __user.employerOptions[@"ALLOW_RECORDING_OF_UNPAID_BREAKS"];
            if ([isBreaksAllowed boolValue])
            {
                if ([_clockInBtn.titleLabel.text isEqualToString:@"Break"]){
                    [_clockInBtn setTitle:@"End Break" forState:UIControlStateNormal];
                    [self enableBreakOut];
                }
                else
                {
                    [_clockInBtn setTitle:@"Break" forState:UIControlStateNormal];
                    [self enableBreakIn];
                }
            }
        }
        user.currentClockMode = ClockModeOut;
    }
  */
}

- (void)enableBreakIn{
        _breakInLabel.hidden = YES;
        _breakInLabel.text = @"";
        [_clockInBtn setTitle:@"Break" forState:UIControlStateNormal];
        [self enableButton:_clockInBtn];

}

- (void)enableBreakOut{
        _breakInLabel.hidden = NO;
        _breakInLabel.text = [NSString stringWithFormat:@"Break In: %@", strLastBreakInTime];
        [_clockInBtn setTitle:@"End Break" forState:UIControlStateNormal];
        [self enableButton:_clockInBtn];

}

//this is the callback that comes from the clock status web service. The error code will tell us what to do
- (void)checkClockStatusServiceCallDidFinish:(CheckClockStatusWebService *)controller timeEntryRec:(NSDictionary *)timeEntryRec ErrorCode:(int)errorValue {
    
}

- (void)enableClockOut:(NSString*)clockTime {
    if (![NSString isNilOrEmpty:clockTime])
    {
        _clockInLabel.hidden = NO;
        _clockInLabel.text = [NSString stringWithFormat:@"Clock In: %@", clockTime]; //[NSString stringWithFormat:@"Clock In: %@", clockTime];
        if (![NSString isNilOrEmpty:lastJobName])
        {
            _jobLabel.hidden = NO;
            _jobLabel.text = [NSString stringWithFormat:@"Job Name: %@", lastJobName];
        }
        _clockOutLabel.hidden = YES;
        [self enableButton:_clockOutBtn];
        [self disableButton:_clockInBtn];
        
    }
    else{
        [self enableClockIn];
    }
}

- (void)enableClockIn {
    _clockInLabel.hidden = YES;
    _clockOutLabel.hidden = YES;
    _breakInLabel.hidden = YES;
    _jobLabel.hidden = YES;
    [_clockInBtn setTitle:@"Clock In" forState:UIControlStateNormal];
    [self enableButton:_clockInBtn];
    [self disableButton:_clockOutBtn];
}


- (void)dealloc {
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}



@end
