//
//  EmailTimeSheetViewController.m
//  Created by Raya Khashab on 10/6/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import "EmailTimeSheetViewController.h"
#import "user.h"
#import <QuartzCore/QuartzCore.h>
#import "CommonLib.h"
#import "Mixpanel.h"
#import "NSString+Extensions.h"
#import "NSNumber+Extensions.h"
#import "completionblockdefines.h"
#import "SharedUICode.h"
#import "NSData+Extensions.h"
#import "threaddefines.h"
#import "DataManager.h"


@interface EmailTimeSheetViewController ()

@end

@implementation EmailTimeSheetViewController

@synthesize MessageTextView = _MessageTextView;
@synthesize MessageLabel;
@synthesize EmailTextEdit = EmailTextEdit;
@synthesize SubjectLabel = _SubjectLabel;
@synthesize delegate = _delegate;
@synthesize startDate;
@synthesize endDate;
@synthesize employeeID;

#define EMAIL_NOT_SENT 101

bool messageTextViewEditing = FALSE;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil

{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        startDate = @"";
        endDate = @"";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //create a TextView inside TextField to get the border around it
    
    
    //put a borde on the text field
    _MessageTextView.text = @"";
    CALayer *imageLayer = _MessageTextView.layer;
    [imageLayer setCornerRadius:10];
    [imageLayer setBorderWidth:2.1];
    imageLayer.borderColor=[[UIColor lightGrayColor] CGColor];
    
    EmailTextEdit.delegate = self;
    _fromTextField.delegate = self;
    _MessageTextView.delegate = self;
    [_fromTextField setReturnKeyType:UIReturnKeyDone];
    [EmailTextEdit setReturnKeyType:UIReturnKeyDone];
    
    
    //    [self registerForKeyboardNotifications];
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    UserClass *user = [UserClass getInstance];
    
    //use this flag to figure out when the message text view is being edited so we scroll the screen since the keyboard is hiding it
    messageTextViewEditing = FALSE;
    
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(keyboardDoneBtnPressed)];
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    _MessageTextView.inputAccessoryView = keyboardToolbar;
    
    _submitBtn.hidden = YES;
    _SubjectLabel.textColor = UIColorFromRGB(BUTTON_BLUE_COLOR);
    
    //show the string that got passed to us
    //    _SubjectLabel.text = [NSString stringWithFormat:@"%@ - %@ Time Sheet", startDate, endDate];
    _SubjectLabel.text = [NSString stringWithFormat:@"%@ - %@", startDate, endDate];
    
    
    self.selectedFromDateValue = startDate ;
    self.selectedToDateValue = endDate ;
    
    //    [_scrollView setScrollEnabled:YES];
    //    [_scrollView setContentSize:CGSizeMake(320, 900)];
    _scrollView.delaysContentTouches = NO;
    
    _scrollView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    
    _optionsViewContainer.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _bottomViewContainer.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _mainView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _lastViewSection.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);;
    
    
    if (!_emailAllTimeSheets)
    {
        
        _bottomViewContainerTopConstraint.constant = 16;
        //        CGRect frame2 = [_bottomViewContainer frame];
        //        frame2.origin.y = _optionsViewContainer.frame.origin.y;  // shift the message view up
        //        [_bottomViewContainer setFrame:frame2];
        //
        //        [_optionsViewContainer removeFromSuperview];
        //
        //        CGRect frame = [_lastViewSection frame];
        //        frame.origin.y = _bottomViewContainer.frame.origin.y + _bottomViewContainer.frame.size.height;  // shift up the last view to the message view
        //        [_lastViewSection setFrame:frame];
        
        //     _optionsViewContainer.hidden = YES; //hide the option since it's only valid for EmailAllTimeSheets
        
        
    }
    else
    {
        _bottomViewContainerTopConstraint.constant = 82;
        NSUInteger emailOption =  [[NSUserDefaults standardUserDefaults] integerForKey:@"optionUseDecimalFormat"];
        if (emailOption == 1)
            [_decimalOptionSwitch setOn:YES];
        
    }
    
#ifdef PERSONAL_VERSION
    if (user.hasAccount)
        _fromTextField.text = user.userEmail;
        //_fromTextField.text = user.indivdualName;
#else
    if ([CommonLib validateEmail:user.userEmail])
        _fromTextField.text = user.userEmail;
