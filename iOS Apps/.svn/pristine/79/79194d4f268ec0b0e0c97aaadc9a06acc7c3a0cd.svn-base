//
//  SKProduct+LocalizedPrice.m
//  IAPSubscription
//
//  Created by Derek Stutsman on 2/16/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "SKProduct+LocalizedPrice.h"

@implementation SKProduct (LocalizedPrice)

- (NSString*)localizedPrice
{
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:self.priceLocale];
    return [formatter stringFromNumber:self.price];
}
@end
