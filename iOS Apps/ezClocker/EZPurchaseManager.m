//
//  EZPurchaseManager.m
//  IAPSubscription
//
//  Created by Derek Stutsman on 2/16/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "EZPurchaseManager.h"
#import "EZValidateReceiptOperation.h"
#import "user.h"

@interface EZPurchaseManager()
@property (strong, nonatomic) NSDictionary* productSKUs;
@property (strong, nonatomic) NSOperationQueue* networkQueue;
@property (strong, nonatomic) SKReceiptRefreshRequest* refreshReceiptRequest;
@property (strong, nonatomic) SKProductsRequest* refreshProductsRequest;
@end

@implementation EZPurchaseManager

#pragma mark - Static

+ (EZPurchaseManager*)sharedInstance
{
    static EZPurchaseManager* instance;
    static dispatch_once_t oncePredicate;
    
    
    dispatch_once(&oncePredicate, ^{
        if ([NSThread isMainThread]) {
            instance = [[EZPurchaseManager alloc] init];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                instance = [[EZPurchaseManager alloc] init];
            });
        }
    });
    //    dispatch_once(&oncePredicate, ^
    //                  {
    //                      instance = [[EZPurchaseManager alloc] init];
    //                  });
    return instance;
}

#pragma mark - Init/Dealloc
- (id)init
{
    self = [super init];
    if (self)
    {
        //Set up networking queue for firing receipts to home server
        self.networkQueue = [[NSOperationQueue alloc] init];
        self.networkQueue.name = @"EZClocker Receipt Validation";
        
        //#warning Replace purchaseSKUs with your own list of IAP skus and durations, you may decide to fetch from your server rather than hard code
#ifndef PERSONAL_VERSION
        self.productSKUs =@{@"com.eznovatech.ezclocker.ezClocker.Basic": @"One Month",
                            @"com.eznovatech.ezclocker.ezClocker.Standard": @"One Month",
                            @"com.eznovatech.ezclocker.ezClocker.Premium": @"One Month",
                            @"com.eznovatech.ezclocker.ezClocker5": @"One Month",
                            @"com.eznovatech.ezclocker.ezClocker10": @"One Month",
                            @"com.eznovatech.ezclocker.ezClocker20": @"One Month",
                            @"com.eznovatech.ezclocker.ezClocker50": @"One Month"};
#else
        self.productSKUs =@{@"com.eznovatech.ezClocker.personal.ezClocker.Pro": @"One Month"};
#endif
        //       self.productSKUs =@{@"com.stutsmansoft.test.oneweek": @"One Week",
        //                           @"com.stutsmansoft.test.month": @"One Month",
        //                           @"com.stutsmansoft.test.sixmonths": @"Six Months",
        //                           @"com.stutsmansoft.test.year": @"One Year"};
        
        //Fetch the updated product identifiers from iTunes
        self.refreshProductsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:[self.productSKUs allKeys]]];
        self.refreshProductsRequest.delegate = self;
        [self.refreshProductsRequest start];
        
        //        //Listen to the purchase queue for events
//        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
//        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        
        //                 [[SKPaymentQueue defaultQueue] removeTransactionObserver:self]
        //Validate the receipt we have immediately
        //        [self validateReceipt];
        
    }
    return self;
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    // Check all transactions for any that might be restoration candidates.
    for (SKPaymentTransaction *transaction in queue.transactions) {
        if (transaction.transactionState == SKPaymentTransactionStateRestored) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
  //          NSDate *expiration = [calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:transaction.originalTransaction.transactionDate options:0];
            //           if ([expiration earlierDate:self.currentUTCTime] == self.currentUTCTime) {
            //               [self setSubscriptionInterfaceActive:true];
            return;
            //           }
        }
    }
    // There are no valid restorations, so we ask the user to subscribe here (this may obviously differ in your application as I am using a Purchase or Restore Subscription button in my app).
    //  [self setSubscriptionInterfaceActive:false];
    //  [self purchase:self.validProduct];
}
#pragma mark - Private Methods
- (void)validateReceipt
{
    //   NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    //   NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    
    //   NSString *encReceipt = [receiptData base64EncodedStringWithOptions:0];
    _receiptDetails = [[NSMutableDictionary alloc] init];

    NSData* purchaseReceipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if (purchaseReceipt == nil)
    {
#ifndef RELEASE
        
        NSLog(@"IAP receipt is missing or hasn't been generated yet, refreshing");
#endif
        self.refreshReceiptRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
        self.refreshReceiptRequest.delegate = self;
        [self.refreshReceiptRequest start];
        return;
    }
    
    //#warning If you have any user params you want to send your server, stick them in this dictionary
    UserClass *user = [UserClass getInstance];
    
    NSString *userInfoStr = [user.employerID stringValue];
    
    
    // NSDictionary* userInfo = @{@"employerId":@"1"};
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]init];
    [userInfo setValue:userInfoStr forKey:@"employerId"];
    //    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
    //                        userInfoStr, @"employerId", nil]; //nil to signify end of objects and keys.
