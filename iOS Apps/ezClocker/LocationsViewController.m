//
//  LocationsViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 12/12/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import "LocationsViewController.h"
#import "ECSlidingViewController.h"
#import "LocationDetailViewController.h"
#import "user.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "NSData+Extensions.h"
#import "LocationsWebService.h"

@interface LocationsViewController ()

@end

@implementation LocationsViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.title = NSLocalizedString(@"Locations", @"Locations");
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    UIView *customView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 44)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, customView.frame.size.width, 44)];
    titleLabel.text = @"Locations";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [customView addSubview:titleLabel];
    self.navigationItem.titleView = customView;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];

//    [self fetchData];
    self.title = NSLocalizedString(@"Locations", @"Locations");
    [self getAllLocations];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    UserClass *user = [UserClass getInstance];
    return [user.locationNameAddressList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
    }
    UserClass *user = [UserClass getInstance];
    NSArray *locations = user.locationNameAddressList;
    if ([locations count] > 0)
    {
        NSDictionary *locObj = [locations objectAtIndex:indexPath.row];
        cell.textLabel.text = [locObj valueForKey:@"name"];
        cell.detailTextLabel.text =[locObj valueForKey:@"fullAddress"];

    }
    //valueForKey:@"type"] ];
   // if ([[[addressComponents objectAtIndex:i] valueForKey:@"type"] isEqualToString:@"street_number"]) {
    //    streetNumber = [[addressComponents objectAtIndex:i] valueForKey:@"name"];
   // }

    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

-(void) callDeleteLocation:(NSNumber*)locID withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    NSString *request_body;
    UserClass *user = [UserClass getInstance];
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    
    httpPostString = [NSString stringWithFormat:@"%@api/v1/location/%@", SERVER_URL, locID];
    //Implement request_body for send request here authToken and clock DateTime set into the body.
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    request_body = [NSString
                    stringWithFormat:@"authToken=%@",
                    [user.authToken  stringByAddingPercentEncodingWithAllowedCharacters: set]
                    ];
    
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    urlRequest.timeoutInterval = TIME_OUT_REQUEST;
    
    
    //set HTTP Method
    [urlRequest setHTTPMethod:@"DELETE"];
    
    //set request body into HTTPBody.
    [urlRequest setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:curEmployerID forHTTPHeaderField:@"employerId"];
    [urlRequest setValue:curAuthToken forHTTPHeaderField:@"authToken"];

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
//    [self stopSpinner];
    
}


- (void)deleteLocationAtIndexPath:(NSIndexPath*)indexPath {
    UserClass *user = [UserClass getInstance];
    NSMutableDictionary *location =  [user.locationNameAddressList objectAtIndex:indexPath.row];
    NSNumber *locID = [location valueForKey:@"id"];
    [_locationListTable setEditing:NO animated: YES];

    [self onCancelClick:self];
//    editFlag = NO;
//    [self callDeleteLocation: locID];
    
    [self startSpinnerWithMessage:@"Deleting, please wait..."];

    [self callDeleteLocation:locID withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        else{
            [user.locationNameAddressList removeObjectAtIndex:indexPath.row];
            // Delete the row from the data source
            [_locationListTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
 
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
/*    if (mode != OperationNone) {
        [SharedUICode messageBox:nil message:@"Cannot delete at this time.  Currently processing a request.  Please try again in a few minutes." withCompletion:^{
            
        }];
        return;
    }
*/
    UIView *view = [cancelButton valueForKey:@"view"];
    
    [SharedUICode yesNoCancel:nil message:@"Delete Location.  Are you sure?" yesBtnTitle:@"Yes - Please Delete" noBtnTitle:@"No - Do Not Delete" cancelBtnTitle:@"Cancel - Cancel Editing" rootControl:view withCompletion:^(YesNoCancelResult Result) {
        switch (Result) {
            case resultYes: {
                [self deleteLocationAtIndexPath:indexPath];
                break;
            }
            case resultNo:
                break;
            default: {
                [self onCancelClick:self];
                break;
            }
        }
    }];

}


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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //prevent the user from leaving the employee list while in edit mode
    if (self.tableView.editing) {
        [SharedUICode messageBox:nil message:@"You cannot view location details while in edit mode.  Cancel editing or tap the red icon to delete the location." withCompletion:^{
            
        }];
        return;
    }

    LocationDetailViewController *locationDetailViewConroller;
    locationDetailViewConroller = [self.storyboard instantiateViewControllerWithIdentifier:@"LocationDetails"];
        
    // ...
    // Pass the selected object to the new view controller.
    UserClass *user = [UserClass getInstance];
    locationDetailViewConroller.locationDetails = [user.locationNameAddressList objectAtIndex:indexPath.row];
    
    locationDetailViewConroller.delegate = self;

    [self.navigationController pushViewController:locationDetailViewConroller animated:YES];

        
}
-(void) getAllLocations
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    LocationsWebService *locationWebService = [[LocationsWebService alloc] init];
    locationWebService.delegate = self;
    [locationWebService fetchAllLocations];
}

- (void)LocationsServiceCallDidFinish:(LocationsWebService *)controller ErrorCode: (int) errorValue;
{
    [self stopSpinner];
    if (errorValue != 0) {
        [SharedUICode messageBox:nil message:@"There was an issue fetching the locations from the server. Please try again later" withCompletion:^{
            return;
        }];
        
    }
    else

        [_locationListTable reloadData];

    
}


-(void) callGetAllLocations:(bool)useSavedValues withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    
    NSString *httpPostString = [NSString stringWithFormat:@"%@api/v1/location", SERVER_URL];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:curEmployerID forHTTPHeaderField:@"employerId"];
    [request setValue:curAuthToken forHTTPHeaderField:@"authToken"];
    
    
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

