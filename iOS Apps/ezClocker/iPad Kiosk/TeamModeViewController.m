//
//  TeamModeViewController.m
//  ezClocker Kiosk
//
//  Created by Raya Khashab on 1/8/18.
//  Copyright © 2018 ezNova Technologies LLC. All rights reserved.
//

#import "TeamModeViewController.h"
#import "PinPadCollectionViewCell.h"
#import "debugdefines.h"
#import "user.h"
#import "CommonLib.h"
#import "completionblockdefines.h"
#import "NSData+Extensions.h"
#import "NSDictionary+Extensions.h"
#import "threaddefines.h"
#import "TeamClockViewController.h"
#import "TimeSheetMasterViewController.h"
#import "ScheduleViewController.h"
#import "SharedUICode.h"
#import "coredatadefines.h"
#import "DataManager.h"
#import "NSDate+Extensions.h"
#import "NSString+Extensions.h"


@interface TeamModeViewController ()

@end

@implementation TeamModeViewController

#define TIME_OUT 60

static NSString * const reuseIdentifier = @"Cell";
//this tells us which Pin Pad box we are on
int currentPinLabelPos = 1;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set color
    _leftHandView.backgroundColor = UIColorFromRGB(LOGO_ORANGE_COLOR);
    
    formatterISO8601DateTime = [[NSDateFormatter alloc] init];
    [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    [formatterISO8601DateTime setTimeZone:[NSTimeZone localTimeZone]];
    formatterTime = [[NSDateFormatter alloc] init];
    [formatterTime setDateFormat:@"h:mm a"];
    [formatterTime setTimeZone:[NSTimeZone localTimeZone]];
    
    formatterDate = [[NSDateFormatter alloc] init];
    [formatterDate setDateFormat:kEEEMMddFormat];
    [formatterDate setTimeZone:[NSTimeZone localTimeZone]];
    
    UIBarButtonItem *adminModeButton = [[UIBarButtonItem alloc] initWithTitle:@"Admin Mode" style:UIBarButtonItemStylePlain target:self action:@selector(switchToAdminMode)];

    self.navigationItem.leftBarButtonItem = adminModeButton;


    
    pinValue = [[NSMutableArray alloc] init];
    
    
    numPadImages = @[
                     @[ @"Dial_Number_1.png", @"Dial_Number_2.png", @"Dial_Number_3.png"],
                     @[ @"Dial_Number_4.png", @"Dial_Number_5.png", @"Dial_Number_6.png"],
                     @[ @"Dial_Number_7.png", @"Dial_Number_8.png", @"Dial_Number_9.png"],
                     @[ @"", @"Dial_Number_0.png", @"Dial_Number_Delete.png"],
                    ];
    
    numPadValues = @[
                     @[ @"1", @"2", @"3"],
                     @[ @"4", @"5", @"6"],
                     @[ @"7", @"8", @"9"],
                     @[ @"", @"0", @"back"],
                     ];
    
    [self clearPinData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _currentDateLabel.text = [formatterDate stringFromDate:[NSDate date]];;

}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self tick:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 4;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PinPadCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    UIImage *image;
    
    image = [UIImage imageNamed:[[numPadImages objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
    
    cell.imageView.image = image;

    return cell;
}

/*- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGSize mElementSize = CGSizeMake(70, 70);
    return mElementSize;
}
*/

-(UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    collectionViewLayout.minimumInteritemSpacing=1;
    collectionViewLayout.minimumLineSpacing =2;
    return UIEdgeInsetsMake(5, 5, 5, 5);
}


-(void) clearPinData
{
    _pinLabel1.text = @"";
    _pinLabel2.text = @"";
    _pinLabel3.text = @"";
    _pinLabel4.text = @"";
    
    [pinValue removeAllObjects];
    
    currentPinLabelPos = 1;

}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger row = indexPath.section;
    NSInteger col = indexPath.row;
    NSString *val = numPadValues[row] [col];
    if ([val isEqualToString:@"back"])
    {
        if (currentPinLabelPos > 1)
        {
            switch (currentPinLabelPos - 1) {
                case 1:
                    _pinLabel1.text = @"";
                    break;
                case 2:
                    _pinLabel2.text = @"";
                    break;
                case 3:
                    _pinLabel3.text = @"";
                    break;
                case 4:
                    _pinLabel4.text = @"";
                    break;
            }
            //pinValue is zero based while currentPinLabelPos is one based and always +1 from the value so we need to -2 to remove the correct digit
            [pinValue removeObjectAtIndex:(currentPinLabelPos - 2)];
            currentPinLabelPos--;
        }
            
    }
    else if ([val isEqualToString:@""])
    {
        
    }
    else if (currentPinLabelPos < 5){
        
        switch (currentPinLabelPos) {
            case 1:
                _pinLabel1.text = @"*";
                break;
            case 2:
                _pinLabel2.text = @"*";
                break;
            case 3:
                _pinLabel3.text = @"*";
                break;
            case 4:
                _pinLabel4.text = @"*";
                break;
        }
        [pinValue addObject:val];
        currentPinLabelPos++;
        
        if (currentPinLabelPos - 1 == 4)
        {
            [self doSignin];
        } else {
            [self stopSpinner];
        }
        
        
    }
    
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

- (void)callLoginByPin:(bool) test withCompletion:(ServerResponseCompletionBlock)completion {


    
    NSString *httpPostString;
    NSString * teamPin = [[pinValue valueForKey:@"description"] componentsJoinedByString:@""];

   // NSString *teamPin = @"1234";

    UserClass* user = [UserClass getInstance];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/employer/team/login", SERVER_URL];

    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          teamPin, @"teamPin",
                          nil];
    NSError *error;
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

     NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

    
    request.HTTPMethod = @"POST";
    
    [request setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    [request setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [request setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authToken"];

    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
   // config.timeoutIntervalForRequest = TIME_OUT; // 2 minutes
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
                 MAINTHREAD_BLOCK_START()
                [self stopSpinner];
                completion(errorCode, resultMessage, results, aError);
                THREAD_BLOCK_END()
                return;
                //                }
            }];
        }
    }];
    [dataTask resume];
}
#pragma mark <UICollectionViewDelegate>