#ifdef PERSONAL_VERSION
    NSString *personalId = [user.userID stringValue];
    [userInfo setValue:personalId forKey:@"personalId"];
#endif
    
//    NSError* error = nil;
 //   NSDictionary *results = purchaseReceipt ? [NSJSONSerialization JSONObjectWithData:purchaseReceipt options:0 error:&error] : nil;
    
    
    //Set up the network request and fire it off
    EZValidateReceiptOperation* receiptOperation = [[EZValidateReceiptOperation alloc] initWithPurchaseReceipt:purchaseReceipt userInfo:userInfo response:^(BOOL success, NSDictionary *receiptValues, NSError *error)
                                                    {
        if (success)
        {
            self.receiptDetails = [receiptValues mutableCopy];
            
            int errorValue = [[receiptValues valueForKey:@"errorCode"] intValue];
            if (errorValue == 0){
                
                //save all info
                user.subscription_freePlanActive = NO;
                user.subscription_HasActivePaidPlan = YES;
                user.subscription_planProvider = [receiptValues valueForKey:@"planProvider"];
                
                
                //              [[NSUserDefaults standardUserDefaults] synchronize]; //write out the data
                NSNumber *isValid = [receiptValues valueForKey:@"valid"];
                NSDictionary *tmpPlan = [receiptValues valueForKey:@"subscriptionPlan"];
                 NSNumber *monthlyFee = [tmpPlan valueForKey:@"monthlyFee"];
                 //Apple shows the subscription as 4.99 not 5 which is what we get from the server.
                 if ([monthlyFee intValue] > 0){
                     double monthlyFee1 = [monthlyFee doubleValue] - 0.01;
                     NSString *appleMonthlyFee = [NSString stringWithFormat:@"$%.02f",monthlyFee1];
                     user.subscription_PlanPrice = appleMonthlyFee;
                     user.subscription_freePlanActive = false;
                 }
                 else
                 {
                     user.subscription_PlanPrice = [NSString stringWithFormat:@"$%.2d",0];
                     user.subscription_freePlanActive = true;

                 }
                
                if ([[tmpPlan valueForKey:@"enabledFeatures"] count] > 0)
                {
                    user.subscription_enabledFeatures = [tmpPlan valueForKey:@"enabledFeatures"];
                    [[NSUserDefaults standardUserDefaults] setObject: user.subscription_enabledFeatures forKey:@"subscription_enabledFeatures"];
                }
                [[NSUserDefaults standardUserDefaults] setObject: user.subscription_planProvider forKey:@"subscription_planProvider"];
                             
                [[NSUserDefaults standardUserDefaults] setObject: user.subscription_PlanPrice forKey:@"subscription_PlanPrice"];

                [[NSUserDefaults standardUserDefaults] setBool: user.subscription_freePlanActive forKey:@"subscription_freePlanActive"];
                
                [[NSUserDefaults standardUserDefaults] setBool: user.subscription_HasActivePaidPlan forKey:@"subscription_HasActivePaidPlan"];
                

                if ([isValid intValue] == 0) {
                    [self.delegate subscriptionNotValidFromReceipt];
                } else {
                     [self.delegate purchaseCompelete];
                }
            }
            
//            NSDictionary *userInfo =
//            [NSDictionary dictionaryWithObject:user.subscription_planProvider forKey:@"planProvider"];
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateStatus" object:nil userInfo:userInfo];
            
        }
        else
        {
#ifndef RELEASE
            
            NSLog(@"Error validating receipt: %@", error);
#endif
        }
    }];
    [self.networkQueue addOperation:receiptOperation];
}

