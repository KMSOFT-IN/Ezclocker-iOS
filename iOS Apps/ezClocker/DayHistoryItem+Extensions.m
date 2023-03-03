//
//  DayHistoryItem+Extensions.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/15/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "DayHistoryItem+Extensions.h"
#import "NSManagedObjectContext+Extensions.h"
#import "NSManagedObject+Extensions.h"
#import "TimeEntry.h"
#import "TimeEntry+CoreDataProperties.h"
#import "TimeEntry+Extensions.h"
#import "debugdefines.h"
#import "NSString+Extensions.h"

@implementation DayHistoryItem (DayHistoryItemExtensions)

- (TimeEntry*)insertNewTimeEntry {
    @synchronized(self) {
        TimeEntry* result = [self.managedObjectContext insertNewEntityForClass:[TimeEntry class]];
        return result;
    }
}

- (TimeEntry*)addFromTimeEntry:(TimeEntry*)timeEntry error:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != error, @"error cannot be nil", msg);
    TimeEntry* result = [self insertNewTimeEntry];
    NSAssert(nil != result, @"Error inserting new DayHistoryItem for Employee %@", msg);
    result.dayHistoryItem = self;
    result.timeEntryID = timeEntry.timeEntryID;
    [result saveFromTimeEntry:timeEntry error:error];
    if (nil != *error) {
#ifndef RELEASE
        NSLog(@"Error while saving new time entry using timeEntry - %@ %@", (*error).localizedDescription, msg);
#endif
        return nil;
    }
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext save:error];
    }];
    if (nil != *error) {
#ifndef RELEASE
        NSLog(@"Error while saving DayHistoryItem managed object context - %@ %@", (*error).localizedDescription, msg);
#endif
        return nil;
    }
    return result;
}

- (void)setValuesForKeysWithDictionary:(NSDictionary<NSString *,id> *)keyedValues
{
    NSAssert(nil != keyedValues, @"Error initializing Managed Object DayHistoryItem");
}

- (NSArray*)fetchTimeEntries:(NSError*__autoreleasing*)error {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != error, @"error cannot be nil", msg);
        __block NSArray* results;
        [self.managedObjectContext performBlockAndWait:^{
            NSFetchRequest* fetchRequest = [NSFetchRequest new];
            NSEntityDescription* entity = [self entityForClass:[TimeEntry class]];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"dayHistoryItem == %@", self];
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"clockIn.dateTimeEntry" ascending:TRUE]];
            [fetchRequest setEntity:entity];
            results = [self.managedObjectContext executeFetchRequest:fetchRequest error:error];
        }];
        return results;
    }
}

- (BOOL)removeTimeEntry:(TimeEntry*)timeEntry error:(NSError*__autoreleasing*)error {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != timeEntry, @"timeEntry cannot be nil %@", msg);
        NSAssert(nil != error, @"error cannot be nil %@", msg);
        REMOVE_ENTITY_FROM_LIST(timeEntries, timeEntry)
    }
}

- (TimeEntry*)fetchTimeEntryByID:(NSInteger)timeEntryID error:(NSError *__autoreleasing *)error {
    @synchronized(self) {
        NSArray* timeEntries = [self fetchTimeEntries:error];
        if (nil == timeEntries || (timeEntries.count == 0)) {
            return nil;
        }
        for (TimeEntry* timeEntry in timeEntries) {
            if ([timeEntry.timeEntryID integerValue] == timeEntryID) {
                return timeEntry;
            }
        }
        return nil;
    }
}

- (TimeEntry*)fetchTimeEntryByObjectID:(NSManagedObjectID*)objectID error:(NSError*__autoreleasing*)error {
    __block TimeEntry* timeEntry;
    [self.managedObjectContext performBlockAndWait:^{
        timeEntry = [self.managedObjectContext existingObjectWithID:objectID error:error];
    }];
    return timeEntry;
}

@end