/*
 // Uncomment this method to specify if the specified item should be highlighted during tracking
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }
 */

/*
 // Uncomment this method to specify if the specified item should be selected
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }
 */

/*
 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
 return NO;
 }
 
 - (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
 return NO;
 }
 
 - (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
 
 }
 */


-(void) showEmployeeScreens: (NSDictionary *) clockInfo TimeEntryObj: (TimeEntry *) timeEntry
{
    
     UIStoryboard *iPadStoryboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
     TeamClockViewController *teamClockView = [iPadStoryboard instantiateViewControllerWithIdentifier:@"teamClockViewController"];
    
     teamClockView.delegate = (id) self;
     teamClockView.employeeClockInfo = clockInfo;
    teamClockView.timeEntry = timeEntry;
    
     UINavigationController *teamClockNavigationController = [[UINavigationController alloc] initWithRootViewController:teamClockView];
     
     UIStoryboard *iPhoneStoryboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
     TimeSheetMasterViewController *empTimeSheetViewController = [iPhoneStoryboard instantiateViewControllerWithIdentifier:@"TimeSheetMasterViewController"];
     UINavigationController *timeSheetNavigationController = [[UINavigationController alloc] initWithRootViewController:empTimeSheetViewController];
     
     ScheduleViewController *scheduleViewController = [iPhoneStoryboard instantiateViewControllerWithIdentifier:@"ScheduleViewController"];
     UINavigationController *scheduleNavigationController = [[UINavigationController alloc] initWithRootViewController:scheduleViewController];
     
     tabBarController = [[UITabBarController alloc] init];
     tabBarController.viewControllers = [NSArray arrayWithObjects:teamClockNavigationController, timeSheetNavigationController, scheduleNavigationController, nil];
     //   tabBarController.viewControllers = [NSArray arrayWithObjects:teamClockView, nil];
    
    UserClass *user = [UserClass getInstance];
     empTimeSheetViewController.employeeID = user.userID;
     // empTimeSheetViewController.employeeName =
     //pass the selected employee email so it can be used in the email time sheet
     
     // empTimeSheetViewController.employeeEmail = [employee valueForKey:@"Email"];//user.userEmail;
     
     
     
     // teamClockView.delegate = (id) self;
//     tabBarController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    tabBarController.modalPresentationStyle = UIModalPresentationFullScreen;
     [self presentViewController:tabBarController animated:YES completion:nil];
     
    
}

