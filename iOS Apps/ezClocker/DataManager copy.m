//
//  DataManager.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/14/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "DataManager.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "NSBundle+Extensions.h"
#import "user.h"
#import "MetricsLogWebService.h"
#import "CommonLib.h"
#import "DayHistoryItem.h"
#import "NSManagedObjectContext+Extensions.h"
#import "Employee+CoreDataProperties.h"
#import "Employee+Extensions.h"
#import "DayHistoryItem+CoreDataProperties.h"
#import "DayHistoryItem+Extensions.h"
#import "TimeEntry+CoreDataProperties.h"
#import "TimeEntry+Extensions.h"
#import "ClockInfo+CoreDataProperties.h"
#import "ClockInfo+Extensions.h"
#import "DayHistoryItem.h"
#import "TimeEntry.h"
#import "TimeEntry+CoreDataProperties.h"
#import "ClockInfo.h"
#import "NSManagedObject+Extensions.h"
#import "debugdefines.h"
#import "threaddefines.h"
#import "NSData+Extensions.h"
#import "NSNumber+Extensions.h"
#import "coredatadefines.h"
#import "DeletedTimeEntry+CoreDataProperties.h"
#import "DeletedTimeEntry.h"
#import "NSDictionary+Extensions.h"
#import "Reachability.h"
#import "NSManagedObjectID+Extensions.h"

@interface TimeEntryInfo ()

@property (nonatomic, assign) ClockMode clockMode;
@property (nonatomic, copy) NSManagedObjectID* objectID; // save a copy of the objectID not a reference to TimeEntry

@end

@implementation TimeEntryInfo

// Get the TimeEntry when you need it instead of holding onto a reference from CoreData
- (TimeEntry*)timeEntry {
    DataManager* manager = [DataManager sharedManager];
    if (nil == _objectID) {
        return nil;
    }
    NSError* error = nil;
    TimeEntry* __result = (TimeEntry*)[manager existingObjectByID:_objectID error:&error];
    return __result;
}

- (instancetype)initWithTimeEntry:(TimeEntry *)aTimeEntry clockMode:(ClockMode)aClockMode {
    DEBUG_MSG
    NSAssert(nil != aTimeEntry, @"aTimeEntry cannot be nil %@", msg);

    self = [super init];
    if (self) {
        self.objectID = aTimeEntry.objectID; // save a copy of the NSManagedObjectID instead of holding onto a reference.
        _clockMode = aClockMode;
    }
    return self;
}

- (ClockInfo*)clockInfo {
    switch (_clockMode) {
        case ClockModeIn: {
            TimeEntry* __timeEntry = self.timeEntry;
            if (nil == __timeEntry) {
                return nil;
            }
            return __timeEntry.clockIn;
        }
        case ClockModeOut: {
            TimeEntry* __timeEntry = self.timeEntry;
            if (nil == __timeEntry) {
                return nil;
            }
            return __timeEntry.clockOut;
        }
        default:
            return nil;
    }
}

@end

@interface DayHistoryItemInfo () {

}

@property (nonatomic, copy) NSManagedObjectID* objectID;
@property (nonatomic, copy) NSString* displayDateTimeStr;
@property (nonatomic, retain) NSArray* timeEntries;

@end

@implementation DayHistoryItemInfo

- (DayHistoryItem*)historyItem {
    DataManager* manager = [DataManager sharedManager];
    if (nil == _objectID) {
        return nil;
    }
    NSError* error = nil;
    DayHistoryItem* __result = (DayHistoryItem*)[manager existingObjectByID:_objectID error:&error];
    return __result;
}


@end

@interface DataManager () {
    NSMutableArray* __timeHistory;
}

@property (retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) Employee* employee;
@property (nonatomic, retain) DayHistoryItem* workingHistoryItem;
@property (nonatomic, retain) TimeEntry* workingTimeEntry;
@property (nonatomic, assign) double totalDuration;
@property (nonatomic, copy) NSManagedObjectID* currentObjectID;
@property (atomic, assign) BOOL isBusy;
@property (nonatomic, assign) BOOL isBackgroundProcessing;
@property (nonatomic, retain) NSTimer* updateTimer;
@property (nonatomic, copy) UIBackgroundFetchResultCompletionBlock backgroundFetchCompletion;
@end

@implementation DataManager

#define SQLLITE_FILENAME @"ezClocker.sqlite"
#define TIME_OUT 60

@synthesize employee, isBusy;

- (instancetype)init
{
    self = [super init];
    if (self) {
        __timeHistory = [NSMutableArray new];
        [self initializeCoreData];
    }
    return self;
}


+ (NSString*)appDocumentsDir {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString*)getDocFileName:(NSString*)fileName {
    return [[DataManager appDocumentsDir] stringByAppendingPathComponent:fileName];
}

- (void)initializeCoreData
{
    DEBUG_MSG
    NSError* error = nil;
    NSString* _fileName = [DataManager getDocFileName:SQLLITE_FILENAME];
    NSURL* sqliteFile = [NSURL fileURLWithPath:_fileName];
    NSFileManager* fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[sqliteFile path]]) {
        //#ifndef RELEASE // ONLY USE THIS TO REMOVE THE FILE IF NEEDED TO START AGAIN FOR DEBUG
        //[fm removeItemAtPath:[sqliteFile path] error:&error];
        //#endif
    }
#ifndef RELEASE
    NSLog(@"SQLite file path: %@", [sqliteFile path]);
#endif
    @try {
        NSManagedObjectContext *context = [NSManagedObjectContext getObjectContextForModelUsingSqlite:@"TimeHistoryDataModel" url:sqliteFile error:&error];
        NSAssert(nil != context, @"Error initializing Managed Object Context %@", msg);
        _managedObjectContext = context;
    }
    @catch(NSException* ex) {
#ifndef RELEASE
        NSLog(@"Exception: %@ %@", ex, msg);
#endif
        @throw ex;
    }
}
- (TimeEntry*)currentTimeEntry {
    if (nil == self.currentObjectID) {
        return nil;
    }
    DataManager* manager = [DataManager sharedManager];
    NSError* error = nil;
    TimeEntry* result = (TimeEntry*)[manager existingObjectByID:_currentObjectID error:&error];
    if (nil != error) {
        return nil;
    }
    if (nil == result) {
        self.currentObjectID = nil;
    }
    return result;
}


- (TimeEntry*)fetchMostRecentTimeEntry:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    
    TimeEntry* timeEntry = [__employee fetchMostRecentTimeEntry:error];
    if (nil != *error) {
        return nil;
    }
    return timeEntry;
}
- (NSManagedObject*)existingObjectByID:(NSManagedObjectID*)objectID error:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != objectID, @"objectID cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil @", msg);
    NSManagedObject* result = [self.managedObjectContext existingObjectWithID:objectID error:error];
    if (nil != *error) {
#ifndef RELEASE
        NSLog(@"Error getting existing NSManagedObject by objectID %@ %@", (*error).localizedDescription, msg);
#endif
    }
    return result;
}

- (TimeEntry*)fetchTimeEntryByID:(NSNumber *)timeEntryID error:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != timeEntryID && [timeEntryID integerValue] > 0, @"timeEntryID must be a valid number.");
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    Employee* __employee = [self employee];
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    TimeEntry* timeEntry = [__employee fetchTimeEntryByID:[timeEntryID integerValue] error:error];
    return timeEntry;
}

- (NSManagedObject*)fetchEmployeeRecord:(NSNumber*)employeeID error:(NSError *__autoreleasing *)error {
    DEBUG_MSG
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    NSAssert(nil != employeeID && [employeeID integerValue] > 0, @"employeeID must be valid %@", employeeID);
    NSFetchRequest* fetchRequest = [NSFetchRequest new];
    NSInteger __employeeID = [employeeID integerValue];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"employeeID == %ld", __employeeID];
    NSEntityDescription* entity = [NSEntityDescription entityForName:NSStringFromClass([Employee class]) inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSArray* results = [self.managedObjectContext executeFetchRequest:fetchRequest error:error];
    if (nil == *error && results.count == 1) {
        Employee* result = [results objectAtIndex:0];
        return result;
    }
    return nil;
}
// external
- (void)checkAndLoadEmployeeInfo:(ServerResponseCompletionBlock)completion {
    [self checkAndLoadEmployeeInfo:FALSE completionBlock:completion];
}

// internal
- (void)checkAndLoadEmployeeInfo:(BOOL)isBackgroundProcess completionBlock:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    NSAssert(nil != completion, @"completion block cannot be nil %@", msg);
    Employee* __employee = self.employee;
    if (nil == __employee) {
#ifndef RELEASE
        NSLog(@"UserClass may not have it's userID set to a valid number.");
#endif
        completion(UNKNOWN_ERROR, @"Employee not set.  Check UserClass to make sure UserID is set.", nil, nil);
        return;
    }
    UserClass* user = [UserClass getInstance];
    [user checkPayrollStartDate:nil];
    
    NSDictionary* dict = @{kStartDateKey: user.payrollStartDate, kEndDateKey: user.payrollEndDate};
    [self loadTimesheetsForEmployee:dict refresh:FALSE isBackgroundProcess:isBackgroundProcess withCompletion:completion];
}


#pragma mark - getting employee
- (Employee*)employee {
    UserClass* user = [UserClass getInstance];
    if (nil != employee && [employee.employeeID integerValue] == [user.userID integerValue]) {
        return employee;
    }
    [__timeHistory removeAllObjects];
    NSError* error = nil;
    NSNumber* employeeID = user.userID;
    if ([NSNumber isNilOrNull:employeeID]) {
        return nil;
    }
    employee = (Employee*)[self fetchEmployeeRecord:employeeID error:&error];
    if ((nil == employee) || [NSNumber isNilOrNull:employee.employeeID] || (0 == [employee.employeeID integerValue])) {
        employee = [self.managedObjectContext insertNewEntityForClass:[Employee class]];
        DEBUG_MSG
        NSAssert(nil != employee, @"Error inserting new Employee into context in %@", msg);
        employee.employeeID = employeeID;
        NSString *name = [NSString trim:user.employerName];
        if ([NSString isNilOrEmpty:name]) {
            name = [NSString trim:user.userEmail];
        }
        employee.name = name;
        employee.email = user.userEmail;
        [self.managedObjectContext save:&error];
        assert(nil == error);
    }
    if (employee) {
        [self startUpdateTimer];
    }
    return employee;
}

- (NSArray*)timeHistory {
    return __timeHistory;
}

- (void)loadUpFromEmployee:(CompletionBlock)completion {
    NSString *clockInDateStr, *clockInDateEEEMMddStr;
    NSDate *clockInDate;
    double ms = 0;
    double totalms = 0;
    NSError* error = nil;
    
    _totalDuration = 0;
    @synchronized(__timeHistory) { // thread safe it
        [__timeHistory removeAllObjects];
        Employee* __employee = self.employee;
        NSArray* items = [__employee fetchHistoryItems:&error];
        if (nil == items) {
            if (nil != completion) {
                completion();
            }
            return;
        }
        
        DayHistoryItemInfo* dayHistoryInfo;
        TimeEntryInfo* timeEntryInfo;
        for (DayHistoryItem* historyItem in items) {
            ms = 0;
            
            dayHistoryInfo = [DayHistoryItemInfo new];
            [__timeHistory addObject:dayHistoryInfo];
            
            dayHistoryInfo.objectID = historyItem.objectID; // save a copy of the objectID not a reference
            
            NSMutableArray* __timeEntries = [NSMutableArray new];
            
            NSArray* timeEntries = [historyItem fetchTimeEntries:&error];
            if (nil == timeEntries || 0 == timeEntries.count) {
#ifndef RELEASE
                NSLog(@"NO timeEntries exists for dayHistoryItem.date=%@", [historyItem.date toLongDateTimeString]);
#endif
                clockInDateEEEMMddStr = [historyItem.date toEEEMMddFormat];
            }
            else {
                for (TimeEntry* timeEntry in timeEntries){
                    
                    clockInDate = nil;
                    clockInDateEEEMMddStr = @"";
                    
                    if (timeEntry.clockIn) {
                        
                        // ClockMode in
                        timeEntryInfo = [[TimeEntryInfo alloc] initWithTimeEntry:timeEntry clockMode:ClockModeIn];
                        [__timeEntries addObject:timeEntryInfo];
                        
                        clockInDate = timeEntry.clockIn.dateTimeEntry;
                        clockInDateEEEMMddStr = [clockInDate toEEEMMddFormat];
                    }
                    
                    // Clock Out NSDate
                    if (timeEntry.clockOut) {
                        // ClockMode out
                        timeEntryInfo = [[TimeEntryInfo alloc] initWithTimeEntry:timeEntry clockMode:ClockModeOut];
                        [__timeEntries addObject:timeEntryInfo];
                    }
                    
                    NSNumber* totalMS = timeEntry.totalMilliseconds;
#ifndef RELEASE
                    NSLog(@"timeEntry.totalMilliseconds=%ld", [totalMS longValue]);
#endif
                    double totalmilleseconds = [totalMS doubleValue];
                    ms += totalmilleseconds;
                }
            }
            
            totalms += ms;
            
            NSString *duration = [DataManager formatInterval:ms];
            
            clockInDateStr = [NSString stringWithFormat:@"%@           %@",clockInDateEEEMMddStr, duration];
            
            dayHistoryInfo.displayDateTimeStr = clockInDateStr;
            dayHistoryInfo.timeEntries = __timeEntries;
        }
        
        _totalDuration = totalms;
        if (nil != completion) {
            completion();
        }
    }
}

