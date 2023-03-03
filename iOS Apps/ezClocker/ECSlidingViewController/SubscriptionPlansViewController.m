//
//  SubscriptionPlansViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 2/22/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "SubscriptionPlansViewController.h"
#import "EZPurchaseManager.h"
#import "SKProduct+LocalizedPrice.h"
#import "ECSlidingViewController.h"
#import "CommonLib.h"
#import "user.h"
#import "CancelSubscriptionViewController.h"
#import "MetricsLogWebService.h"
#import "SubscriptionWebService.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"
#import "NSString+Extensions.h"
#import "NSNumber+Extensions.h"
#import "SharedUICode.h"


@interface SubscriptionPlansViewController ()

@end


@implementation SubscriptionPlansViewController

NSMutableArray* _subscriptionPlans;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        if (_subscriptionPlans == nil)
            _subscriptionPlans = [NSMutableArray new];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // [[EZPurchaseManager sharedInstance] addObserver:self forKeyPath:@"receiptDetails" options:NSKeyValueObservingOptionNew context:nil];
    isExpired = NO;
    flagTap = NO;
    NSArray* product = [[EZPurchaseManager sharedInstance] availableProducts];
    NSLog(@"Available product:%@", product);
    if (subscriptionPlansList == nil)
        subscriptionPlansList =  [[NSMutableArray alloc] init];
    
    [self getSubscriptionPlans];
    
    //call the subscription webservice to check if their subsription has expired
 //   [self startSpinnerWithMessage:@"Connecting to the server..."];
 //   SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
 //   subscriptionWebService.delegate = (id) self;
    // [subscriptionWebService callHasValidLicenseWebService];
 //   [subscriptionWebService checkValidLicense];
    
    [self.scrollView setContentInsetAdjustmentBehavior: NO];
//    self.automaticallyAdjustsScrollViewInsets = false;
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.scrollView.contentOffset = CGPointMake(0.0, 0.0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(receiveUpdateStatusNotification:)
    name:@"updateStatus"
    object:nil];
    
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [_scrollView setScrollEnabled:YES];
    [_scrollView setContentSize:CGSizeMake(320, 650)];
    
    // _mainView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    _mainView.backgroundColor = [UIColor whiteColor];
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];
    
    
    CGFloat contentHeight = _infoTextView.contentSize.height;
    CGFloat offSet = _infoTextView.contentOffset.x;
    CGFloat contentOffset = contentHeight - offSet;
    _infoTextView.contentOffset = CGPointMake(0, -contentOffset);
    
    _subscriptionPlansTable.rowHeight = UITableViewAutomaticDimension;
    _subscriptionPlansTable.estimatedRowHeight = 20;
    

}

- (void) receiveUpdateStatusNotification:(NSNotification *) notification {

    
    [_currentSubscriptionTable reloadData];
}

