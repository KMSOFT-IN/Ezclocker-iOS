//
//  DataManager.h
//  ezClocker
//
//  Created by Kenneth Lewis on 12/14/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singletondef.h"
#import "Employee.h"
#import "TimeEntry.h"
#import "DayHistoryItem.h"
#import "completionblockdefines.h"
#import "CommonLib.h"
#import <CoreLocation/CoreLocation.h>

#define kStartDateKey @"startDate"
#define kEndDateKey @"endDate"
#define kDefaultNotes @""
//#define kDefaultNotes @"new time entry"

#define kDataManagerProcessCompleteNotification @"DataManagerProcessCompleteNotification"
#define kCheckClockStatusNotification @"CheckClockStatusNotification"
#define kForceSyncCompleteInAppWillEnterForegroundNotification @"ForceSyncCompleteInAppWillEnterForegroundNotification"
#define kDataWasModifiedNotification @"DataWasModifiedNotification"


#define DATA_MANAGER_DOMAIN @"DATA_MANAGER"

//#define kErrBusyCode -1001
//#define kErrEmployeeNotSet -1002

//#define DATAMANAGER_BUSY 123

#define UPDATE_IN_SECONDS 60*30

typedef enum __TimeSheetError {
    tseAlreadySubscribed,
    tseConnectionFailed,
    tseFetchError,
    tseErrorDeletingDayHistory,
    tseSuccessful,
    tseSuccessfulNoData
} TimeSheetError;

@interface TimeEntryInfo : NSObject {

}

- (instancetype)initWithTimeEntry:(TimeEntry*)timeEntry clockMode:(ClockMode)clockMode;

@property (nonatomic, retain, readonly) TimeEntry* timeEntry;
@property (nonatomic, assign, readonly) ClockMode clockMode;


@end

@interface DayHistoryItemInfo : NSObject {

}

@property (nonatomic, retain, readonly) DayHistoryItem* historyItem;
@property (nonatomic, copy, readonly) NSString* displayDateStr;
//display the time in hrs mins
@property (nonatomic, copy, readonly) NSString* displayTimeLongStr;
//display the time in h and m because we have no space
@property (nonatomic, copy, readonly) NSString* displayTimeShortStr;
@property (nonatomic) float dayTotalsInDecimal;
@property (nonatomic) double dayTotalPay;
@property (nonatomic, retain, readonly) NSArray* timeEntries;

@end

typedef void (^TimeSheetCompletionBlock)(TimeSheetError result, Employee* employee, NSError* error);

@interface DataManager : NSObject {

}

@property (atomic, retain, readonly) NSArray* timeHistory;
@property (nonatomic, assign, readonly) double totalDuration;
@property (nonatomic, assign, readonly) double totalPay;
@property (nonatomic, assign, readonly) BOOL isBusy;
@property (nonatomic, assign, readonly) BOOL isBackgroundProcessing;
@property (nonatomic, retain, readonly) Employee* employee;

// 1.  This method calls on the UserClass.checkPayrollStartDate: in order to get the date range.
// 2.  It then calls on the loadTimeSheetsForEmployee: to make sure the timesheet information has been loaded for current employee.
// 3.  It does not refresh the data from the server unless there is no data to begin with.

- (void)checkAndLoadEmployeeInfo:(ServerResponseCompletionBlock)completion;

// Main method called by the TimeSheetMasterViewController
- (void)loadTimesheetsForEmployee:(NSDictionary*)info refresh:(BOOL)bRefresh withCompletion:(ServerResponseCompletionBlock)completion;

- (void)removeTimeEntryFromServer:(TimeEntry*)timeEntry withCompletion:(ServerResponseCompletionBlock)completion;
- (void)sendNewTimeEntryToServer:(NSDate*)clockIn clockOut:(NSDate*)clockOut notes:(NSString*)notes jobCodeId: (NSNumber *)jobCodeId withCompletion:(ServerResponseCompletionBlock)completion;
- (void)modifyTimeEntryOnServer:(TimeEntry*)timeEntry clockIn:(NSDate*)clockIn clockOut:(NSDate*)clockOut notes:(NSString*)notes jobCodeId: selectedJobCodeId partialTimeEntry: partialTimeEntryVal withCompletion:(ServerResponseCompletionBlock)completion;

- (TimeEntry*)addOrUpdateTimeEntry:(NSDictionary*)dict error:(NSError *__autoreleasing *)error;

- (TimeEntry*)getTimeEntryByID:(NSNumber*)timeEntryID error:(NSError*__autoreleasing*)error;
- (TimeEntry*)fetchMostRecentTimeEntry:(NSError*__autoreleasing*)error;
- (TimeEntry*)fetchMostRecentNormalTimeEntry:(NSError*__autoreleasing*)error;

- (BOOL)clearAllData:(NSError *__autoreleasing *)error;

- (void)saveData;

- (BOOL)deleteAllRecordsForEmployee:(NSError *__autoreleasing *)error;

+ (NSString *) formatInterval: (NSTimeInterval) interval;

+ (float) formatIntervalToDecimal: (NSTimeInterval) interval;


- (void)clockInOrClockOut:(ClockMode)clockMode
        timeEntryObjectID:(NSManagedObjectID*)timeEntryObjectID
              currentDate:(NSDate*)currentDateTime
                jobCodeId:(NSNumber*) selectedJobCodeId
                 location:(CLLocation*)loc
                   source:(NSString*)source
              locOverride:(BOOL)bOverrideLocationCheck
           withCompletion:(ServerResponseCompletionBlock)completion;

- (void)checkClockStatus:(NSNumber*)employeeId withCompletion:(ServerResponseCompletionBlock)completion;
- (void)callGetTimeEntryByIDWebService:(NSNumber *)timeEntryID withCompletion:(ServerResponseCompletionBlock)completion;


- (NSInteger)doesCurrentEmployeeNeedingSubmission:(NSError*__autoreleasing*)error;
- (NSInteger)anyEmployeesNeedingSubmission:(NSError*__autoreleasing*)error;
- (NSManagedObject*)existingObjectByID:(NSManagedObjectID*)objectID error:(NSError*__autoreleasing*)error;

- (TimeEntry*)fetchTimeEntryByID:(NSNumber*)timeEntryID error:(NSError*__autoreleasing*)error;

- (void)stopTimer;
- (void)startUpdateTimer;
- (void)forceSyncWithCompletion:(UIBackgroundFetchResultCompletionBlock)completionBlock;

+ (void)postDataWasModifiedNotification;


+ (BOOL)isClosed;

SINGLETON_HEADER_DEF(DataManager)

@end
