//
//  DayHistoryItem+CoreDataProperties.h
//  ezClocker
//
//  Created by Kenneth Lewis on 1/13/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DayHistoryItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DayHistoryItem (CoreDataProperties)

@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, retain) Employee *employee;
@property (nullable, nonatomic, retain) NSOrderedSet<TimeEntry *> *timeEntries;

@end

@interface DayHistoryItem (CoreDataGeneratedAccessors)

- (void)insertObject:(TimeEntry *)value inTimeEntriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTimeEntriesAtIndex:(NSUInteger)idx;
- (void)insertTimeEntries:(NSArray<TimeEntry *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTimeEntriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTimeEntriesAtIndex:(NSUInteger)idx withObject:(TimeEntry *)value;
- (void)replaceTimeEntriesAtIndexes:(NSIndexSet *)indexes withTimeEntries:(NSArray<TimeEntry *> *)values;
- (void)addTimeEntriesObject:(TimeEntry *)value;
- (void)removeTimeEntriesObject:(TimeEntry *)value;
- (void)addTimeEntries:(NSOrderedSet<TimeEntry *> *)values;
- (void)removeTimeEntries:(NSOrderedSet<TimeEntry *> *)values;

@end

NS_ASSUME_NONNULL_END