- (void)doSignin {

    [self startSpinnerWithMessage:@"Signing in, please wait..."];
    NSLog(@"Spinner set");
    [self callLoginByPin: 1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopSpinner];
        });
        
        //error code10403
        if (aErrorCode != 0) {
            if (aErrorCode == SERVICE_ACCESSDENIED_ERROR)
            {
                [SharedUICode messageBox:nil message:@"Error Signing in. PIN is incorrect. Please check the information and try again" withCompletion:^{
                    
                    [self clearPinData];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self stopSpinner];
                    });
                return;
                }];

            }
            else
            {
                [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                    [self clearPinData];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self stopSpinner];
                    });
                return;
                }];
            }

        }
        else
        {
            UserClass *user = [UserClass getInstance];
            user.userID     = [aResults valueForKey:@"employeeId"];
            user.employeeName = [aResults valueForKey:@"employeeName"];

            NSNumber *isActiveBreak = 0;
            NSDictionary *selectedJobCode = nil;
            NSMutableArray *jobsList;
            NSString *breakInTime = @"";
            NSNumber *allowRecordingOfUnpaidBreaks;
            allowRecordingOfUnpaidBreaks = [aResults valueForKey:@"allowRecordingOfUnpaidBreaks"];
            if (allowRecordingOfUnpaidBreaks)
            {
                NSDictionary *activeBreak = [aResults valueForKey:@"activeBreak"];
                if (![NSDictionary isNilOrNull:activeBreak])
                {
                    isActiveBreak = [NSNumber numberWithInt:1];
                    breakInTime = [NSString stringWithFormat: @"%@",[activeBreak valueForKey:kclockInIso8601Key]];
                }
            }
            
            NSArray *jobCodesFromServer = [aResults valueForKey:@"employeeDataTags"];
            jobsList = [[NSMutableArray alloc] init];
            NSNumber *jobCodeId;
            NSString *jobCodeName;
            NSMutableDictionary *_jobCode;
            //save the jobs list to the user object so the joblist picker screen can pick them up and show them to the user.
            [user.jobCodesList removeAllObjects];
            for (NSDictionary *jobCode in jobCodesFromServer){
                //if not archived then add it
                if (![[jobCode valueForKey:@"archived"] boolValue])
                {
                    jobCodeId = [jobCode valueForKey:@"id"];
                    jobCodeName = [jobCode valueForKey:@"tagName"];//tagId
                
                    _jobCode = [[NSMutableDictionary alloc] init];
                    @try{
                        [_jobCode setValue:jobCodeId forKey:@"id"];
                        [_jobCode setValue:jobCodeName forKey:@"tagName"];
                    }
                    @catch(NSException* ex) {
                        NSLog(@"Exception in setting JobCodes from Server: %@", ex);
                    }
                
                    [jobsList addObject:_jobCode];
                    [user.jobCodesList addObject:_jobCode];
                }
                
            }

            
            NSDictionary *clockInfo = [aResults valueForKey:@"clockInOutState"];
             if ([NSDictionary isNilOrNull:clockInfo])
                 clockInfo = [aResults valueForKey:@"latestTwoWeeksTimeEntry"];

            
            NSString *clockInTime = @"";
            NSString *clockOutTime = @"";
            TimeEntry* aTimeEntry = nil;
            NSNumber *isClockedIn = 0;
            
            if ( clockInfo != (id)[NSNull null] )
            {
                isClockedIn = [clockInfo valueForKey:@"isActiveClockIn"];
                
                
                NSMutableArray *jobCodes =  [clockInfo valueForKey: @"assignedJobs"];
                for (NSDictionary *jobCode in jobCodes)
                {
                    NSString *jobCodeType = [jobCode objectForKey:@"ezDataTagType"];//dataTagType
                    if ([jobCodeType isEqual:@"JOB_CODE"])
                        selectedJobCode = jobCode;

                }
                 clockInTime = [NSString stringWithFormat: @"%@",[clockInfo valueForKey:kclockInIso8601Key]];
                clockInTime  = [clockInTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
            
                NSDate *DateValue = [formatterISO8601DateTime dateFromString:clockInTime];
                clockInTime = [formatterTime stringFromDate:DateValue];

                clockOutTime = [NSString stringWithFormat: @"%@",[clockInfo valueForKey:kclockOutIso8601Key]];
                clockOutTime  = [clockOutTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
            
                DateValue = [formatterISO8601DateTime dateFromString:clockOutTime];
                clockOutTime = [formatterTime stringFromDate:DateValue];
                
                //  NSDictionary *timeEntryRec = [aResults valueForKey:@"clockInOutState"];
                NSError* error = nil;
                
                DataManager* dataManager = [DataManager sharedManager];
                
                aTimeEntry = [dataManager addOrUpdateTimeEntry:clockInfo error:&error];
            }
            
                
            NSDictionary *employeeClockInfo = [[NSMutableDictionary alloc]init];
            [employeeClockInfo setValue:clockInTime forKey:@"clockInTime"];
            [employeeClockInfo setValue:clockOutTime forKey:@"clockOutTime"];
            [employeeClockInfo setValue:breakInTime forKey:@"breakInTime"];
            [employeeClockInfo setValue:isClockedIn forKey:@"isClockedIn"];
            [employeeClockInfo setValue:isActiveBreak forKey:@"isActiveBreak"];
            [employeeClockInfo setValue:allowRecordingOfUnpaidBreaks forKey:@"allowRecordingOfUnpaidBreaks"];
            [employeeClockInfo setValue:selectedJobCode forKey:@"selectedJobCode"];
            [employeeClockInfo setValue:jobsList forKey:@"jobsList"];
            
            [self stopSpinner];

            [self showEmployeeScreens: employeeClockInfo TimeEntryObj:aTimeEntry];
        }
   
    }];


}
- (void)teamClockViewControllerSignOut:(UIViewController *)controller CancelWasSelected:(bool)cancelWasSelected
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//if employee signed out then take us back to the Enter your Pin screen
- (void)TeamcSignOut:(TeamClockViewController *)controller
{
    [self clearPinData];
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

-(void) getPassword
{
 /*   UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Admin Password"
                                                                   message:@"Enter password"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
  //  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"confirm the modification" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        UITextField *password = alert.textFields.firstObject;
        if (![password.text isEqualToString:@""]) {
            
            NSString *result = password.text;
            
        }
        else{
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
    
    [alert addAction:okAction];
  //  [self presentViewController:alert animated:YES completion:nil];
  */
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Admin Password" message:@"Enter password" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Current password";
        textField.secureTextEntry = YES;
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //compare the current password and do action here
        NSString *passwordEntered = [[alertController textFields][0] text];
        [self AuthenticateUser: passwordEntered];
    }];
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Canelled");
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) switchToAdminMode
{
    [self getPassword];

 //    [self.delegate adminModeWasSelected:self];
}