-(void) fetchData
{
    UserClass *user = [UserClass getInstance];
    
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callGetAllLocations:YES withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue fetching the locations from the server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        NSArray *locations = [aResults valueForKey:@"locations"];
        NSString *_name;
        NSString *_fullAddress;
        NSString *_streetAddress;
        NSString *_csz;
        NSString *_id;
        NSString *_phoneNumber;
        NSMutableDictionary *_location;
        [user.locationNameAddressList removeAllObjects];
        for (NSDictionary *location in locations){
            _name = [location valueForKey:@"name"];
            _id = [location valueForKey:@"id"];
            _phoneNumber = [location valueForKey:@"phoneNumber"];
            _fullAddress = [NSString stringWithFormat:@"%@ %@ %@, %@ %@", [location valueForKey:@"streetNumber"], [location valueForKey:@"streetName"] ,[location valueForKey:@"city"], [location valueForKey:@"_state"], [location valueForKey:@"postalCode"]];
            _streetAddress = [NSString stringWithFormat:@"%@ %@", [location valueForKey:@"streetNumber"], [location valueForKey:@"streetName"]];
            _csz = [NSString stringWithFormat:@"%@, %@ %@", [location valueForKey:@"city"], [location valueForKey:@"_state"], [location valueForKey:@"postalCode"]];
            
            _location = [[NSMutableDictionary alloc] init];
            @try{
                [_location setValue:_name forKey:@"name"];
                [_location setValue:[location valueForKey:@"streetNumber"] forKey:@"streetNumber"];
                [_location setValue:[location valueForKey:@"streetName"] forKey:@"streetName"];
                [_location setValue:[location valueForKey:@"city"] forKey:@"city"];
                [_location setValue:[location valueForKey:@"_state"] forKey:@"_state"];
                [_location setValue:[location valueForKey:@"postalCode"] forKey:@"postalCode"];
                [_location setValue:_fullAddress forKey:@"fullAddress"];
                [_location setValue:_streetAddress forKey:@"streetAddress"];
                [_location setValue:_csz forKey:@"csz"];
                [_location setValue:_phoneNumber forKey:@"phoneNumber"];
                [_location setValue:_id forKey:@"id"];
            }
            @catch(NSException* ex) {
                NSLog(@"Exception: %@", ex);
            }
            [_location setValue:@"" forKey:@"streetNumber"];

            [user.locationNameAddressList addObject: _location];
            //get list of locations
            //employeeList = [[NSMutableArray alloc] initWithArray:[user.employeeNameIDList allValues]];
            //NSArray* arrayOfKeys = [user.employeeNameIDList allKeysForObject:_employeeButton.titleLabel.text];


      
        }
        [_locationListTable reloadData];
        
    }];
    
}


- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}


- (IBAction)onAddClick:(id)sender {
    
    locationDetailViewConroller = [self.storyboard instantiateViewControllerWithIdentifier:@"LocationDetails"];
    locationDetailViewConroller.delegate = self;

    [self.navigationController pushViewController:locationDetailViewConroller animated:YES];

}

- (void)setEditButtons {
    if (self.tableView.editing) {
        [self setEditing:NO animated:TRUE];
    }
    
    [self __setEditButtons];
}

- (void)__setEditButtons {
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:UIBarButtonItemStylePlain target:self action:@selector(revealMenu:)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddClick:)];
    
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditClick:)];
    // self.navigationItem.rightBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:editButton, addButton, nil];
    
}

- (void)setCancelButtonForSwipDelete {
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelClick:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    // self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.rightBarButtonItems = nil;
    
}
static BOOL __cancelling = FALSE;
- (void)onCancelClick:(id)sender {
    __cancelling = TRUE;
    @try {
        [self __cancelEditing];
    }
    @finally {
        __cancelling = FALSE;
    }
}

- (void)__cancelEditing {
    [self setEditButtons];
}

- (void)cancelEditing {
    if (nil == self.navigationItem.leftBarButtonItem) {
        return;
    }
    [self __cancelEditing];
}

- (void)setEditState {
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


- (IBAction)onEditClick:(id)sender {
    [self setEditState];
}

 -(void)LocationDetailModalViewDismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) LocationDetailSave
{
    [locationDetailViewConroller onSaveClick];

}

- (void)LocationDetailsDidFinish:(LocationDetailViewController *)controller CancelWasSelected:(bool)cancelWasSelected;
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