- (void)dealloc
{
    //Unwire KVO
    UserClass *user = [UserClass getInstance];
    if (([user.userType isEqualToString:@"employer"]) && ([user.subscription_planProvider isEqualToString:@"APPLE_SUBSCRIPTION"]))
    {
        [[EZPurchaseManager sharedInstance] removeObserver:self forKeyPath:@"receiptDetails"];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
    
}




-(void) callSubscriptionPlansAPI: (int)flag withCompletion:(ServerResponseCompletionBlock)completion
{
    NSString *httpPostString;
    
    
    httpPostString = [NSString stringWithFormat:@"%@subscriptionPlan/active", SERVER_URL];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    [urlRequest setHTTPMethod:@"GET"];
    
    
    //set header info
    [urlRequest setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    // NSString *tmpEmployerID = [user.employerID stringValue];
    // NSString *tmpAuthToken = user.authToken;
    // [urlRequest setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerid"];
    // [urlRequest setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authtoken"];
    
    
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

- (void)getSubscriptionPlans {
    [self startSpinnerWithMessage:@"Retrieving plans , please wait..."];
    [self callSubscriptionPlansAPI:1 withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
 //       [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue connecting to the server. Please try again later" withCompletion:^{
                return;
            }];
        }
        else{
            //remove the employee from the local employeelist
            //           [archiveEmployeeList removeObjectAtIndex:indexPath.row];
            // NSArray *plans = [aResults valueForKey:@"subscriptionPlan"];
            
            [_subscriptionPlans removeAllObjects];
            NSDictionary* plan;
            NSString* _planName;
            NSString* _planDescription;
            NSString* _planMaximumEmployees;
            NSString* _planId;
            NSMutableArray* _planEnabledfeatures;
            NSNumber* _planMonthlyFee;
            
            for (NSDictionary *curResult in aResults){
                plan = [curResult valueForKey:@"subscriptionPlan"];;
                NSMutableDictionary* _subscriptionPlan = [[NSMutableDictionary alloc] init];
                @try{
                    _planName = [plan valueForKey:@"name"];
                    _planDescription = [plan valueForKey:@"description"];
                    _planMaximumEmployees = [plan valueForKey:@"maximumEmployees"];
                    _planMonthlyFee = [plan valueForKey:@"appleStoreFee"];
                    _planId = [plan valueForKey:@"applePlanName"];
                    _planEnabledfeatures = [plan valueForKey:@"enabledFeatures"];
                    
                    [_subscriptionPlan setValue:_planDescription forKey:@"title"];
                    [_subscriptionPlan setValue:_planMaximumEmployees forKey:@"maximumEmployees"];
                    [_subscriptionPlan setValue:_planEnabledfeatures forKey:@"enabledFeatures"];
                    [_subscriptionPlan setValue:_planMonthlyFee forKey:@"price"];
                    
                    [_subscriptionPlan setValue:_planId forKey:@"applePlanId"];
                    
                    //ignore all the free and testing plans
                    if ((![NSNumber isNilOrNull:_planMonthlyFee]) && (_planMonthlyFee.integerValue != 0))
                        [_subscriptionPlans addObject: _subscriptionPlan];
                }
                @catch(NSException* ex) {
                    NSLog(@"Exception: %@", ex);
                }
            }
            _planMonthlyFee= 0;
        //    _subscriptionTableHeight.constant =  44 * (_subscriptionPlans.count);
            [_subscriptionPlansTable reloadData];
            

            //Call check valid license to get the updated current subscription
            SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
            subscriptionWebService.delegate = (id) self;
            [subscriptionWebService checkValidLicense];
        }
        
    }];
}

- (void)viewDidLayoutSubviews {
 //   [super updateViewConstraints];
  //  dispatch_async(dispatch_get_main_queue(), ^{
  //      _subscriptionTableHeight.constant =  _subscriptionPlansTable.contentSize.height;
  //  });
 }