- (DayHistoryItem*)getTodaysDayHistoryItem:(NSError* __autoreleasing*)error {
    Employee* __employee = self.employee;
    if (__employee) {
        DayHistoryItem* item = [__employee fetchTodaysDayHistoryItem:error];
        return item;
    }
    return nil;
}

- (NSEntityDescription*)employeeEntityDesc {
    NSEntityDescription* entity = [NSEntityDescription entityForName:NSStringFromClass([Employee class]) inManagedObjectContext:self.managedObjectContext];
    return entity;
}

- (BOOL)clearAllData:(NSError *__autoreleasing *)error {
    DEBUG_MSG
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    NSFetchRequest* fetchRequest = [NSFetchRequest new];
    NSManagedObjectContext* __context = self.managedObjectContext;
    NSEntityDescription* entity = [self employeeEntityDesc];
    [fetchRequest setEntity:entity];
    NSArray* employees = [__context executeFetchRequest:fetchRequest error:error];
    if (nil != *error) {
        return FALSE;
    }
    if (nil == employees || 0 == employees.count) {
        return TRUE;
    }
    for (Employee* aEmployee in employees) {
        [__context deleteObject:aEmployee];
    }
    return [__context save:error];
}

- (BOOL)deleteAllEmployeesDayHistoryItems:(NSError *__autoreleasing *)error {
    NSAssert(nil != error, @"error cannot be nil");
    NSFetchRequest* fetchRequest = [NSFetchRequest new];
    NSEntityDescription* entity = [self employeeEntityDesc];
    [fetchRequest setEntity:entity];
    NSArray* employees = [self.managedObjectContext executeFetchRequest:fetchRequest error:error];
    if (nil != *error) {
        return FALSE;
    }
    // If we change the date range we have to clear out the day history items for everyone
    NSArray* dayHistory;
    for (Employee* aEmployee in employees) {
        dayHistory = [aEmployee fetchHistoryItems:error];
        for (DayHistoryItem* item in dayHistory) {
            [aEmployee.managedObjectContext deleteObject:item];
        }
    }
    return TRUE;
}

- (BOOL)deleteAllRecordsForEmployee:(NSError *__autoreleasing *)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil");
    NSArray* historyItems = [__employee fetchHistoryItems:error];
    if (nil != *error) {
        return FALSE;
    }

    [__timeHistory removeAllObjects];

    // Delete all DayHistoryItems for employee which will delete cascade for the other tables
    BOOL bAnyDeleted = FALSE;
    for (DayHistoryItem* historyItem in historyItems) {
        [__employee.managedObjectContext deleteObject:historyItem];
        bAnyDeleted = TRUE;
    }
    if (bAnyDeleted) {
        __employee.dayHistory = nil;
    }

    NSArray* deletedItems = [__employee fetchDeletedTimeEntries:error];
    for (DeletedTimeEntry* deleteItem in deletedItems) {
        [__employee.managedObjectContext deleteObject:deleteItem];
        bAnyDeleted = TRUE;
    }
    if (bAnyDeleted) {
        [__employee.managedObjectContext save:error];
        if (nil != *error) {
            return FALSE;
        }
        [self.managedObjectContext save:error];
        if (nil != *error) {
            return FALSE;
        }
    }
    _totalDuration = 0;
    return TRUE;
}

- (BOOL)deleteTimeEntry:(TimeEntry*)timeEntry error:(NSError *__autoreleasing *)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    NSAssert(nil != timeEntry, @"timeEntry cannot be nil %@", msg);
    NSArray* historyItems = [__employee fetchHistoryItems:error];
    if (nil == historyItems || *error) {
        return FALSE;
    }
    
    NSArray* timeEntries;
    DayHistoryItem* dayHistoryItem;
    
    // If the timeEntryID hasn't been set that means we never saved it to the server
    // so we can simply delete it from core data nothing to do on server
    IS_TIME_ENTRY_VALID()
    
    if (!bIsTimeEntryIDValid) {
        dayHistoryItem = timeEntry.dayHistoryItem;
        
        assert(nil != dayHistoryItem);
        
        NSManagedObjectID* deletedObjectID = [timeEntry.objectID copy];
        
        [dayHistoryItem removeTimeEntry:timeEntry error:error];
        if (nil != *error) {
            return FALSE;
        }
        
        if ((nil != _currentObjectID) && [deletedObjectID isEquals:_currentObjectID]) {
            self.currentObjectID = nil;
        }
        
        timeEntries = [dayHistoryItem fetchTimeEntries:error];
        if (nil != *error) {
            return FALSE;
        }
        
        if (0 == timeEntries.count) {
            [__employee removeDayHistoryItem:dayHistoryItem error:error];
            if (nil != *error) {
                return FALSE;
            }
        }
        
        [__employee.managedObjectContext save:error];
        if (nil != *error) {
            return FALSE;
        }
        
        [self.managedObjectContext save:error];
        if (nil != *error) {
            return FALSE;
        }
        
        return TRUE;
    }
    
    // Time Entry needs to be recorded in DeletedTimeEntry table for deletion from the server
    DeletedTimeEntry* deletedTimeEntry = [__employee insertNewDeleteTimeEntry];
    assert(nil != deletedTimeEntry);
    
    // Save the timeEntryID into DeleteTimeEntry table so we can remove it and delete
    // it from the server at a later point
    NSNumber* deletedTimeEntryID = [timeEntry.timeEntryID copy];
    deletedTimeEntry.timeEntryID = deletedTimeEntryID;
    deletedTimeEntry.employee = __employee;
    
    [__employee.managedObjectContext save:error];
    if (nil != *error) {
        return FALSE;
    }
    
    BOOL bResult = [self removeTimeEntry:timeEntry error:error];
    return bResult;
}

- (BOOL)removeTimeEntry:(TimeEntry*)timeEntry error:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != timeEntry, @"timeEntry cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    
    NSArray* timeEntries;
    DayHistoryItem* dayHistoryItem = timeEntry.dayHistoryItem;
    
    assert(nil != dayHistoryItem);
    
    NSManagedObjectID* deletedObjectID = [timeEntry.objectID copy];
    [dayHistoryItem removeTimeEntry:timeEntry error:error];
    if (nil != *error) {
        return FALSE;
    }
    
    if ((nil != _currentObjectID) && [deletedObjectID isEquals:_currentObjectID]) {
        self.currentObjectID = nil;
    }
    
    timeEntries = [dayHistoryItem fetchTimeEntries:error];
    if (nil != *error) {
        return FALSE;
    }
    
    if (0 == timeEntries.count) {
        [__employee removeDayHistoryItem:dayHistoryItem error:error];
        if (nil != *error) {
            return FALSE;
        }
    }
    
    [__employee.managedObjectContext save:error];
    if (nil != *error) {
        return FALSE;
    }
    
    [self.managedObjectContext save:error];
    if (nil != *error) {
        return FALSE;
    }
    
    return TRUE;
}

- (TimeEntry*)updateTimeEntryDetail:(TimeEntry*)timeEntry info:(NSDictionary*)info error:(NSError* __autoreleasing *)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != info, @"info cannot be nil %@", msg);
    NSAssert(nil != timeEntry, @"timeEntry cannot be nil %@", msg);
    
    NSDate* clockInDate = [info valueForKey:kClockInDateKey];
    NSAssert(TRUE != [NSDate isNilOrNull:clockInDate], @"clockInDate cannot be nil %@", msg);
    
    NSDate* clockOutDate = [info valueForKey:kClockOutDateKey];
    
    NSString* notes = [NSString trim:[info valueForKey:kNotesKey]];
    
    timeEntry.notes = notes;
    [timeEntry updateClockInClockOut:clockInDate clockOut:clockOutDate];
    [timeEntry updateTimeEntryForMilliseconds];
    
    // dbStatus must be dsUpdated in order ot set it to dsPendingUpdate
    // it could be on dsPendingCreate
    DBStatus dbStatus = [timeEntry getDBStatus];
    if (dbStatus == dsUpdated) {
        [timeEntry setDBStatus:dsPendingUpdate];
    }
    
    TimeEntry* result = timeEntry;
    
    // If we modify the clock in date we need to do the following:
    // 1.  Move the timeEntry to that DayHistoryItem if it exists.
    // 2.  If the DayHistoryItem does not exist then we create a new DayHistoryItem
    // 3.  We remove the TimeEntry from the old location.
    // 4.  If the source DayHistoryItem has no TimeEntry's we will delete the DayHistoryItem.
    if (timeEntry.clockIn && timeEntry.clockIn.dateTimeEntry && ![NSDate isEquals:timeEntry.dayHistoryItem.date dest:timeEntry.clockIn.dateTimeEntry]) {
        NSDate* date = timeEntry.clockIn.dateTimeEntry;
        DayHistoryItem* historyItem = [__employee fetchHistoryItemByDate:date error:error];
        if (nil != *error) {
#ifndef RELEASE
            NSLog(@"Error fetching dayHistoryItem - %@", (*error).localizedDescription);
#endif
            return nil;
        }
        
        if (nil == historyItem) {
            historyItem = [__employee insertNewDayHistoryItem];
            NSAssert(nil != historyItem, @"Error inserting new DayHistoryItem for Employee %@", msg);
            historyItem.date = date;
            historyItem.employee = __employee;
        }
        
        result = [historyItem addFromTimeEntry:timeEntry error:error];
        if (nil != *error) {
            return nil;
        }
        
        DayHistoryItem* __dayHistoryItem = timeEntry.dayHistoryItem;
        
        NSManagedObjectID* deletedObjectID = [timeEntry.objectID copy];
        [__dayHistoryItem removeTimeEntry:timeEntry error:error];
        if (nil != *error) {
            return nil;
        }
        
        if ((nil != _currentObjectID) && [_currentObjectID isEquals:deletedObjectID]) {
            self.currentObjectID = nil;
        }
        
        NSArray* array = [__dayHistoryItem fetchTimeEntries:error];
        if (array.count <= 0) {
            [__employee removeDayHistoryItem:__dayHistoryItem error:error];
            if (nil != *error) {
                return nil;
            }
        }
        
        [__employee.managedObjectContext save:error];
        if (nil != *error) {
            return nil;
        }
        
        return result;
    }
    
    [timeEntry.managedObjectContext save:error];
    if (nil != *error) {
        return nil;
    }
    
    [timeEntry.dayHistoryItem.managedObjectContext save:error];
    if (nil != *error) {
        return nil;
    }
    
    [__employee.managedObjectContext save:error];
    if (nil != *error) {
        return nil;
    }
    [self.managedObjectContext save:error];
    if (nil != *error) {
        return nil;
    }
    return result;
}

- (BOOL)updateTimeEntryInfo:(TimeEntry*)timeEntry info:(NSDictionary*)dict updateStatus:(BOOL)bUpdateStatus wasModified:(BOOL*)bModified error:(NSError *__autoreleasing *)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != timeEntry, @"timeEntry cannot be nil %@", msg);
    NSAssert(nil != bModified, @"bModified cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil in %@", msg);

    if (![timeEntry updateTimeEntryFromDict:dict wasModified:bModified error:error]) {
        return FALSE;
    }
    if (*bModified) {
        if (bUpdateStatus) {
            [timeEntry updateDBStatus:dsUpdated];
        }
        [__employee.managedObjectContext save:error];
        if (nil != *error) {
            return FALSE;
        }
    }
    return TRUE;
}

- (TimeEntry*)addNewTimeEntry:(NSDictionary*)dict error:(NSError *__autoreleasing *)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != dict, @"dict cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);

    NSNumber* timeEntryID = [dict valueForKey:@"id"];
    NSAssert(nil != timeEntryID && [timeEntryID integerValue] > 0, @"Invalid time entry 'id' %@", msg);

    NSDate* date = [[dict valueForKey:@"date"] toDefaultDate];
    if (nil == date) {
        NSString* test = [NSString trim:[dict valueForKey:kclockInIso8601Key]];
        date = [test toUTCDateTime];
    }

    DayHistoryItem* historyItem = [__employee fetchHistoryItemByDate:date error:error];
    if (nil == historyItem) {
        historyItem = [__employee insertNewDayHistoryItem];
        NSAssert(nil != historyItem, @"Error inserting new DayHistoryItem for Employee %@", msg);
        historyItem.date = date;
        historyItem.employee = __employee;
    }

    TimeEntry* timeEntry = [historyItem insertNewTimeEntry];
    NSAssert(nil != timeEntry, @"Error inserting new TimeEntry into DayHistoryItem %@", msg);
    timeEntry.dayHistoryItem = historyItem;
    
    timeEntry.timeEntryID = timeEntryID;

    BOOL bModified = FALSE;
    [self updateTimeEntryInfo:timeEntry info:dict updateStatus:FALSE wasModified:&bModified error:error];
    return timeEntry;
}

