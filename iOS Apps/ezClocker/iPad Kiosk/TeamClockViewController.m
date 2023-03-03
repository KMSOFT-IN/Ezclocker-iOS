//
//  TeamClockViewController.m
//  ezClocker Kiosk
//
//  Created by Raya Khashab on 1/12/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import "TeamClockViewController.h"
#import "CommonLib.h"
#import "NSDate+Extensions.h"
#import "ClockWebServices.h"
#import "CheckClockStatusWebService.h"
#import "DataManager.h"
#import "SharedUICode.h"
#import "debugdefines.h"
#import "user.h"
#import "completionblockdefines.h"
#import "NSData+Extensions.h"
#import "NSDictionary+Extensions.h"
#import "threaddefines.h"
#import "coredatadefines.h"
#import "NSNumber+Extensions.h"
#import "ClockInfo+CoreDataProperties.h"
#import "NSString+Extensions.h"


@interface TeamClockViewController ()
@property (nonatomic, retain) ClockWebServices* clockWebServices;
@property (nonatomic, copy) NSManagedObjectID* timeEntryObjectID;
@property (weak, nonatomic) IBOutlet UIView *popupInsideView;
@property (strong, nonatomic) IBOutlet UIView *popUpView;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@property (weak, nonatomic) IBOutlet UIView *popupNotesInsideView;
@property (weak, nonatomic) IBOutlet UIView *popupNotesView;
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;

@end

