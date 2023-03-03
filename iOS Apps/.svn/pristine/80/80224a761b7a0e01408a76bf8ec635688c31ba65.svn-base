//
//  NSBundle+Extensions.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/14/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "NSBundle+Extensions.h"
#import "NSString+Extensions.h"

@implementation NSBundle (BRABundleExtensions)

+ (NSString *)infoValueForKey:(NSString *)keyName
{
    NSString *testKeyName = [NSString trim:keyName];
    if ([NSString isNilOrEmpty:testKeyName]) {
        return nil;
    }
    NSBundle *bundle = [NSBundle mainBundle];
    return [NSString trim:[bundle objectForInfoDictionaryKey:keyName]];
}

@end