- (TimeEntry*)addOrUpdateTimeEntry:(NSDictionary *)dict error:(NSError *__autoreleasing *)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != dict, @"dict cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    
    NSNumber* timeEntryID = [dict valueForKey:@"id"];
    NSAssert(nil != timeEntryID && [timeEntryID integerValue] > 0, @"Invalid time entry 'id' %@", msg);
    
    TimeEntry* timeEntry = [__employee fetchTimeEntryByID:[timeEntryID integerValue] error:error];
    if (nil == timeEntry && nil == *error) {
        TimeEntry* result = [self addNewTimeEntry:dict error:error];
        if (nil != result) {
            self.currentObjectID = result.objectID;
        } else {
            self.currentObjectID = nil;
        }
        return timeEntry;
    }
    self.currentObjectID = timeEntry.objectID;
    BOOL bModified = FALSE;
    [self updateTimeEntryInfo:timeEntry info:dict updateStatus:TRUE wasModified:&bModified error:error];
    return timeEntry;
}

+ (BOOL)isReachable {
    BOOL bResult = [CommonLib DoWeHaveNetworkConnection];
    return bResult;
}

#pragma mark - Load Timesheets for Employee
// external
- (void)loadTimesheetsForEmployee:(NSDictionary*)info refresh:(BOOL)bRefresh withCompletion:(ServerResponseCompletionBlock)completion {
    [self loadTimesheetsForEmployee:info refresh:bRefresh isBackgroundProcess:FALSE withCompletion:completion];
}
// internal
- (void)loadTimesheetsForEmployee:(NSDictionary*)info refresh:(BOOL)bRefresh isBackgroundProcess:(BOOL)bIsBackgroundProcess  withCompletion:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    
    NSAssert(nil != info, @"info cannot be nil %@", msg);
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);
    if (!bIsBackgroundProcess) {
        if (self.isBusy) {
            completion(DATAMANAGER_BUSY, nil, nil, nil);
            return;
        }
    } else { // Reset background processing but do not set isBusy so that checkClockStatus can't sneak in before this one starts
        // because it has a while loop that is checking isBusy so it can check once it's set to FALSE
        // We will leave isBusy to TRUE so nothing can steal it and refreshing will be completed fully before
        // post notification is done and the TimeSheetMasterViewController just simply call reloadData for the tableview.
        // He will not refresh the data by calling this method after syncing.
        self.isBackgroundProcessing = FALSE;
    }
    
    self.isBusy = TRUE;
    
    Employee* __employee = self.employee;
    if (nil == __employee) {
        self.isBusy = FALSE;
        NSError* error = [self errorWithCode:DATAMANAGER_EMPLOYEE_NOT_SET];
        completion(DATAMANAGER_EMPLOYEE_NOT_SET, nil, nil, error);
        return;
    }
    
    NSString* startDate = [NSString trim:[info valueForKey:kStartDateKey]];
    NSAssert(TRUE != [NSString isNilOrEmpty:startDate], @"startDate cannot be nil or empty %@", msg);
    
    NSString* endDate = [NSString trim:[info valueForKey:kEndDateKey]];
    NSAssert(TRUE != [NSString isNilOrEmpty:endDate], @"endDate cannot be nil or empty %@", msg);
    
    NSInteger _employeeID = [__employee.employeeID integerValue];
    
    UserClass* user = [UserClass getInstance];
    
    [self loadUpFromEmployee:nil]; // load up the employee
    
    if (bRefresh) {
#ifndef DISABLE_OFFLINE_MODE
        self.isBusy = FALSE;
        completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
        return;
#else
        BOOL bIsReachable = [DataManager isReachable];
        if (!bIsReachable) {
#ifndef RELEASE
            NSLog(@"Not reachable");
#endif
            self.isBusy = FALSE;
            completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
            return;
        }
#endif
        
    } else {
        // If we do have timeHistory
        if (__timeHistory.count > 0) {
            self.isBusy = FALSE;
            completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
            return;
        }
        
        // else we will call the web service
    }
    
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    
    NSString* httpPostString = [NSString stringWithFormat:@"%@timeEntry/queryEmployee/%ld", SERVER_URL, (long)_employeeID];
    
    //Implement request_body for send request here authToken and clock DateTime set into the body.
    NSString* request_body = [NSString
                              stringWithFormat:@"authToken=%@&startDate=%@&endDate=%@&timeZoneId=%@&employerId=%@",
                              [user.authToken URLUTF8Encode],
                              [startDate  URLUTF8Encode],
                              [endDate  URLUTF8Encode],
                              [timeZoneId  URLUTF8Encode],
                              [[user.employerID  stringValue] URLUTF8Encode]
                              ];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    //set HTTP Method
    request.HTTPMethod = @"POST";
    request.HTTPBody = [request_body dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = TIME_OUT; // 2 minutes
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            MAINTHREAD_BLOCK_START()
            self.isBusy = FALSE;
            completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            MAINTHREAD_BLOCK_START()
            self.isBusy = FALSE;
            completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        @autoreleasepool {
            [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                    MAINTHREAD_BLOCK_START()
                    self.isBusy = FALSE;
                    completion(errorCode, resultMessage, results, aError);
                    THREAD_BLOCK_END()
                    return;
                }
                
                // delete here if it was successful
                NSError* __error = nil;
                if (![self deleteAllRecordsForEmployee:&__error]) {
                    self.isBusy = FALSE;
                    completion(UNKNOWN_ERROR, nil, nil, __error);
                    return;
                }
                
                NSDate *clockInDate;
                NSError *error = nil;
                NSArray* timeEntriesArray;
                double ms;
                double totalms = 0;
                NSDate* date;
                
                for (NSDictionary *dayEntries in results){
                    // *********************
                    // Insert DayHistoryItem
                    // *********************
                    self.workingHistoryItem = [__employee insertNewDayHistoryItem];
                    NSAssert(nil != _workingHistoryItem, @"Error inserting new DayHistoryItem for Employee");
                    _workingHistoryItem.employee = __employee;
                    
                    date = [[dayEntries valueForKey:@"date"] toDefaultDate];
                    _workingHistoryItem.date = date;
                    
                    ms = 0;
                    //add a date
                    resultMessage = [NSString trim:[dayEntries valueForKey:@"message"]];
                    clockInDate = nil;
                    //if message is null or <> Success then the call failed
                    if (([NSString isNilOrEmpty:resultMessage]) || (![resultMessage isEqualToString:@"Success"])){
                        if ([CommonLib isProduction]) {
                            [MetricsLogWebService LogException: [NSString stringWithFormat:@"Error from JSON Error= %@ resultMessage= %@", aError.localizedDescription, resultMessage]];
                        }
                    }
                    else {
                        timeEntriesArray = [dayEntries valueForKey:@"timeEntries"];
                        
                        for (NSDictionary *timeEntryRec in timeEntriesArray){
                            
                            // ****************
                            // Insert TimeEntry
                            // ****************
                            self.workingTimeEntry = [_workingHistoryItem insertNewTimeEntry];
                            NSAssert(nil != _workingTimeEntry, @"Error inserting new TimeEntry into DayHistoryItem");
                            _workingTimeEntry.dayHistoryItem = _workingHistoryItem;
                            
                            NSNumber* timeEntryID = [timeEntryRec valueForKey:@"id"];
                            NSAssert(nil != timeEntryID && [timeEntryID integerValue] > 0, @"Invalid time entry 'id' %@", msg);
                            
                            _workingTimeEntry.timeEntryID = timeEntryID;
                            
                            BOOL bModified = FALSE;
                            [self updateTimeEntryInfo:_workingTimeEntry info:timeEntryRec updateStatus:FALSE wasModified:&bModified error:&error];
                            
                            double milleseconds = [_workingTimeEntry.totalMilliseconds doubleValue];
                            ms += milleseconds;
                        }
                        
                        totalms += ms;
                        
                        _workingHistoryItem = nil;
                        _workingTimeEntry = nil;
                        
                        // This is already called inside updateTimeEntryInfo and [employee.managedObjectContext save:]
                        // will be called after so no need and may be causing issue.
                        /*[_workingHistoryItem.managedObjectContext save:&error];
                         if (nil != error) {
                         MAINTHREAD_BLOCK_START()
                         self.isBusy = FALSE;
                         completion(UNKNOWN_ERROR, nil, nil, error);
                         THREAD_BLOCK_END()
                         return;
                         }*/
                    }
                    
                }
                [self loadUpFromEmployee:^{
                    MAINTHREAD_BLOCK_START()
                    self.isBusy = FALSE;
                    completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
                    THREAD_BLOCK_END()
                }];
                
            }];
        }
    }];
    [dataTask resume];
}

+ (NSString *) formatInterval: (NSTimeInterval) interval{
    unsigned long milliseconds = interval;
    unsigned long seconds = milliseconds / 1000;
    unsigned long minutes = seconds / 60;
    unsigned long hours = minutes / 60;
    minutes %= 60;
    NSString *duration = [NSString stringWithFormat:@"%ldhrs %ldmins", hours, minutes];
    return duration;
}

#define kTimeEntryClockInOutURLFormat @"%@timeEntry/%@/%@/%@"
#ifndef PERSONAL_VERSION
#define kTimeEntryClockInOutBodyFormat @"authToken=%@&%@=%@&timeZoneId=%@&%@&%@&%@&%@&%@&%@&%@&%@&%@&%@&source=%@"

#else
#define kTimeEntryClockInOutBodyFormat @"authToken=%@&%@=%@&timeZoneId=%@%@&source=%@"
#endif

#ifndef PERSONAL_VERSION

+ (NSString*)getBodyForClockInClockOut:(NSDictionary*)dict {
    DEBUG_MSG

    NSAssert(nil != dict, @"dict cannot be nil %@", msg);
    UserClass* user = [UserClass getInstance];

    // clock in or clock out time
    NSDate* currentDateTime = [dict valueForKey:kcurrentDateTimeKey];
    NSString* strCurrentDateTime = [currentDateTime toUTCDateTimeStringForURL];

    // timezoneId
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;

    // gpsStatus
    NSString* gpsStatus = [NSString trim:[dict valueForKey:kgpsDataStatusKey]];

    // modified by
    NSString *modifiedBy = [NSString trim:[dict valueForKey:kmodifiedByKey]];

    // clock mode - clockInISO8601Utc or clockOutISO8601Utc
    NSNumber* num = [dict valueForKey:kclockModeKey];
    ClockMode clockMode = (ClockMode)[num intValue];
    NSString* clockModeStr = (clockMode == ClockModeIn) ? kclockInISO8601Utc : kclockOutISO8601Utc;

    // latitude
    num = [dict objectForKey:klatitudeKey];
    double latitude = [num doubleValue];

    // longitude
    num = [dict objectForKey:klongitudeKey];
    double longitude = [num doubleValue];

    // locTime
    num = [dict objectForKey:klocTimeKey];
    double locTime = [num doubleValue];

    // overrideLocationCheck - true/false
    num = [dict objectForKey:koverrideLocationCheckKey];
    BOOL bOverrideLocationCheck = [num boolValue];

    // speed
    num = [dict objectForKey:kspeedKey];
    double speed = [num doubleValue];

    // altitude
    num = [dict objectForKey:kaltitudeKey];
    double altitude = [num doubleValue];

    // accuracy
    num = [dict objectForKey:kaccuracyKey];
    double accuracy = [num doubleValue];

    // bearing
    num = [dict objectForKey:kbearingKey];
    double bearing = [num doubleValue];

    // source
    
    NSString* source = [NSString trim:[dict objectForKey:ksourceKey]];
    NSString* body = [NSString stringWithFormat:kTimeEntryClockInOutBodyFormat,
                      [user.authToken URLUTF8Encode],
                      clockModeStr, // clockInISO8601Utc or clockOutISO8601Utc
//                      [@"06/18/2016 8:40amPM"  URLUTF8Encode],
                      [strCurrentDateTime  URLUTF8Encode],
                      [timeZoneId  URLUTF8Encode],
                      [NSString stringWithFormat:@"gpsDataStatus=%@", gpsStatus],
                      [NSString stringWithFormat:@"modifiedBy=%@", modifiedBy],
                      [NSString stringWithFormat:@"latitude=%f", latitude],
                      [NSString stringWithFormat:@"longitude=%f", longitude],
                      [NSString stringWithFormat:@"locTime=%f", locTime],
                      [NSString stringWithFormat:@"overrideLocationCheck=%@", (bOverrideLocationCheck)?@"true":@"false"],
                      [NSString stringWithFormat:@"speed=%f", speed],
                      [NSString stringWithFormat:@"altitude=%f", altitude],
                      [NSString stringWithFormat:@"accuracy=%f", accuracy],
                      [NSString stringWithFormat:@"bearing=%f", bearing],
                      [source URLUTF8Encode]];
    return body;
}
#else
+ (NSString*)getBodyForClockInClockOut:(NSDictionary*)dict {
    DEBUG_MSG
    
    NSAssert(nil != dict, @"dict cannot be nil %@", msg);
    UserClass* user = [UserClass getInstance];
    
    // clock in or clock out time
    NSDate* currentDateTime = [dict valueForKey:kcurrentDateTimeKey];
    NSString* strCurrentDateTime = [currentDateTime toUTCDateTimeStringForURL];
    
    // timezoneId
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;
    
    // modified by
    //    NSString *modifiedBy = [NSString trim:[dict valueForKey:kmodifiedByKey]];
    
    // clock mode - clockInISO8601Utc or clockOutISO8601Utc
    NSNumber* num = [dict valueForKey:kclockModeKey];
    ClockMode clockMode = (ClockMode)[num intValue];
    NSString* clockModeStr = (clockMode == ClockModeIn) ? kclockInISO8601Utc : kclockOutISO8601Utc;
    
    // notes
    NSString* notes = [NSString trim:[dict valueForKey:kNotesKey]];
    NSString* desc = @"";
    if (![NSString isNilOrEmpty:notes]) {
        desc = [NSString stringWithFormat:@"&description=%@", [notes URLUTF8Encode]];
    }
    // source
    NSString* source = [NSString trim:[dict objectForKey:ksourceKey]];
    
    NSString* body = [NSString stringWithFormat:kTimeEntryClockInOutBodyFormat,
                      [user.authToken URLUTF8Encode],
                      clockModeStr, // clockInISO8601Utc or clockOutISO8601Utc
                      [strCurrentDateTime  URLUTF8Encode],
                      [timeZoneId  URLUTF8Encode],
                      //                      [NSString stringWithFormat:@"modifiedBy=%@", modifiedBy],
                      desc,
                      [source URLUTF8Encode]];
    return body;
}
#endif