#endif
    
    //if the user is an employer and didn't select email all time sheets then default to employee email
    if ((!_emailAllTimeSheets) && [user.userType isEqual:@"employer"])
        EmailTextEdit.text = _employeeEmail;
    else
    {
        //if we are running the personal app see if we have customers and use the customer email to populate the to-email text field
#ifdef PERSONAL_VERSION
        NSString* customerEmail = @"";
        if (![NSNumber isNilOrNull:user.curCustomerId])
        {
            customerEmail = [self findCusterEmail:user.curCustomerId];
            if (![NSString isNilOrEmpty:customerEmail])
                EmailTextEdit.text = customerEmail;
        }
        //if we have a current customer but no email is assigned in the customer mgmt screen then just leave it blank otherwise, pick the last email addresss we sent
        if (([NSNumber isNilOrNull:user.curCustomerId]) && [NSString isNilOrEmpty:customerEmail])
            EmailTextEdit.text = user.lastEmailToSent;
#else
        EmailTextEdit.text = user.lastEmailToSent;
#endif
    }
    
    UIBarButtonItem* sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendButtonAction)];
    
    
    self.navigationItem.rightBarButtonItem = sendButton;
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];
    
    [self removeKeyboard];
    
    
}

-(NSString*) findCusterEmail: (NSNumber*) curCustomerId
{
    UserClass *user = [UserClass getInstance];
    NSString *result = @"";
    NSNumber* customerId;
    for (NSDictionary *customer in user.customerNameIDList){
        customerId = [customer valueForKey:@"id"];
        if ([NSNumber isEquals:customerId dest:curCustomerId])
        {
            result = [customer valueForKey:@"email"];
            break;
        }
    }
    return result;
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setEmailTextEdit:nil];
    [self setSubjectLabel:nil];
    [self setMessageTextView:nil];
    [self setMessageLabel:nil];
    [super viewDidUnload];
}
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    messageTextViewEditing = TRUE;
    return  YES;
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    if (messageTextViewEditing)
    {
        messageTextViewEditing = FALSE;
        NSDictionary* info = [aNotification userInfo];
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
        _scrollView.contentInset = contentInsets;
        _scrollView.scrollIndicatorInsets = contentInsets;
        
        // If active text field is hidden by keyboard, scroll it so it's visible
        // Your app might not need or want this behavior.
        CGRect aRect = self.view.frame;
        aRect.size.height -= kbSize.height;
        
        CGRect scrollFrame = _lastViewSection.frame;
        scrollFrame.size.height = (scrollFrame.size.height - 50);
        
        if (!CGRectContainsPoint(aRect, _MessageTextView.frame.origin) ) {
            [_scrollView scrollRectToVisible:scrollFrame animated:YES];
            
        }
    }
}
-(void)keyboardDoneBtnPressed
{
    [_MessageTextView resignFirstResponder];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [_scrollView scrollRectToVisible:_fromTextField.frame animated:YES];
    
    //UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    //_scrollView.contentInset = contentInsets;
    //_scrollView.scrollIndicatorInsets = contentInsets;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
}


-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
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

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    //do nothing with the data since we don't want to wait for it to go through or not
    NSError *error = nil;
    
    //   NSString* JSONStr = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
    NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    NSString *resultMessage = [results valueForKey:@"message"];
    if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"]))
    {
        [ErrorLogging logErrorWithDomain:@"EMAIL" code:UNKNOWN_ERROR description:@"UNABLE_TO_SEND_EMAIL" error:nil];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"ezClocker is unable to send emails at this time. If this error persist please contact support@ezclocker.com"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        // alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to send emails at this time. If this error persist please contact support@ezclocker.com" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        // [alert show];
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"ERROR"
                                 message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    // [alert show];
    
    connection = nil;
    data = nil;
}


