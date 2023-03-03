//
//  EZPurchaseManager.h
//  IAPSubscription
//
//  Created by Derek Stutsman on 2/16/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

//use this delegate to communicate back to any UI that we failed
@protocol PurchaseDelegate
- (void)purchaseFailed;
- (void)purchaseCompelete;
- (void)subscriptionNotValidFromReceipt;
@end

static const NSString* kProductPurchasedNotification = @"StoreKitProductPurchased";

@interface EZPurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic) BOOL isNotExpired;
@property (strong, nonatomic) NSArray* availableProducts;
@property (strong, nonatomic) NSMutableDictionary* receiptDetails;
@property (assign, nonatomic) IBOutlet id <PurchaseDelegate> delegate;
+ (EZPurchaseManager*)sharedInstance;



//- (NSArray*)availableProducts;
- (NSString*)durationForProductIdentifier:(NSString*)productID;
- (void)purchaseProduct:(SKProduct*)product;
- (NSDate*)subscriptionExpirationDate;
- (NSDate*) subscriptionStartDate;
- (void)restorePurchases;
- (void)validateReceipt;
@end
