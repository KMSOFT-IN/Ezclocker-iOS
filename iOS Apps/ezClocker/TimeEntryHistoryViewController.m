//
//  TimeEntryHistoryViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 2/27/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import "TimeEntryHistoryViewController.h"
#import "CommonLib.h"
#import "user.h"
#import "NSString+Extensions.h"
#import "SharedUICode.h"
#import "threaddefines.h"



@implementation TimeEntryHistoryViewController


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    _clockInLabel.text = [NSString stringWithFormat:@"Clocked In %@", _clockInDateTime];
    if (_clockOutDateTime != nil)
        _clockOutLabel.text = [NSString stringWithFormat:@"Clocked Out: %@", _clockOutDateTime];
    else
        _clockOutLabel.hidden = YES;
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];

    if ((_employeeName == nil) || ([_employeeName isEqualToString:@""]))
        self.title = @"Time History";
    else
        self.title = _employeeName;
    
    [_historyTable reloadData];

    [self getTimeEntryHistory];
    
}

-(void) getTimeEntryHistory
{
    [self callGetTimeEntryHistory:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [ErrorLogging logErrorWithDomain:@"TIME_ENTRY_HISTORY" code:UNKNOWN_ERROR description:@"ERROR_TIME_ENTRY_HISTORY" error:aError];
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else
        {
         //   NSError *error = nil;
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
        //    NSArray *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
            
            //sometimes we get a json object (usually when something goes wrong) and other times we get an array of time entries
        #ifndef RELEASE
         //   NSString* JSONStr = [[NSString alloc] initWithData:data
          //                                            encoding:NSUTF8StringEncoding];
            
        #endif
            NSString *resultMessage = [aResults valueForKey:@"message"];

            if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
        //        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from TimeSheetMasterViewController.m JSON Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"ERROR"
                                             message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];
                
              //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Server Failure" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
             //   [alert show];
            }
            else
            {
                NSArray *timeEntriesAuditsArray = [aResults valueForKey:@"timeEntryAudits"];
                
                NSString *status, *modifiedByName, *notes, *action;
                
                historyItems = [[NSMutableArray alloc] initWithCapacity:0];
            
                for (NSDictionary *timeEntryAuditRec in timeEntriesAuditsArray){
                    
                    status = [timeEntryAuditRec valueForKey:@"status"];
                    modifiedByName = [timeEntryAuditRec valueForKey:@"modifiedBy"];
                    if ([modifiedByName isEqual:[NSNull null]]  || (modifiedByName == nil))
                        modifiedByName = @"Unknown";
                    
                    action = [timeEntryAuditRec valueForKey:@"log"];
                    
                    notes = [timeEntryAuditRec valueForKey:@"notes"];

                    NSString *clockInTime = [NSString stringWithFormat: @"%@",[timeEntryAuditRec valueForKey:@"clockInIso8601"]];
                    clockInTime  = [clockInTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                    
                    NSDate *DateValue = [formatterISO8601DateTime dateFromString:clockInTime];
                    clockInTime = [formatterDateTime12 stringFromDate:DateValue];
                  
                    NSString *clockOutTime = [NSString stringWithFormat: @"%@",[timeEntryAuditRec valueForKey:@"clockOutIso8601"]];
         
                    clockOutTime  = [clockOutTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                    
                    DateValue = [formatterISO8601DateTime dateFromString:clockOutTime];
                    clockOutTime = [formatterDateTime12 stringFromDate:DateValue];
                    
                    if ([clockOutTime isEqual:[NSNull null]] || (clockOutTime == nil))
                    {
                        clockOutTime = @"";
                        if ([notes isEqualToString:@""])
                            notes = @"Clocked In";
                    }
                    else{
                        if ([notes isEqual:[NSNull null]])
                            notes = @"";
                        else if ([notes isEqualToString:@""])
                            notes = @"Clocked Out";
                    }
                    NSString *modifiedTime = [NSString stringWithFormat: @"%@",[timeEntryAuditRec valueForKey:@"modifiedIso"]];
                    modifiedTime  = [modifiedTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
                    
                    DateValue = [formatterISO8601DateTime dateFromString:modifiedTime];
                    modifiedTime = [formatterDateTime12 stringFromDate:DateValue];

                    NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
                    [item setValue:clockInTime forKey:@"clockInTime"];
                    [item setValue:clockOutTime forKey:@"clockOutTime"];
                    [item setValue:notes forKey:@"notes"];
                    [item setValue:modifiedByName forKey:@"modifiedBy"];
                    [item setValue:modifiedTime forKey:@"modifiedDateTime"];
                    [item setValue:status forKey:@"status"];
                    [item setValue:action forKey:@"action"];
                    [historyItems addObject:item];
                    
                }
                

                [_historyTable reloadData];

            }

        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    formatterISO8601DateTime = [[NSDateFormatter alloc] init];
    [formatterISO8601DateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    [formatterISO8601DateTime setTimeZone:[NSTimeZone localTimeZone]];
    formatterDateTime12 = [[NSDateFormatter alloc] init];
  //  [formatterDateTime12 setDateFormat:@"MM/dd/yyyy h:mm a"];
    [formatterDateTime12 setDateFormat:@"EEE, MM/dd/yyyy h:mm a"];
    [self startSpinnerWithMessage:@"Retrieving data..."];

    
}

- (void)viewDidUnload
{    
    [super viewDidUnload];

}

-(void) doDoneClick{
    [self.delegate historyTimeEntryViewControllerDidFinish:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [historyItems count];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.f;
}

//because we are overridng the color of the section header we'll also need to set the Header text
//because by using this method it will override whatever is in titleForHeaderInSection method
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *tempView=[[UIView alloc]initWithFrame:CGRectMake(0,200,400,244)];
    tempView.backgroundColor = UIColorFromRGB(BLUE_TOOLBAR_COLOR);
    UILabel *tempLabel=[[UILabel alloc]initWithFrame:CGRectMake(15,0,400,36)];
    tempLabel.backgroundColor=[UIColor clearColor];
    tempLabel.textColor = [UIColor whiteColor];
    tempLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0f];
    tempLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    
    NSMutableDictionary *item = [historyItems objectAtIndex:section];

    tempLabel.text =   [NSString stringWithFormat:@"Action: %@ on %@", [item valueForKey:@"action"], [item valueForKey:@"modifiedDateTime"]];
    //tempLabel.text =   [NSString stringWithFormat:@"Modified On %@", [item valueForKey:@"modifiedDateTime"]];
    
    
    [tempView addSubview:tempLabel];
    
    return tempView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return 1;

    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"HistoryCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSMutableDictionary *item = [historyItems objectAtIndex:indexPath.section];
    
    // Configure Cell
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:10];
    NSString *modifiedByName = [NSString stringWithFormat:@"Action By: %@", [item valueForKey:@"modifiedBy"]];
    
    [nameLabel setText:  modifiedByName];

    UILabel *clockInLabel = (UILabel *)[cell.contentView viewWithTag:11];
    NSString *clockedInTime = [NSString stringWithFormat:@"Clock In Time: %@", [item valueForKey:@"clockInTime"]];
    
    [clockInLabel setText:clockedInTime];
    
    UILabel *clockOutLabel = (UILabel *)[cell.contentView viewWithTag:12];
    NSString *clockOutValue = [item valueForKey:@"clockOutTime"];
    NSString *clockedOutTime = [NSString stringWithFormat:@"Clock Out Time: %@", clockOutValue];
    
    [clockOutLabel setText:clockedOutTime];
    
    UILabel *noteLabel = (UILabel *)[cell.contentView viewWithTag:13];
    
    NSString *notes = @"Notes:";
    if (![[item valueForKey:@"notes"] isEqualToString:@"[note empty]"])
        notes = [NSString stringWithFormat:@"Notes: %@", [item valueForKey:@"notes"]];
    
    [noteLabel setText: notes]; //@"Note: Had to update the clock in because my employee forgot to it and this is the second time he forgot"];
   // noteLabel.textColor = [UIColor colorWithRed:81.0/255.0 green:102.0/255.0 blue:145.0/255.0 alpha:1.0];
    
    


     return cell;
}

//-(void) callGetTimeEntryHistory{
-(void) callGetTimeEntryHistory:(int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    NSString *request_body;
    UserClass *user = [UserClass getInstance];
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/timeentry/%@/audits", SERVER_URL, _timeEntryID];
    
     NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    
    request_body = [NSString
                    stringWithFormat:@"timeEntryId=%@",
                    [ _timeEntryID stringByAddingPercentEncodingWithAllowedCharacters: set]];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    
    //set HTTP Method
    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;
    
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"employerId"];
    [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"authToken"];
    
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

    
    //set request body into HTTPBody.
    //    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set request url to the NSURLConnection
  /*  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest  delegate:self startImmediately:YES];
    if (connection)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    else {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
      //  alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connection to the server failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
        
    }
    */
    
}


-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
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
            
           // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
          //  [alert show];
        }
    }
    
    
    data = [[NSMutableData alloc] init];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataIn
{
    [data appendData:dataIn];
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self stopSpinner];
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"ERROR"
                                 message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
  //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"ezClocker is unable to connect to the server at this time. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
  //  [alert show];
    
    connection = nil;
    data = nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self stopSpinner];
    NSError *error = nil;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSArray *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    
    //sometimes we get a json object (usually when something goes wrong) and other times we get an array of time entries