-(int) emailTimeSheet_new{
    __block int returnedError = 0;
    
    [self callEmailTimeSheetAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
        if (aError != nil) {
            [ErrorLogging logError:aError];
        }
        [self stopSpinner];
        returnedError = (int) aErrorCode;
        if ((aErrorCode != 0) && (aErrorCode != EMAIL_NOT_SENT)) {
            [SharedUICode messageBox:nil message:@"There was an error sending the email. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        //    [self.delegate JobCodeDetailsDidFinish:self CancelWasSelected:NO];
        
    }];
    return returnedError;
    
}


#ifdef PERSONAL_VERSION
-(void) callEmailTimeSheetAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    UserClass *user = [UserClass getInstance];
    NSString *personalId = [user.userID stringValue];
    
    //if user has an account then pass then name else pass whatever they entered in the from text field
    NSString *senderName = _fromTextField.text;
    if (user.hasAccount)
        senderName = user.indivdualName;
    
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    
    NSDateFormatter *dateFormatterMMDDYYYY = [[NSDateFormatter alloc] init];
    [dateFormatterMMDDYYYY setLocale: [[NSLocale alloc]
                                       initWithLocaleIdentifier:@"en_US"]];
    [dateFormatterMMDDYYYY setDateFormat:@"MM/dd/yyyy"];
    
    NSDateFormatter *dateFormatterIso8601 = [[NSDateFormatter alloc] init];
    [dateFormatterIso8601 setLocale: [[NSLocale alloc]
                                      initWithLocaleIdentifier:@"en_US"]];
    [dateFormatterIso8601 setDateFormat:@"yyyy-MM-dd"];
    
    //    NSDate *dateValue = [dateFormatterMMDDYYYY dateFromString:startDate];
    //    startDate = [dateFormatterIso8601 stringFromDate:dateValue];
    //    dateValue = [dateFormatterMMDDYYYY dateFromString:endDate];
    //    endDate = [dateFormatterIso8601 stringFromDate:dateValue];
    
    NSDate *startDateValue = [dateFormatterMMDDYYYY dateFromString:_selectedFromDateValue];
    
    
    NSDate *endDateValue = [dateFormatterMMDDYYYY dateFromString:
                            _selectedToDateValue];
    
    
    
    if ([self daysBetween:startDateValue and:endDateValue] > 31)
        
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"you can not email more than a month worth of data"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        completion(EMAIL_NOT_SENT, nil, nil, nil);
    }
    else
    {
        
        startDate = [dateFormatterIso8601 stringFromDate:startDateValue];
        endDate = [dateFormatterIso8601 stringFromDate:endDateValue];
        NSString *strCurCustomerId = [user.curCustomerId stringValue];
        
        NSString *subjectLine;
        
        //if we are going to show total pay then change the subject to an invoice vs. just timesheet
        
        if ((user.showTotalPay) && (_totalPay > 0))
        {
            subjectLine = [NSString stringWithFormat:@"%@ sent you an invoice for %@", senderName, _SubjectLabel.text];
        }
        else{
            subjectLine = [NSString stringWithFormat:@"%@ timesheet for %@", _SubjectLabel.text, senderName];
        }
        
        httpPostString = [NSString stringWithFormat:@"%@api/v1/personal/email/report/csv", SERVER_URL];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpPostString]];
        
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     personalId, @"employeeId",
                                     senderName, @"senderName",
                                     startDate, @"startDateIso8601",
                                     endDate, @"endDateIso8601",
                                     subjectLine, @"subject",
                                     _MessageTextView.text, @"message",
                                     EmailTextEdit.text, @"toEmail",
                                     timeZoneId, @"targetTimeZone",
                                     @"false", @"showSeconds",
                                     //check if we have job codes then set to true
                                     strCurCustomerId, @"customerId",
                                     nil];
        
        if ((user.jobCodesList) && ([user.jobCodesList count] > 0))
        {
            [dict setValue:@"true" forKey:@"includeDataTags"];
        }
        
        //send a cc email to the from email if it's a valid email and if it's not equal to the to email in other words don't send them a copy if they are emailing it to themselves
        NSString *fromEmail = _fromTextField.text;
        if ([CommonLib validateEmail:fromEmail] && (![NSString isEquals:fromEmail dest:EmailTextEdit.text]))
        {
            NSArray *ccEmails = [NSArray arrayWithObjects: fromEmail, nil];
            [dict setObject:ccEmails forKey:@"ccs"];
        }
        
        //if the user doesn't have an account i.e. using the temporary account then pass the email as the senderNameOverride so the email doens't say ezClocker7845 sent you an invoice
        if (!user.hasAccount)
        {
            [dict setObject:fromEmail forKey:@"senderNameOverride"];
        }
        
        
        if ((user.showTotalPay) && (_totalPay > 0))
        {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setMaximumFractionDigits:2];
            NSString *numberString = [formatter stringFromNumber:_totalPay];
            NSNumber* numTotalPay = [formatter numberFromString:numberString];
            [dict setObject:numTotalPay forKey:@"totalPay"];
        }
        
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                           options:NSJSONWritingPrettyPrinted error:&error];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //set request body into HTTPBody.
        request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        request.HTTPMethod = @"POST";
        
        [request setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *tmpAuthToken = user.authToken;
        NSString *tmpEmployerID = [user.employerID stringValue];
        [request setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
        [request setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
        [request setValue:personalId forHTTPHeaderField:@"x-ezclocker-personal-id"];
        
        
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
}
#else
-(void) callEmailTimeSheetAPI:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    UserClass *user = [UserClass getInstance];
    // NSString *employeeId = [user.userID stringValue];
    
    //if user has an account then pass then name else pass whatever they entered in the from text field
    NSString *senderName = _fromTextField.text;
    
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    
    NSDateFormatter *dateFormatterMMDDYYYY = [[NSDateFormatter alloc] init];
    [dateFormatterMMDDYYYY setLocale: [[NSLocale alloc]
                                       initWithLocaleIdentifier:@"en_US"]];
    [dateFormatterMMDDYYYY setDateFormat:@"MM/dd/yyyy"];
    
    NSDateFormatter *dateFormatterIso8601 = [[NSDateFormatter alloc] init];
    [dateFormatterIso8601 setLocale: [[NSLocale alloc]
                                      initWithLocaleIdentifier:@"en_US"]];
    [dateFormatterIso8601 setDateFormat:@"yyyy-MM-dd"];
    
    //   NSDate *startDateValue = [dateFormatterMMDDYYYY dateFromString:startDate];
    NSDate *startDateValue = [dateFormatterMMDDYYYY dateFromString:_selectedFromDateValue];
    
    
    NSDate *endDateValue = [dateFormatterMMDDYYYY dateFromString:
                            _selectedToDateValue];
    if ([self daysBetween:startDateValue and:endDateValue] > 31)
        
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"you can not email more than a month worth of data"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        completion(EMAIL_NOT_SENT, nil, nil, nil);
    }
    else{
        
        startDate = [dateFormatterIso8601 stringFromDate:startDateValue];
        endDate = [dateFormatterIso8601 stringFromDate:endDateValue];
        NSString *subjectLine;
        
        
        subjectLine = [NSString stringWithFormat:@"%@ timesheet for %@", _SubjectLabel.text, senderName];
        
        NSString *userEmployerID = [NSString stringWithFormat:@"%@", user.employerID];
        
        if (_emailAllTimeSheets)
        {
            httpPostString = [NSString stringWithFormat:@"%@api/v1/email/report/%@", SERVER_URL, userEmployerID];
            
        }
        else
        {
            httpPostString = [NSString stringWithFormat:@"%@api/v1/email/report/%@/%@", SERVER_URL, userEmployerID, employeeID];
        }
        
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpPostString]];
        
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     userEmployerID, @"employerId",
                                     senderName, @"senderName",
                                     startDate, @"startDateIso8601",
                                     endDate, @"endDateIso8601",
                                     subjectLine, @"subject",
                                     _MessageTextView.text, @"message",
                                     EmailTextEdit.text, @"toEmail",
                                     timeZoneId, @"targetTimeZone",
                                     nil];
        
        //Send the job codes not needed for biz app bc the service already does the check
        if ((user.jobCodesList) && ([user.jobCodesList count] > 0))
        {
            [dict setValue:@"true" forKey:@"includeDataTags"];
        }
        
        //if employer or payroll manager then show estimated pay in report
        if (CommonLib.userHasPayrollPermission)
        {
            [dict setValue: @"true" forKey:@"showEstimatedPay"];
        }
        
        NSString *fromEmail = _fromTextField.text;
        //send a cc email to the from email if it's a valid email and if it's not equal to the to email in other words don't send them a copy if they are emailing it to themselves
        if ([CommonLib validateEmail:fromEmail] && (![NSString isEquals:fromEmail dest:EmailTextEdit.text]))
        {
            NSArray *ccEmails = [NSArray arrayWithObjects: fromEmail, nil];
            [dict setObject:ccEmails forKey:@"ccEmails"];
        }
        
        //if we are doing a single employee then send the employeeId
        if (!_emailAllTimeSheets)
        {
            [dict setObject:employeeID forKey:@"employeeId"];
        }
        
        //if the user chose to email all timesheets check to see if the total decimal option is on or off
        if ((_emailAllTimeSheets) && ([_decimalOptionSwitch isOn]))
        {
            [dict setObject:@"true" forKey:@"totalsAsDecimal"];
        }
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                           options:NSJSONWritingPrettyPrinted error:&error];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //set request body into HTTPBody.
        request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        request.HTTPMethod = @"POST";
        
        [request setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *tmpAuthToken = user.authToken;
        NSString *tmpEmployerID = [user.employerID stringValue];
        [request setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
        [request setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
        
        
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
}
#endif

- (int)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2 {
    NSUInteger unitFlags = NSCalendarUnitDay;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return (int) [components day]+1;
}


-(void) sendEmail{
    if (![CommonLib validateEmail:EmailTextEdit.text])
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a valid email address"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        
    }
    else if ([NSString isNilOrEmpty:_fromTextField.text])
    {
        [SharedUICode messageBox:nil message:@"Please enter an email in the from text box" withCompletion:^{
            return;
        }];
    }
    else{
        UserClass *user = [UserClass getInstance];
        //save the last email so they don't have to type it again. Mostly used for employees trying to email time sheets not employers. For employers we don't want to save it if they came from the employee email time sheet and they didn't override the employee email
        bool saveEmail = true;
        if (([user.userType isEqualToString:@"employer"]) && ((!_emailAllTimeSheets) && ([_employeeEmail isEqualToString: EmailTextEdit.text])))
            saveEmail = false;
        if (saveEmail)
            user.lastEmailToSent = EmailTextEdit.text;
        [[NSUserDefaults standardUserDefaults] setValue:user.lastEmailToSent forKey:@"lastEmailToSent"];
        //  [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
        
        //call webservice to send the email
        
        int aErrorCode = [self emailTimeSheet_new];
        
        //        [self emailTimeSheet];
        
        //send message back to the delegate to close the view since we don't care to wait and check if the mail got sent or not
        if (aErrorCode != EMAIL_NOT_SENT)
            [CommonLib logEvent:@"Email all timesheets"];
            [self.delegate emailTimeSheetViewControllerDidFinish:self];
        
        
    }
    
}

-(void) sendButtonAction{
    [self sendEmail];
}



- (IBAction)doSubmitEmail:(id)sender {
    [self sendEmail];
}

- (IBAction)doOptionSwitchChanged:(id)sender {
    if([_decimalOptionSwitch isOn])
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"optionUseDecimalFormat"];
    else
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"optionUseDecimalFormat"];
    
    // [[NSUserDefaults standardUserDefaults] synchronize];
    
}