@implementation TeamClockViewController
#define ksetJobCodeViewNotification @"setJobCodeView"
#define TIME_OUT 60
NSNumber *employerID;
NSNumber *employeeID;
static BOOL checkingClockStatus = false;
NSTimer *timer;
NSInteger count = 60;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Tap to pick a job code" attributes:@{ NSForegroundColorAttributeName : [UIColor systemBlueColor] }];
    self.jobCodeTextField.attributedPlaceholder = str;
    
    _jobCodeView.hidden = FALSE;
    self.jobCodeTextField.delegate = self;
    _popupInsideView.layer.borderColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR).CGColor;
    _popupInsideView.layer.borderWidth = 2;
    _popupInsideView.layer.cornerRadius = 10;
    
    
    _popupNotesInsideView.layer.cornerRadius = 10;
    
    _signOutBtn.backgroundColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
    [_signOutBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_signOutBtn setTitle:@"Sign Out" forState:UIControlStateNormal];

    
    isActiveClockIn = [[_employeeClockInfo valueForKey:@"isClockedIn"] boolValue];
    isActiveBreak = [[_employeeClockInfo valueForKey:@"isActiveBreak"] boolValue];
    if (isActiveBreak)
    {
       NSString *breakInTimeStr = [_employeeClockInfo valueForKey:@"breakInTime"];
        breakInTimeStr  = [breakInTimeStr stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
        NSDateFormatter *formatterISO8601DateTime = [[NSDateFormatter alloc] init];
        [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatterISO8601DateTime setTimeZone:[NSTimeZone localTimeZone]];

        breakInTime = [formatterISO8601DateTime dateFromString:breakInTimeStr];
    }
    allowRecordingOfUnpaidBreaks = [[_employeeClockInfo valueForKey:@"allowRecordingOfUnpaidBreaks"] boolValue];

    if (isActiveBreak)
        _breakDurationLabel.text = @"Break Total Duration:";
    else
        _breakDurationLabel.hidden = true;
    
    _leftHandView.backgroundColor = UIColorFromRGB(LOGO_ORANGE_COLOR);
    _leftHandTopView.backgroundColor = UIColorFromRGB(LOGO_ORANGE_COLOR);

    UserClass *user = [UserClass getInstance];
    employerID = user.employerID;
    employeeID = user.userID;
  //  [self getAllJobCodes];
    jobCodesList = [_employeeClockInfo valueForKey:@"jobsList"];
    
    
    formatterTime = [[NSDateFormatter alloc] init];
    [formatterTime setDateFormat:@"h:mm a"];
    [formatterTime setTimeZone:[NSTimeZone localTimeZone]];
    
    formatterDate = [[NSDateFormatter alloc] init];
    [formatterDate setDateFormat:kEEEMMddFormat];
    [formatterDate setTimeZone:[NSTimeZone localTimeZone]];

    _mainActionBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    _rightHandView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _bottomView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _breakDurationView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    [_mainActionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_mainActionBtn setTitle:@"Clock In" forState:UIControlStateNormal];
    
    _secondaryActionBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    _rightHandView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _bottomView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    [_secondaryActionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_secondaryActionBtn setTitle:@"Clock Out" forState:UIControlStateNormal];

    _topLabel.text = [NSString stringWithFormat:@"Welcome %@!", user.employeeName];
    [_topLabel sizeToFit];
    
    _employeeNameLabel.text = user.employeeName;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)  {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(orientationChanged:)
         name:UIDeviceOrientationDidChangeNotification
         object:[UIDevice currentDevice]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setJobCodeViewIsHidden:)
         
                                                     name:ksetJobCodeViewNotification object:nil];
    _breakDurationView.hidden = true;
    if (isActiveClockIn)
    {
        //if we are currently clocked in the check to see if we are allowed to take breaks if we are then check to see are we currently on break or not
        if (allowRecordingOfUnpaidBreaks)
        {
            if (!isActiveBreak)
            {
                [_mainActionBtn setTitle:@"Start Break" forState:UIControlStateNormal];
                _mainActionBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);
                _secondaryActionBtn.hidden = false;
               
            }
            else{
                [_mainActionBtn setTitle:@"End Break" forState:UIControlStateNormal];
                _mainActionBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);
                _secondaryActionBtn.hidden = true;
                _breakDurationLabel.text = @"Break Total Duration:";
                _breakDurationView.hidden = false;
            }
        }
        else{
            [_mainActionBtn setTitle:@"Clock Out" forState:UIControlStateNormal];
            _secondaryActionBtn.hidden = true;
        }
        _lastClockInLabel.text =  [_employeeClockInfo valueForKey:@"clockInTime"];
    }
    else
    {
        [_mainActionBtn setTitle:@"Clock In" forState:UIControlStateNormal];
        _lastClockInLabel.text =  [_employeeClockInfo valueForKey:@"clockInTime"];
        _lastClockOutLabel.text =  [_employeeClockInfo valueForKey:@"clockOutTime"];
        _secondaryActionBtn.hidden = true;
    }
    
    _selectedJobCode = [_employeeClockInfo valueForKey:@"selectedJobCode"];
    if (![NSDictionary isNilOrNull:_selectedJobCode])
        _jobCodeTextField.text = [_selectedJobCode valueForKey:@"tagName"];;
    
    
    
 /*   if ([_lastClockInLabel.text isEqualToString:@""]) {
        [self getPrimaryJobCode:1 withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
            NSDictionary *dic = results[@"employee"];
            NSString *primaryJobCode = @"";
            primaryJobCodeId = dic[@"primaryJobCodeId"];
            if (![NSNumber isNilOrNull:primaryJobCodeId])
                primaryJobCode = [dic[@"primaryJobCodeId"] stringValue];
            
            [self getSelectedJobCodeID:primaryJobCode];
        }];
    }
  */
    

}
const int GET_ALL_JOB_CODES = 1;
-(void) getAllJobCodes
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callJobCodesAPI:GET_ALL_JOB_CODES withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
//        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            //save all the values we got back to the employeeDetails object so we can keep track of what changed
            [jobCodesList removeAllObjects];
            UserClass *user = [UserClass getInstance];
            [user.jobCodesList removeAllObjects];
            NSNumber *jobCodeId;
            NSString *jobCodeName;
            NSString *jobCodeIdDescription;
       //     NSString *jobCodeDisplayValue;
            NSString *hourlyRateValue;
            NSNumber *employeeId;
            NSMutableDictionary *_jobCode;
            NSArray *jobCodesFromServer = [aResults valueForKey:@"entities"];
            
            NSNumber *assignToAllEmployees;
            for (NSDictionary *jobCode in jobCodesFromServer){
                assignToAllEmployees = 0;
                jobCodeId = [jobCode valueForKey:@"id"];
                jobCodeName = [jobCode valueForKey:@"tagName"];//tagId
                jobCodeIdDescription = [jobCode valueForKey:@"description"];
              //  jobCodeDisplayValue = [jobCode valueForKey:@"displayValue"];
                hourlyRateValue = [jobCode valueForKey:@"value"];//used to be tagvalue
               // employeeId = [jobCode valueForKey:@"employeeId"];
                NSArray *assignedToEntities = [jobCode valueForKey: @"assignedToEntities"];
                NSMutableArray *assignedEmployeeList = [NSMutableArray new];
                for (NSDictionary *assignedEntity in assignedToEntities)
                {
                    NSDictionary *assignedEzEntity = [assignedEntity valueForKey: @"assignedEzEntity"];
                    NSNumber *isPrimary = [assignedEntity valueForKey: @"level"];
                    if ([NSDictionary isNilOrNull:assignedEzEntity])
                    {
                       assignToAllEmployees = [NSNumber numberWithInt:1];
                    }
                    else{
                        NSDictionary *employeeObj = [[NSMutableDictionary alloc] init];
                        NSString *employeeName = [assignedEzEntity valueForKey:@"employeeName"];
                         [employeeObj setValue:employeeName forKey:@"employeeName"];
                        
                         [employeeObj setValue:[assignedEzEntity valueForKey:@"id"] forKey:@"employeeId"];
                        
                        [employeeObj setValue:isPrimary forKey:@"isPrimary"];

                        // [employeeObj setValue:employeeId forKey:@"employeeId"];
                        // [employeeObj setValue:isPrimary forKey:@"isPrimary"];
                         [assignedEmployeeList addObject:employeeObj];

                    }
                }
                
                _jobCode = [[NSMutableDictionary alloc] init];
                @try{
                    [_jobCode setValue:jobCodeId forKey:@"id"];
                    [_jobCode setValue:jobCodeName forKey:@"tagName"];
                    [_jobCode setValue:jobCodeIdDescription forKey:@"description"];
                  //  [_jobCode setValue:jobCodeDisplayValue forKey:@"displayValue"];
                    [_jobCode setValue:hourlyRateValue forKey:@"hourlyRateValue"];
                    [_jobCode setValue:assignToAllEmployees forKey:@"assignToAllEmployees"];
                    [_jobCode setValue:assignedEmployeeList forKey:@"assignedEmployeeList"];
                    
                }
                @catch(NSException* ex) {
                    NSLog(@"Exception in setting JobCodes from Server: %@", ex);
                }
                
                [jobCodesList addObject: _jobCode];
                [user.jobCodesList addObject:_jobCode];
                
            }
           
            NSString *count = [NSString stringWithFormat:@"%d",[jobCodesList count]];
            NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
            [dictionary setValue:count forKey:@"jobCodeCount"];
            [NSNotificationCenter.defaultCenter postNotificationName: ksetJobCodeViewNotification object:nil userInfo:dictionary];
            
        }
    }];
    
}
-(void) callJobCodesAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    httpPostString = [NSString stringWithFormat:@"%@api/v1/datatags?ez-entity-type=EMPLOYEE", SERVER_URL];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];


    [urlRequest setHTTPMethod:@"GET"];

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

                MAINTHREAD_BLOCK_START()
                completion(errorCode, resultMessage, results, aError);
                THREAD_BLOCK_END()
                return;
            }];
        }
    }];
    [dataTask resume];
    
}
-(void)setJobCodeViewIsHidden:(NSNotification*)notification {
    
    NSDictionary* userInfo = notification.userInfo;
    int value = [userInfo[@"jobCodeCount"] intValue];
    if (value == 0) {
         _jobCodeView.hidden = TRUE;
    } else {
         _jobCodeView.hidden = FALSE;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.title = NSLocalizedString(@"Clock in/out", @"Clock in/out");
        self.tabBarItem.image = [UIImage imageNamed:@"clock"];

    }
    
    
    return self;
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self tick:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.popUpView.frame = self.view.bounds;
    _todayDateLabel.text =  [formatterDate stringFromDate:[NSDate date]];
    //figure out if we are currently clocked in or out so we can set the correct button
    UserClass *user = [UserClass getInstance];
//    if (isActiveClockIn)
//    {
//        [_mainActionBtn setTitle:@"Clock Out" forState:UIControlStateNormal];
//        _lastClockInLabel.text =  [_employeeClockInfo valueForKey:@"clockInTime"];
//    }
//    else
//    {
//        [_mainActionBtn setTitle:@"Clock In" forState:UIControlStateNormal];
//        _lastClockInLabel.text =  [_employeeClockInfo valueForKey:@"clockInTime"];
//        _lastClockOutLabel.text =  [_employeeClockInfo valueForKey:@"clockOutTime"];
//    }
    
    
    if ([user.jobCodesList count] == 0)
        _jobCodeView.hidden = TRUE;
    
    if(!running){
        running = TRUE;
        if (stopTimer == nil) {
            stopTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                                                         target:self
                                                       selector:@selector(updateTimer)
                                                       userInfo:nil
                                                        repeats:YES];
        }
    }else{
        running = FALSE;
        [stopTimer invalidate];
        stopTimer = nil;
    }

    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self runTimer];
    
 //   UserClass *user = [UserClass getInstance];
 //     if ([user.userID integerValue] > 0)
 //     {
 //         [self checkClockStatus];
 //     }
}