-(void) doPurchase: (SKProduct*) product{
    [self startSpinnerWithMessage:@"Purchasing, please wait..."];
#ifndef DEBUG
    UserClass *user = [UserClass getInstance];
    //send the info the metric service to record this event if we are in production
  //  [MetricsLogWebService LogException: [NSString stringWithFormat:@"Somebody tried to purchase a subscription Yay!!!! userEmail: %@ employerID= %@", user.userEmail, user.employerID]];
#endif
    
    [[EZPurchaseManager sharedInstance] setDelegate: self];
    [[EZPurchaseManager sharedInstance] purchaseProduct:product];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _currentSubscriptionTable)
        return 3;
    else
        //return [[[EZPurchaseManager sharedInstance] availableProducts] count];
        return [_subscriptionPlans count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0 ];
        
    }
    
    if (tableView == _currentSubscriptionTable)
    {
        UserClass *user = [UserClass getInstance];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 120, 30)];
        label.font = [UIFont boldSystemFontOfSize:14.0 ];
        label.textAlignment= NSTextAlignmentCenter;
        
        if (indexPath.row == 0){
            cell.textLabel.text = @"Current Subscription";
            //if the plan provider is our Free always plan thens how Free else put the price
            if (user.subscription_planProvider == nil) {
                label.text = @"Free";
                cell.detailTextLabel.text = @"Up to 1 employee";
            } else
            if ([user.subscription_planProvider isEqualToString:@"EZCLOCKER_SUBSCRIPTION"])
                //           if (user.subscription_freePlanActive)
            {
                label.text = @"Free";
                cell.detailTextLabel.text = @"Up to 1 employee";
            }
            else{
                if (isExpired) {
                    label.text = [NSString stringWithFormat:@"%@ (Expired)", user.subscription_PlanPrice];
                } else {
                    label.text = user.subscription_PlanPrice;
                }
                cell.detailTextLabel.text = @"";
                /* cell.detailTextLabel.text = @"Active";//@"";
                 cell.detailTextLabel.textColor = [UIColor greenColor];
                 cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
                 */
            }
            cell.accessoryView = label;
        }
        
        else if (indexPath.row == 1){
            cell.textLabel.text = @"Free Trial";
            //          if ((user.subscription_freePlanActive) || ([user.subscription_planStartDate isEqual:[NSNull null]]))
            if ([user.subscription_planProvider isEqualToString:@"EZCLOCKER_SUBSCRIPTION"])
            {
                label.text = @"n/a";
            }
            else {
                bool onFreeTrial = [user.subscription_freeTrialDaysLeft intValue] > 0;
                if (onFreeTrial)
                {
                    
                    label.text = @"Yes";
                }
                else{
                    label.text = @"No";
                    
                }
            }
            cell.accessoryView = label;
            
        }
        else
        {
            cell.textLabel.text =@"Manage Subscription";
            UIButton *manageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [manageButton setTitle:@"Manage" forState:UIControlStateNormal];
            [manageButton setFrame:CGRectMake(0, 0, 100, 35)];
            // [tableView cellForRowAtIndexPath:indexPath].accessoryView = manageButton;
            
            [manageButton addTarget:self action:@selector(doCancel:) forControlEvents:
             UIControlEventTouchUpInside];
            if ([user.subscription_planProvider isEqualToString:@"EZCLOCKER_SUBSCRIPTION"])
            {
                manageButton.enabled = false;
            }
            else
            {
                manageButton.enabled = true;
            }
            cell.accessoryView = manageButton;
            
            /* if ((user.subscription_freePlanActive) || ([user.subscription_PlanExpireDate isEqual:[NSNull null]]))
             {
             
             label.text = @"n/a";
             }
             else{
             //label.text = user.subscription_PlanExpireDate;
             
             }
             */
            
        }
        //cell.accessoryView = label;
        // [cell.contentView addSubview:label];
        
    }
    else
    {
        NSString* subTitle = @"";
        if ([_subscriptionPlans count] > 0)
        {
            NSDictionary* _subscriptionPlan;
            _subscriptionPlan = [_subscriptionPlans  objectAtIndex:indexPath.row];
            NSMutableArray *features = [_subscriptionPlan valueForKey:@"enabledFeatures"];
            if ((features != nil) && ([features count] > 0) && ([features indexOfObject:@"OVERTIME"] != NSNotFound) )
            {
                subTitle = [NSString stringWithFormat:@"Invite up to %@ employees, jobs, and overtime", [_subscriptionPlan valueForKey:@"maximumEmployees"]];
            }
            else
            {
                subTitle = [NSString stringWithFormat:@"Invite up to %@ employees", [_subscriptionPlan valueForKey:@"maximumEmployees"]];
            }
            
            cell.textLabel.text = [_subscriptionPlan valueForKey:@"title"];
            cell.detailTextLabel.text = subTitle;
            cell.detailTextLabel.numberOfLines = 0;
            UIButton *purchaseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [purchaseButton addTarget:self action:@selector(purchaseBtnClick:) forControlEvents:
             UIControlEventTouchUpInside];
            //tag it so we know which row it comes from
            purchaseButton.tag = indexPath.row;
            NSString *price = [[_subscriptionPlan valueForKey:@"price"] stringValue];
            UserClass *user = [UserClass getInstance];
            selectedPlanPrice = user.subscription_PlanPrice;
            purchaseButton.enabled = YES;
            if (![NSString isNilOrEmpty:selectedPlanPrice])
            {
                NSString *dSelectedPlanPrice;
                //if there is $ take it out
                if([selectedPlanPrice hasPrefix:@"$"]) {
                    dSelectedPlanPrice = [selectedPlanPrice substringFromIndex:1];
                }
                //disable the button so they can't purchase it again since they already have it
                if ([dSelectedPlanPrice isEqualToString:price])
                    //                    if (isExpired == NO) {
                    purchaseButton.enabled = NO;
                [cell setSelected:NO];
                //                    }
            }
            [purchaseButton setTitle:[NSString stringWithFormat:@"$%@/month", price] forState:UIControlStateNormal];
            //      downloadButton.backgroundColor = [UIColor greenColor];
            [purchaseButton setFrame:CGRectMake(0, 0, 105, 35)];
            cell.accessoryView = purchaseButton;
            
        }
        
        /*
         SKProduct* product = [[[EZPurchaseManager sharedInstance] availableProducts] objectAtIndex:indexPath.row];
         
         //Set the name and price
         //    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@) - %@", product.localizedTitle, [[EZPurchaseManager sharedInstance] durationForProductIdentifier:product.productIdentifier], product.localizedPrice];
         
         cell.textLabel.text = product.localizedTitle;
         cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", product.localizedDescription];
         
         UIButton *purchaseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
         [purchaseButton addTarget:self action:@selector(purchaseBtnClick:) forControlEvents:
         UIControlEventTouchUpInside];
         //tag it so we know which row it comes from
         purchaseButton.tag = indexPath.row;
         [purchaseButton setTitle:[NSString stringWithFormat:@"%@ /month", product.localizedPrice] forState:UIControlStateNormal];
         //      downloadButton.backgroundColor = [UIColor greenColor];
         [purchaseButton setFrame:CGRectMake(0, 0, 120, 35)];
         cell.accessoryView = purchaseButton;*/
        //  }
    }
    return cell;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (tableView != _currentSubscriptionTable)
