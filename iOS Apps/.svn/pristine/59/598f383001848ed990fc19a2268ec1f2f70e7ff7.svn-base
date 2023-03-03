//
//  CoreDataUtils.m
//  ezClocker
//
//  Created by Kenneth Lewis on 6/4/17.
//  Copyright © 2017 ezNova Technologies LLC. All rights reserved.
//

#import "CoreDataUtils.h"
#import "NSString+Extensions.h"

@implementation CoreDataUtils

+ (BOOL)isEquals:(NSManagedObjectID*)src dest:(NSManagedObjectID*)dest {
    if ((nil == src || nil == dest) || [src isTemporaryID] || [dest isTemporaryID]) {
        return FALSE;
    }
    NSURL* __url = [dest URIRepresentation];
    NSURL* __srcURL = [src URIRepresentation];
    NSString* __urlString = [__url absoluteString];
    NSString* __srcURLString = [__srcURL absoluteString];
    BOOL bResult = ([NSString isEquals:__urlString dest:__srcURLString]);
    return bResult;
}

@end
