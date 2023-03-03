//
//  Employee+Extensions.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/15/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "Employee+Extensions.h"
#import "NSString+Extensions.h"
#import "NSManagedObjectContext+Extensions.h"
#import "DayHistoryItem.h"
#import "DayHistoryItem+Extensions.h"
#import "NSManagedObject+Extensions.h"
#import "DayHistoryItem.h"
#import "debugdefines.h"
#import "NSDate+Extensions.h"
#import "coredatadefines.h"
#import "CommonLib.h"
#import "TimeEntry+Extensions.h"
#import "ClockInfo+Extensions.h"
#import "NSNumber+Extensions.h"

@implementation Employee (EmployeeExtensions)

- (DayHistoryItem*)insertNewDayHistoryItem {
    @synchronized(self) {
        __block DayHistoryItem* result;
        if ([NSThread isMainThread]){
            [self.managedObjectContext performBlockAndWait:^{
                result = [self.managedObjectContext insertNewEntityForClass:[DayHistoryItem class]];
            }];
        }
        else {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.managedObjectContext performBlockAndWait:^{
                    result = [self.managedObjectContext insertNewEntityForClass:[DayHistoryItem class]];
                }];
                dispatch_semaphore_signal(sema);
            });

            if (![NSThread isMainThread]) {
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            } else {
                while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW)) {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0]];
                }
            }
        }
        return result;
    }
}

#pragma mark - DeleteTimeEntry methods

- (DeletedTimeEntry*)insertNewDeleteTimeEntry {
    @synchronized(self) {
        __block DeletedTimeEntry* result;
        [self.managedObjectContext performBlockAndWait:^{
            result = [self.managedObjectContext insertNewEntityForClass:[DeletedTimeEntry class]];
        }];
        return result;
    }
}

- (NSMutableArray*)fetchDeletedTimeEntries:(NSError *__autoreleasing *)error {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != error, @"error cannot be nil %@", msg);
        __block NSMutableArray* results = [NSMutableArray new];
        __block BOOL shouldReturnNil = NO;
        [self.managedObjectContext performBlockAndWait:^{
            NSFetchRequest* fetchRequest = [NSFetchRequest new];
            NSEntityDescription* entity = [self entityForClass:[DeletedTimeEntry class]];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"employee == %@", self];
            [fetchRequest setEntity:entity];
            NSArray* array = [self.managedObjectContext executeFetchRequest:fetchRequest error:error];
            if (nil != *error) {
                shouldReturnNil = YES;
                return;
            }
            if (nil != array && array.count > 0) {
                results = [[NSMutableArray alloc] initWithArray:array];
            }
        }];
        if (shouldReturnNil) {
            return nil;
        }
        return results;
    }
}

- (DeletedTimeEntry*)fetchDeletedTimeEntry:(NSNumber*)timeEntryID error:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != error, @"error cannot be nil %@", msg);

    BOOL bIsTimeEntryIDValid = ![NSNumber isNilOrNull:timeEntryID] && ([timeEntryID integerValue] > 0);
    NSAssert(TRUE == bIsTimeEntryIDValid, @"timeEntryID must be valid %@", msg);
    assert(TRUE == bIsTimeEntryIDValid); // sanity!

    NSArray* deletedTimeEntries = [self fetchDeletedTimeEntries:error];
    if (nil == deletedTimeEntries) {
        return nil;
    }
    if (nil != *error) {
        return nil;
    }
    for (DeletedTimeEntry* deletedTimeEntry in deletedTimeEntries) {
        if ([deletedTimeEntry.timeEntryID integerValue] == [timeEntryID integerValue]) {
            return deletedTimeEntry;
        }
    }
    return nil;

}

- (BOOL)deleteTimeEntryFromDeletedTimeEntries:(NSNumber*)timeEntryID error:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != error, @"error cannot be nil %@", msg);

    BOOL bIsTimeEntryIDValid = ![NSNumber isNilOrNull:timeEntryID] && ([timeEntryID integerValue] > 0);
    NSAssert(TRUE == bIsTimeEntryIDValid, @"timeEntryID must be valid %@", msg);
    assert(TRUE == bIsTimeEntryIDValid); // sanity!

    DeletedTimeEntry* deletedTimeEntry = [self fetchDeletedTimeEntry:timeEntryID error:error];
    if (nil != *error) {
        return FALSE;
    }
    if (nil == deletedTimeEntry) {
        return FALSE;
    }
    REMOVE_ENTITY_FROM_LIST(deletedEntries, deletedTimeEntry)
}