//    {
//
//    } else {
////        _subscriptionPlansTable.rowHeight = UITableViewAutomaticDimension;
//        return UITableViewAutomaticDimension;;
//    }
//}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != _currentSubscriptionTable)
    {
        if (!flagTap) {
            flagTap = YES;
            NSDictionary* _subscriptionPlan = [_subscriptionPlans  objectAtIndex:indexPath.row];
            NSString *price = [[_subscriptionPlan valueForKey:@"price"] stringValue];
            
            UserClass *user = [UserClass getInstance];
//            if (user.subscription_HasActivePaidPlan) {
//                flagTap = NO;
//            } else {
                if (![NSString isNilOrEmpty:user.subscription_PlanPrice])
                {
                    NSString *dSelectedPlanPrice;
                    if([user.subscription_PlanPrice hasPrefix:@"$"]) {
                        dSelectedPlanPrice = [user.subscription_PlanPrice substringFromIndex:1];
                    }
                    //disable the button so they can't purchase it again since they already have it
                    if ([dSelectedPlanPrice isEqualToString:price]) {
                        flagTap = NO;
                    } else {
                        [self purchasePlan:_subscriptionPlan];
                    }
                } else {
                    [self purchasePlan:_subscriptionPlan];
                }
//            }
        }
    }
}


- (void) purchasePlan: (NSDictionary*)selectedPlan {
//    UserClass *user = [UserClass getInstance];
//    if (user.subscription_HasActivePaidPlan) {
//
//    } else {
        if ([self userCanDoPurchase])
        {
            NSString *selectedApplePlanID = [selectedPlan valueForKey:@"applePlanId"];
            NSNumber *price = [selectedPlan valueForKey:@"price"];
            selectedPlanPrice =  [price stringValue];//product.localizedPrice;
            for (SKProduct* product  in [[EZPurchaseManager sharedInstance] availableProducts])
            {
                NSString *productPlanId = product.productIdentifier;
                if ([selectedApplePlanID isEqual:productPlanId])
                {
//                    selectedPlanPrice = product.localizedPrice;
                    selectedPlanPrice =  [price stringValue];
                    [self doPurchase: product];
                    break;
                }
            }
        }
//    }
}

-(bool) userCanDoPurchase
{
    bool resultValue = true;
    UserClass *user = [UserClass getInstance];
    //if they are not on the free trial and not apple subscribers then block them
    if (![NSString isNilOrEmpty:user.subscription_planProvider])
    {
        if ((![user.subscription_planProvider isEqualToString:@"APPLE_SUBSCRIPTION"]) &&
            (![user.subscription_planProvider isEqualToString:@"EZCLOCKER_SUBSCRIPTION"]))
        {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Alert"
                                         message:@"Your current subscription is not using iTunes. Please use our website ezclocker.com to upgrade/downgrade your subscription."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Your current subscription is not using iTunes. Please use our website ezclocker.com to upgrade/downgrade your subscription." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            //  [alert show];
            resultValue = false;
        }
        else
        {
            //this has a specific purpose, the $4.99 is our old legacy price so ask customers to cancel before changing subscripitons. This will not fix the $9.99, $19.99, $49.99 old
            
            if (([user.subscription_planProvider isEqualToString:@"APPLE_SUBSCRIPTION"]) &&
                (([user.subscription_PlanPrice isEqualToString:@"$4.99"]) || [user.subscription_PlanPrice isEqualToString:@"$19.99"]))
            {
            UIAlertController * alert = [UIAlertController
                            alertControllerWithTitle:@"Alert"
                                message:@"Please cancel your previous subscription before purchasing a new plan by pressing the Manage link on this screen then select to cancel on iTunes. If you have any issues canceling or upgrading please send email to support@ezclocker.com"
                                preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];
                
                resultValue = false;
                
            }
            
        }
        
    }
    
    return resultValue;
}