-(void) getPrimaryJobCode:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    UserClass *user = [UserClass getInstance];
    NSString *httpPostString;
    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/state/employee/%@", SERVER_URL, employeeID];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];


    [urlRequest setHTTPMethod:@"GET"];

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
                
//                MAINTHREAD_BLOCK_START()
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(errorCode, resultMessage, results, aError);
                });
//                THREAD_BLOCK_END()
                return;
            }];
        }
    }];
    [dataTask resume];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self timerInvalidate];
}

-(NSString*) getCurrentTime{
    NSString *currentDateTime = [formatterTime stringFromDate:[NSDate date]];
    return currentDateTime;
    
}

- (void) tick:(id)sender
{
    NSString *time = self.getCurrentTime;
    self.currentTimeLabel.text = time;
    [ self performSelector: @selector(tick:)
                withObject: nil
                afterDelay: 1.0
     ];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

-(void)doClockInSteps{

    [CommonLib logEvent:@"Clock in"];
    UserClass *user = [UserClass getInstance];

  //  CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking in")

    [self startSpinnerWithMessage:@"Clocking in.."];
    
  /*  NSNumber* _selectedJobCodeId = nil;
    //if we have a job code selected from a prev clock in/out then use that
    if (![NSString isNilOrEmpty:_jobCodeTextField.text])
        [self getSelectedJobCode];
    if (![NSDictionary isNilOrNull:selectedJobCode])
        _selectedJobCodeId = [selectedJobCode valueForKey:@"id"];
    */
    NSNumber* _selectedJobCodeId = nil;
    //if the employee has a primary job code then send that else send the one they selected which should  be the value of the job text field
    if (![NSNumber isNilOrNull:primaryJobCodeId])
        _selectedJobCodeId = primaryJobCodeId;
    else
    {
        //if we have a job code selected
        if (![NSString isNilOrEmpty:_jobCodeTextField.text])
            [self getSelectedJobCode];
        if (![NSDictionary isNilOrNull:_selectedJobCode])
            _selectedJobCodeId = [_selectedJobCode valueForKey:@"id"];
    }

    
    _clockWebServices = [[ClockWebServices alloc] init];
    _clockWebServices.delegate = self;
    [_clockWebServices callTCSWebService:ClockModeIn timeEntryObjectID:nil dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];
    self.notesTextView.text = @"";
}

-(void)doBreakInSteps{

    UserClass *user = [UserClass getInstance];

  //  CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking in")

    [self startSpinnerWithMessage:@"Taking Break.."];
    NSNumber* _selectedJobCodeId = nil;
    if (![NSDictionary isNilOrNull:_selectedJobCode])
        _selectedJobCodeId = [_selectedJobCode valueForKey:@"id"];
    
    _clockWebServices = [[ClockWebServices alloc] init];
    _clockWebServices.delegate = self;
    [_clockWebServices callTCSWebService:BreakModeIn timeEntryObjectID:nil dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];
    

}
-(void)getSelectedJobCode
{
    NSString *name;
    for (NSDictionary *jobCodeObj in jobCodesList)
    {
        name = [jobCodeObj valueForKey:@"tagName"];
        if ([name isEqualToString:_jobCodeTextField.text])
            _selectedJobCode = [jobCodeObj copy];
    }
}

-(void)getSelectedJobCodeID: (NSString *)jobId
{
    if (jobCodesList.count > 0) {
        for (NSDictionary *jobCodeObj in jobCodesList)
        {
            NSString *jobCodeId = [[jobCodeObj valueForKey:@"id"] stringValue];
            if ([jobId isEqualToString:jobCodeId]) {
                self.jobCodeTextField.text = [jobCodeObj valueForKey:@"tagName"];
                _selectedJobCode = jobCodeObj;
            }
        }
        [self stopSpinner];
    } else {
        [self stopSpinner];
    }
}

-(void) doClockOutSteps{
    CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking out")
    [CommonLib logEvent:@"Clock out"];
    [self startSpinnerWithMessage:@"Clocking out.."];
    
    DataManager* dataManager = [DataManager sharedManager];
    @try {
        [dataManager checkAndLoadEmployeeInfo:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
            
            _clockWebServices = [[ClockWebServices alloc] init];
            _clockWebServices.delegate = self;
            UserClass *user = [UserClass getInstance];
            
            TimeEntry* __timeEntry = self.timeEntry;
            
            [self determineClockInOrClockOut:__timeEntry];
            
            if (nil == _timeEntryObjectID) {
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"ezClocker had an issue with clocking out at this time. Please try again later."
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];

             //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker had an issue with clocking out at this time. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
              //  [alert show];
                return;
            }
            
            NSNumber* _selectedJobCodeId = nil;
            if (![NSDictionary isNilOrNull:_selectedJobCode])
                _selectedJobCodeId = [_selectedJobCode valueForKey:@"id"];
            
            [_clockWebServices callTCSWebService:ClockModeOut timeEntryObjectID:_timeEntryObjectID dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];
        }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    
}

-(void) doBreakOutSteps{
  //  CLOCK_IN_CLOCK_OUT_PENDING_UPDATES_CHECK(@"clocking out")
  //  [CommonLib logEvent:@"Clock out"];
    [self startSpinnerWithMessage:@"Ending Break.."];
    
    DataManager* dataManager = [DataManager sharedManager];
    @try {
        [dataManager checkAndLoadEmployeeInfo:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
            
            _clockWebServices = [[ClockWebServices alloc] init];
            _clockWebServices.delegate = self;
            UserClass *user = [UserClass getInstance];
            
            TimeEntry* __timeEntry = self.timeEntry;
            
            [self determineClockInOrClockOut:__timeEntry];
            
            if (nil == _timeEntryObjectID) {
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"ezClocker had an issue with clocking out at this time. Please try again later."
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];

             //   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker had an issue with clocking out at this time. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
              //  [alert show];
                return;
            }
            
            NSNumber* _selectedJobCodeId = nil;
            if (![NSDictionary isNilOrNull:_selectedJobCode])
                _selectedJobCodeId = [_selectedJobCode valueForKey:@"id"];
            
            [_clockWebServices callTCSWebService:BreakModeOut timeEntryObjectID:_timeEntryObjectID dateTime:[NSDate date] jobCodeId: _selectedJobCodeId employeeID: user.userID locOverride:YES];
        }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    
}

- (IBAction)doJobCodes:(id)sender {
    
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // We are now showing the UIPickerViewer instead
    
    // Close the keypad if it is showing
    [self.view.superview endEditing:YES];

    if ([_mainActionBtn.titleLabel.text isEqualToString:@"Clock Out"] || [_mainActionBtn.titleLabel.text isEqualToString:@"Start Break"])
        [self showJobCodesPicker];
    else
    {
        UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Error"
                                 message:@"You can not change a job after a clock out"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
        [alert addAction:defaultAction];
    
        [self presentViewController:alert animated:YES completion:nil];
    }

    return  NO;
}

-(void) showJobCodesPicker{
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    UINavigationController *viewController = [story instantiateViewControllerWithIdentifier:@"jobCodeList"];
    JobCodeListViewController * controller = viewController.viewControllers.firstObject;
    controller.delegate = self;
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)searchJobCode:(NSDictionary *)jobCodeObj {
    _jobCodeTextField.text = [jobCodeObj valueForKey:@"tagName"];
    _selectedJobCode = jobCodeObj;
    //if clock out button is enabled then that means we are in active clock in and we need to update the selected job code on the server
    
    if ([_mainActionBtn.titleLabel.text isEqualToString:@"Clock Out"]){
         [self assignSelectedJobCode];
    }
    else
        [self doClockInSteps];
}

-(void) assignSelectedJobCode
{
    //if we are offline don't call the server API to save the data
    BOOL bIsReachable = [CommonLib DoWeHaveNetworkConnection];
    if (bIsReachable)
        [self callModifyTimeEntryWebService];
    
 }
-(void) callModifyTimeEntryWebService{
    //NSString *currentDateTime = self.getCurrentDateTime;
    
    DataManager* manager = [DataManager sharedManager];
    TimeEntry* __timeEntry = self.timeEntry;
    if (nil == __timeEntry) {
        [SharedUICode messageBox:nil message:@"There was an issue with the Time Entry." withCompletion:^{
            return;
        }];
    }
    
    NSString *selectedJobCodeId = [_selectedJobCode valueForKey:@"id"];
    
    NSDate* clockInDateValue = __timeEntry.clockIn.dateTimeEntry;
    
    NSDate* clockOutDateValue = __timeEntry.clockOut.dateTimeEntry;
    if (__timeEntry == nil) {
        return;
    }
    
    NSString *notes = self.notesTextView.text;
    
    if ([NSString isNilOrEmpty:notes]) {
        notes = nil;
    }
    
    [self startSpinnerWithMessage:@"Connecting to Server.."];
    [manager modifyTimeEntryOnServer:__timeEntry clockIn:clockInDateValue clockOut:clockOutDateValue notes:notes jobCodeId: selectedJobCodeId partialTimeEntry: partialTimeEntryVal withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {

        [self stopSpinner];
        
        if (nil != results) { // If we had changed the date of the time entry that means it was moved so we need to check to see if the _timeEntryObjectID is different and update
            TimeEntry* timeEntry = [results objectForKey:ktimeEntryKey];
            NSManagedObjectID *obj1 = self.timeEntryObjectID;
            NSManagedObjectID *obj2 = timeEntry.objectID;
            if ((nil != timeEntry) && ![obj1 isEqual:obj2])
            {
                self.timeEntryObjectID = timeEntry.objectID;
            }
        }

        switch (errorCode) {
            case DATAMANAGER_BUSY: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:DATAMANAGER_BUSY description:@"DATAMANAGER_BUSY" error:error];
                [SharedUICode displayServerIsBusy];
                break;
            }
            case SERVICE_UNAVAILABLE_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_UNAVAILABLE_ERROR description:@"SERVICE_UNAVAILABLE_ERROR" error:error];
                [SharedUICode displayServiceUnavailableErrorWithMsg:@"NOTE: You can continue to modify time entries and we will save to the server later." withCompletion:^{
                    [DataManager postDataWasModifiedNotification];
  //                  [self.delegate saveTimeEntryDidFinish:self];
                }];
                break;
            }
            case SERVICE_ERRORCODE_UNKNOWN_ERROR: {
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:SERVICE_ERRORCODE_UNKNOWN_ERROR description:@"SERVICE_ERRORCODE_UNKNOWN_ERROR" error:error];
                [SharedUICode checkResultsMessageAndDisplayError:resultMessage error:error];
//[self showDatePicker];
                break;
            }
            case SERVICE_ERRORCODE_SUCCESSFUL: {
                [DataManager postDataWasModifiedNotification];
              //  [self updateUserClockInClockOut];
               // [self.delegate saveTimeEntryDidFinish:self];
                break;
            }
            default: {
#ifndef RELEASE
                DEBUG_MSG
                NSLog(@"Unhandled errorCode: %ld %@ %@", (long)errorCode, msg, error.localizedDescription);
                [ErrorLogging logErrorWithDomain:DATA_MANAGER_DOMAIN code:UNKNOWN_ERROR description:@"UNKNOWN_ERROR" error:error];
#endif
                break;
            }
        }
    }];


}

