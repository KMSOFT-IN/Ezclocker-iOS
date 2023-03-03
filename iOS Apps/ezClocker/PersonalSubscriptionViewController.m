//
//  PersonalSubscriptionViewController.m
//  ezClocker Personal
//
//  Created by Raya Khashab on 11/9/19.
//  Copyright © 2019 ezNova Technologies LLC. All rights reserved.
//

#import "PersonalSubscriptionViewController.h"
#import "CommonLib.h"
#import "ECSlidingViewController.h"
#import "EZPurchaseManager.h"
#import "SharedUICode.h"
#import "user.h"
#import "CreatePersonalAccountViewController.h"
#import "SubscriptionWebService.h"
#import "NSString+Extensions.h"
#import "NSNumber+Extensions.h"
#import "MetricsLogWebService.h"

@interface PersonalSubscriptionViewController ()

@end

@implementation PersonalSubscriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _upgradeHeaderView.backgroundColor = UIColorFromRGB(GRAY_BACKGROUND_COLOR);
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor whiteColor],
                                               NSForegroundColorAttributeName,
                                               nil];
    [self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];
    
//    UserClass *user = [UserClass getInstance];
//    [self.subscriptionBtn setHidden: NO];
//    if (user.subscription_HasActivePaidPlan) {
////        [self.subscriptionBtn setHidden: YES];
//    } else {

    NSLog(@"Available product:%@", [[EZPurchaseManager sharedInstance] availableProducts]);
//    }
    
    UserClass *user = [UserClass getInstance];
     //   if (!user.subscription_freePlanActive)
    if ([CommonLib onFreePlan])
        _subscriptionPlanValue.text = @"Free";
    else
        _subscriptionPlanValue.text = user.subscription_PlanPrice;
        
    
    SubscriptionWebService *subscriptionWebService = [[SubscriptionWebService alloc] init];
     subscriptionWebService.delegate = (id) self;
    [self startSpinnerWithMessage:@"Checking License..."];
    [subscriptionWebService checkValidLicense];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    //if we are not on the free plan and not expired then show them the cancel subscription button
 //   if ((![CommonLib onFreePlan]) && ([[EZPurchaseManager sharedInstance] isNotExpired]))
    UserClass *user = [UserClass getInstance];
    if ((![NSNumber isNilOrNull:user.subscription_IsValid]) && ([user.subscription_IsValid intValue] != 0))
    {
           [self.subscriptionBtn setTitle:@"Cancel Subscription" forState:UIControlStateNormal];
        
      } else {
            [self.subscriptionBtn setTitle:@"Subscribe" forState:UIControlStateNormal];
          [[EZPurchaseManager sharedInstance] setIsNotExpired:NO];
      }
        
}

- (IBAction)doTermsOfUseClick:(id)sender {
      //  [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://ezclocker.com/public/ezclocker_terms_of_service.html"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://ezclocker.com/public/ezclocker_terms_of_service.html"] options:@{} completionHandler:nil];
}

- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)doPrivacyClick:(id)sender {
 //       [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://ezclocker.com/public/privacy.html"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://ezclocker.com/public/privacy.html"] options:@{} completionHandler:nil];

}

-(void) displayCreatePersonalScreen
{
    CreatePersonalAccountViewController *createAccountController = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccount"];
    
    
    createAccountController.delegate = (id) self;
        
    //we don't want to show the sign in button only allow create account
    createAccountController.hideLoginButton = [NSNumber numberWithInt:1];

    UINavigationController *navCreateAccount = [[UINavigationController alloc] initWithRootViewController:createAccountController];
        
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, 550, 44)];
        
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
        
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(doCancelCreateAccount)];
    
    navItem.leftBarButtonItem = leftButton;
        
    navBar.items = @[ navItem ];

    createAccountController.navigationItem.leftBarButtonItem = leftButton;
        
    [self presentViewController:navCreateAccount animated:YES completion:nil];
}

-(bool)checkUserHasAccount
{
    bool result = true;
    UserClass *user= [UserClass getInstance];
    if (![user.hasAccount isEqualToString:@"YES"]){
        result = false;
        [SharedUICode messageBox:@"Alert" message:@"Before you subscribe you have to create an account. Please click the menu icon and select the Account option" withCompletion:^{
 //           [self displayCreatePersonalScreen];
        }];
    }
    return result;
}

-(void) cancelSubscription
{
    CancelSubscriptionViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CancelSubscription"];
     
     UINavigationController *addEmployeeNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
     
     
     controller.delegate = (id) self;
     controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
     
     [self presentViewController:addEmployeeNavigationController animated:YES completion:nil];

}

- (IBAction)doSubscribe:(id)sender {
   // self.subscriptionBtn.titleLabel.text setTitle:@"Subscribe"
    if ([NSString isEquals:self.subscriptionBtn.titleLabel.text dest:@"Subscribe"])
    {
        if ([self checkUserHasAccount])
        {
            // subscribe
            SKProduct* product = [[[EZPurchaseManager sharedInstance] availableProducts] objectAtIndex:0];
            [self doPurchase: product];
        }
    }
//    if ([[EZPurchaseManager sharedInstance] isNotExpired]) {
    else
    {
        // cancel subscribe
        UserClass *user = [UserClass getInstance];
        if ([user.customerNameIDList count] > 1)
        {
            UIAlertController * alert = [UIAlertController
                                alertControllerWithTitle:@"Alert"
                                message:@"If you wish to downgrade and use our free version please press Cancel and delete all customers except for one. Otherwise, press Continue."
                                preferredStyle:UIAlertControllerStyleAlert];
                    
                    
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                
                    [alert dismissViewControllerAnimated:YES completion:nil];
                        
            }];
                    
            [alert addAction:cancelAction];
                    
                    UIAlertAction* continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        
                    [self cancelSubscription];
            }];
                    
            [alert addAction:continueAction];

            [self presentViewController:alert animated:YES completion:nil];
            
        }
        else
        {
            [self cancelSubscription];
        }
     }
}

