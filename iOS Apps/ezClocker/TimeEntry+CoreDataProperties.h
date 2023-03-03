//
//  TimeEntry+CoreDataProperties.h
//  
//
//  Created by Raya Khashab on 10/26/19.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "TimeEntry.h"


NS_ASSUME_NONNULL_BEGIN

@interface TimeEntry (CoreDataProperties)

+ (NSFetchRequest<TimeEntry *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *notes;
@property (nullable, nonatomic, copy) NSNumber *status;
@property (nullable, nonatomic, copy) NSNumber *timeEntryID;
@property (nullable, nonatomic, copy) NSString *timeEntryType;
@property (nullable, nonatomic, copy) NSNumber *totalMilliseconds;
@property (nullable, nonatomic, copy) NSNumber *jobCodeId;
@property (nullable, nonatomic, retain) ClockInfo *clockIn;
@property (nullable, nonatomic, retain) ClockInfo *clockOut;
@property (nullable, nonatomic, retain) DayHistoryItem *dayHistoryItem;

@end

NS_ASSUME_NONNULL_END
