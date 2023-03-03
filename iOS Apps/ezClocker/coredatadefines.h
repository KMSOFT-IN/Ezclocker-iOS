//
//  coredatadefines.h
//  ezClocker
//
//  Created by Kenneth Lewis on 1/8/16.
//  Copyright © 2016 ezNova Technologies LLC. All rights reserved.
//

#ifndef coredatadefines_h
#define coredatadefines_h

#define kNotesKey @"notes"
#define kClockInDateKey @"clockInDate"
#define kClockOutDateKey @"clockOutDate"
#define kJobCode @"jobCodeId"
#define kTimeEntryType @"timeEntryType"
#define kPartialTimeEntry @"partialTimeEntry"


#define kclockInGpsDataStatusKey @"clockInGpsDataStatus"
#define kclockOutGpsDataStatusKey @"clockOutGpsDataStatus"
#define kclockInIso8601Key @"clockInIso8601"
#define kclockOutIso8601Key @"clockOutIso8601"
#define klocationsKey @"locations"
#define kgpsLatitudeKey @"gpsLatitude"
#define kgpsLongitudeKey @"gpsLongitude"
#define kgpsAccuracyKey @"gpsAccuracy"
#define kclockInLocationKey @"clockInLocation"
#define ktotalMillisecondsKey @"totalMilliseconds"

#define ktimeEntryKey @"timeEntry"
#define kidKey @"id"
#define kmillisecondsDurationKey @"millisecondsDuration" // field returned when clocking in/out

#define kactiveTimeEntryIDKey @"activeTimeEntryID"
#define kTimeEntryIDKey @"timeEntryID"
#define kclockModeKey @"clockMode"
#define kcurrentDateTimeKey @"currentDateTime"

#define kemployerIdKey @"employerId"
#define kgpsDataStatusKey @"gpsDataStatus"
#define kmodifiedByKey @"modifiedBy"
#define klatitudeKey @"latitude"
#define klongitudeKey @"longitude"
#define klocTimeKey @"locTime"
#define koverrideLocationCheckKey @"overrideLocationCheck"
#define kspeedKey @"speed"
#define kaltitudeKey @"altitude"
#define kaccuracyKey @"accuracy"
#define kbearingKey @"bearing"
#define ksourceKey @"source"

#define kclockInISO8601Utc @"clockInISO8601Utc"
#define kclockOutISO8601Utc @"clockOutISO8601Utc"

#define kACTIVE @"ACTIVE"
#define kDISABLED @"DISABLED"

#define kBreakTimeEntryType @"BREAK"
#define kNormalTimeEntryType @"NORMAL"


#ifdef IPAD_VERSION
#define kIPHONE @"IPAD"
#elif defined PERSONAL_VERSION
#define kIPHONE @"IPHONE-PERSONAL"
#else
#define kIPHONE @"IPHONE"
#endif

#define kLastTimeEntryForTodayKey @"lastTimeEntryForToday"

typedef enum __DBStatus {
    dsUpdated = 0,       // Is updated from a web standpoint
    dsPendingDelete = 1, // Pending Delete from the TimeSheetDetailViewController
    dsPendingCreate = 2, // Pending Create from the AddTimeEntryViewController
    dsPendingInsert = 3, // Pending Insert from the EmployeeProfileViewController
    dsPendingUpdate = 4, // Pending Update hasn't been updated from a web standpoint
} DBStatus;

#define REMOVE_ENTITY_FROM_LIST(LIST_PROPERTY, ENTITY_VAR) \
NSMutableOrderedSet* tempSet = [self.LIST_PROPERTY mutableCopy]; \
[tempSet removeObject:ENTITY_VAR]; \
self.LIST_PROPERTY = tempSet; \
[self.managedObjectContext deleteObject:ENTITY_VAR]; \
[self.managedObjectContext save:error]; \
if (nil != *error) { \
    return FALSE; \
} \
return TRUE;

#endif /* coredatadefines_h */
