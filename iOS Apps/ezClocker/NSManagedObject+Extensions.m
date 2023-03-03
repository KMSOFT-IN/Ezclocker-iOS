//
//  NSManagedObject+Extensions.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/16/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "NSManagedObject+Extensions.h"

@implementation NSManagedObject (NSManagedObjectExtensions)

- (NSEntityDescription*)entityForClass:(Class)aClass {
    return [NSEntityDescription entityForName:NSStringFromClass(aClass) inManagedObjectContext:self.managedObjectContext];
}

@end