- (TimeEntry*)getLastTimeEntryForToday:(NSError *__autoreleasing *)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    TimeEntry* timeEntry = [__employee fetchLastTimeEntryForToday:error];
    return timeEntry;
}

- (TimeEntry*)getTimeEntryByID:(NSNumber*)timeEntryID error:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != timeEntryID && [timeEntryID integerValue] > 0, @"timeEntryID cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    Employee* __employee = self.employee;
    TimeEntry* timeEntry = [__employee fetchTimeEntryByID:[timeEntryID integerValue] error:error];
    return timeEntry;
}

- (NSInteger)doesCurrentEmployeeNeedingSubmission:(NSError *__autoreleasing *)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    
    // check time entries needing submission
    NSArray* array = [self retrieveTimeEntriesNeedingSubmission:error];
    if (nil != *error) {
#ifndef RELEASE
        NSLog(@"there was an error retrievingTimeEntriesForNeedingSubmission %@ %@", *error, msg);
#endif
    }
    
    NSInteger count = nil != array ? array.count : 0;
    
    // check deleted time entries
    NSMutableArray* deletedTimeEntries = [__employee fetchDeletedTimeEntries:error];
    if (nil != *error) {
#ifndef RELEASE
        NSLog(@"there was an error fetchedingDeletedTimeEntries %@ %@", *error, msg);
#endif
    }
    
    count += nil != deletedTimeEntries ? deletedTimeEntries.count : 0;
    return count;
}

- (NSInteger)anyEmployeesNeedingSubmission:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    NSFetchRequest* fetchRequest = [NSFetchRequest new];
    NSEntityDescription* entity = [NSEntityDescription entityForName:NSStringFromClass([Employee class]) inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSArray* results = [self.managedObjectContext executeFetchRequest:fetchRequest error:error];
    if (nil == results || 0 == results.count || nil != *error) {
        return 0;
    }
    NSMutableArray* timeEntriesNeedingSubmission;
    NSMutableArray* deletedTimeEntriesNeedingSubmission;
    NSInteger count = 0;
    for (Employee* aEmployee in results) {
        timeEntriesNeedingSubmission = [aEmployee fetchTimeEntriesNeedingSubmission:error];
        if (nil != *error) {
#ifndef RELEASE
            NSLog(@"Error while fetching time entries needing submission %@", msg);
#endif
        }
        deletedTimeEntriesNeedingSubmission = [aEmployee fetchDeletedTimeEntries:error];
        if (nil != *error) {
            if (nil != *error) {
#ifndef RELEASE
                NSLog(@"Error while fetching deleted entries %@", msg);
#endif
            }
        }
        count = nil != timeEntriesNeedingSubmission ? timeEntriesNeedingSubmission.count : 0;
        count += nil != deletedTimeEntriesNeedingSubmission ? deletedTimeEntriesNeedingSubmission.count : 0;
    }
    return count;
}

- (NSMutableArray*)retrieveTimeEntriesNeedingSubmission:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    NSMutableArray* results = [__employee fetchTimeEntriesNeedingSubmission:error];
    return results;
}

- (void)__setCommonInfoForSubmission:(NSMutableDictionary*)dict {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != dict, @"dict cannot be nil %@", msg);

    UserClass* user = [UserClass getInstance];

    NSString *modifiedBy = [user getModifiedBy];

    [dict setValue:modifiedBy forKey:kmodifiedByKey];

    [dict setValue:user.employerID forKey:kemployerIdKey];
    [dict setValue:__employee.employeeID forKey:kEmployeeIDKey];
}

- (void)setInfoForClockModeSubmission:(NSMutableDictionary*)dict clockMode:(ClockMode)clockMode {
    [self __setCommonInfoForSubmission:dict];

    [dict setValue:[NSNumber numberWithInt:(int)clockMode] forKey:kclockModeKey];
}

- (void)setInfoForCreateSubmission:(NSMutableDictionary*)dict {
    [self __setCommonInfoForSubmission:dict];
}

#pragma mark - Handle Insert and Updates to the server in a recursive fashion so that the next one doesn't start till the previous has completed
// Recursively update to the server so that each update is completed and then the next time entry is processed in the list
- (void)updateNextTimeEntry:(NSMutableArray*)timeEntriesToUpdate withCompletion:(ServerResponseCompletionBlock)completion {
    if (timeEntriesToUpdate.count == 0) {
        completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
        return;
    }

    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
#ifndef RELEASE
        DEBUG_MSG
        NSLog(@"Not reachable - %@", msg);
#endif
        completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
        return;
    }
    TimeEntry* timeEntry = [timeEntriesToUpdate firstObject];
#ifndef RELEASE
    NSLog(@"timeEntry.date - %@", [timeEntry.dayHistoryItem.date toLongDateTimeString]);
    if (timeEntry.clockIn) {
        NSLog(@"timeEntry.clockIn - %@", [timeEntry.clockIn.dateTimeEntry toLongDateTimeString]);
    }
    if (timeEntry.clockOut) {
        NSLog(@"timeEntry.clockOut - %@", [timeEntry.clockOut.dateTimeEntry toLongDateTimeString]);
    }
#endif
    NSMutableDictionary* dict;
    DBStatus status = [timeEntry getDBStatus];
    switch (status) {
        case dsPendingCreate: { // This is when they added from the AddNewTimeEntryViewController
#ifndef RELEASE
            NSLog(@"starting pending create submission to server");
#endif
            dict = [NSMutableDictionary new];
            [timeEntry saveToDictForCreateSubmission:dict];
            [self setInfoForCreateSubmission:dict];
            [dict setValue:timeEntry forKey:ktimeEntryKey];
            [self sendCreateTimeEntryToServer:dict withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
                if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL) {
                    [timeEntriesToUpdate removeObjectAtIndex:0];
                    [self updateNextTimeEntry:timeEntriesToUpdate withCompletion:completion];
                } else {
                    completion(errorCode, resultMessage, results, error);
                    return;
                }
            }];
            break;
        }
        case dsPendingInsert: { // This is this is when you clock in/clock out EmployeeProfileViewController
#ifndef RELEASE
            NSLog(@"starting pending insert submission to server");
#endif
            BOOL bClockInNeedingSubmission = timeEntry.clockIn ? [timeEntry.clockIn isNeedingSubmission] : FALSE;
            BOOL bClockOutNeedingSubmission = timeEntry.clockOut ? [timeEntry.clockOut isNeedingSubmission] : FALSE;
            if (bClockInNeedingSubmission) {
                dict = [NSMutableDictionary new];
                [timeEntry.clockIn saveToDictForClockSubmission:dict isClockIn:TRUE];
                [self setInfoForClockModeSubmission:dict clockMode:ClockModeIn];
                [dict setValue:timeEntry forKey:ktimeEntryKey];
                [self sendClockModeToServer:dict withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
                    if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL && (bClockOutNeedingSubmission)) {
                        [timeEntry.clockOut saveToDictForClockSubmission:dict isClockIn:FALSE];
                        [self setInfoForClockModeSubmission:dict clockMode:ClockModeOut];
                        [dict setValue:timeEntry forKey:ktimeEntryKey];
                        [self sendClockModeToServer:dict withCompletion:^(NSInteger bErrorCode, NSString * _Nullable bResultMessage, NSDictionary * _Nullable bResults, NSError * _Nullable bError) {
                            if (bErrorCode == SERVICE_ERRORCODE_SUCCESSFUL) {
                                [timeEntriesToUpdate removeObjectAtIndex:0];
                                [self updateNextTimeEntry:timeEntriesToUpdate withCompletion:completion];
                            } else {
                                completion(bErrorCode, bResultMessage, bResults, bError);
                                return;
                            }
                        }];
                    } else if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL) {
                         [timeEntriesToUpdate removeObjectAtIndex:0];
                        [self updateNextTimeEntry:timeEntriesToUpdate withCompletion:completion];
                    } else {
                        completion(errorCode, resultMessage, results, error);
                        return;
                    }
                }];
            } else if (bClockOutNeedingSubmission) {
                dict = [NSMutableDictionary new];
                [timeEntry.clockOut saveToDictForClockSubmission:dict isClockIn:FALSE];
                [self setInfoForClockModeSubmission:dict clockMode:ClockModeOut];
                [dict setValue:timeEntry forKey:ktimeEntryKey];
                [self sendClockModeToServer:dict withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
                    if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL) {
                        [timeEntriesToUpdate removeObjectAtIndex:0];
                        [self updateNextTimeEntry:timeEntriesToUpdate withCompletion:completion];
                    } else {
                        completion(errorCode, resultMessage, results, error);
                        return;
                    }
                }];
            } else {
#ifndef RELEASE
                NSString* status = [timeEntry getDBStatusString];
                NSLog(@"WARNING: TimeEntry.getDBStatus is reporting but neither clockIn or clockOut is reporting any updates - %@", status);
#endif

            }
            break;
        }
        case dsPendingUpdate: { // This is when they update from the TimeSheetDetailViewController
#ifndef RELEASE
            NSLog(@"starting pending update submission to server");
#endif
            dict = [NSMutableDictionary new];
            [timeEntry saveToDictForUpdateSubmission:dict];
            [self setInfoForCreateSubmission:dict];
            [dict setValue:timeEntry forKey:ktimeEntryKey];
            [self sendTimeEntryUpdateToServer:dict withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
                if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL) {
                    [timeEntriesToUpdate removeObjectAtIndex:0];
                    [self updateNextTimeEntry:timeEntriesToUpdate withCompletion:completion];
                } else {
                    completion(errorCode, resultMessage, results, error);
                    return;
                }
            }];
            break;
        }
        default: {
#ifndef RELEASE
            NSLog(@"IF IT GOT HERE then dbStatus is not being set correctly somewhere!");
            if (timeEntry.clockIn && [timeEntry.clockIn getDBStatus] != dsUpdated) {
                NSLog(@"timeEntry.clockIn.dbStatus = %d", (int)[timeEntry.clockIn getDBStatus]);
            }
            if (timeEntry.clockOut && [timeEntry.clockOut getDBStatus] != dsUpdated) {
                NSLog(@"timeEntry.clockOut.dbStatus = %d", (int)[timeEntry.clockOut getDBStatus]);
            }
#endif
             [timeEntriesToUpdate removeObjectAtIndex:0];
            [self updateNextTimeEntry:timeEntriesToUpdate withCompletion:completion];
            break;
        }
    }
}

- (void)submitTimeEntriesNeedingSubmissionWithCompletion:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);
    NSError* error = nil;
    NSMutableArray* timeEntries = [self retrieveTimeEntriesNeedingSubmission:&error];
    if (nil != error) {
#ifndef RELEASE
        NSLog(@"error while retrieving time entries needing submission - %@", error.localizedDescription);
#endif
        completion(UNKNOWN_ERROR, nil, nil, error);
        return;
    }
    if (nil == timeEntries || timeEntries.count == 0) { // if no entries send success but nothing to do
        completion(SERVICE_ERRORCODE_SUCCESSFUL_NOTHING_TO_DO, nil, nil, nil);
        return;
    }
#ifndef RELEASE
    NSLog(@"starting submission(s) of CRUD to server");