- (NSDateFormatter*)dateFormatter
{
    //2014-02-17 00:56:48 Etc/GMT
    static NSDateFormatter* dateFormatter;
    if (dateFormatter == nil)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss 'Etc/GMT'"];
    }
    return dateFormatter;
}

#pragma mark - SKRequestDelegate
- (void)requestDidFinish:(SKRequest *)request
{
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
#ifndef RELEASE
    
    NSLog(@"Error with request: %@ %@", error, request);
#endif
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    self.refreshProductsRequest = nil;
    
    //Save off the list of good products
    self.availableProducts = response.products;
    
    //These products failed
    if ([response.invalidProductIdentifiers count] > 0)
    {
#ifndef RELEASE
        
        NSLog(@"StoreKit Error: Failed products: %@", response.invalidProductIdentifiers);
#endif
    }
    
    //sort the list by price
    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"price" ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
//    NSArray *testProducts = [response.products sortedArrayUsingDescriptors:descriptors];
    self.availableProducts = [response.products sortedArrayUsingDescriptors:descriptors];
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction* transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
            {
                //Purchase process has been started - notify UI to put up a spinner or whatever
                break;
            }
            case SKPaymentTransactionStatePurchased:
                [self validateReceipt];
                [self.delegate purchaseCompelete];
                //                [queue finishTransaction:transaction];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
                break;
            case SKPaymentTransactionStateRestored:
            {
                //Purchase was completed, or restored - verify the receipt with the server
                [self validateReceipt];
                [self.delegate purchaseCompelete];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                 [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
                //                [queue finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateFailed:
            {
                //Purchase process was canceled, or failed.  Turn off the UI spinner
#ifndef RELEASE
                
                NSLog(@"StoreKit purchase cancelled or failed: %@", transaction.error);
#endif
                //call back to the delegate to turn off the spinner
                [self.delegate purchaseFailed];
                //                [queue finishTransaction:transaction];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
                break;
            }
            case SKPaymentTransactionStateDeferred:
                
                break;
        }
    }
}

#pragma mark - Public Methods
- (NSString*)durationForProductIdentifier:(NSString*)productID
{
    return self.productSKUs[productID];
}

- (void)purchaseProduct:(SKProduct*)product
{
     [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    //Make the purchase
#ifndef RELEASE
    NSLog(@"Purchase started for %@", product);
#endif
    [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
}

- (void)restorePurchases
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (NSDate *)subscriptionExpirationDate
{
    //Check the values in latest_receipt_info for one that is not expired
    NSDate* expirationDate = nil;
    
    NSString *resultMessage = [self.receiptDetails valueForKey:@"message"];
    if ([resultMessage isEqualToString:@"Success"])
    {
        
        NSString *expireDateTime = [self.receiptDetails valueForKey:@"expiresDateIso8601"];
        expireDateTime  = [expireDateTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
        
        NSDateFormatter *formatterDateTime = [[NSDateFormatter alloc] init];
        [formatterDateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatterDateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        
        
        expirationDate = [formatterDateTime dateFromString:expireDateTime];
        
    }
    
    /*    for (NSDictionary* receipt in self.receiptDetails[@"latest_receipt_info"])
     {
     NSString* expirationDateString = receipt[@"expires_date"];
     NSDate* expirationDate = [[self dateFormatter] dateFromString:expirationDateString];
     if (latestExpirationDate == nil || [expirationDate compare:latestExpirationDate] == NSOrderedDescending)
     {
     latestExpirationDate = expirationDate;
     }
     }
     */
    
    return expirationDate;
}

- (NSDate *)subscriptionStartDate
{
    //Check the values in latest_receipt_info for one that is not expired
    NSDate* startDate = nil;
    
    NSString *resultMessage = [self.receiptDetails valueForKey:@"message"];
    if ([resultMessage isEqualToString:@"Success"])
    {
        
        NSString *startDateTime = [self.receiptDetails valueForKey:@"originalPurchaseDateIso8601"];
        startDateTime  = [startDateTime stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
        
        NSDateFormatter *formatterDateTime = [[NSDateFormatter alloc] init];
        [formatterDateTime setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatterDateTime setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        
        
        startDate = [formatterDateTime dateFromString:startDateTime];
        
    }
    return startDate;
}


@end
