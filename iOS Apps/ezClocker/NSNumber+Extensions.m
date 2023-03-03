//
//  NSNumber+Extensions.m
//  ezClocker
//
//  Created by Kenneth Lewis on 1/11/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import "NSNumber+Extensions.h"

@implementation NSNumber (NSNumberExtensions)

+ (BOOL)isEquals:(NSNumber*)src dest:(NSNumber*)aDest {
    if (nil == src && nil == aDest) {
        return TRUE;
    }
    return (nil != src && nil != aDest && [src isEqualToNumber:aDest]);
}

+ (double)toDouble:(NSNumber*)num {
    if ([NSNumber isNilOrNull:num]) {
        return 0;
    }
    return [num doubleValue];
}

+ (BOOL)isNilOrNull:(NSNumber*)num {
    if (nil == num || num == (NSNumber*)[NSNull null]) {
        return TRUE;
    }
    return FALSE;
}

+ (NSNumber*)safeNum:(NSNumber*)num {
    if ([NSNumber isNilOrNull:num]) {
        return nil;
    }
    return num;
}

@end