#endif
    [self updateNextTimeEntry:timeEntries withCompletion:completion];
}

#pragma mark - Handle Delete entries from the server
- (void)removeNextTimeEntry:(NSMutableArray*)deletedTimeEntries selEmployeeID:(NSNumber*)selEmployeID withCompletion:(ServerResponseCompletionBlock)completion {
    if (deletedTimeEntries.count == 0) {
        completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
        return;
    }

#ifndef RELEASE
    NSLog(@"starting delete submission(s) to server");
#endif
    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
#ifndef RELEASE
        DEBUG_MSG
        NSLog(@"Not reachable - %@", msg);
#endif
        completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
        return;
    }
    DeletedTimeEntry* timeEntry = [deletedTimeEntries lastObject];
    [self sendRemoveTimeEntryToServer:timeEntry.timeEntryID withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
        if (errorCode == SERVICE_ERRORCODE_SUCCESSFUL) {
            [deletedTimeEntries removeLastObject];
            [self removeNextTimeEntry:deletedTimeEntries selEmployeeID:selEmployeID withCompletion:completion];
        } else {
            completion(errorCode, resultMessage, results, error);
        }
    }];
}

- (void)submitTimeEntriesForDeleteWithCompletion:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);
    NSError* error = nil;

    NSMutableArray* timeEntries = [__employee fetchDeletedTimeEntries:&error];
    if (nil != error) {
#ifndef RELEASE
        NSLog(@"error while fetching deleted time entries - %@", error.localizedDescription);
#endif
        completion(UNKNOWN_ERROR, nil, nil, error);
        return;
    }
    if (nil == timeEntries || timeEntries.count == 0) { // if no entries send success but nothing to do
        completion(SERVICE_ERRORCODE_SUCCESSFUL_NOTHING_TO_DO, nil, nil, nil);
        return;
    }
    [self removeNextTimeEntry:timeEntries selEmployeeID:__employee.employeeID withCompletion:completion];
}

- (void)startUpdateTimer {
    @synchronized(self) {
        [self stopTimer]; // 5 minutes
        if (!employee) { // cannot start timer if you don't have an employee selected
            return;
        }
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_IN_SECONDS target:self selector:@selector(updateInBackground:) userInfo:nil repeats:FALSE];
        [[NSRunLoop currentRunLoop] addTimer:_updateTimer forMode:NSRunLoopCommonModes];
    }
}
- (NSError*)errorWithCode:(NSInteger)code {
    NSError* result = [self errorWithCode:code desc:nil];
    return result;
}

- (NSError*)errorWithCode:(NSInteger)code desc:(NSString*)str {
    NSString* test = [NSString trim:str];
    if ([NSString isNilOrEmpty:test]) {
        test = [CommonLib errorMsg:code];
    }
    NSError* error = [NSError errorWithDomain:DATA_MANAGER_DOMAIN code:code userInfo:@{NSLocalizedDescriptionKey: test}];
    return error;
}


#pragma mark - Update in the background
- (void)__updateInBackground {
    DEBUG_MSG
    if (!employee) {
#ifndef RELEASE
        NSLog(@"unable to update in the background because there is no employee set and loaded");
#endif
        [self stopTimer]; // stop timer just in case sanity!
        self.isBusy = FALSE;
        self.isBackgroundProcessing = FALSE;
        if (_backgroundFetchCompletion) {
            UIBackgroundFetchResultCompletionBlock _block = _backgroundFetchCompletion;
            _backgroundFetchCompletion = nil;
            NSError* error = [self errorWithCode:DATAMANAGER_EMPLOYEE_NOT_SET];
            MAINTHREAD_BLOCK_START()
            _block(UIBackgroundFetchResultFailed, DATAMANAGER_EMPLOYEE_NOT_SET, error);
            THREAD_BLOCK_END()
        }
        return;
    }
    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
#ifndef RELEASE
        NSLog(@"Not reachable - %@", msg);
#endif
        [self __finishedBackgroundProcess:SERVICE_UNAVAILABLE_ERROR];
        return;
    }
    //    @autoreleasepool { // no need sync using Grand Central Dispatch to call this rountine
#ifndef RELEASE
        NSLog(@"starting CRUD submission(s) in background to server");
#endif
        //1. Start of with handle delete entries first
        [self submitTimeEntriesForDeleteWithCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
            // failed to submit time entries for delete so restart the timer and try again later
            if (errorCode == SERVICE_UNAVAILABLE_ERROR) {
                [self __finishedBackgroundProcess:errorCode];
                return;
            }
#ifndef RELEASE
            NSLog(@"Finished submission of deleted entries if there was any");
#endif
            // 2.  Next handle Create, Insert, and Update's in that order
            [self submitTimeEntriesNeedingSubmissionWithCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
#ifndef RELEASE
                NSLog(@"Finished submission of CRUD to server if there was any");
#endif
                [self __finishedBackgroundProcess:errorCode];
            }];
        }];
//    }
}

- (void)__finishedBackgroundProcess:(NSInteger)errorCode {
    if (_backgroundFetchCompletion) {
        UIBackgroundFetchResultCompletionBlock _block = _backgroundFetchCompletion;
        _backgroundFetchCompletion = nil;
        [self startUpdateTimer];
        if (errorCode == SERVICE_UNAVAILABLE_ERROR) {
            [self checkAndLoadEmployeeInfo:TRUE completionBlock:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
                [DataManager postDataManagerProcessCompleteNotification];
                MAINTHREAD_BLOCK_START()
                _block(UIBackgroundFetchResultFailed, errorCode, error);
                THREAD_BLOCK_END()
            }];
        } else {
            [self checkAndLoadEmployeeInfo:TRUE completionBlock:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
                [DataManager postDataManagerProcessCompleteNotification];
                MAINTHREAD_BLOCK_START()
                _block(UIBackgroundFetchResultNewData, errorCode, error); // only need to refresh if not an error
                THREAD_BLOCK_END()
            }];
        }
        return;
    }
    [self checkAndLoadEmployeeInfo:TRUE completionBlock:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable error) {
        [self startUpdateTimer];
        [DataManager postDataManagerProcessCompleteNotification];
    }];
}

+ (void)postDataManagerProcessCompleteNotification {
    MAINTHREAD_BLOCK_START()
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kDataManagerProcessCompleteNotification object:nil];
    THREAD_BLOCK_END()
}


- (void)forceSync {
    if (_backgroundFetchCompletion) {
        [self startUpdateTimer];
        return;
    }
    [self updateInBackground:nil];
}

- (void)forceSyncWithCompletion:(UIBackgroundFetchResultCompletionBlock)completionBlock {
    if (self.isBusy) {
        [self startUpdateTimer];
        NSError* error = [self errorWithCode:DATAMANAGER_BUSY];
        completionBlock(UIBackgroundFetchResultNoData, DATAMANAGER_BUSY, error);
        return;
    }
    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
        NSError* error = [self errorWithCode:SERVICE_UNAVAILABLE_ERROR];
        completionBlock(UIBackgroundFetchResultFailed, SERVICE_UNAVAILABLE_ERROR, error);
        return;
    }
    NSError* error = nil;
    NSInteger count = [self doesCurrentEmployeeNeedingSubmission:&error];
    if (nil != error) {
#ifndef RELEASE
        NSLog(@"error fetching any employees needing submission - %@", error.localizedDescription);
#endif
    }
    if (0 == count) {
        NSError* error = [self errorWithCode:DATAMANAGER_NO_PENDING_UPDATES];
        completionBlock(UIBackgroundFetchResultNoData, DATAMANAGER_NO_PENDING_UPDATES, error);
        return;
    }
    self.backgroundFetchCompletion = completionBlock;
    [self updateInBackground:nil];
}

- (void)updateInBackground:(NSTimer*)sender {
#ifndef RELEASE
    NSLog(@"updateInBackground");
#endif
    if (self.isBusy) {
        [self startUpdateTimer];
        return;
    }
    [self stopTimer];
    self.isBusy = TRUE;
    self.isBackgroundProcessing = TRUE; // set TRUE here only!  This will prevent main threading for background processing
    //                      when sending to the server.  When the UI calls the methods
    //                      and it was successfully sent to the server then it will
    //                      main thread before going back to the UI.
    THREAD_BLOCK_START()
    [self __updateInBackground];
    THREAD_BLOCK_END()
}

- (void)stopTimer {
    if (_updateTimer) {
        [_updateTimer invalidate];
        _updateTimer = nil;
    }
}

- (NSMutableDictionary*)prepareForClockModeSubmission:(ClockMode)clockMode
                                   currentDate:(NSDate*)currentDateTime
                                      location:(CLLocation*)loc
                                        source:(NSString*)source
                                   locOverride:(BOOL)bOverrideLocationCheck {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != currentDateTime, @"currentDateTime cannot be nil %@", msg);
    
#ifndef PERSONAL_VERSION

    NSAssert(nil != loc, @"loc cannot be nil %@", msg);

    NSString *gpsStatus = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)? kDISABLED: kACTIVE;
#endif

    NSMutableDictionary* dict = [NSMutableDictionary new];
    UserClass* user = [UserClass getInstance];

    NSString *modifiedBy = [user getModifiedBy];
    [dict setValue:modifiedBy forKey:kmodifiedByKey];

    [dict setValue:user.employerID forKey:kemployerIdKey];
    [dict setValue:__employee.employeeID forKey:kEmployeeIDKey];

    [dict setValue:[NSNumber numberWithInt:(int)clockMode] forKey:kclockModeKey];

    [dict setValue:currentDateTime forKey:kcurrentDateTimeKey]; // date in DayHistoryItem if it's the first one for the day and clockIn or clockOut based on ClockMode
#ifndef PERSONAL_VERSION
    [dict setValue:gpsStatus forKey:kgpsDataStatusKey];
    [dict setValue:[NSNumber numberWithDouble:loc.coordinate.latitude] forKey:klatitudeKey];
    [dict setValue:[NSNumber numberWithDouble:loc.coordinate.longitude] forKey:klongitudeKey];
    [dict setValue:[NSNumber numberWithDouble:loc.timestamp.timeIntervalSince1970] forKey:klocTimeKey];
    [dict setValue:[NSNumber numberWithBool:bOverrideLocationCheck] forKey:koverrideLocationCheckKey];
    [dict setValue:[NSNumber numberWithDouble:loc.speed] forKey:kspeedKey];
    [dict setValue:[NSNumber numberWithDouble:loc.altitude] forKey:kaltitudeKey];
    [dict setValue:[NSNumber numberWithDouble:loc.horizontalAccuracy] forKey:kaccuracyKey];
    [dict setValue:[NSNumber numberWithDouble:loc.course] forKey:kbearingKey];
#endif

    [dict setValue:source forKey:ksourceKey];
    return dict;
}