- (void)determineClockInOrClockOut:(TimeEntry*)aTimeEntry {
    bool endedBreak = FALSE;
    UserClass *user = [UserClass getInstance];
    TimeEntry* __timeEntry = aTimeEntry;

    if (nil == __timeEntry) {
        DataManager* manager = [DataManager sharedManager];
        NSError* error = nil;
        //we don't want breaks
        __timeEntry = [manager fetchMostRecentNormalTimeEntry:&error];
        if (nil != error) {
#ifndef RELEASE
            NSLog(@"error fetching most recent time entry - %@", error.localizedDescription);
            [ErrorLogging logError:error];
#endif
            __timeEntry = nil;
        }
    }
    //if this is a break figure out if we already ended the break
    if ((![NSString isNilOrEmpty:__timeEntry.timeEntryType]) && ([NSString isEquals:__timeEntry.timeEntryType dest: kBreakTimeEntryType]))
    {
       if ( __timeEntry.clockIn && __timeEntry.clockOut)
       {
           DataManager* manager = [DataManager sharedManager];
           NSError* error = nil;
           //we don't want breaks
           __timeEntry = [manager fetchMostRecentNormalTimeEntry:&error];
           user.currentClockMode = ClockModeIn;
           endedBreak = TRUE;
           NSString* strLastClockOutTime = [__timeEntry.clockOut.dateTimeEntry toDefaultTimeString];
           [self enableBreakIn: strLastClockOutTime];
           
       }
    }
    if ((nil == __timeEntry) || (!__timeEntry.clockIn && !__timeEntry.clockOut)) {
        user.lastClockIn = @"";
        user.lastClockOut = @"";
        [self enableClockIn: @""];
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
    
    _breakDurationView.hidden = true;
    if (!endedBreak)
    {
        // Check clockOut if there is one enable clock in
        if (__timeEntry.clockIn && __timeEntry.clockOut) {
            NSString* strLastClockOutTime = [__timeEntry.clockOut.dateTimeEntry toDefaultTimeString];
            [self enableClockIn: strLastClockOutTime];
            user.lastClockIn = [__timeEntry.clockIn.dateTimeEntry toLongDateTimeString];
            user.lastClockOut = [__timeEntry.clockOut.dateTimeEntry toLongDateTimeString];
            user.currentClockMode = ClockModeIn;
        } else if (__timeEntry.clockIn) {
            user.lastClockOut = @"";
            NSString* strLastClockInTime = [__timeEntry.clockIn.dateTimeEntry toDefaultTimeString];
            if ((![NSString isNilOrEmpty:__timeEntry.timeEntryType]) && ([NSString isEquals:__timeEntry.timeEntryType dest: kBreakTimeEntryType]))
            {
                [self enableBreakOut:strLastClockInTime];
                _breakDurationView.hidden = false;
                user.currentClockMode = BreakModeOut;
            }
            else
            {
                user.lastClockIn = strLastClockInTime;
                [self enableClockOut:strLastClockInTime];
                user.currentClockMode = ClockModeOut;
            }
        }
    
        //show the job code if it exists
        if (![NSNumber isNilOrNull:__timeEntry.jobCodeId])
        {
            NSString *jobCodeName;
            NSNumber *jobCodeId;
            for (NSDictionary *jobCodeObj in jobCodesList)
            {
                jobCodeName = [jobCodeObj valueForKey:@"tagName"];
                jobCodeId = [jobCodeObj valueForKey:@"id"];
                if ([jobCodeId isEqualToNumber:__timeEntry.jobCodeId])
                    if ([NSDictionary isNilOrNull:_selectedJobCode]) {
                        _jobCodeTextField.text = jobCodeName;
                    }
            }
        }
    }
}

- (IBAction)doSecondaryBtnClick:(id)sender {
    [self doClockOutSteps];
}



- (void)enableClockOut:(NSString*)clockTime {
    if (![NSString isNilOrEmpty:clockTime])
    {
       // _lastClockInLabel.hidden = NO;
        isActiveClockIn = TRUE;
        _lastClockInLabel.text = [NSString stringWithFormat:@"%@", clockTime];
        _lastClockOutLabel.text = @"";
        //update clock in time
        [_employeeClockInfo setValue:clockTime forKey: @"clockInTime"];
        [_employeeClockInfo setValue:@"" forKey: @"clockOutTime"];
        
        if (allowRecordingOfUnpaidBreaks)
        {
            [_mainActionBtn setTitle:@"Start Break" forState:UIControlStateNormal];
            _mainActionBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);
            [_secondaryActionBtn setTitle:@"Clock Out" forState:UIControlStateNormal];
            _secondaryActionBtn.hidden = false;
        }
        else{
            [_mainActionBtn setTitle:@"Clock Out" forState:UIControlStateNormal];
            _secondaryActionBtn.hidden = true;
        }

       // _lastClockOutLabel.hidden = YES;
       // [SharedUICode disableButton:_mainActionBtn];

        
    }
    else{
        [self enableClockIn: clockTime];
    }
}

