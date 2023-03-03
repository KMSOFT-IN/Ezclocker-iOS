//
//  EZValidateReceiptOperation.h
//  IAPSubscription
//
//  Created by Derek Stutsman on 2/16/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^EZReceiptValidationResponse)(BOOL success, NSDictionary* receiptValues, NSError* error);

@interface EZValidateReceiptOperation : NSOperation <NSURLConnectionDataDelegate>{
    NSMutableData *data;
}

- (id)initWithPurchaseReceipt:(NSData*)purchaseReceipt userInfo:(NSDictionary*)userInfo response:(EZReceiptValidationResponse)responseBlock;

@end