#pragma mark - Send Clock In/Out to the server
- (void)sendClockModeToServer:(NSMutableDictionary*)dict withCompletion:(ServerResponseCompletionBlock)completion {
    @synchronized(self) {
        DEBUG_MSG
        Employee* __employee = self.employee;
        NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
        NSAssert(nil != dict, @"dict cannot be nil @", msg);
        
        NSNumber* num = [dict valueForKey:kclockModeKey];
        NSAssert(TRUE != [NSNumber isNilOrNull:num], @"%@ must be in the dictionary %@", kclockModeKey, msg);
        NSNumber* selEmployeeID = [dict valueForKey:kEmployeeIDKey];
        NSAssert(TRUE != [NSNumber isNilOrNull:num], @"%@ must be in the dictionary %@", kEmployeeIDKey, msg);
        
        NSMutableDictionary* __dict = [NSMutableDictionary dictionaryWithDictionary:dict];
        
        // This will be set in the background process only now.
        // We will only create the time entry if it was sent to the server successfully.
        __block TimeEntry* __timeEntry = [dict valueForKey:ktimeEntryKey];
        if (__timeEntry) {
            NSString* testNotes = [NSString trim:__timeEntry.notes];
            if (![NSString isNilOrEmpty:testNotes]) {
                [__dict setValue:testNotes forKey:kNotesKey];
            }
        }
        
        ClockMode clockMode = (ClockMode)[num intValue];
        
        UserClass* user = [UserClass getInstance];
        
        NSString* clockInOrOutStr = clockMode == ClockModeIn ? @"clockIn" : @"clockOut";
        
        NSString* request_body = [DataManager getBodyForClockInClockOut:__dict];
        
        NSString* httpPostString = [NSString stringWithFormat:kTimeEntryClockInOutURLFormat, SERVER_URL, clockInOrOutStr, user.employerID, selEmployeeID];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpPostString]];
        
        request.HTTPMethod = @"POST";
        request.HTTPBody = [request_body dataUsingEncoding:NSUTF8StringEncoding];
        
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = TIME_OUT; // 2 minutes
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
        
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            __block NSError* __error = nil;
            if (nil != error) { // if error reported such as timeout or anything from iOS
#ifndef RELEASE
                NSLog(@"Error retrieved from request sent - %@ - %@", error.localizedDescription, msg);
#endif
                if (self.isBackgroundProcessing) {
                    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
                    return;
                }
                MAINTHREAD_BLOCK_START()
                [self saveNewClockInfoToDatabase:dict error:&__error];
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
                THREAD_BLOCK_END()
                return;
            }
            // Check the response statusCode
            NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
            if (statusCode == SERVICE_UNAVAILABLE_ERROR){
                if (self.isBackgroundProcessing) {
                    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                    return;
                }
                MAINTHREAD_BLOCK_START()
                [self saveNewClockInfoToDatabase:dict error:&__error];
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
                THREAD_BLOCK_END()
                return;
            }
            @autoreleasepool {
                [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                    if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                        if (self.isBackgroundProcessing) {
                            completion(errorCode, resultMessage, results, aError);
                            return;
                        }
                        MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(errorCode, resultMessage, results, aError);
                        THREAD_BLOCK_END()
                        return;
                    }
                    
                    if ((errorCode == SERVICE_ERRORCODE_ALREADY_CLOCKED_IN || errorCode == SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT)) {
                        if (__timeEntry) {
                            [self handleAlreadyClockedInOrOut:errorCode timeEntry:__timeEntry withCompletion:completion];
                        } else {
                            MAINTHREAD_BLOCK_START()
                            self.isBusy = FALSE;
                            //[DataManager postDataManagerProcessCompleteNotification];
                            completion(errorCode, resultMessage, results, aError);
                            THREAD_BLOCK_END()
                        }
                        return;
                    }
                    
                    // Look for the timeEntry
                    NSDictionary *timeEntryRec = [results valueForKey:ktimeEntryKey];
                    if ([NSDictionary isNilOrNull:timeEntryRec]) { // if not there then return the information
                        if (self.isBackgroundProcessing) {
                            completion(UNKNOWN_ERROR, nil, nil, nil);
                            return;
                        }
                        MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(UNKNOWN_ERROR, nil, nil, nil);
                        THREAD_BLOCK_END()
                        return;
                    }
                    
                    // check the timeEntryId
                    NSNumber *timeEntryId = [timeEntryRec valueForKey:kidKey];
                    if (nil == timeEntryId || ([timeEntryId intValue] <= 0)) {
                        completion(UNKNOWN_ERROR, nil, nil, nil);
                        return;
                    }
                    
                    // If __timeEntry was NOT passed into the dictionary by the background process that means
                    // we were successful when clocking in and we got a timeEntryId so we will create a new
                    // time entry
                    if (nil == __timeEntry) {
                        NSError* __error = nil;
                        __timeEntry = [self saveNewClockInfoToDatabase:dict error:&__error];
                        if (nil != __error) {
                            completion(UNKNOWN_ERROR, nil, nil, __error);
                            return;
                        }
                    }
                    if (![NSNumber isEquals:__timeEntry.timeEntryID dest:timeEntryId]) {
                        __timeEntry.timeEntryID = timeEntryId;
                    }
                    [__timeEntry updateDBStatusAndDBStatusForClockMode:dsUpdated clockMode:clockMode];
                    NSNumber* millescondsDuration = [timeEntryRec valueForKey:kmillisecondsDurationKey];
                    if (![NSNumber isNilOrNull:millescondsDuration]) {
                        __timeEntry.totalMilliseconds = millescondsDuration;
                    }
                    
                    NSError* __error = nil;
                    DayHistoryItem* dayHistoryItem = __timeEntry.dayHistoryItem;
                    [dayHistoryItem.managedObjectContext save:&__error];
                    if (nil != __error) {
#ifndef RELEASE
                        NSLog(@"Error saving updating __timeEntry - %@ - %@", __error.localizedDescription, msg);
#endif
                        if (self.isBackgroundProcessing) {
                            completion(UNKNOWN_ERROR, nil, nil, __error);
                            return;
                        }
                        MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(UNKNOWN_ERROR, nil, nil, __error);
                        THREAD_BLOCK_END()
                        return;
                    }
                    [__employee.managedObjectContext save:&__error];
                    if (nil != __error) {
#ifndef RELEASE
                        NSLog(@"Error saving __employee.managedObjectContext save: - %@ - %@", __error.localizedDescription, msg);
#endif
                        if (self.isBackgroundProcessing) {
                            completion(UNKNOWN_ERROR, nil, nil, __error);
                            return;
                        }
                        MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(UNKNOWN_ERROR, nil, nil, __error);
                        THREAD_BLOCK_END()
                        return;
                    }
                    [self.managedObjectContext save:&__error];
                    if (self.isBackgroundProcessing) {
                        completion(errorCode, resultMessage, results, aError);
                        return;
                    }
                    MAINTHREAD_BLOCK_START()
                    self.isBusy = FALSE;
                    completion(errorCode, resultMessage, results, aError);
                    THREAD_BLOCK_END()
                }];
            }
        }];
        [dataTask resume];
    }
}

- (TimeEntry*)saveNewClockInfoToDatabase:(NSMutableDictionary*)dict error:(NSError* __autoreleasing*)error {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    
    NSNumber* num = [dict valueForKey:kclockModeKey];
    ClockMode clockMode = (ClockMode)[num intValue];
    TimeEntry* __currentTimeEntry = self.currentTimeEntry;
    if (nil == __currentTimeEntry && ClockModeOut == clockMode) {
        __currentTimeEntry = [__employee fetchMostRecentTimeEntry:error];
    } else if (ClockModeIn == clockMode) {
        __currentTimeEntry = nil;
    }
    
    TimeEntry* timeEntry = [__employee saveNewClockInfo:dict currentTimeEntry:__currentTimeEntry error:error];
    if (nil == timeEntry || nil != *error) {
        self.currentObjectID = nil;
        return nil;
    }
    if (ClockModeIn == clockMode) {
        self.currentObjectID = timeEntry.objectID;
    }
    [dict setValue:timeEntry forKey:ktimeEntryKey];
    return timeEntry;
}

#pragma mark - Clock In/Clock Our - EmployeeProfileViewController calls this to clock in and clock out
- (void)clockInOrClockOut:(ClockMode)clockMode
        timeEntryObjectID:(NSManagedObjectID*)timeEntryObjectID
              currentDate:(NSDate*)currentDateTime
                 location:(CLLocation*)loc
                   source:(NSString*)source
              locOverride:(BOOL)bOverrideLocationCheck
           withCompletion:(ServerResponseCompletionBlock)completion {
    
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != completion, @"completionBlock cannot be nil %@", msg);
    
    if (clockMode == ClockModeIn) { // sanity check - clock in should not have a TimeEntry it hasn't been created
        timeEntryObjectID = nil;
    } else if (clockMode == ClockModeOut && nil == timeEntryObjectID) { // sanity check - if clock out and no timeEntryObjectID then return UNKNOWN_ERROR as it's required
#ifndef RELEASE
        NSLog(@"If ClockMode is ClockModeOut you must have a timeEntryObjectID");
#endif
        completion(UNKNOWN_ERROR, nil, nil, nil);
        return;
    }
    
    if (self.isBusy) {
        completion(DATAMANAGER_BUSY, nil, nil, nil);
        return;
    }
    
    self.isBusy = TRUE;
    
    NSMutableDictionary* dict = [self prepareForClockModeSubmission:clockMode currentDate:currentDateTime location:loc source:source locOverride:bOverrideLocationCheck];
    
    NSError* error = nil;
    
    TimeEntry* timeEntry = nil;
    // If clockMode is ClockModeOut use the TimeEntry.objectID passed in to get the timeEntry that we are going to use and set currentObjectID
    if (clockMode == ClockModeOut) {
        timeEntry = (TimeEntry*)[self existingObjectByID:timeEntryObjectID error:&error];
        if ((nil == timeEntry) || (nil != error)) {
            self.isBusy = FALSE;
            completion(UNKNOWN_ERROR, nil, nil, error);
            return;
        }
        self.currentObjectID = timeEntry.objectID;
        [dict setObject:timeEntry forKey:ktimeEntryKey];
    } else {
        self.currentObjectID = nil;
    }
    
#ifndef DISABLE_OFFLINE_MODE
    // ******************************************************************
    // TODO: TESTING OFFLINE rem out once you got everything working good
    // ******************************************************************
    [self saveNewClockInfoToDatabase:dict error:&error];
    self.isBusy = FALSE;
    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
    return;
#else
    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
#ifndef RELEASE
        NSLog(@"Not reachable");
#endif
        [self saveNewClockInfoToDatabase:dict error:&error];
        self.isBusy = FALSE;
        completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
        return;
    }
#endif
    
    [self sendClockModeToServer:dict withCompletion:completion];
}


-(void) checkOptions:(NSDictionary*) aResults
{
    //check if the edit disable flag changed
    UserClass *user = [UserClass getInstance];
    NSString *optionName;
    NSNumber *optionValue;
    NSArray *employerOptions = [aResults valueForKey:@"employerOptions"];
    for (NSDictionary* optionItem in employerOptions) {
        optionName = [optionItem valueForKey:@"optionName"];
        if ([optionName isEqualToString:@"EMPLOYER_DISABLE_TIME_ENTRY_EDITING"])
        {
            optionValue = [optionItem valueForKey:@"optionValue"];
            bool boolValue = true;
            if (user.disableTimeEntryEditing != [optionValue intValue]){
                user.disableTimeEntryEditing = [optionValue intValue];
                //persist selection
                [[NSUserDefaults standardUserDefaults] setInteger:user.disableTimeEntryEditing forKey:@"disableTimeEntryEditing"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
            }
        }
        
    }

}

#pragma mark - Check Clock Status
- (void)checkClockStatus:(NSNumber*)employeeId withCompletion:(ServerResponseCompletionBlock)completion {
    self.currentObjectID = nil; // reset current time entry so that it will use today if it cannot connect for whatever reason
    DEBUG_MSG
    NSAssert(nil != completion, @"completion block cannot be nil %@", msg); NSAssert(nil != employeeId && [employeeId integerValue] > 0, @"employerId cannot be nil and must be valid %@", msg);

    
    if (self.isBusy) {
        completion(DATAMANAGER_BUSY, nil, nil, nil);
        return;
    }

    self.isBusy = TRUE;

#ifndef DISABLE_OFFLINE_MODE
    // ******************************************************************
    // TODO: TESTING OFFLINE rem out once you got everything working good
    // ******************************************************************
    self.isBusy = FALSE;
    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
    return;
#else
    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
#ifndef RELEASE
        NSLog(@"Not reachable - %@", msg);
#endif
        self.isBusy = FALSE;
        completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
        return;
    }
#endif

    UserClass *user = [UserClass getInstance];
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;

    NSString *employeeIDStr = [employeeId stringValue];
   // NSString *httpPostString = [NSString stringWithFormat:@"%@api/v1/timeentry/active/%@?timezone=%@&source=%@", SERVER_URL, employeeIDStr, timeZoneId, @"iPhone"];
    NSString *httpPostString = [NSString stringWithFormat:@"%@api/v1/account/state/employee/%@?timezone=%@", SERVER_URL, employeeIDStr, timeZoneId];



    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];

    NSString *tmpEmployerID = [user.employerID stringValue];
    NSString *tmpAuthToken = user.authToken;

    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:tmpEmployerID forHTTPHeaderField:@"x-ezclocker-employerId"];
    [request setValue:tmpAuthToken forHTTPHeaderField:@"x-ezclocker-authToken"];

    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = TIME_OUT; // 2 minutes
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];

    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        @autoreleasepool {
            [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                
                [self checkOptions: results];
                
                if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                    MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(errorCode, resultMessage, results, aError);
                    THREAD_BLOCK_END()
                    return;
                }
                NSDictionary *timeEntryRec = [results valueForKey:@"clockInOutState"];
                //NSDictionary *timeEntryRec = [results valueForKey:@"timeEntry"];
                if ([NSDictionary isNilOrNull:timeEntryRec]) {
                    timeEntryRec = nil;
                    //user.activeTimeEntryId = nil;
                    MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
                    THREAD_BLOCK_END()
                } else {
                    MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(errorCode, resultMessage, results, aError);
                    THREAD_BLOCK_END()
                }
            }];
        }
    }];
    [dataTask resume];
}

- (void)callGetTimeEntryByIDWebService:(NSNumber *)timeEntryID withCompletion:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    NSAssert(nil != timeEntryID && [timeEntryID integerValue] > 0, @"invalid timeEntryID provided %@", msg);
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);

    if (self.isBusy) {
        completion(DATAMANAGER_BUSY, nil, nil, nil);
        return;
    }

    self.isBusy = TRUE;

#ifndef DISABLE_OFFLINE_MODE
    // ******************************************************************
    // TODO: TESTING OFFLINE rem out once you got everything working good
    // ******************************************************************
    self.isBusy = FALSE;
    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
    return;
#else
    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
#ifndef RELEASE
        NSLog(@"Not reachable - %@", msg);
#endif
        self.isBusy = FALSE;
        completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
        return;
    }
