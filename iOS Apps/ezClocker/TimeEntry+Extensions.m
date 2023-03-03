//
//  TimeEntry+Extensions.m
//  ezClocker
//
//  Created by Kenneth Lewis on 12/15/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "TimeEntry+Extensions.h"
#import "ClockInfo.h"
#import "ClockInfo+Extensions.h"
#import "NSManagedObjectContext+Extensions.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"
#import "debugdefines.h"
#import "TimeEntry+CoreDataProperties.h"
#import "DayHistoryItem.h"
#import "NSNumber+Extensions.h"
#import "NSDictionary+Extensions.h"

@implementation TimeEntry (TimeEntryExtensions)

- (void)setValuesForKeysWithDictionary:(NSDictionary<NSString *,id> *)keyedValues
{
    NSAssert(nil != keyedValues, @"Error initializing Managed Object TimeEntry");
}

- (void)updateClockInClockOut:(NSDate *)clockInDate clockOut:(NSDate *)clockOutDate {
    __block ClockInfo* clockInfo;
    // Clock In Date
    if (clockInDate) {
        if (nil == self.clockIn) {
            [self.managedObjectContext performBlockAndWait:^{
                clockInfo = [self.managedObjectContext insertNewEntityForClass:[ClockInfo class]];
            }];
            self.clockIn = clockInfo;
        } else {
            clockInfo = self.clockIn;
        }
        clockInfo.dateTimeEntry = clockInDate;
    } else {
        // Clock In Info
        if (self.clockIn) {
            __block ClockInfo* info = self.clockIn;
            self.clockIn = nil;
            [self.managedObjectContext performBlockAndWait:^{
                [self.managedObjectContext deleteObject:info];
            }];
        }
    }

    // Clock Out Date
    if (clockOutDate) {
        if (nil == self.clockOut) {
            [self.managedObjectContext performBlockAndWait:^{
                clockInfo = [self.managedObjectContext insertNewEntityForClass:[ClockInfo class]];
            }];
            self.clockOut = clockInfo;
        } else {
            clockInfo = self.clockOut;
        }
        clockInfo.dateTimeEntry = clockOutDate;
    } else {
        [self deleteClockOut];
    }
}

- (BOOL)saveFromTimeEntry:(TimeEntry*)timeEntry error:(NSError*__autoreleasing*)error {
    DEBUG_MSG
    NSAssert(nil != timeEntry, @"timeEntry cannot be nil %@", msg);
    NSAssert(nil != error, @"error cannot be nil %@", msg);
    NSAssert(self != timeEntry, @"timeEntry cannot be the same as self - %@", msg);
    self.notes = timeEntry.notes;
    self.timeEntryType = timeEntry.timeEntryType;
    self.jobCodeId = timeEntry.jobCodeId;
    self.timeEntryID = timeEntry.timeEntryID;
    self.totalMilliseconds = timeEntry.totalMilliseconds;
    self.status = timeEntry.status;
    __block ClockInfo* clockInfo;
    if (timeEntry.clockIn) {
        if (nil == self.clockIn) {
            [self.managedObjectContext performBlockAndWait:^{
                clockInfo = [self.managedObjectContext insertNewEntityForClass:[ClockInfo class]];
            }];
            self.clockIn = clockInfo;
        } else {
            clockInfo = self.clockIn;
        }
        [clockInfo assign:timeEntry.clockIn];
    } else {
#ifndef RELEASE
        NSLog(@"WARNING! No clockIn provide by the timeEntry passed in %@", msg);
#endif
    }
    if (timeEntry.clockOut) {
        if (nil == self.clockOut) {
            [self.managedObjectContext performBlockAndWait:^{
                clockInfo = [self.managedObjectContext insertNewEntityForClass:[ClockInfo class]];
            }];
            self.clockOut = clockInfo;
        } else {
            clockInfo = self.clockOut;
        }
        [clockInfo assign:timeEntry.clockOut];
    } else {
        [self deleteClockOut];
    }
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext save:error];
    }];
    if (nil != *error) {
#ifndef RELEASE
        NSLog(@"Error saving timeEntry managedObjectContext - %@ %@", (*error).localizedDescription, msg);
#endif
        return FALSE;
    }
    return TRUE;
}

