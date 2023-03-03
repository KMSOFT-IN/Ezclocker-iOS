//
//  LocationDetailViewController
//  ezClocker
//
//  Created by Raya Khashab on 12/12/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import "LocationDetailViewController.h"
#import "user.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "SharedUICode.h"
#import "NSData+Extensions.h"
#import <GooglePlaces/GooglePlaces.h>
#import "NSString+Extensions.h"
#import <CoreLocation/CoreLocation.h>
#import "LocationManager.h"

@interface LocationDetailViewController () <GMSAutocompleteViewControllerDelegate>

@end

@implementation LocationDetailViewController

int SECTION_OPTIONS = 0;
int SECTION_ASSIGNED_EMPLOYEES = 1;

int NAME_ROW = 0;
int ADDRESS_ROW = 1;
int PHONE_ROW = 2;

int CREATE_LOCATION = 1;
int UPDATE_LOCATION = 2;

int GET_ALL_EMPLOYEES_FROM_LOCATION = 1;
int ADD_EMPLOYEE_TO_LOCATION = 2;
int DELETE_EMPLOYEE_FROM_LOCATION = 3;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_locationDetails == nil)
        _locationDetails = [[NSMutableDictionary alloc] init];
    
    UserClass *user = [UserClass getInstance];
    employeeList = [[NSMutableArray alloc] initWithArray:[user.employeeNameIDList allValues]];



    
    [self addDoneButtonToKeyboards];
    
    UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(onSaveClick)];
    
    _cityStateZipLabel.hidden = YES;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    if (assignedEmployeeList == nil)
        assignedEmployeeList = [NSMutableArray new];
    
    if ((_locationDetails != nil) && ([_locationDetails count] > 0))
    {
        NSString *name = [_locationDetails valueForKey:@"name"];
        _nameLabel.text = name;
        NSString *streetAddress = [_locationDetails valueForKey:@"streetAddress"];
        NSString *csz = [_locationDetails valueForKey:@"csz"];

        if (!([streetAddress length] > 1))
        {
            _addressLabel.text = csz;
            _addressLabel.textColor = [UIColor blackColor];
        }
        else
        {
            _addressLabel.text = streetAddress;
            _addressLabel.textColor = [UIColor blackColor];
            _cityStateZipLabel.text = csz;
            _cityStateZipLabel.textColor = [UIColor blackColor];
            _cityStateZipLabel.hidden = NO;
            
        }
        NSString *phoneNumber = [_locationDetails valueForKey:@"phoneNumber"];
        _phoneLabel.text = phoneNumber;
        
     }
    
    _locationDetailsTable.allowsSelectionDuringEditing = YES;
    _locationDetailsTable.allowsMultipleSelectionDuringEditing = NO;
    
   // _locationDetailsTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];


    UIColor *separatorColor = [_locationDetailsTable separatorColor];
    _separatorLbl1.textColor = separatorColor;
    _separatorLbl2.textColor = separatorColor;
    
    UITapGestureRecognizer* gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedOnAddress:)];
    // if labelView is not set userInteractionEnabled, you must do so
    [_addressLabel setUserInteractionEnabled:YES];
    [_addressLabel addGestureRecognizer:gesture];
 
    [self setFramePicker];
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
    pickerViewEmployeeName = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerViewEmployeeName.dataSource = self;
    pickerViewEmployeeName.delegate = self;
    if ((_locationDetails != nil) && ([_locationDetails count] > 0))
        
        [self getAssignedEmployees];
}