-(void) AuthenticateUser: (NSString*) passwordEntered
{
    
    [self startSpinnerWithMessage:@"Authenticating..."];

    [self callAuthenticateUserAPI:passwordEntered withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            NSString *msg = @"There was an issue signing in. Please try again later";

            if (![NSString isNilOrEmpty:aResultMessage] && aErrorCode == 500)
                msg = aResultMessage;
            [SharedUICode messageBox:nil message:msg withCompletion:^{
                return;
            }];
            
        }
        else{
            //switch to Admin mode and set the user type to employer
            UserClass *user = [UserClass getInstance];
            if (CommonLib.userIsManager)
                user.userType = @"employee";
            else
                user.userType = @"employer";
            [[NSUserDefaults standardUserDefaults] setValue:user.userType forKey:@"userType"];
  //           [[NSUserDefaults standardUserDefaults] synchronize]; 
            [self.delegate adminModeWasSelected:self];
          }
    }];
    
    
}


-(void) callAuthenticateUserAPI:(NSString *)passwordEntered withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    NSString *userName = user.userEmail;
    NSString *userPassword = passwordEntered;
    
    NSString *httpPostString = [NSString stringWithFormat:@"%@api/v1/account/authenticate", SERVER_URL];

    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          userName, @"userName",
                          userPassword, @"password",
                          @"iPHONE", @"source",
                          nil];

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
    
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:DEV_TOKEN forHTTPHeaderField:@"x-ezclocker-developertoken"];
    
    
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

@end
