//
//  NSManagedObjectContext+Extensions.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/14/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "NSManagedObjectContext+Extensions.h"
#import "NSString+Extensions.h"

@implementation NSManagedObjectContext (NSManagedObjectContextExtensions)

+ (NSManagedObjectContext *)getDefaultContextForModel:(NSString *)modelFileNameWithoutExt
{
    NSString *testModelFileNameWithoutExt = [NSString trim:modelFileNameWithoutExt];
    NSAssert(TRUE != [NSString isNilOrEmpty:testModelFileNameWithoutExt], @"modelFileNameWithoutExt cannot be nil or empty in call to [NSManagedObjectContext getDefaultContextForModel:]");

    NSString *modelPath = [NSString trim:[[NSBundle mainBundle] pathForResource:testModelFileNameWithoutExt ofType:@"momd"]];
    NSAssert(modelPath, @"Error retrieving the model from the bundle in call to [NSManagedObjectContext getDefaultContextForModel:]");

    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(model != nil, @"Error initializing Managed Object Model");

    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSAssert(nil != psc, @"Error initializing the NSPersistentStoreCoordinator in call to [NSManagedObjectContext getDefaultContextForModel");

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    NSAssert(nil != context, @"Error initializing the NSManagedObjectContext in call to [NSManagedObjectContext getDefaultContextForModel");

    [context setPersistentStoreCoordinator:psc];
    return context;
}

+ (NSManagedObjectContext *)getObjectContextForModelUsingSqlite:(NSString *)modelFileNameWithoutExt url:(NSURL*)sqliteURL error:(NSError**)error
{

    NSString *testModelFileNameWithoutExt = [NSString trim:modelFileNameWithoutExt];
    NSAssert(TRUE != [NSString isNilOrEmpty:testModelFileNameWithoutExt], @"modelFileNameWithoutExt cannot be nil or empty in call to [NSManagedObjectContext getObjectContextForModelUsingSqlite:url:error:]");
    NSAssert(nil != sqliteURL, @"sqliteURL cannot be nil");
    NSAssert(nil != error, @"error cannot be nil");

    NSString *modelPath = [NSString trim:[[NSBundle mainBundle] pathForResource:testModelFileNameWithoutExt ofType:@"momd"]];
    NSAssert(modelPath, @"Error retrieving the model from the bundle in call to [NSManagedObjectContext getObjectContextForModelUsingSqlite:url:error:]");

    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(model != nil, @"Error initializing Managed Object Model");

    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSAssert(nil != coordinator, @"Error initializing the NSPersistentStoreCoordinator in call to [NSManagedObjectContext getObjectContextForModelUsingSqlite:url:error:]");

    NSString* STORE_TYPE = NSSQLiteStoreType;
    NSDictionary* options = @{NSMigratePersistentStoresAutomaticallyOption: @TRUE, NSInferMappingModelAutomaticallyOption: @TRUE};
    NSPersistentStore* sqliteStore = [coordinator addPersistentStoreWithType:STORE_TYPE configuration:nil URL:sqliteURL options:options error:error];
    NSAssert(nil != sqliteStore, @"Unable to add sqlite persistent store to persistent store coordinator");

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    NSAssert(nil != context, @"Error initializing the NSManagedObjectContext in call to [NSManagedObjectContext getObjectContextForModelUsingSqlite:url:error:]");
    [context setPersistentStoreCoordinator:coordinator];

    return context;
}

- (id)insertNewEntityForClass:(Class)aClass
{
    id entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(aClass) inManagedObjectContext:self];
    return entity;
}

@end
