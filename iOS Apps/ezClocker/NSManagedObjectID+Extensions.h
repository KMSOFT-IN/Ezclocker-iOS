//
//  NSManagedObjectID+Extensions.h
//  ezClocker
//
//  Created by Kenneth Lewis on 8/5/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectID (NSManagedObjectExtensions)

- (BOOL)isEquals:(NSManagedObjectID*)src;

@end