#endif

    UserClass* user = [UserClass getInstance];

    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;

    NSString* httpPostString = [NSString stringWithFormat:@"%@timeEntry/getSingle/%@/%@?timezone=%@&authToken=%@", SERVER_URL, user.employerID, timeEntryID, timeZoneId, user.authToken];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];

    request.HTTPMethod = @"GET";

    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = TIME_OUT; // 2 minutes
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];

    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        @autoreleasepool {
                [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                    if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                    MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(errorCode, resultMessage, results, aError);
                    THREAD_BLOCK_END()
                    return;
                }
                NSDictionary *timeEntryRec = [results valueForKey:ktimeEntryKey];
                if ([NSDictionary isNilOrNull:timeEntryRec]) {
                    timeEntryRec = nil;
                    MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
                    THREAD_BLOCK_END()
                } else {
                    MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(errorCode, resultMessage, results, aError);
                    THREAD_BLOCK_END()
                }
            }];
        }
    }];
    [dataTask resume];
 }

#pragma mark - Remove Time Entry From Server - TimeSheetDetailViewController calls this to delete the time entry
- (void)removeTimeEntryFromServer:(TimeEntry*)timeEntry withCompletion:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    NSAssert(nil != timeEntry, @"timeEntryID must be valid %@", msg);
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);

    if (self.isBusy) {
        completion(DATAMANAGER_BUSY, nil, nil, nil);
        return;
    }

    self.isBusy = TRUE;

    NSError* error = nil;
    IS_TIME_ENTRY_VALID()

    if (![self deleteTimeEntry:timeEntry error:&error]) {
        self.isBusy = FALSE;
        completion(UNKNOWN_ERROR, nil, nil, nil);
        return;
    }

    if (!bIsTimeEntryIDValid) { // no timeEntryID has been set on timeEntry meaning no new entry sent to server yet
                                // and sence you deleted it no need to go to the server
        self.isBusy = FALSE;
        completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
        return;
    }

#ifndef DISABLE_OFFLINE_MODE
    // ***********************************************
    // TODO: Remove these lines after testing offline!
    // ***********************************************
    self.isBusy = FALSE;
    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
    return;
#else
    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
#ifndef RELEASE
        NSLog(@"Not reachable - %@", msg);
#endif
        self.isBusy = FALSE;
        completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
        return;
    }
#endif

    [self sendRemoveTimeEntryToServer:timeEntryID withCompletion:completion];
}

#pragma mark - Delete Time Entry from the server
- (void)sendRemoveTimeEntryToServer:(NSNumber*)timeEntryID withCompletion:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);

    BOOL bIsTimeEntryIDValid = ![NSNumber isNilOrNull:timeEntryID] && ([timeEntryID integerValue] > 0);

    NSAssert(TRUE == bIsTimeEntryIDValid, @"timeEntryID must be valid %@", msg);

    // SANITY to prevent sending a zero to the server ever!
    assert(TRUE == bIsTimeEntryIDValid);

    UserClass* user = [UserClass getInstance];

    NSString *modifiedBy = [user getModifiedBy];

    NSString *httpPostString = [NSString stringWithFormat:@"%@timeEntry/remove/%@/%@", SERVER_URL, user.employerID, timeEntryID];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];

    //Implement request_body for send request here authToken and clock DateTime set into the body.
    NSString* request_body = [NSString stringWithFormat:@"authToken=%@&modifiedBy=%@", [user.authToken URLUTF8Encode], [modifiedBy URLUTF8Encode]];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [request_body dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = TIME_OUT; // 2 minutes
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];

    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
#ifndef RELEASE
            NSLog(@"Error retrieved from request sent - %@ - %@", error.localizedDescription, msg);
#endif
            if (self.isBackgroundProcessing) {
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
                return;
            }
            MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            if (self.isBackgroundProcessing) {
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                return;
            }
            MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
            THREAD_BLOCK_END()
            return;
        }
        @autoreleasepool {
            [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                NSString* tmpMsg = [[NSString stringWithFormat:@"unable to locate timeentry with id of %@", timeEntryID] lowercaseString];
                BOOL bRemovedAlready = [[resultMessage lowercaseString] containsString:tmpMsg];
                if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR && !bRemovedAlready) {
                    if (self.isBackgroundProcessing) {
                        completion(errorCode, resultMessage, results, aError);
                        return;
                    }
                    MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(errorCode, resultMessage, results, aError);
                    THREAD_BLOCK_END()
                    return;
                }
                NSError* __error = nil;
                if (![__employee deleteTimeEntryFromDeletedTimeEntries:timeEntryID error:&__error]) {
#ifndef RELEASE
                    NSLog(@"Error while deleting time entries after submission - %@ - %@", __error.localizedDescription, msg);
#endif
                    if (self.isBackgroundProcessing) {
                        completion(UNKNOWN_ERROR, nil, nil, __error);
                        return;
                    }
                    MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(UNKNOWN_ERROR, nil, nil, __error);
                    THREAD_BLOCK_END()
                    return;
                }
                [self.managedObjectContext save:&__error];
#ifndef RELEASE
                if (nil != __error) {
                    NSLog(@"Error while saving self.managedObjectContext save: - %@ - %@", __error.localizedDescription, msg);
                }
#endif
                if (self.isBackgroundProcessing) {
                    completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, __error);
                    return;
                }
                MAINTHREAD_BLOCK_START()
                    self.isBusy = FALSE;
                    completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, __error);
                THREAD_BLOCK_END()
            }];
        }
    }];
    [dataTask resume];
}

- (NSMutableDictionary*)prepareForUpdateSubmission:(TimeEntry*)timeEntry clockIn:(NSDate*)clockIn clockOut:(NSDate*)clockOut notes:(NSString*)notes {
    DEBUG_MSG
    NSAssert(nil != timeEntry, @"timeEntry cannot be nil %@", msg);
    NSAssert(TRUE != [NSDate isNilOrNull:clockIn], @"clockIn cannot be nil %@", msg);
    NSString* testNotes = [NSString trim:notes];
    NSAssert(TRUE != [NSString isNilOrEmpty:testNotes], @"notes cannot be nil or empty %@", notes);

    NSMutableDictionary* dict = [NSMutableDictionary new];

    UserClass* user = [UserClass getInstance];
    NSString *modifiedBy = [user getModifiedBy];
    [dict setValue:modifiedBy forKey:kmodifiedByKey];

    [dict setValue:user.employerID forKey:kemployerIdKey];

    [dict setValue:clockIn forKey:kClockInDateKey];
    if (nil != clockOut) {
        [dict setValue:clockOut forKey:kClockOutDateKey];
    }
    [dict setValue:testNotes forKey:kNotesKey];

    return dict;
}

#pragma mark - Modify Time Entry To Server - TimeSheetDetailViewController call this to update a time entry
- (void)modifyTimeEntryOnServer:(TimeEntry*)timeEntry clockIn:(NSDate*)clockIn clockOut:(NSDate*)clockOut notes:(NSString*)notes withCompletion:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);
    NSAssert(nil != timeEntry, @"timeEntry cannot be nil", msg);
    NSAssert(TRUE != [NSDate isNilOrNull:clockIn], @"clockIn cannot be nil %@", msg);
    NSString* testNotes = [NSString trim:notes];
    NSAssert(nil != testNotes, @"notes cannot be nil or empty %@", msg);
    
    if (self.isBusy) {
        completion(DATAMANAGER_BUSY, nil, nil, nil);
        return;
    }
    
    self.isBusy = TRUE;
    
    NSMutableDictionary* dict = [self prepareForUpdateSubmission:timeEntry clockIn:clockIn clockOut:clockOut notes:notes];
    
    NSError* error = nil;
    TimeEntry* result = [self updateTimeEntryDetail:timeEntry info:dict error:&error];
    if (nil != error) {
        self.isBusy = FALSE;
        completion(UNKNOWN_ERROR, nil, nil, error);
        return;
    }
    [dict setValue:result forKey:ktimeEntryKey];
    
#ifndef DISABLE_OFFLINE_MODE
    // **************************************************
    // TODO: Remove these lines once testing offline mode
    // **************************************************
    self.isBusy = FALSE;
    completion(SERVICE_UNAVAILABLE_ERROR, nil, dict, nil);
    return;
#else
    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
#ifndef RELEASE
        NSLog(@"Not reachable - %@", msg);
#endif
        self.isBusy = FALSE;
        completion(SERVICE_UNAVAILABLE_ERROR, nil, dict, nil);
        return;
    }
#endif
    
    // If the dbStatus is not dsPendingUpdate then the background process
    // needs to handle sending it to the server and not this one.
    DBStatus dbStatus = [result getDBStatus];
    if (dbStatus != dsPendingUpdate) {
        self.isBusy = FALSE;
        completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, dict, nil);
        return;
    }
    
    [self sendTimeEntryUpdateToServer:dict withCompletion:completion];
    
}

+ (NSString*)getBodyForTimeEntryUpdate:(NSDictionary*)dict {
    DEBUG_MSG
    NSAssert(nil != dict, @"dict cannot be nil %@", msg);
    UserClass* user = [UserClass getInstance];

    // timezoneId
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;

    // modified by
    NSString *modifiedBy = [NSString trim:[dict valueForKey:kmodifiedByKey]];

    NSDate* clockIn = [dict valueForKey:kClockInDateKey];
    NSAssert(TRUE != [NSDate isNilOrNull:clockIn], @"clockIn cannot be nil %@", msg);

    NSString* clockInStr = [clockIn toUTCDateTimeStringForURL];

    NSDate* clockOut = [dict valueForKey:kClockOutDateKey];

    NSString* clockOutStr = @"";
    if (![NSDate isNilOrNull:clockOut]) {
        clockOutStr = [clockOut toUTCDateTimeStringForURL];
    }

    NSString* notes = [NSString trim:[dict valueForKey:kNotesKey]];
    
    NSString* source = [NSString trim:[dict objectForKey:ksourceKey]];

    NSString* body = [NSString stringWithFormat:@"authToken=%@&description=%@&clockInISO8601Utc=%@&clockOutISO8601Utc=%@&timeZoneId=%@&modifiedBy=%@&source=%@",
                      [user.authToken URLUTF8Encode],
                      [notes URLUTF8Encode],
                      [clockInStr URLUTF8Encode],
                      [clockOutStr URLUTF8Encode],
                      [timeZoneId URLUTF8Encode],
                      [modifiedBy URLUTF8Encode],
                      [kIPHONE URLUTF8Encode]];
    return body;
}

#pragma mark - Update Time Entry to the server
- (void)sendTimeEntryUpdateToServer:(NSDictionary*)dict withCompletion:(ServerResponseCompletionBlock)completion {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != dict, @"dict cannot be nil @", msg);
        
        TimeEntry* timeEntry = [dict valueForKey:ktimeEntryKey];
        assert(nil != timeEntry);
        
        UserClass* user = [UserClass getInstance];
        
        IS_TIME_ENTRY_VALID()
        
        NSAssert(TRUE == bIsTimeEntryIDValid, @"timeEntry.timeEntryID is not valid for an update %@", msg);
        
        // sanity to prevent a zero from going to the server ever!
        assert(TRUE == bIsTimeEntryIDValid);
        
        NSString* httpPostString = [NSString stringWithFormat:@"%@timeEntry/modify/%@/%@", SERVER_URL, user.employerID, timeEntryID];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
        
        //Implement request_body for send request here authToken and clock DateTime set into the body.
        NSString* request_body = [DataManager getBodyForTimeEntryUpdate:dict];
        
        request.HTTPMethod = @"POST";
        request.HTTPBody = [request_body dataUsingEncoding:NSUTF8StringEncoding];
        
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = TIME_OUT; // 2 minutes
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
        
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (nil != error) {
#ifndef RELEASE
                NSLog(@"Error retrieved from request sent - %@ - %@", error.localizedDescription, msg);
#endif
                if (self.isBackgroundProcessing) {
                    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                    return;
                }
                MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                THREAD_BLOCK_END()
                return;
            }
            NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
            if (statusCode == SERVICE_UNAVAILABLE_ERROR){
                if (self.isBackgroundProcessing) {
                    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                    return;
                }
                MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                THREAD_BLOCK_END()
                return;
            }
            @autoreleasepool {
                [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                    NSMutableDictionary* __results = nil;
                    if (nil != results) {
                        __results = [NSMutableDictionary dictionaryWithDictionary:results];
                        [__results setObject:timeEntry forKey:ktimeEntryKey];
                    }
                    if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                        if (self.isBackgroundProcessing) {
                            completion(errorCode, resultMessage, __results, aError);
                            return;
                        }
                        MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(errorCode, resultMessage, __results, aError);
                        THREAD_BLOCK_END()
                        return;
                    }
                    NSError* __error = nil;
                    [timeEntry updateDBStatus:dsUpdated];
                    [timeEntry.dayHistoryItem.managedObjectContext save:&__error];
                    if (nil != __error) {
#ifndef RELEASE
                        NSLog(@"Error while saving timeEntry.dayHistoryItem.managedObjectContext save: - %@ - %@", __error.localizedDescription, msg);
#endif
                        if (self.isBackgroundProcessing) {
                            completion(UNKNOWN_ERROR, nil, __results, nil);
                            return;
                        }
                        MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(UNKNOWN_ERROR, nil, __results, nil);
                        THREAD_BLOCK_END()
                        return;
                    }
                    if (self.isBackgroundProcessing) {
                        completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, __results, nil);
                        return;
                    }
                    MAINTHREAD_BLOCK_START()
                    self.isBusy = FALSE;
                    completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, __results, nil);
                    THREAD_BLOCK_END()
                }];
            }
        }];
        [dataTask resume];
    }
}