- (void)setValuesForKeysWithDictionary:(NSDictionary<NSString *,id> *)keyedValues
{
    DEBUG_MSG

    NSAssert(nil != keyedValues, @"Error initializing Managed Object DayHistoryItem %@", msg);

    NSNumber* __employeeID = keyedValues[kEmployeeIDKey];
    NSAssert(nil != __employeeID, @"employeeID cannot be nil %@", msg);

    self.employeeID = __employeeID;

    NSString* value = [NSString trim:keyedValues[kEmployeeNameKey]];
    self.name = value;

    value = [NSString trim:keyedValues[kEmployeeEmailKey]];
    self.email = value;

}

- (NSArray*)fetchHistoryItems:(NSError**)error; {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != error, @"error cannot be nil %@", msg);
        __block NSArray* results;
        
        [self.managedObjectContext performBlockAndWait:^{
            NSFetchRequest* fetchRequest = [NSFetchRequest new];
            NSEntityDescription* entity = [self entityForClass:[DayHistoryItem class]];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"employee == %@", self];
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
            [fetchRequest setEntity:entity];
            results = [self.managedObjectContext executeFetchRequest:fetchRequest error:error];
        }];
        return results;
    }
}

- (DayHistoryItem*)fetchHistoryItemByDate:(NSDate *)date error:(NSError *__autoreleasing *)error {
    @synchronized(self) {
        NSAssert(nil != date, @"date cannot be nil");
        NSAssert(nil != error, @"error cannot be nil");

        NSArray* historyItems = [self fetchHistoryItems:error];
        if (nil == historyItems) {
            return nil;
        }
        NSString* srcDate;
        NSString* destDate = [date toDefaultDateString];
        DayHistoryItem* result = nil;
        for (DayHistoryItem* item in historyItems) {
            srcDate = [item.date toDefaultDateString];
            if ([srcDate isEqualToString:destDate]) {
                result = item;
                return result;
            }
        }
        return nil;
    }
}

- (DayHistoryItem*)fetchTodaysDayHistoryItem:(NSError* __autoreleasing*)error {
    DayHistoryItem* dayHistoryItem = [self fetchHistoryItemByDate:[NSDate date] error:error];
    return dayHistoryItem;
}

- (TimeEntry*)fetchLastTimeEntryForToday:(NSError *__autoreleasing *)error {
    DayHistoryItem* dayHistoryItem = [self fetchTodaysDayHistoryItem:error];
    if (!dayHistoryItem) {
        return nil;
    }
    NSArray* timeEntries = [dayHistoryItem fetchTimeEntries:error];
    if (nil == timeEntries || nil != *error) {
        return nil;
    }
    NSInteger count = timeEntries.count;
    if (count > 0) {
        TimeEntry* result = [timeEntries lastObject];
        return result;
    }
    return nil;
}

- (TimeEntry*)fetchMostRecentTimeEntry:(NSError*__autoreleasing*)error {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != error, @"error cannot be nil %@", msg);

        NSArray* array = [self fetchHistoryItems:error];
        if ((nil != *error) || (array.count <= 0)) {
            return nil;
        }
        DayHistoryItem* dayHistoryItem = (DayHistoryItem*)array.firstObject; // most recent is the first day history item
        NSArray* timeEntries = [dayHistoryItem fetchTimeEntries:error];
        if ((nil != *error) || (timeEntries.count <= 0)) {
            return nil;
        }
        TimeEntry* timeEntry = (TimeEntry*)timeEntries.lastObject; // most recent for the timeEntries is the last object
        return timeEntry;
    }
}

- (TimeEntry*)fetchMostRecentNormalTimeEntry: (NSError*__autoreleasing*)error {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != error, @"error cannot be nil %@", msg);

        NSArray* array = [self fetchHistoryItems:error];
        if ((nil != *error) || (array.count <= 0)) {
            return nil;
        }
        DayHistoryItem* dayHistoryItem = (DayHistoryItem*)array.firstObject; // most recent is the first day history item
        NSArray* timeEntries = [dayHistoryItem fetchTimeEntries:error];
        if ((nil != *error) || (timeEntries.count <= 0)) {
            return nil;
        }
        TimeEntry* timeEntry = (TimeEntry*)timeEntries.lastObject; // most recent for the timeEntries is the last object
        if ((![NSString isNilOrEmpty:timeEntry.timeEntryType]) && ([timeEntry.timeEntryType isEqualToString:kBreakTimeEntryType]))
        {
            //if the last object is a break then go backwards and see if they one before it is not a break then check the one before it and so on until you find a non break time entry
            int count = (int) timeEntries.count;
            for (int i = count - 1 ; i >= 0; i--) {
                timeEntry = (TimeEntry*) [timeEntries objectAtIndex:i];
                //if the type is not a break
                if (([NSString isNilOrEmpty:timeEntry.timeEntryType]) || (![timeEntry.timeEntryType isEqualToString:kBreakTimeEntryType]))
                    break;
            }
            return timeEntry;
        }
        else
            return timeEntry;
    }
}