-(void)removeKeyboard{
    [_fromTextField resignFirstResponder];
    [EmailTextEdit resignFirstResponder];
    [_MessageTextView resignFirstResponder];
}



- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self removeKeyboard];
    return YES;
}



- (IBAction)doCancel:(id)sender {
    [self.delegate emailTimeSheetViewControllerDidFinish:self];
    
}

- (IBAction)doSetDateRange:(id)sender {
    [self DatePickerView];
}


//picking dates for reporting
-(void)DatePickerView
{
    WWCalendarTimeSelector *selector  = (WWCalendarTimeSelector *)[[UIStoryboard storyboardWithName:@"WWCalendarTimeSelector" bundle:nil] instantiateViewControllerWithIdentifier:@"WWCalendarTimeSelector"];
    selector.delegate = self;
    //    selector.optionShowTopContainer = false;
    //    selector.optionLayoutHeight = 300;
    selector.optionSelectionType = WWCalendarTimeSelectorSelectionRange;
    NSDate *startDateObj = [self convertStringToDate:self.startDate];
    NSDate *endDateObj = [self convertStringToDate:self.endDate];
    [selector.optionCurrentDateRange setStartDate:startDateObj];
    [selector.optionCurrentDateRange setEndDate:endDateObj];
    selector.optionCurrentDate = startDateObj;
    
    self.selectedFromDateValue = self.startDate;
    self.selectedToDateValue = self.endDate;
    [self presentViewController:selector animated:YES completion:nil];
}

- (void) WWCalendarTimeSelectorDone:(WWCalendarTimeSelector *)selector date:(NSDate *)date {
    NSLog(@"%@date:", date);
}

- (void)WWCalendarTimeSelectorDone:(WWCalendarTimeSelector *)selector dates:(NSArray<NSDate *> *)dates {
    NSLog(@"%@date:", dates);
    
    self.selectedFromDateValue = [self convertDateToString:dates.firstObject] ;
    self.selectedToDateValue = [self convertDateToString:dates.lastObject] ;
    
    
    _SubjectLabel.text = [NSString stringWithFormat:@"%@ - %@", self.selectedFromDateValue, self.selectedToDateValue];
    
    self.startDate = self.selectedFromDateValue;
    self.endDate = self.selectedToDateValue;
    
    [self datePickerDoneClick];
    
}
-(void)datePickerDoneClick {
    
    
}

-(NSDate*)convertStringToDate: (NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}

-(NSString*)convertDateToString: (NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}
@end