-(void)purchaseBtnClick:(id)sender{
    
    if (!flagTap) {
        flagTap = YES;
        int tagNum = (int)((UIButton*) sender).tag;
        NSDictionary* _subscriptionPlan = [_subscriptionPlans  objectAtIndex:tagNum];
        NSString *price = [[_subscriptionPlan valueForKey:@"price"] stringValue];
        
        UserClass *user = [UserClass getInstance];
//        if (user.subscription_HasActivePaidPlan) {
//            flagTap = NO;
//        } else {
            if (![NSString isNilOrEmpty:user.subscription_PlanPrice])
            {
                NSString *dSelectedPlanPrice;
                if([user.subscription_PlanPrice hasPrefix:@"$"]) {
                    dSelectedPlanPrice = [user.subscription_PlanPrice substringFromIndex:1];
                }
                //disable the button so they can't purchase it again since they already have it
                if ([dSelectedPlanPrice isEqualToString:price]) {
                    flagTap = NO;
                } else {
                    [self purchasePlan:_subscriptionPlan];
                }
            } else {
                 [self purchasePlan:_subscriptionPlan];
            }
//        }
        
//        if ([self userCanDoPurchase])
//        {
//            //the tag tells us which button came from which is which row it belongs to
//
//            NSDictionary *selectedPlan =  [_subscriptionPlans objectAtIndex:tagNum];
//            NSString *selectedApplePlanID = [selectedPlan valueForKey:@"applePlanId"];
//            NSNumber *price = [selectedPlan valueForKey:@"price"];
//            selectedPlanPrice =  [price stringValue];//product.localizedPrice;
//
//            for (SKProduct* product  in [[EZPurchaseManager sharedInstance] availableProducts])
//            {
//                NSString *productPlanId = product.productIdentifier;
//                if ([selectedApplePlanID isEqual:productPlanId])
//                {
//                    [self doPurchase: product];
//                    break;
//                }
//            }
//        }
    }

}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return @"";
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"receiptDetails"])
    {
        [self stopSpinner];
        [self updateStatus];
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Private UI
- (NSDateFormatter*)dateFormatter
{
    static NSDateFormatter* dateFormatter;
    if (dateFormatter == nil)
    {
        //        dateFormatter = [[NSDateFormatter alloc] init];
        //        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        //  [dateFormatter setDateFormat:@"MMM"];
        //   [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        //   [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
    }
    return dateFormatter;
}


- (void)updateStatus
{
    UserClass *user = [UserClass getInstance];
    if (![NSString isNilOrEmpty:user.subscription_PlanPrice])
        selectedPlanPrice = user.subscription_PlanPrice;
    if (![NSString isNilOrEmpty:selectedPlanPrice])
    {
        if(![selectedPlanPrice hasPrefix:@"$"]) {
            selectedPlanPrice = [NSString stringWithFormat: @"$%@", selectedPlanPrice];
        }
        user.subscription_PlanPrice = selectedPlanPrice;
    }
    
    [_currentSubscriptionTable reloadData];
    [_subscriptionPlansTable reloadData];
}

//this is a delegate call from ezPurchaseManager to let us know that the purchase failed so turn off the spinner, let the serve know
-(void)purchaseFailed{
    flagTap = NO;
    [self stopSpinner];
    
    UserClass *user = [UserClass getInstance];
  //  [MetricsLogWebService LogException: [NSString stringWithFormat:@"Purchase Failed! for employerId= %@" , user.employerID]];
    
    //    user.subscription_PlanPrice = selectedPlanPrice;
    //    user.subscription_freePlanActive = NO;
    //    user.subscription_HasActivePaidPlan = YES;
    //    user.subscription_PlanExpireDate = @"";;
    //    user.subscription_planStartDate = @"";;
    //    [self updateStatus];
    
}

-(void)subscriptionNotValidFromReceipt
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Error"
                                 message:@"Your ezClocker subscription has expired. If you want to keep your current plan please press the manage button and resubscribe using iTunes or upgrade/downgrade to another plan using ezClocker subscription screen."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    isExpired = YES;
    [self presentViewController:alert animated:YES completion:nil];
    [self updateStatus];
}

