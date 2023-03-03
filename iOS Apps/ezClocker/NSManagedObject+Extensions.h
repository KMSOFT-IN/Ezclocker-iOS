//
//  NSManagedObject+Extensions.h
//  ezClocker
//
//  Created by Kenneth Lewis on 12/16/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (NSManagedObjectExtensions)

- (NSEntityDescription*)entityForClass:(Class)aClass;

@end