- (void)viewDidUnload
{
    
    pickerToolbar = nil;
    pickerMainView = nil;
    
    [super viewDidUnload];
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
-(IBAction)EmployeePickerDoneClick{
    NSInteger row = [pickerViewEmployeeName selectedRowInComponent:0];
    
    NSString *employeeName = [employeeList objectAtIndex:row];
    NSString *employeeID;
    UserClass *user = [UserClass getInstance];
    NSArray *employeesObjs = [user.employeeNameIDList allKeysForObject:employeeName];
    if ([employeesObjs count] > 0)
    {
        employeeID = [employeesObjs objectAtIndex:0];
    }
    
    NSDictionary *employeeObj = [[NSMutableDictionary alloc] init];
    [employeeObj setValue:employeeName forKey:@"employeeName"];
    [employeeObj setValue:employeeID forKey:@"employeeId"];
    [assignedEmployeeList addObject:employeeObj];
    
    [self closeEmployeePicker:self];
    
    [_locationDetailsTable reloadData];
}

-(void) showEmployeePicker{
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

    

/*    for (NSString *name in employeeList)
    {
        if ([name isEqualToString:_employeeButton.titleLabel.text])
            pos = row;
        else
            row++;
    }
    [pickerViewEmployeeName selectRow:pos inComponent:0 animated:YES];
*/

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

    
}
-(IBAction)EmployeePickerCancelClick{
    [self closeEmployeePicker:self];
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
    _phoneLabel.inputAccessoryView = keyboardToolbar;
    _nameLabel.inputAccessoryView = keyboardToolbar;
}

-(void)userTappedOnAddress:(UIGestureRecognizer*)gestureRecognizer;

{
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;
    CLLocation *loc = [LocationManager defaultLocationManager].lastKnownLocation;

    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];
    bounds = [bounds includingCoordinate:loc.coordinate];

    acController.autocompleteBounds = bounds;
    //for the iPad version we want the dialog to cover the popup view
#ifdef IPAD_VERSION
    acController.modalPresentationStyle = UIModalPresentationCurrentContext;
#endif
    [self presentViewController:acController animated:YES completion:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];

   // [self setAppRatedValue];
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
    tempLabel.text =  @"Employees At This Location";
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
    if (_locationDetailsTable.editing) {
        [_locationDetailsTable setEditing:NO animated:TRUE];
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
        [_locationDetailsTable setEditing:NO animated:YES];
        return;
    }
    
    //    [self beforeEditingBegins];
    [_locationDetailsTable setEditing:YES animated:YES];
    
    //hide the edit button and show the cancel button
    editButton.hidden = YES;
    addButton.hidden = YES;
    cancelButton.hidden = NO;
    
    
}- (void)setCancelState {
    if (self.editing) { // Not editing go into edit mode
        [_locationDetailsTable setEditing:NO animated:YES];
        return;
    }
    
    //    [self beforeEditingBegins];
    [_locationDetailsTable setEditing:YES animated:YES];
    
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
    
}

