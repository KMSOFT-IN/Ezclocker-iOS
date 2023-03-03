//
//  NSManagedObjectID+Extensions.m
//  ezClocker
//
//  Created by Kenneth Lewis on 8/5/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import "NSManagedObjectID+Extensions.h"
#import "NSString+Extensions.h"

@implementation NSManagedObjectID (NSManagedObjectExtensions)

- (BOOL)isEquals:(NSManagedObjectID*)src {
    if (nil == src) {
        return FALSE;
    }
    NSURL* __url = [self URIRepresentation];
    NSURL* __srcURL = [src URIRepresentation];
    NSString* __urlString = [__url absoluteString];
    NSString* __srcURLString = [__srcURL absoluteString];
    BOOL bResult = ([NSString isEquals:__urlString dest:__srcURLString]);
    return bResult;
}

@end