- (void)enableClockIn:(NSString*)clockTime  {
    _lastClockOutLabel.text = [NSString stringWithFormat:@"%@", clockTime];
    [_employeeClockInfo setValue:clockTime forKey: @"clockOutTime"];
    isActiveClockIn = FALSE;
    [_mainActionBtn setTitle:@"Clock In" forState:UIControlStateNormal];
    _mainActionBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
    _secondaryActionBtn.hidden = true;

   // [SharedUICode disableButton:_mainActionBtn];

}

- (void)enableBreakIn:(NSString*)clockTime  {
    [_employeeClockInfo setValue:clockTime forKey: @"breakOutTime"];
    isActiveBreak = FALSE;
    [_mainActionBtn setTitle:@"Start Break" forState:UIControlStateNormal];
    _mainActionBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);
    _secondaryActionBtn.hidden = false;

}

- (void)enableBreakOut:(NSString*)clockTime  {
    [_employeeClockInfo setValue:clockTime forKey: @"breakInTime"];
    isActiveBreak = TRUE;
    [_mainActionBtn setTitle:@"End Break" forState:UIControlStateNormal];
    _mainActionBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);
    _breakDurationLabel.hidden = false;
    _secondaryActionBtn.hidden = true;

}
//self.notesTextView.text = [timeEntryRec valueForKey:@"notes"];
-(void) checkClockStatus{
    if (checkingClockStatus) { // prevent multiple calls to checkClockStatus being called within this view because checkClockStatus below is async
        [self stopSpinner];
        return;
    }
    checkingClockStatus = TRUE;
    [self startSpinnerWithMessage:@"Connecting to Server.."];
    
    DataManager* manager = [DataManager sharedManager];
    while ([manager isBusy]) {
        sleep(1);
    }
    [manager checkClockStatus:employeeID withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
//        [self stopSpinner];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        //if no error
        if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL)
        {
            
            //NSDictionary *timeEntryRec = [results valueForKey:ktimeEntryKey];
            
            
            
            NSDictionary *timeEntry;
            timeEntry = [results valueForKey:@"clockInOutState"];
            
            
            if (!([NSDictionary isNilOrNull:timeEntry])) {
                self.notesTextView.text = [timeEntry valueForKey:@"notes"];
            } else {
                NSDictionary *timeEntryRec = [results valueForKey:@"latestTwoWeeksTimeEntry"];
                if (!([NSDictionary isNilOrNull:timeEntryRec]))
                    self.notesTextView.text = [timeEntryRec valueForKey:@"notes"];
            }
            
            NSDictionary *timeEntryRec = [results valueForKey:@"latestTwoWeeksTimeEntry"];
           
            if (![NSDictionary isNilOrNull:timeEntryRec]) {
                DEBUG_MSG
                NSNumber *timeEntryId = [timeEntryRec valueForKey:@"id"];
                NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);
                UserClass *user = [UserClass getInstance];
                user.activeTimeEntryId = timeEntryId;
                
                _jobCodeView.hidden = TRUE;
                if ([user.jobCodesList count] > 0)
                {
                    _jobCodeView.hidden = FALSE;
                    //                        _clockTableViewHeight.constant = -173.667;
                    jobCodesList = user.jobCodesList;
                }
                
                NSError* error = nil;
                DataManager* dataManager = [DataManager sharedManager];
                
                TimeEntry* aTimeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];
 //               NSString *primaryJobCode = @"";
  //              if ([aTimeEntry.jobCodeId isEqual:@0]) {
                    NSDictionary *dic = results[@"employee"];
                    primaryJobCodeId = dic[@"primaryJobCodeId"];
     //               if (![NSNumber isNilOrNull:_selectedJobCodeId])
     //                   primaryJobCode = [dic[@"primaryJobCodeId"] stringValue];
     //               [self getSelectedJobCodeID:primaryJobCode];
 //               } else {
                    // a prod production where the tagtype is not being set to job code is causing the job code id associated with the time entry not to show up
 //                    primaryJobCode = [aTimeEntry.jobCodeId stringValue];
 //                    [self getSelectedJobCodeID:primaryJobCode];
         //       }
                [self stopSpinner];
                [self determineClockInOrClockOut:aTimeEntry];
            } else {
                 [self stopSpinner];
                [self determineClockInOrClockOut:nil];
            }
        } else {
             [self stopSpinner];
            [self determineClockInOrClockOut:nil];
        }
        checkingClockStatus = FALSE;
    }];
}