- (DayHistoryItem*)fetchDayHistoryItemByObjectID:(NSManagedObjectID*)dayHistoryItemObjectID error:(NSError*__autoreleasing*)error {
    DEBUG_MSG

    NSAssert(nil != dayHistoryItemObjectID, @"Invalid dayHistoryItemObjectID %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    __block DayHistoryItem* dayHistoryItem;
    [self.managedObjectContext performBlockAndWait:^{
        dayHistoryItem = [self.managedObjectContext existingObjectWithID:dayHistoryItemObjectID error:error];
    }];
    return dayHistoryItem;
}

- (TimeEntry*)fetchTimeEntryByObjectID:(NSManagedObjectID*)timeEntryObjectID error:(NSError *__autoreleasing *)error {
    DEBUG_MSG

    NSAssert(nil != timeEntryObjectID, @"Invalid timeEntryObjectID %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    NSArray* historyItems = [self fetchHistoryItems:error];
    if (nil == historyItems) {
        return nil;
    }
    if (nil != *error) {
        return nil;
    }
    TimeEntry* timeEntry;
    for (DayHistoryItem* item in historyItems) {
        timeEntry = [item fetchTimeEntryByObjectID:timeEntryObjectID error:error];
        if (nil != *error) {
            return nil;
        }
        if (timeEntry) {
            return timeEntry;
        }
    }
    return nil;
}

- (TimeEntry*)fetchTimeEntryByID:(NSInteger)timeEntryID error:(NSError *__autoreleasing *)error {
    @synchronized(self) {
        DEBUG_MSG

        NSAssert(timeEntryID > 0, @"Invalid timeEntryID %@", msg);
        NSAssert(nil != error, @"error cannot be nil %@", msg);
        NSArray* historyItems = [self fetchHistoryItems:error];
        if (nil == historyItems) {
            return nil;
        }
        if (nil != *error) {
            return nil;
        }
        TimeEntry* timeEntry;
        for (DayHistoryItem* item in historyItems) {
            timeEntry = [item fetchTimeEntryByID:timeEntryID error:error];
            if (nil != *error) {
                return nil;
            }
            if (timeEntry) {
                return timeEntry;
            }
        }
        return nil;
    }
}

- (NSMutableArray*)fetchTimeEntriesNeedingSubmission:(NSError*__autoreleasing*)error {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != error, @"error cannot be nil @", msg);
        NSArray* dayHistoryItems = [self fetchHistoryItems:error];
        if ((nil != *error) || (nil == dayHistoryItems) || (0 == dayHistoryItems.count)) {
            return nil;
        }
        NSArray* timeEntries;
        NSMutableArray* timeEntriesForSubmission = [NSMutableArray new];
        for (DayHistoryItem* item in dayHistoryItems) {
            timeEntries = [item fetchTimeEntries:error];
            if (nil != *error) {
                return nil;
            }
            if (nil == timeEntries || (0 == timeEntries.count)) {
                continue;
            }
            for (TimeEntry* timeEntry in timeEntries) {
                if ([timeEntry isNeedingSubmission]) {
                    [timeEntriesForSubmission addObject:timeEntry];
                }
            }
        }
        // sort the time entries in ascending order
        if (timeEntriesForSubmission.count > 1) {
            //RK: I changed it to sort from clock in value to clock out because of breaks. If you clock in at 9am, take a breatk at 12pm the end break at 1pm ad clock out at 5pm then if you sort by clock in time we would do the 9am/5pm before doing a break.
            NSSortDescriptor* descriptor = [NSSortDescriptor sortDescriptorWithKey:@"clockOut.dateTimeEntry" ascending:TRUE];
                //sortDescriptorWithKey:@"clockIn.dateTimeEntry" ascending:TRUE];
            NSArray* sortDescriptors = [NSArray arrayWithObject:descriptor];
            NSArray* sortedArray = [timeEntriesForSubmission sortedArrayUsingDescriptors:sortDescriptors];
            NSMutableArray* results = [NSMutableArray arrayWithArray:sortedArray];
            return results;
        }
        return timeEntriesForSubmission;
    }
}