- (void)deleteAssignedEmployeeAtIndexPath:(NSIndexPath*)indexPath {
    [_locationDetailsTable setEditing:NO animated: YES];
//    [self onCancelClick:self];
  //  NSDictionary *employeeObj = [assignedEmployeeList objectAtIndex:indexPath.row];
    
  //  NSString *employeeID = [employeeObj valueForKey:@"employeeId"];
    [assignedEmployeeList removeObjectAtIndex:indexPath.row];
    // Delete the row from the data source
    [_locationDetailsTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    //reset
    [self cancelEditing];
    
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
        cell.textLabel.text = employeeName;
        
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

// Handle the user's selection.
- (void)viewController:(GMSAutocompleteViewController *)viewController
didAutocompleteWithPlace:(GMSPlace *)place {
    [self dismissViewControllerAnimated:YES completion:nil];
    // Do something with the selected place.
//    _addressLabel.text = place.formattedAddress;
//    _nameLabel.text = place.name;
    
    
    NSArray *addressComponents = place.addressComponents;
    
    streetNumber = @"";
    streetName = @"";
    city = @"";
    state = @"";
    zipCode = @"";
    country = @"";
    
    for (int i=0;i<[addressComponents count];i++) {
        if ([[[addressComponents objectAtIndex:i] valueForKey:@"type"] isEqualToString:@"street_number"]) {
            streetNumber = [[addressComponents objectAtIndex:i] valueForKey:@"name"];
            [_locationDetails setValue:streetNumber forKey:@"streetNumber"];
        }
        else if ([[[addressComponents objectAtIndex:i] valueForKey:@"type"] isEqualToString:@"route"]) {
            streetName = [[addressComponents objectAtIndex:i] valueForKey:@"name"];
            [_locationDetails setValue:streetName forKey:@"streetName"];
        }
        else if ([[[addressComponents objectAtIndex:i] valueForKey:@"type"] isEqualToString:@"locality"]) {
            city = [[addressComponents objectAtIndex:i] valueForKey:@"name"];
            [_locationDetails setValue:city forKey:@"city"];
        }
        else if ([[[addressComponents objectAtIndex:i] valueForKey:@"type"] isEqualToString:@"administrative_area_level_1"]) {
            state = [[addressComponents objectAtIndex:i] valueForKey:@"name"];
            [_locationDetails setValue:state forKey:@"_state"];
        }
        else if ([[[addressComponents objectAtIndex:i] valueForKey:@"type"] isEqualToString:@"postal_code"]) {
            zipCode = [[addressComponents objectAtIndex:i] valueForKey:@"name"];
            [_locationDetails setValue:zipCode forKey:@"postalCode"];
        }
        else if ([[[addressComponents objectAtIndex:i] valueForKey:@"type"] isEqualToString:@"country"]) {
            country = [[addressComponents objectAtIndex:i] valueForKey:@"name"];
            [_locationDetails setValue:country forKey:@"country"];
        }
    }
    NSString *street = [NSString stringWithFormat:@"%@ %@", streetNumber, streetName];
    if ([street length] > 1)
    {
        _addressLabel.text = street;
        _addressLabel.textColor = [UIColor blackColor];
 
    }
    NSString *csz = [NSString stringWithFormat:@"%@, %@ %@", city, state, zipCode];
    if ([csz length] > 3)
    {
        if (!([street length] > 1))
        {
            _addressLabel.text = csz;
            _addressLabel.textColor = [UIColor blackColor];
        }
        else
        {
            _cityStateZipLabel.text = csz;
            _cityStateZipLabel.textColor = [UIColor blackColor];
            _cityStateZipLabel.hidden = NO;
            
        }
        
    }

}

- (void)viewController:(GMSAutocompleteViewController *)viewController
didFailAutocompleteWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    // TODO: handle the error.
    NSLog(@"Error: %@", [error description]);
}

// User canceled the operation.
- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Turn the network activity indicator on and off again.
- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void) callEmployerLocationBatchAPI:(int)operation withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    NSString *httpPostString;
    NSString *locID;
    if (operation == CREATE_LOCATION)
        httpPostString = [NSString stringWithFormat:@"%@api/v1/location", SERVER_URL];
    else //we are doing a location update
    {
        locID = [_locationDetails valueForKey:@"id"];
        httpPostString = [NSString stringWithFormat:@"%@api/v1/location/modify", SERVER_URL];
    }
    
    NSMutableArray *assignedEmployeesList = [[NSMutableArray alloc] init];
    for (NSDictionary *employeeObj in assignedEmployeeList)
    {
        [assignedEmployeesList addObject:employeeObj ];
    }
    
    NSString *_name = _nameLabel.text;
    NSString *_phone = _phoneLabel.text;
    streetNumber =  [_locationDetails valueForKey:@"streetNumber"] ? [_locationDetails valueForKey:@"streetNumber"] : @"";
    streetName =  [_locationDetails valueForKey:@"streetName"] ? [_locationDetails valueForKey:@"streetName"] : @"";
    city =  [_locationDetails valueForKey:@"city"] ? [_locationDetails valueForKey:@"city"] : @"";;
    state =  [_locationDetails valueForKey:@"_state"] ? [_locationDetails valueForKey:@"_state"] : @"";
    zipCode =  [_locationDetails valueForKey:@"postalCode"] ? [_locationDetails valueForKey:@"postalCode"] : @"";
    country =  [_locationDetails valueForKey:@"country"] ? [_locationDetails valueForKey:@"country"] : @"";

    NSDictionary *locationDetailsDict;
    if (operation == CREATE_LOCATION)
    {

        locationDetailsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              _name, @"name",
                              streetNumber, @"streetNumber",
                              streetName, @"streetName",
                              city, @"city",
                              state, @"_state",
                              zipCode, @"postalCode",
                              country, @"country",
                              _phone, @"phoneNumber",
                              curEmployerID, @"employerId",
                              nil];
    }
    else
    {
        locationDetailsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               locID, @"id",
                               _name, @"name",
                               streetNumber, @"streetNumber",
                               streetName, @"streetName",
                               city, @"city",
                               state, @"_state",
                               zipCode, @"postalCode",
                               country, @"country",
                               _phone, @"phoneNumber",
                               curEmployerID, @"employerId",
                               nil];

    }
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              locationDetailsDict, @"location",
                              assignedEmployeesList, @"assignedEmployees",
                              nil];
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:0
                                                         error:&error];
    NSString *JSONString;
    if (!jsonData) {
    } else {
        
        JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    request.HTTPBody = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    if (operation == CREATE_LOCATION)
    {
        [request setHTTPMethod:@"POST"];
        [request setValue:curEmployerID forHTTPHeaderField:@"employerId"];
        [request setValue:curAuthToken forHTTPHeaderField:@"authToken"];

    }
    else //we are doing a location update
    {
        [request setHTTPMethod:@"PATCH"];
        [request setValue:curEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
        [request setValue:curAuthToken forHTTPHeaderField:@"x-ezclocker-authToken"];

    }
    
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

-(void) callEmployerLocationAPI:(int)operation withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    NSString *httpPostString;
    if (operation == CREATE_LOCATION)
        httpPostString = [NSString stringWithFormat:@"%@api/v1/location", SERVER_URL];
    else //we are doing a location update
    {
        NSString *locID = [_locationDetails valueForKey:@"id"];
        httpPostString = [NSString stringWithFormat:@"%@api/v1/location/%@", SERVER_URL, locID];
    }
    NSString *_name = _nameLabel.text;
    NSString *_phone = _phoneLabel.text;
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              _name, @"name",
                              streetNumber, @"streetNumber",
                              streetName, @"streetName",
                              city, @"city",
                              state, @"_state",
                              zipCode, @"postalCode",
                              country, @"country",
                              _phone, @"phoneNumber",
                              nil];
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:0
                                                         error:&error];
    NSString *JSONString;
    if (!jsonData) {
    } else {
        
        JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    request.HTTPBody = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    
    
//    if (operation == CREATE_LOCATION)
        [request setHTTPMethod:@"POST"];
//    else //we are doing a location update
//        [request setHTTPMethod:@"PUT"];
    
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


-(void) callEmployeeAssignedLocationAPI:(int)operation employeeID: empId withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    NSString *httpPostString;
    NSString *locID = [_locationDetails valueForKey:@"id"];
    httpPostString = [NSString stringWithFormat:@"%@api/v1/location/%@/assigned_employees", SERVER_URL, locID];

    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    if (operation == ADD_EMPLOYEE_TO_LOCATION)
    {
        [request setHTTPMethod:@"PUT"];
    }
    else if (operation == DELETE_EMPLOYEE_FROM_LOCATION)
    {
        [request setHTTPMethod:@"DELETE"];

    }
    //else default to GET
    else
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
 

-(void) callGetAppRated:(int)operation withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    NSString *httpPostString;
    httpPostString = [NSString stringWithFormat:@"%@api/v1/account/acceptedReviewPrompt", SERVER_URL];
    
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    NSString *userName = @"ez.comp2@mailinator.com";
    NSString *userID = @"";
    NSString *accepted = @"true";
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              userName, @"userName",
                              userID, @"userId",
                              accepted, @"accepted",
                              nil];
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:0
                                                         error:&error];
    NSString *JSONString;
    if (!jsonData) {
    } else {
        
        JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }

    request.HTTPBody = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setHTTPMethod:@"POST"];
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