//this is the callback that comes from the clock in/out web service. The error code will tell us what to do
- (void)clockServiceCallDidFinish:(ClockWebServices *)controller timeEntryRec:(NSDictionary *)timeEntryRec ErrorCode:(int)errorValue resultMessage: (NSString *) resultMessage ClockMode:(ClockMode)clockMode
{
    [self stopSpinner];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (errorValue == SERVICE_ERRORCODE_SUCCESSFUL){
        TimeEntry* aTimeEntry = nil;
        if (nil != timeEntryRec) {
            //DEBUG_MSG
            NSNumber *timeEntryId = [timeEntryRec valueForKey:@"id"];
           // NSAssert(nil != timeEntryId && [timeEntryId integerValue], @"timeEntry 'id' is invalid %@", msg);
            NSError* error = nil;
            UserClass *user = [UserClass getInstance];
            user.activeTimeEntryId = timeEntryId;
            DataManager* dataManager = [DataManager sharedManager];
            aTimeEntry = [dataManager addOrUpdateTimeEntry:timeEntryRec error:&error];

        }
        [self determineClockInOrClockOut:aTimeEntry];
        
        _topLabel.textColor = UIColorFromRGB(GREEN_CLOCKEDIN_COLOR);
        if (isActiveClockIn)
        {
            if (isActiveBreak)
            {
                breakInTime  = aTimeEntry.clockIn.dateTimeEntry;
                _topLabel.text = @"You Are Currently on Break!";
            }
            else
            _topLabel.text = @"You Are Currently Clocked In!";
        }
        else
            _topLabel.text = @"You Are Currently Clocked Out!";

        //ask them to rate us after clocking out
        if (clockMode == ClockModeOut)
            [self CheckRateUsOnAppStoreTrigger];

    }
    //if error code = 1 that means that person has already clocked in from the website so
    else if (errorValue  == SERVICE_ERRORCODE_ALREADY_CLOCKED_IN){
         [self checkClockStatus];
         isActiveClockIn = YES;
        
     }
    //if error code = 2 that means that person has already clocked out from the website so
    else if (errorValue  == SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT){
        [SharedUICode messageBox:nil message:@"Please sign out and sign back in to Clock in" withCompletion:^{
            return;
        }];

    }
    else {
        //else if (errorValue == SERVICE_UNAVAILABLE_ERROR) {
        [self determineClockInOrClockOut:nil];
    }
    _clockWebServices = nil;
}
//MARK:- Review Appstore