- (NSMutableDictionary*)prepareForCreateSubmission:(NSDate*)clockIn clockOut:(NSDate*)clockOut notes:(NSString*)notes {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(TRUE != [NSDate isNilOrNull:clockIn], @"clockIn cannot be nil %@", msg);
    NSString* testNotes = [NSString trim:notes];
    if ([NSString isNilOrEmpty:testNotes]) {
        testNotes = kDefaultNotes;
    }

    NSMutableDictionary* dict = [NSMutableDictionary new];

    UserClass* user = [UserClass getInstance];

    NSString *modifiedBy = [user getModifiedBy];
    [dict setValue:modifiedBy forKey:kmodifiedByKey];

    [dict setValue:__employee.employeeID forKey:kEmployeeIDKey];

    [dict setValue:clockIn forKey:kClockInDateKey];
    if (nil != clockOut) {
        [dict setValue:clockOut forKey:kClockOutDateKey];
    } else {
        [dict setValue:clockIn forKey:kClockOutDateKey];
    }
    [dict setValue:testNotes forKey:kNotesKey];

    [dict setValue:kIPHONE forKey:ksourceKey];

    return dict;
}

#pragma mark - Send New Time Entry To Server - AddNewTimeEntryViewController calls this
- (void)sendNewTimeEntryToServer:(NSDate*)clockIn clockOut:(NSDate*)clockOut notes:(NSString*)notes withCompletion:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != completion, @"completion cannot be nil %@", msg);
    NSAssert(nil != clockIn, @"clockIn cannot be nil %@", msg);
    NSString* testNotes = [NSString trim:notes];
    if ([NSString isNilOrEmpty:testNotes]) {
        testNotes = kDefaultNotes;
    }

    if (self.isBusy) {
        completion(DATAMANAGER_BUSY, nil, nil, nil);
        return;
    }

    self.isBusy = TRUE;

    NSMutableDictionary* dict = [self prepareForCreateSubmission:clockIn clockOut:clockOut notes:notes];

    NSError* error = nil;
    TimeEntry* timeEntry = [__employee createNewTimeEntry:dict error:&error];
    if (nil != error) {
        self.isBusy = FALSE;
        completion(UNKNOWN_ERROR, nil, nil, error);
        return;
    }
    [dict setValue:timeEntry forKey:ktimeEntryKey];

#ifndef DISABLE_OFFLINE_MODE
    // **************************************************
    // TODO: Remove these lines once testing offline mode
    // **************************************************
    self.isBusy = FALSE;
    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
    return;
#else
    BOOL bIsReachable = [DataManager isReachable];
    if (!bIsReachable) {
#ifndef RELEASE
        NSLog(@"Not reachable - %@", msg);
#endif
        self.isBusy = FALSE;
        completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
        return;
    }
#endif

    [self sendCreateTimeEntryToServer:dict withCompletion:completion];
}

- (NSString*)getBodyForCreateNewTimeEntry:(NSDictionary*)dict {

    DEBUG_MSG
    Employee* __employee = self.employee;
    NSAssert(nil != __employee, @"employee cannot be nil %@", msg);
    NSAssert(nil != dict, @"dict cannot be nil %@", msg);
    UserClass* user = [UserClass getInstance];

    NSString* userEmployerID = [NSString trim:[user.employerID stringValue]];
    NSAssert(TRUE != [NSString isNilOrEmpty:userEmployerID], @"user.employerID cannot be nil %@", msg);

    NSString* employeeIDStr = [__employee.employeeID stringValue];

    // timezoneId
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *timeZoneId = timeZone.name;

    // modified by
    NSString *modifiedBy = [NSString trim:[dict valueForKey:kmodifiedByKey]];

    NSDate* clockIn = [dict valueForKey:kClockInDateKey];
    NSAssert(TRUE != [NSDate isNilOrNull:clockIn], @"clockIn cannot be nil %@", msg);

    NSString* clockInStr = [clockIn toUTCDateTimeStringForURL];

    NSDate* clockOut = [dict valueForKey:kClockOutDateKey];

    NSString* clockOutStr = @"";
    if (![NSDate isNilOrNull:clockOut]) {
        clockOutStr = [clockOut toUTCDateTimeStringForURL];
    }

    NSString* notes = [NSString trim:[dict valueForKey:kNotesKey]];

    NSString* source = [NSString trim:[dict valueForKey:ksourceKey]];
    if ([NSString isNilOrEmpty:source]) {
        source = kIPHONE;
    }


    NSString* body = [NSString stringWithFormat:@"employerId=%@&employeeId=%@&authToken=%@&clockInISO8601Utc=%@&clockOutISO8601Utc=%@&description=%@&modifiedBy=%@&timeZoneId=%@&source=%@",
                      [userEmployerID  URLUTF8Encode],
                      [employeeIDStr   URLUTF8Encode],
                      [user.authToken   URLUTF8Encode],
                      [clockInStr  URLUTF8Encode],
                      [clockOutStr  URLUTF8Encode],
                      [notes  URLUTF8Encode],
                      [modifiedBy  URLUTF8Encode],
                      [timeZoneId URLUTF8Encode],
                      [source URLUTF8Encode]];
    return body;
}

- (void)handleAlreadyClockedInOrOut:(NSInteger)errorCode timeEntry:(TimeEntry*)timeEntry withCompletion:(ServerResponseCompletionBlock)completion {
    DEBUG_MSG
    NSAssert(nil != timeEntry, @"timeEntry cannot be nil %@", msg);
    NSAssert(nil != completion, @"completion block cannot be nil %@", msg);
    // CLOCK IN ALREADY EXIST - Delete the TimeEntry
    if (errorCode == SERVICE_ERRORCODE_ALREADY_CLOCKED_IN) {
        if (self.isBackgroundProcessing) {
            NSError* error = nil;
            [self removeTimeEntry:timeEntry error:&error];
#ifndef RELEASE
            if (nil != error) {
                NSLog(@"error occured while deleting - %@", error);
            }
#endif
            completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
            return;
        }
        MAINTHREAD_BLOCK_START()
        NSError* error = nil;
        [self removeTimeEntry:timeEntry error:&error];
#ifndef RELEASE
        if (nil != error) {
            NSLog(@"error occured while deleting - %@", error);
        }
#endif
        self.isBusy = FALSE;
        [DataManager postDataManagerProcessCompleteNotification];
        completion(SERVICE_ERRORCODE_ALREADY_CLOCKED_IN, nil, nil, nil);
        THREAD_BLOCK_END()
        return;
        // CLOCK OUT ALREADY EXIST - Delete the ClockOut only
    } else if (errorCode == SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT) {
        if (self.isBackgroundProcessing) {
            NSError* error = nil;
            [self deleteClockOut:timeEntry error:&error];
            completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, nil, nil);
            return;
        }
        MAINTHREAD_BLOCK_START()
        NSError* error = nil;
        [self deleteClockOut:timeEntry error:&error];
        self.isBusy = FALSE;
        [DataManager postDataManagerProcessCompleteNotification];
        completion(SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT, nil, nil, nil);
        THREAD_BLOCK_END()
        return;
    }
}

- (BOOL)deleteClockOut:(TimeEntry*)timeEntry error:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != timeEntry, @"timeEntry cannot be nil %@", msg);
    NSAssert(nil != error, @"error canot be nil %@", msg);
    [timeEntry deleteClockOut];
    [timeEntry setDBStatus:dsUpdated]; // set DBStatus back to dsUpdated since it was deleted otherwise dsPendingInsert or dsPendingCreate would remain in TimeEntry but there would be no pending updates
    [timeEntry.managedObjectContext save:error];
#ifndef RELEASE
    if (nil != *error) {
        NSLog(@"error occured while deleting - %@", *error);
    }
#endif
    [_managedObjectContext save:error];
    if (nil != *error) {
#ifndef RELEASE
        NSLog(@"error occured while deleting - %@", *error);
#endif
        return FALSE;
    }
    return TRUE;
}

#pragma mark - Create new time entry to the server
- (void)sendCreateTimeEntryToServer:(NSDictionary*)dict withCompletion:(ServerResponseCompletionBlock)completion {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != dict, @"dict cannot be nil @", msg);
        
        __block TimeEntry* __timeEntry = [dict valueForKey:ktimeEntryKey];
        assert(nil != __timeEntry);
        
        NSString* httpPostString = [NSString stringWithFormat:@"%@timeEntry/create", SERVER_URL];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
        
        //Implement request_body for send request here authToken and clock DateTime set into the body.
        NSString* request_body = [self getBodyForCreateNewTimeEntry:dict];
        
        request.HTTPMethod = @"POST";
        request.HTTPBody = [request_body dataUsingEncoding:NSUTF8StringEncoding];
        
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = TIME_OUT; // 2 minutes
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
        
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (nil != error) {
#ifndef RELEASE
                NSLog(@"Error retrieved from request sent - %@ - %@", error.localizedDescription, msg);
#endif
                if (self.isBackgroundProcessing) {
                    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                    return;
                }
                MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                THREAD_BLOCK_END()
                return;
            }
            NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
            if (statusCode == SERVICE_UNAVAILABLE_ERROR){
                if (self.isBackgroundProcessing) {
                    completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                    return;
                }
                MAINTHREAD_BLOCK_START()
                self.isBusy = FALSE;
                completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, nil);
                THREAD_BLOCK_END()
                return;
            }
            @autoreleasepool {
                [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                    if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                        if (self.isBackgroundProcessing) {
                            completion(errorCode, resultMessage, results, aError);
                            return;
                        }
                        MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(errorCode, resultMessage, results, aError);
                        THREAD_BLOCK_END()
                        return;
                    }
                    if (errorCode == SERVICE_ERRORCODE_ALREADY_CLOCKED_IN || errorCode == SERVICE_ERRORCODE_ALREADY_CLOCKED_OUT) {
                        [self handleAlreadyClockedInOrOut:errorCode timeEntry:__timeEntry withCompletion:completion];
                        return;
                    }
                    NSDictionary *timeEntryRec = [results valueForKey:ktimeEntryKey];
                    if (nil == timeEntryRec) {
#ifndef RELEASE
                        NSLog(@"NO %@ returned from the server for the new Id that is needed for TimeEntry %@", ktimeEntryKey, msg);
#endif
                        if (self.isBackgroundProcessing) {
                            completion(UNKNOWN_ERROR, nil, nil, nil);
                        } else {
                            MAINTHREAD_BLOCK_START()
                            self.isBusy = FALSE;
                            completion(UNKNOWN_ERROR, nil, nil, nil);
                            THREAD_BLOCK_END()
                            return;
                        }
                    } else {
                        NSNumber *timeEntryId = [timeEntryRec valueForKey:kidKey];
                        __timeEntry.timeEntryID = timeEntryId;
                        NSError* __error = nil;
                        NSNumber* millescondsDuration = [timeEntryRec valueForKey:kmillisecondsDurationKey];
                        if (![NSNumber isNilOrNull:millescondsDuration]) {
                            __timeEntry.totalMilliseconds = millescondsDuration;
                        }
                        [__timeEntry updateDBStatus:dsUpdated];
                        [__timeEntry.dayHistoryItem.managedObjectContext save:&__error];
                        if (nil != __error) {
#ifndef RELEASE
                            NSLog(@"Error while saving timeEntry.dayHistoryItem.managedObjectContext save: - %@ - %@", __error.localizedDescription, msg);
#endif
                            if (self.isBackgroundProcessing) {
                                completion(UNKNOWN_ERROR, nil, nil, nil);
                                return;
                            }
                            MAINTHREAD_BLOCK_START()
                            self.isBusy = FALSE;
                            completion(UNKNOWN_ERROR, nil, nil, nil);
                            THREAD_BLOCK_END()
                            return;
                        }
                        if (self.isBackgroundProcessing) {
                            completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, results, nil);
                            return;
                        }
                        MAINTHREAD_BLOCK_START()
                        self.isBusy = FALSE;
                        completion(SERVICE_ERRORCODE_SUCCESSFUL, nil, results, nil);
                        THREAD_BLOCK_END()
                    }
                }];
            }
        }];
        [dataTask resume];
    }
}


- (void)releaseAll {
    [self stopTimer];
    while (self.isBusy) {
#ifndef RELEASE
        NSLog(@"NSDateManager isBusy...");
#endif
        sleep(1);
    }
    // destroy anything here
}

SINGLETON_IMPLEMENTATION_DEF(DataManager)

+ (BOOL)isClosed {
    BOOL bIsClosed = (nil == __sharedManager);
    return bIsClosed;
}

@end