-(void) getAssignedEmployees
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    [self callEmployeeAssignedLocationAPI:GET_ALL_EMPLOYEES_FROM_LOCATION employeeID: 0 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue in retrieving data from server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        
        NSArray *employees = [aResults valueForKey:@"employees"];
        NSString *employeeName = @"";
        NSString *employeeID = @"";
        NSDictionary *curEmployee;
        [assignedEmployeeList removeAllObjects];
        
        if ([employees count] > 0)
        {
            for (NSDictionary *employeeObj in employees){
                curEmployee = [employeeObj valueForKey:@"employee"];
                employeeName = [curEmployee valueForKey:@"employeeName"];
                employeeID = [curEmployee valueForKey:@"id"];
                BOOL isEmpty = [NSString isNilOrEmpty:employeeName];

                if (!isEmpty){
                   NSDictionary *employeeObj = [[NSMutableDictionary alloc] init];
                    [employeeObj setValue:employeeName forKey:@"employeeName"];
                    [employeeObj setValue:employeeID forKey:@"employeeId"];
                    [assignedEmployeeList addObject:employeeObj];
                }

            }
            @try{
                
            [_locationDetailsTable reloadData];
            }@catch (NSException *theException) {
                NSLog(@"%@ doClockOutBtnClick check error!", [theException name]);

            }
        }
//        [self.delegate LocationDetailsDidFinish:self CancelWasSelected:NO];
        
    }];
    
}
/*-(void) deleteAssignedEmployees: (NSString*) _employeeID
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    [self callEmployeeAssignedLocationAPI:DELETE_EMPLOYEE_FROM_LOCATION employeeID: _employeeID withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue in retrieving data from server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        
    }];
    
}
*/
-(void) setAppRatedValue
{
    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    [self callGetAppRated:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
        [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue in retrieving data from server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        [self.delegate LocationDetailsDidFinish:self CancelWasSelected:NO];
        
    }];
    
}
-(void) onSaveClick
{
    BOOL isEmpty = [NSString isNilOrEmpty:_nameLabel.text];

    if (isEmpty)
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Please enter a location name"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

      //  UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a location name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      //  [alert show];
    }
    else{
        int mode = CREATE_LOCATION;
        //if we have a location ID then this is an edit not create
        if ((_locationDetails) && ([_locationDetails objectForKey:@"id"]) )
            mode = UPDATE_LOCATION;
        [self callEmployerLocationBatchAPI:mode withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
            [self stopSpinner];
            if (aErrorCode != 0) {
                [SharedUICode messageBox:nil message:@"There was an issue saving the location. Please try again later" withCompletion:^{
                    return;
                }];
                
            }
            [self.delegate LocationDetailsDidFinish:self CancelWasSelected:NO];
            
        }];

        
    }

    
/*    if ([_nameLabel.text length] == 0) {
        UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter a location name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
    else
    {
        [self startSpinnerWithMessage:@"Saving, please wait..."];
        int operation = CREATE_LOCATION;
        if ((_locationDetails != nil) && ([_locationDetails count] > 0))
            operation = UPDATE_LOCATION;
    
        [self callEmployerLocationAPI:operation withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError){
            [self stopSpinner];
            if (aErrorCode != 0) {
                [SharedUICode messageBox:nil message:@"There was an issue saving the location. Please try again later" withCompletion:^{
                return;
                }];
            
            }
            [self.delegate LocationDetailsDidFinish:self CancelWasSelected:NO];

        }];
 
    }
 */
}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [employeeList count];
}

#pragma mark Picker Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *name = [employeeList objectAtIndex:row];
    
    return name;
}


@end
