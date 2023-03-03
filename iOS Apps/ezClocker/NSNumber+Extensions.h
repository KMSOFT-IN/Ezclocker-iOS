//
//  NSNumber+Extensions.h
//  ezClocker
//
//  Created by Kenneth Lewis on 1/11/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (NSNumberExtensions)

+ (double)toDouble:(NSNumber*)num;
+ (BOOL)isNilOrNull:(NSNumber*)num;
+ (NSNumber*)safeNum:(NSNumber*)num;
+ (BOOL)isEquals:(NSNumber*)src dest:(NSNumber*)aDest;

@end
