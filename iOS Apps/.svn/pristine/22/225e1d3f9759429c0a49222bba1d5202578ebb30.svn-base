//
//  NSManagedObjectContext+Extensions.h
//  ezClocker
//
//  Created by Kenneth Lewis on 12/14/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (NSManagedObjectContextExtensions)

+ (NSManagedObjectContext *)getDefaultContextForModel:(NSString *)modelFileNameWithoutExt;
+ (NSManagedObjectContext *)getObjectContextForModelUsingSqlite:(NSString *)modelFileNameWithoutExt url:(NSURL*)sqliteURL error:(NSError**)error;
- (id)insertNewEntityForClass:(Class)aClass;

@end