- (TimeEntry*)saveNewClockInfo:(NSDictionary*)dict currentTimeEntry:(TimeEntry*)currentTimeEntry error:(NSError* __autoreleasing*)error {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != dict, @"dict cannot be nil %@", msg);
        NSAssert(nil != error, @"error cannot be nil %@", msg);

        __block TimeEntry* timeEntry = nil;
        __block BOOL shouldReturnNil = NO;
        
        [self.managedObjectContext performBlockAndWait:^{
            NSNumber* num = [dict valueForKey:kclockModeKey];
            ClockMode clockMode = (ClockMode)[num intValue];
            __block DayHistoryItem* dayHistoryItem;
            if ((clockMode == ClockModeOut) || (clockMode == BreakModeOut)) {
                if (nil != currentTimeEntry) {
                    timeEntry = currentTimeEntry;
                    dayHistoryItem = timeEntry.dayHistoryItem;
                } else {
                    timeEntry = [self fetchLastTimeEntryForToday:error];
                    NSAssert(nil != timeEntry, @"timeEntry cannot be nil if your clocking out %@", msg);
                    dayHistoryItem = timeEntry.dayHistoryItem;
                }
                assert(nil != dayHistoryItem);
            } else {
                dayHistoryItem = [self fetchTodaysDayHistoryItem:error];
            }
            if (nil != *error) {
                shouldReturnNil = YES;
                return;
            }
            NSDate* date = [dict valueForKey:kcurrentDateTimeKey];
            if (nil == dayHistoryItem) {
                dayHistoryItem = [self insertNewDayHistoryItem];
                dayHistoryItem.date = date;
                dayHistoryItem.employee = self;
            }
            if ((clockMode == ClockModeIn) || (clockMode == BreakModeIn)) {
                timeEntry = [dayHistoryItem insertNewTimeEntry];
                timeEntry.dayHistoryItem = dayHistoryItem;
                if (clockMode == BreakModeIn)
                    timeEntry.timeEntryType = kBreakTimeEntryType;
                else
                    timeEntry.timeEntryType = kNormalTimeEntryType;
            }
            [timeEntry setDBStatus:dsPendingInsert];
            [timeEntry updateTimeEntryFromDict:dict clockMode:clockMode];
            [timeEntry updateDBStatusAndDBStatusForClockMode:[timeEntry getDBStatus] clockMode:clockMode];
            [timeEntry.managedObjectContext save:error];
            if (nil != *error) {
                shouldReturnNil = YES;
                return;
            }
            [dayHistoryItem.managedObjectContext save:error];
            if (nil != *error) {
                shouldReturnNil = YES;
                return;
            }
            [self.managedObjectContext save:error];
            if (nil != *error) {
                shouldReturnNil = YES;
                return;
            }
        }];
        return timeEntry;
    }
}

- (TimeEntry*)createNewTimeEntry:(NSDictionary*)dict error:(NSError* __autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != dict, @"dict cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    NSDate* clockInDate = [dict valueForKey:kClockInDateKey];
    NSAssert(TRUE != [NSDate isNilOrNull:clockInDate], @"clockInDate cannot be nil %@", msg);

    NSDate* clockOutDate = [dict valueForKey:kClockOutDateKey];

    TimeEntry* timeEntry = nil;
    DayHistoryItem* dayHistoryItem = [self fetchHistoryItemByDate:clockInDate error:error];
    if (nil != *error) {
        return FALSE;
    }
    if (nil == dayHistoryItem) {
        dayHistoryItem = [self insertNewDayHistoryItem];
        dayHistoryItem.date = clockInDate;
        dayHistoryItem.employee = self;
    }
    timeEntry = [dayHistoryItem insertNewTimeEntry];
    timeEntry.dayHistoryItem = dayHistoryItem;
    
    timeEntry.notes = [dict objectForKey:kNotesKey];
    
    timeEntry.jobCodeId = [dict valueForKey:kJobCode];

    [timeEntry updateClockInClockOut:clockInDate clockOut:clockOutDate];

    [timeEntry updateDBStatus:dsPendingCreate];
    __block BOOL shouldReturnNil = NO;
    [self.managedObjectContext performBlockAndWait:^{
        [timeEntry.managedObjectContext save:error];
        if (nil != *error) {
            shouldReturnNil = YES;
            return;
        }
        [dayHistoryItem.managedObjectContext save:error];
        if (nil != *error) {
            shouldReturnNil = YES;
            return;
        }
        [self.managedObjectContext save:error];
        if (nil != *error) {
            shouldReturnNil = YES;
            return;
        }
    }];
    return timeEntry;
}

- (BOOL)removeDayHistoryItem:(DayHistoryItem*)dayHistoryItem error:(NSError*__autoreleasing*)error {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != dayHistoryItem, @"dayHistoryItem cannot be nil %@", msg);
        NSAssert(nil != error, @"error cannot be nil %@", msg);
        REMOVE_ENTITY_FROM_LIST(dayHistory, dayHistoryItem)
    }
}

@end