- (void)updateTimeEntryForMilliseconds {
    @synchronized(self) {
        double milliseconds = [self calculateTotalMilliseconds];
        if (milliseconds > 0) {
            self.totalMilliseconds = [NSNumber numberWithDouble:milliseconds];
        }
    }
}

- (void)deleteClockOut {
    if (self.clockOut) { // no date delete clockOut
        __block ClockInfo* info = self.clockOut;
        self.clockOut = nil;
        [self.managedObjectContext performBlockAndWait:^{
            [self.managedObjectContext deleteObject:info];
        }];
    }
}

- (ClockInfo*)insertNewClockInfo {
    @synchronized(self) {
        __block ClockInfo* result;
        if ([NSThread isMainThread]) {
            [self.managedObjectContext performBlockAndWait:^{
                result = [self.managedObjectContext insertNewEntityForClass:[ClockInfo class]];
            }];
        }
        else {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.managedObjectContext performBlockAndWait:^{
                    result = [self.managedObjectContext insertNewEntityForClass:[ClockInfo class]];
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

- (BOOL)updateTimeEntryFromDict:(NSDictionary*)dict wasModified:(BOOL*)bModified error:(NSError* __autoreleasing*)error {
    @synchronized (self) {
        DEBUG_MSG

        NSAssert(nil != error, @"error cannot be nil in %@", msg);
        NSAssert(nil != dict, @"dict cannot be nil in %@", msg);
        NSAssert(nil != bModified, @"bModified cannot be nil %@", msg);

        *bModified = FALSE;

        NSString* timeEntryNotes = [NSString trim:[dict objectForKey:kNotesKey]];
        if (![NSString isEquals:self.notes dest:timeEntryNotes]) {
            self.notes = timeEntryNotes;
            *bModified = TRUE;
        }
        NSString* timeEntryType = [NSString trim:[dict objectForKey:kTimeEntryType]];
        if (![NSString isEquals:self.timeEntryType dest:timeEntryType]) {
            self.timeEntryType = timeEntryType;
            *bModified = TRUE;
        }
        
        NSNumber* _jobCodeId = nil;
        NSArray *dataTags = [dict objectForKey:@"dataTags"];
        //we can have multiple data tags associated with a time entry all we want is the job code here and we should only have one job code per time entry
        if ([dataTags count] > 0)
        {
            NSString *jobCodeType;
            for (NSDictionary *dataTag in dataTags)
            {
                jobCodeType = [dataTag objectForKey:@"ezDataTagType"];//dataTagType
                if ([jobCodeType isEqual:@"JOB_CODE"])
                     _jobCodeId = [dataTag valueForKey: @"id"];
            }
            
        }
        if ((![NSNumber isNilOrNull:_jobCodeId])  && ![NSNumber isEquals:self.jobCodeId dest:_jobCodeId])
        {
            self.jobCodeId = _jobCodeId;
            *bModified = TRUE;
        }

        NSString *clockInGpsDataStatus = [NSString trim:[dict objectForKey:kclockInGpsDataStatusKey]];

        // *****************************
        // Insert ClockInfo for Clock In
        // *****************************
        ClockInfo* clockInfo;
        if (nil == self.clockIn) {
            clockInfo = [self insertNewClockInfo];
            NSAssert(nil != clockInfo, @"Error inserting new ClockInfo for TimeEntry %@", msg);
            *bModified = TRUE;
            self.clockIn = clockInfo;
        } else {
            clockInfo = self.clockIn;
        }
        if (![NSString isEquals:clockInfo.gpsDataStatus dest:clockInGpsDataStatus]) {
            clockInfo.gpsDataStatus = clockInGpsDataStatus;
            *bModified = TRUE;
        }

        NSString *clockInTimeStr = [NSString trim:[dict objectForKey:kclockInIso8601Key]];

        // Clock out NSDate
        NSDate* clockInDate = [clockInTimeStr toUTCDateTime];

        //  clockoutDate = [timeEntryRec valueForKey:@"clockOutDate"];
        NSString *clockOutTimeStr = [NSString trim:[dict objectForKey:kclockOutIso8601Key]];

        // Clock Out NSDate
        NSDate* clockOutDate = [clockOutTimeStr toUTCDateTime];

        clockOutTimeStr = [clockOutDate toDefaultTimeString]; // h:mm:ss a

        //get Location
        NSArray *locationsArray = [dict objectForKey:klocationsKey];
        //clear out values
        NSString* clockInLat = @"";
        NSString* clockInLon = @"";
        NSString* clockInAcc = @"";
        NSString* clockOutLat = @"";
        NSString* clockOutLon = @"";
        NSString* clockOutAcc = @"";
        NSString* latitude = nil;
        NSString* longitude = nil;
        NSString* accuracy = nil;
        NSNumber* num;
        if (locationsArray && locationsArray.count > 0) {
            for (NSDictionary *loc in locationsArray) {

                latitude = [NSString trim:[loc objectForKey:kgpsLatitudeKey]];
                longitude = [NSString trim:[loc objectForKey:kgpsLongitudeKey]];
                accuracy = [NSString trim:[loc objectForKey:kgpsAccuracyKey]];
                
                num = [NSNumber safeNum:[loc objectForKey:kclockInLocationKey]];
                if (num && [num boolValue]){
                    clockInLat = latitude;
                    clockInLon = longitude;
                    clockInAcc = accuracy;
                } else {
                    clockOutLat = latitude;
                    clockOutLon = longitude;
                    clockOutAcc = accuracy;
                }
            }
        }


        
         bool isActiveClockIn = [[dict valueForKey:@"isActiveClockIn"] boolValue];
        if (isActiveClockIn)
            clockOutTimeStr = @"";
        else
        {
            bool isActiveBreakIn = [[dict valueForKey:@"isActiveBreak"] boolValue];
            if (isActiveBreakIn)
                clockOutTimeStr = @"";
        }
        //took this out because now we have the active clock in variable to tell us this information
        //if the clock out is equal to the clock in then there is no clock out
    //    NSString* testClockOut = [NSString trim:[dict objectForKey:kclockOutIso8601Key]];
    //    NSString* testClockIn = [NSString trim:[dict objectForKey:kclockInIso8601Key]];
    //    if ([testClockOut isEqualToString:testClockIn]) {
    //        clockOutTimeStr = @"";
    //    }

        // Clock In Information
        NSNumber* __latitude = [NSString isNilOrEmpty:clockInLat] ? nil : [NSNumber numberWithDouble:[clockInLat doubleValue]];
        if (__latitude && ![NSNumber isEquals:clockInfo.latitude dest:__latitude]) {
            clockInfo.latitude = __latitude;
            *bModified = TRUE;
        }
        
        NSNumber* __longitude = [NSString isNilOrEmpty:clockInLon] ? nil : [NSNumber numberWithDouble:[clockInLon doubleValue]];
        if (__longitude && ![NSNumber isEquals:clockInfo.longitude dest:__longitude]) {
            clockInfo.longitude = __longitude;
            *bModified = TRUE;
        }
        NSNumber* __accuracy = [NSString isNilOrEmpty:clockInAcc] ? nil : [NSNumber numberWithDouble:[clockInAcc doubleValue]];
        if (__accuracy && ![NSNumber isEquals:clockInfo.accuracy dest:__accuracy]) {
            clockInfo.accuracy = __accuracy;
            *bModified = TRUE;
        }
        if (![NSDate isEquals:clockInfo.dateTimeEntry dest:clockInDate]) {
            clockInfo.dateTimeEntry = clockInDate;
            *bModified = TRUE;
        }

        // Clock Out Information
        if ([clockOutTimeStr length] > 0)
        {
            if (nil == self.clockOut) {
                clockInfo = [self insertNewClockInfo];
                NSAssert(nil != clockInfo, @"Error inserting new ClockInfo for TimeEntry %@", msg);
                *bModified = TRUE;
                self.clockOut = clockInfo;
            } else {
                clockInfo = self.clockOut;
            }

            NSString *clockOutGpsDataStatus = [NSString trim:[dict objectForKey:kclockOutGpsDataStatusKey]];
            if (![NSString isEquals:clockInfo.gpsDataStatus dest:clockOutGpsDataStatus]) {
                clockInfo.gpsDataStatus = clockOutGpsDataStatus;
                *bModified = TRUE;
            }
            NSNumber* __latitude = [NSString isNilOrEmpty:clockOutLat] ? nil : [NSNumber numberWithDouble:[clockOutLat doubleValue]];
            if (__latitude && ![NSNumber isEquals:clockInfo.latitude dest:__latitude]) {
                clockInfo.latitude = __latitude;
                *bModified = TRUE;
            }
            NSNumber* __longitude = [NSString isNilOrEmpty:clockOutLon] ? nil : [NSNumber numberWithDouble:[clockOutLon doubleValue]];
            if (__longitude && ![NSNumber isEquals:clockInfo.longitude dest:__longitude]) {
                clockInfo.longitude = __longitude;
                *bModified = TRUE;
            }

            NSNumber* __accuracy = [NSString isNilOrEmpty:clockOutAcc] ? nil : [NSNumber numberWithDouble:[clockOutAcc doubleValue]];
            if (__accuracy && ![NSNumber isEquals:clockInfo.accuracy dest:__accuracy]) {
                clockInfo.accuracy = __accuracy;
                *bModified = TRUE;
            }

            if (![NSDate isEquals:clockInfo.dateTimeEntry dest:clockOutDate]) {
                clockInfo.dateTimeEntry = clockOutDate;
                *bModified = TRUE;
            }
        } else if (self.clockOut) {
            [self deleteClockOut];
            *bModified = TRUE;
        }

        NSNumber* totalMilleseconds = [NSNumber safeNum:[dict objectForKey:ktotalMillisecondsKey]];
        if (![NSNumber isNilOrNull:totalMilleseconds] && ![NSNumber isEquals:self.totalMilliseconds dest:totalMilleseconds]) {
            self.totalMilliseconds = totalMilleseconds;
            *bModified = TRUE;
        } else { // Clock-In Clock Out uses millisecondsDuration not totalMilliseconds
            totalMilleseconds = [NSNumber safeNum:[dict objectForKey:kmillisecondsDurationKey]];
            if (![NSNumber isNilOrNull:totalMilleseconds] && ![NSNumber isEquals:self.totalMilliseconds dest:totalMilleseconds]) {
                self.totalMilliseconds = totalMilleseconds;
                *bModified = TRUE;
            }
        };

        if (*bModified) {
            __block BOOL shouldReturnFALSE;
            [self.managedObjectContext performBlockAndWait:^{
                [self.managedObjectContext save:error];
                if (nil != *error) {
                    shouldReturnFALSE = FALSE;
                    return;
                }
                [self.dayHistoryItem.managedObjectContext save:error];
            }];
            if (shouldReturnFALSE) {
                return FALSE;
            }
            if (nil != *error) {
                return FALSE;
            }
        }

        return TRUE;
    }
}

- (double)calculateTotalMilliseconds {
    double milleseconds = 0;
    NSDate* clockInDate;
    NSDate* clockOutDate;
    if (self.clockIn && self.clockOut) {
        clockInDate = self.clockIn.dateTimeEntry;
        clockOutDate = self.clockOut.dateTimeEntry;
        milleseconds = [clockOutDate timeIntervalSinceDate:clockInDate];
    }
    return milleseconds * 1000;
}

- (void)updateTimeEntryFromDict:(NSDictionary *)dict clockMode:(ClockMode)clockMode {
    @synchronized(self) {
        DEBUG_MSG
        NSAssert(nil != dict, @"dict cannot be nil %@", msg);
        ClockInfo* clockInfo = nil;
//switch (clockMode) {
            if ((clockMode == ClockModeIn) || (clockMode == BreakModeIn)) {
                if (nil == self.clockIn) {
                    self.clockIn = [self insertNewClockInfo];
                }
                clockInfo = self.clockIn;
  //              break;
            }
//            case ClockModeOut: {
            else if ((clockMode == ClockModeOut) || (clockMode == BreakModeOut)){
                if (nil == self.clockOut) {
                    self.clockOut = [self insertNewClockInfo];
                }
                clockInfo = self.clockOut;
  //              break;
            }
  //          default:
  //              break;
  //      }
        NSAssert(nil != clockInfo, @"clockInfo cannot be nil %@", msg);
        [clockInfo updateFromDict:dict];
        NSNumber* __jobCodeId = [dict valueForKey:kJobCode];
        if (![NSNumber isNilOrNull:__jobCodeId])
            self.jobCodeId = __jobCodeId;
        [self updateTimeEntryForMilliseconds];
    }
}

- (NSMutableDictionary*)saveToDictForSubmissionForClockMode:(ClockMode)clockInOrOut {
    NSMutableDictionary* dict = [NSMutableDictionary new];

    [dict setValue:[NSNumber numberWithInt:(int)clockInOrOut] forKey:kclockModeKey];
    ClockInfo* clockInfo;
    switch (clockInOrOut) {
        case ClockModeIn:
            clockInfo = self.clockIn;
            break;
        case ClockModeOut:
            clockInfo = self.clockOut;
            break;
        default:
            break;
    }
    if (nil == clockInfo) {
        return nil;
    }
    [clockInfo saveToDictForClockSubmission:dict isClockIn:(clockInOrOut == ClockModeIn)];
    return dict;
}

- (void)saveToDictForCreateSubmission:(NSMutableDictionary *)dict {
    DEBUG_MSG
    NSAssert(nil != dict, @"dict cannot be nil %@", msg);

    if (![NSString isNilOrEmpty:self.notes]) {
        [dict setValue:self.notes forKey:kNotesKey];
    }
    
    if (![NSString isNilOrEmpty:self.timeEntryType]) {
        [dict setValue:self.timeEntryType forKey:kTimeEntryType];
    }
    
    if (![NSNumber isNilOrNull:self.jobCodeId] && ([self.jobCodeId intValue] > 0))
        [dict setValue:self.jobCodeId forKey:kJobCode];

    if (self.clockIn) {
        [self.clockIn saveToDictForCreateSubmission:dict isClockIn:TRUE];
    }
    if (self.clockOut) {
        [self.clockOut saveToDictForCreateSubmission:dict isClockIn:FALSE];
    }
}

- (void)saveToDictForUpdateSubmission:(NSMutableDictionary*)dict {
    DEBUG_MSG
    NSAssert(nil != dict, @"dict cannot be nil %@", msg);

    if (![NSString isNilOrEmpty:self.notes]) {
        [dict setValue:self.notes forKey:kNotesKey];
    }
    
    if (![NSString isNilOrEmpty:self.timeEntryType]) {
        [dict setValue:self.timeEntryType forKey:kTimeEntryType];
    }
    
    if (![NSNumber isNilOrNull:self.jobCodeId] && ([self.jobCodeId intValue] > 0))
         [dict setValue:self.jobCodeId forKey:kJobCode];

    if (self.clockIn) {
        [self.clockIn saveToDictForCreateSubmission:dict isClockIn:TRUE];

    }
    if (self.clockOut) {
        [self.clockOut saveToDictForCreateSubmission:dict isClockIn:FALSE];
    }
}

- (DBStatus)getDBStatus {
    @synchronized(self) {
        NSNumber* numStatus = self.status;
        if ([NSNumber isNilOrNull:numStatus]) {
            return dsUpdated;
        }
        NSInteger value = [numStatus integerValue];
        return (DBStatus)value;
    }
}

- (void)setDBStatus:(DBStatus)value {
    @synchronized(self) {
        NSNumber* num = [NSNumber numberWithInt:(int)value];
        self.status = num;
    }
}

/*dsUpdated = 0,       // Is updated from a web standpoint
 dsPendingDelete = 1, // Pending Delete from the TimeSheetDetailViewController
 dsPendingCreate = 2, // Pending Create from the AddTimeEntryViewController
 dsPendingInsert = 3, // Pending Insert from the EmployeeProfileViewController
 dsPendingUpdate = 4, // Pending Update hasn't been updated from a web standpoint*/

- (NSString*)getDBStatusString {
    DBStatus __status = [self getDBStatus];
    switch(__status) {
        case dsPendingInsert:
            return @"dsPendingInsert";
        case dsPendingCreate:
            return @"dsPendingCreate";
        case dsPendingUpdate:
            return @"dsPendingUpdate";
        case dsPendingDelete:
            return @"dsPendingDelete";
        default:
            return @"dsUpdated";
    }
}

- (BOOL)hasPendingUpdates {
    @synchronized(self) {
        DBStatus __status = [self getDBStatus];
        if (__status != dsUpdated) {
            return TRUE;
        }
        if (self.clockIn) {
            __status = [self.clockIn getDBStatus];
            if (__status != dsUpdated) {
                return TRUE;
            }
        }
        if (self.clockOut) {
            __status = [self.clockOut getDBStatus];
            if (__status != dsUpdated) {
                return TRUE;
            }
        }
        return FALSE;
    }
}

- (BOOL)isNeedingSubmission {
    @synchronized(self) {
        // entryID is not valid meaning it's null or zero (default) then
        // it hasn't been submitted to the server
        BOOL bIsTimeEntryIDValid = [self isTimeEntryIDValid];
        BOOL bHasPendingUpdates = [self hasPendingUpdates];
        if (!bIsTimeEntryIDValid || bHasPendingUpdates) {
            return TRUE;
        }
        return FALSE;
    }
}

- (void)updateDBStatusAndDBStatusForClockMode:(DBStatus)aStatus clockMode:(ClockMode)clockMode {
    @synchronized(self) {
 //       switch (clockMode) {
 //           case ClockModeIn: {
        if ((ClockModeIn == clockMode) || (BreakModeIn == clockMode)){
                if (self.clockIn) {
                    [self.clockIn setDBStatus:aStatus];
                }
                // Only set status if clockOut doesn't exist or
                // it's the same as the status coming in
                if (self.clockOut) {
                    if ([self.clockOut getDBStatus] == aStatus) {
                        [self setDBStatus:aStatus];
                    }
                } else {
                    [self setDBStatus:aStatus];
                }
   //             break;
            }
         //   case ClockModeOut: {
        if ((ClockModeOut == clockMode) || (BreakModeOut == clockMode)){
                if (self.clockOut) {
                    [self.clockOut setDBStatus:aStatus];
                }
                // Only set status if clockIn doesn't exist or
                // it's the same as the status coming in
                if (self.clockIn) {
                    if ([self.clockIn getDBStatus] == aStatus) {
                        [self setDBStatus:aStatus];
                    }
                } else {
                    [self setDBStatus:aStatus];
                }
 //               break;
            }
  //          default:
  //              break;
      //  }
    }
}

- (void)updateDBStatus:(DBStatus)aStatus {
    @synchronized(self) {
        [self setDBStatus:aStatus];
        if (self.clockIn) {
            [self.clockIn setDBStatus:aStatus];
        }
        if (self.clockOut) {
            [self.clockOut setDBStatus:aStatus];
        }
    }
}

- (BOOL)isTimeEntryIDValid {
    NSNumber* __timeEntryID = self.timeEntryID;
    BOOL bIsTimeEntryIDValid = ![NSNumber isNilOrNull:__timeEntryID] && ([__timeEntryID integerValue] > 0);
    return bIsTimeEntryIDValid;
}

@end
