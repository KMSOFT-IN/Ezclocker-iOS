//
//  DayHistoryItem+Extensions.h
//  ezClocker
//
//  Created by Kenneth Lewis on 12/15/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "DayHistoryItem.h"
#import "TimeEntry.h"
#import "coredatadefines.h"

@interface DayHistoryItem (DayHistoryItemExtensions)

- (TimeEntry*)insertNewTimeEntry;
- (TimeEntry*)addFromTimeEntry:(TimeEntry*)timeEntry error:(NSError*__autoreleasing*)error;

- (NSArray*)fetchTimeEntries:(NSError *__autoreleasing*)error;

- (BOOL)removeTimeEntry:(TimeEntry*)timeEntry error:(NSError*__autoreleasing*)error;
- (TimeEntry*)fetchTimeEntryByID:(NSInteger)timeEntryID error:(NSError *__autoreleasing *)error;

// Will have to search by NSManagedObjectID if timeEntryId hasn't been assigned yet from the server
- (TimeEntry*)fetchTimeEntryByObjectID:(NSManagedObjectID*)objectID error:(NSError*__autoreleasing*)error;

@end