-(void)CheckRateUsOnAppStoreTrigger
{
    [SharedUICode CheckRateUsOnAppStoreTrigger:self :^(NSInteger index) {
        [self stopSpinner];
        if (index == 0) {
            // For No
            //                 ratingDialogType = EnjoyingEzClokcer_dlg;
            [self didNotEnjoyEzClocker];
        } else if (index == 1) {
            // For Yes
            //                 ratingDialogType = EnjoyingEzClokcer_dlg;
            //                [self enjoyedEzClockerWasSelected];
            
            if (@available(iOS 10.3, *)) {
                [SKStoreReviewController requestReview];
            } else {
                [self willingToGiveUsRating];
            }
        } else {
            // For visitCounter zero
        }
    }];
}

-(void)didNotEnjoyEzClocker
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"Would you mind giving us some feedback?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Ok, sure"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action){
                                                          [self willingToGiveUsFeedback];
                                                      }];
    
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"No, thanks"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action){}];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];

}
-(void)willingToGiveUsRating
{
    //log to the server that this user rated us so we don't bug them
    AppStoreRatingWebService *webService = [[AppStoreRatingWebService alloc] init];
    [webService LogRatingToServer];
        
#ifdef PERSONAL_VERSION
 //   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-personal-time-tracking/id833047956?mt=8"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-personal-time-tracking/id833047956?mt=8"]options:@{} completionHandler:nil];
#elif IPAD_VERSION
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-kiosk-time-tracking/id1339692641?mt=8"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker-kiosk-time-tracking/id1339692641?mt=8"]options:@{} completionHandler:nil];
#else
 //   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker/id800807197?ls=1&mt=8"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ezclocker/id800807197?ls=1&mt=8"]options:@{} completionHandler:nil];
