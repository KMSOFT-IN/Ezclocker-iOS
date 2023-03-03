//
//  Employee+CoreDataProperties.h
//  ezClocker
//
//  Created by Kenneth Lewis on 1/18/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Employee.h"

NS_ASSUME_NONNULL_BEGIN

@interface Employee (CoreDataProperties)

@property (nullable, nonatomic, copy) NSNumber *acceptedInvite;
@property (nullable, nonatomic, copy) NSString *email;
@property (nullable, nonatomic, copy) NSNumber *employeeID;
@property (nullable, nonatomic, copy) NSNumber *isClockedIn;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSOrderedSet<DayHistoryItem *> *dayHistory;
@property (nullable, nonatomic, retain) NSOrderedSet<DeletedTimeEntry *> *deletedEntries;

@end

@interface Employee (CoreDataGeneratedAccessors)

- (void)insertObject:(DayHistoryItem *)value inDayHistoryAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDayHistoryAtIndex:(NSUInteger)idx;
- (void)insertDayHistory:(NSArray<DayHistoryItem *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDayHistoryAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDayHistoryAtIndex:(NSUInteger)idx withObject:(DayHistoryItem *)value;
- (void)replaceDayHistoryAtIndexes:(NSIndexSet *)indexes withDayHistory:(NSArray<DayHistoryItem *> *)values;
- (void)addDayHistoryObject:(DayHistoryItem *)value;
- (void)removeDayHistoryObject:(DayHistoryItem *)value;
- (void)addDayHistory:(NSOrderedSet<DayHistoryItem *> *)values;
- (void)removeDayHistory:(NSOrderedSet<DayHistoryItem *> *)values;

- (void)insertObject:(DeletedTimeEntry *)value inDeletedEntriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDeletedEntriesAtIndex:(NSUInteger)idx;
- (void)insertDeletedEntries:(NSArray<DeletedTimeEntry *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDeletedEntriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDeletedEntriesAtIndex:(NSUInteger)idx withObject:(DeletedTimeEntry *)value;
- (void)replaceDeletedEntriesAtIndexes:(NSIndexSet *)indexes withDeletedEntries:(NSArray<DeletedTimeEntry *> *)values;
- (void)addDeletedEntriesObject:(DeletedTimeEntry *)value;
- (void)removeDeletedEntriesObject:(DeletedTimeEntry *)value;
- (void)addDeletedEntries:(NSOrderedSet<DeletedTimeEntry *> *)values;
- (void)removeDeletedEntries:(NSOrderedSet<DeletedTimeEntry *> *)values;

@end

NS_ASSUME_NONNULL_END