#ifndef RELEASE
 //   NSString* JSONStr = [[NSString alloc] initWithData:data
  //                                            encoding:NSUTF8StringEncoding];
    
#endif
    NSString *resultMessage = [results valueForKey:@"message"];

    if (([resultMessage isEqual:[NSNull null]]) || (![resultMessage isEqualToString:@"Success"])){
//        [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from TimeSheetMasterViewController.m JSON Error= %@ resultMessage= %@", error.localizedDescription, resultMessage]];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"ezClocker is unable to connect to the server at this time. Please try again later"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
      //  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Server Failure" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //   [alert show];
    }
    else
    {
        NSArray *timeEntriesAuditsArray = [results valueForKey:@"timeEntryAudits"];
        
        NSString *status, *modifiedByName, *notes, *action;
        
        historyItems = [[NSMutableArray alloc] initWithCapacity:0];
    
        for (NSDictionary *timeEntryAuditRec in timeEntriesAuditsArray){
            
            status = [timeEntryAuditRec valueForKey:@"status"];
            modifiedByName = [timeEntryAuditRec valueForKey:@"modifiedBy"];
            if ([modifiedByName isEqual:[NSNull null]]  || (modifiedByName == nil))
                modifiedByName = @"Unknown";
            
            action = [timeEntryAuditRec valueForKey:@"log"];
            
            notes = [timeEntryAuditRec valueForKey:@"notes"];

            NSString *clockInTime = [NSString stringWithFormat: @"%@",[timeEntryAuditRec valueForKey:@"clockInIso8601"]];
            clockInTime  = [clockInTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
            
            NSDate *DateValue = [formatterISO8601DateTime dateFromString:clockInTime];
            clockInTime = [formatterDateTime12 stringFromDate:DateValue];
          
            NSString *clockOutTime = [NSString stringWithFormat: @"%@",[timeEntryAuditRec valueForKey:@"clockOutIso8601"]];
 
            clockOutTime  = [clockOutTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
            
            DateValue = [formatterISO8601DateTime dateFromString:clockOutTime];
            clockOutTime = [formatterDateTime12 stringFromDate:DateValue];
            
            if ([clockOutTime isEqual:[NSNull null]] || (clockOutTime == nil))
            {
                clockOutTime = @"";
                if ([notes isEqualToString:@""])
                    notes = @"Clocked In";
            }
            else{
                if ([notes isEqual:[NSNull null]])
                    notes = @"";
                else if ([notes isEqualToString:@""])
                    notes = @"Clocked Out";
            }
            NSString *modifiedTime = [NSString stringWithFormat: @"%@",[timeEntryAuditRec valueForKey:@"modifiedIso"]];
            modifiedTime  = [modifiedTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
            
            DateValue = [formatterISO8601DateTime dateFromString:modifiedTime];
            modifiedTime = [formatterDateTime12 stringFromDate:DateValue];

            NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
            [item setValue:clockInTime forKey:@"clockInTime"];
            [item setValue:clockOutTime forKey:@"clockOutTime"];
            [item setValue:notes forKey:@"notes"];
            [item setValue:modifiedByName forKey:@"modifiedBy"];
            [item setValue:modifiedTime forKey:@"modifiedDateTime"];
            [item setValue:status forKey:@"status"];
            [item setValue:action forKey:@"action"];
            [historyItems addObject:item];
            
        }
        

        [_historyTable reloadData];

    }
}


@end
