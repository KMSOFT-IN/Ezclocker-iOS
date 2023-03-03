//
//  SubscriptionWebService.h
//  ezClocker
//
//  Created by Raya Khashab on 11/5/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SubscriptionDelegate

- (void)subscriptionError;
- (void)subscriptionExpired;
- (void)subscriptionValid;
- (void)subscriptionNotValid;
//-(void)subscr
@end

@interface SubscriptionWebService : NSObject <NSURLConnectionDataDelegate>
{
    NSMutableData *data;
}
//-(void)callHasValidLicenseWebService;
-(void)checkValidLicense;

@property (assign, nonatomic) IBOutlet id <SubscriptionDelegate> delegate;



@end