- (void)subscriptionError{
    [self stopSpinner];
    
}
- (void)subscriptionExpired{
    [self stopSpinner];
    [self updateStatus];
    
}
//this is a call back from the subscription webservice
- (void)subscriptionValid{
    [self stopSpinner];
    UserClass *user = [UserClass getInstance];
    //NSString *tmpUserType = user.userType;
    //NSString *tmpProvider = user.subscription_planProvider;
    //    [[EZPurchaseManager sharedInstance] removeObserver:self forKeyPath:@"receiptDetails"];
    if (([user.userType isEqualToString:@"employer"]) && ([user.subscription_planProvider isEqualToString:@"APPLE_SUBSCRIPTION"]))
    {
        [[EZPurchaseManager sharedInstance] addObserver:self forKeyPath:@"receiptDetails" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    [self updateStatus];
}

- (void)subscriptionNotValid{
    [self stopSpinner];
    UserClass *user = [UserClass getInstance];
    // NSString *tmpUserType = user.userType;
    // NSString *tmpProvider = user.subscription_planProvider;
    
    
    NSString *msg = @"";
    if (([user.userType isEqualToString:@"employer"]) && ([user.subscription_planProvider isEqualToString:@"APPLE_SUBSCRIPTION"]))
    {
        //call validateReceipt to make sure we have the latest
        [[EZPurchaseManager sharedInstance] validateReceipt];
        
        [[EZPurchaseManager sharedInstance] addObserver:self forKeyPath:@"receiptDetails" options:NSKeyValueObservingOptionNew context:nil];
        msg = @"Your ezClocker subscription has expired. Please pick a new subscription plan from the list of Available Plans.";
        
    }
    
    else
    {
        msg = @"Your ezClocker subscription has expired. Please subscribe to a plan using our website ezclocker.com.";
    }
    
    if (![NSString isNilOrEmpty:msg])
    {
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Alert"
                                     message:msg
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        isExpired = YES;
    }
    
    [self updateStatus];
}

//this changed to manage subscriptions
- (IBAction)doCancel:(id)sender {
    
    UserClass *user = [UserClass getInstance];
    if (![user.subscription_planProvider isEqualToString:@"APPLE_SUBSCRIPTION"])
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Alert"
                                     message:@"Your current subscription is not using iTunes. Please use our website ezclocker.com to upgrade/downgrade your subscription."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else{
        CancelSubscriptionViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CancelSubscription"];
        
        UINavigationController *addEmployeeNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        
        
        controller.delegate = (id) self;
        controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self presentViewController:addEmployeeNavigationController animated:YES completion:nil];
    }
    
}

- (void)cancelSubscriptionViewControllerDidFinish:(UIViewController *)controller BackBtnWasSelected:(bool)cancelWasSelected
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doTermsOfUse:(id)sender {
  //  [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://ezclocker.com/public/ezclocker_terms_of_service.html"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://ezclocker.com/public/ezclocker_terms_of_service.html"] options:@{} completionHandler:nil];
}

- (IBAction)doPrivacyPolicy:(id)sender {
  //  [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://ezclocker.com/public/privacy.html"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://ezclocker.com/public/privacy.html"] options:@{} completionHandler:nil];
}

-(void)purchaseCompelete{
    flagTap = NO;
    [self stopSpinner];
    [self updateStatus];
    [CommonLib logEvent:@"Successful InAppPurchase"];
    [[EZPurchaseManager sharedInstance] addObserver:self forKeyPath:@"receiptDetails" options:NSKeyValueObservingOptionNew context:nil];
//    [self startSpinnerWithMessage:@""];
//       SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
//       subscriptionWebService.delegate = (id) self;
//       // [subscriptionWebService callHasValidLicenseWebService];
//       [subscriptionWebService checkValidLicense];
}


@end