-(void) doPurchase: (SKProduct*) product{
    [self startSpinnerWithMessage:@"Purchasing, please wait..."];
#ifndef DEBUG
    UserClass *user = [UserClass getInstance];
    //send the info the metric service to record this event if we are in production
    [MetricsLogWebService LogException: [NSString stringWithFormat:@"Somebody tried to purchase a subscription for the Personal App Yay!!!! userEmail: %@ employerID= %@", user.userEmail, user.employerID]];
#endif

    [[EZPurchaseManager sharedInstance] setDelegate: self];
    [[EZPurchaseManager sharedInstance] purchaseProduct:product];

}

-(void) doCancelCreateAccount
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
    //Unwire KVO
    UserClass *user = [UserClass getInstance];
    if ([user.subscription_planProvider isEqualToString:@"APPLE_SUBSCRIPTION"])
    {
        if ([[EZPurchaseManager sharedInstance] observationInfo] != nil) {

           [[EZPurchaseManager sharedInstance] removeObserver:self forKeyPath:@"receiptDetails"];
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//MARK:- Subscription Valid or Not

//this is a call back from the subscription license check webservice
- (void)subscriptionValid {
    [self stopSpinner];
    UserClass *user = [UserClass getInstance];
    
    [[EZPurchaseManager sharedInstance] setIsNotExpired:YES];

//    if (!user.subscription_freePlanActive)
    if ([CommonLib onFreePlan])
    {
        _subscriptionPlanValue.text = @"Free";

    }
    else
    {
        _subscriptionPlanValue.text = user.subscription_PlanPrice;
        
        [self.subscriptionBtn setTitle:@"Cancel Subscription" forState:UIControlStateNormal];
    }
    
    if ([user.subscription_planProvider isEqualToString:@"APPLE_SUBSCRIPTION"])
    {
        [[EZPurchaseManager sharedInstance] addObserver:self forKeyPath:@"receiptDetails" options:NSKeyValueObservingOptionNew context:nil];
        
    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"receiptDetails"]) {
       
     }
 
}

- (void)subscriptionNotValid{
       [self stopSpinner];
    
       [[EZPurchaseManager sharedInstance] setIsNotExpired:NO];
    
       UserClass *user = [UserClass getInstance];

     //  NSString *tmpProvider = user.subscription_planProvider;

       _subscriptionPlanValue.text = [NSString stringWithFormat:@"%@ (%@)", user.subscription_PlanPrice, @"Expired"];

       NSString *msg = @"";
       if ([user.subscription_planProvider isEqualToString:@"APPLE_SUBSCRIPTION"])
       {
           [[EZPurchaseManager sharedInstance] addObserver:self forKeyPath:@"receiptDetails" options:NSKeyValueObservingOptionNew context:nil];
           msg = @"Your ezClocker subscription has expired. Please subscribe to a plan using the subscribe button";
       }
       else
       {
            msg = @"Your ezClocker subscription has expired. Please subscribe to a plan using our website ezclocker.com";
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
    }
    
}

//MARK: - Purchase Delegate

//this is a delegate call from ezPurchaseManager to let us know that the purchase failed so turn off the spinner, let the serve know
-(void)purchaseFailed{

    [self stopSpinner];
    
  //  UserClass *user = [UserClass getInstance];
  //  [MetricsLogWebService LogException: [NSString stringWithFormat:@"Purchase Failed! for employerId= %@" , user.employerID]];

//    user.subscription_PlanPrice = selectedPlanPrice;
//    user.subscription_freePlanActive = NO;
//    user.subscription_HasActivePaidPlan = YES;
//    user.subscription_PlanExpireDate = @"";;
//    user.subscription_planStartDate = @"";;
//    [self updateStatus];
    
}


-(void)purchaseCompelete{

    [self stopSpinner];
    UserClass *user = [UserClass getInstance];
    _subscriptionPlanValue.text = user.subscription_PlanPrice;
    [self.subscriptionBtn setTitle:@"Cancel Subscription" forState:UIControlStateNormal];
    [[EZPurchaseManager sharedInstance] setIsNotExpired:YES];
    
    [CommonLib logEvent:@"Successful InAppPurchase"];
//    UserClass *user = [UserClass getInstance];
//    user.subscription_HasActivePaidPlan = YES;
//    [self.subscriptionBtn setHidden: YES];
}


-(void)subscriptionNotValidFromReceipt
{
    [[EZPurchaseManager sharedInstance] setIsNotExpired:NO];
/*    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Error"
                                 message:@"Your ezClocker subscription has expired. If you want to keep your current plan please press the manage button and resubscribe using iTunes or upgrade/downgrade to another plan using ezClocker subscription screen."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
 */
}

//MARK:- createAccountViewControllerDelegate

- (void)createAccountViewControllerDidFinish:(CreatePersonalAccountViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loginPersonalViewControllerWasSelected:(CreatePersonalAccountViewController *)controller {
     [self dismissViewControllerAnimated:YES completion:nil];
}

//MARK:- CancelSubscriptionViewControllerDelegate
- (void)cancelSubscriptionViewControllerDidFinish:(UIViewController *)controller BackBtnWasSelected:(bool)cancelWasSelected
{
    //if cancel was selected then they did not cancel the subscription so show the  Cancel Subscription button
    if (cancelWasSelected)
    {
        [self.subscriptionBtn setTitle:@"Cancel Subscription" forState:UIControlStateNormal];
    }
    else{
        [self.subscriptionBtn setTitle:@"Subscribe" forState:UIControlStateNormal];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];

}



@end