#endif

}

-(void)notWillingToGiveUsRating
{
    //10/15/17 RK: took this out and moved it back to the calling function
    /*           //reset so we can ask them again later
     NSDate *todaysDate = [NSDate date];
     user.appInstallDate = todaysDate;
     user.userGaveUsRatingFeedback = [NSNumber numberWithInt:0];
     [[NSUserDefaults standardUserDefaults] setInteger:[user.userGaveUsRatingFeedback intValue] forKey:@"userGaveUsRatingFeedback"];
     */
}
-(void)willingToGiveUsFeedback
{
    //take them to our feedback screen
     UIStoryboard *story = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    EmailFeedbackViewController *emailFeedbackController = [story instantiateViewControllerWithIdentifier:@"EmailFeedback"];
    UINavigationController *emailFeedbackNavigationController = [[UINavigationController alloc] initWithRootViewController:emailFeedbackController];
        
        
    emailFeedbackController.delegate = (id) self;
    emailFeedbackController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
    [self presentViewController:emailFeedbackNavigationController animated:YES completion:nil];

}


- (void)emailFeedbackViewControllerDidFinish:(UIViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doMainActionBtnClick:(id)sender {
    [self runTimer];
    if ([_mainActionBtn.titleLabel.text isEqualToString:@"Start Break"])
         [self doBreakInSteps];
    else if ([_mainActionBtn.titleLabel.text isEqualToString:@"End Break"])
        [self doBreakOutSteps];
    else
    {
        //determine if we are clocking in or out

        if (isActiveClockIn)
            [self doClockOutSteps];
        else
        {
            //if the employee does not have a primary job assigned to them and they have jobs then force the employee to pick a job before clocking in
            if (([NSNumber isNilOrNull:primaryJobCodeId]) && ([jobCodesList count] > 0))
                [self showJobCodesPicker];
            else
            {
                [self doClockInSteps];
            }
        }
       // [self doClockInSteps];
    }
}
- (IBAction)doSignOut:(id)sender {
    [self timerInvalidate];
    [self logout];
}

-(void)logout {
    [self.delegate TeamcSignOut:self];
}
-(void)runTimer {
    [self timerInvalidate];
    count = 60;
    timer = [NSTimer scheduledTimerWithTimeInterval: 1
                                             target: self
                                           selector:@selector(resetTimer)
                                           userInfo: nil repeats:YES];
}

- (void) orientationChanged:(NSNotification *)note
{
    self.popUpView.frame = self.view.bounds;
    [self.popUpView updateConstraints];
    [self.popUpView layoutIfNeeded];
}
-(void) resetTimer {
    count -= 1;
    if (count == 10) {
        self.popUpView.frame = self.view.bounds;
        [self.view addSubview:_popUpView];
    }
    if (count <= 10) {
        self.timerLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
    }
    if (count == 0) {
        [self timerInvalidate];
        [self logout];
        [self.popUpView removeFromSuperview];
    }
}

-(void)timerInvalidate {
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}
- (IBAction)cancelButtonAction:(UIButton *)sender {
    [self runTimer];
    [self.popUpView removeFromSuperview];
    
}

/*-(void)resetIdleTimer {
    
    if (self.idleTimer) {
        [self.idleTimer invalidate];
    }
    NSTimeInterval timeInterval = [[[User currentUser]AutomaticLogoutTime] doubleValue]*60;
    
    if (timeInterval > 0) {
        [[NSUserDefaults standardUserDefaults]setValue:@"yes" forKey:@"istouch"];
        self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO] ;
        
    }
 }
 */

-(IBAction)notes_btn:(id)sender
{
    self.popupNotesView.frame = self.view.bounds;
    [UIApplication.sharedApplication.keyWindow addSubview:_popupNotesView];
}

-(IBAction)submitNotes:(id)sender
{
    BOOL bIsReachable = [CommonLib DoWeHaveNetworkConnection];
    if (bIsReachable)
    
    if ([NSString isNilOrEmpty:self.notesTextView.text]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter notes." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        [self callModifyTimeEntryWebService];
        [self.popupNotesView removeFromSuperview];
    }
}

-(IBAction)cancelNotes:(id)sender
{
    [self.popupNotesView removeFromSuperview];
}

- (int) daysBetweenDates: (NSDate *)startDate currentDate: (NSDate *)endDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponent = [calendar components:NSCalendarUnitDay fromDate:startDate toDate:endDate options:0];

    int totalDays = (int)dateComponent.day;
    return totalDays;

}

-(void) updateTimer {
     NSDate *currentDate = [NSDate date];
     NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:breakInTime];
     double secondsInAnHour = 3600;
     NSInteger hoursBetweenDates = timeInterval / secondsInAnHour;

     NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
     NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm:ss"];
    [dateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT:0.0]];
     NSString *mmss=[dateFormatter stringFromDate:timerDate];
    NSString *timeString = [NSString stringWithFormat:@"%ld:%@", hoursBetweenDates, mmss];
    _breakDurationLabel.text = timeString;
}


@end
