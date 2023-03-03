//
//  TimeEntry+CoreDataProperties.m
//  
//
//  Created by Raya Khashab on 10/26/19.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "TimeEntry+CoreDataProperties.h"

@implementation TimeEntry (CoreDataProperties)

+ (NSFetchRequest<TimeEntry *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"TimeEntry"];
}

@dynamic notes;
@dynamic status;
@dynamic timeEntryID;
@dynamic timeEntryType;
@dynamic totalMilliseconds;
@dynamic jobCodeId;
@dynamic clockIn;
@dynamic clockOut;
@dynamic dayHistoryItem;

@end
