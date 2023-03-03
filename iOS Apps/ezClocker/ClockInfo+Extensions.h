//
//  ClockInfo+Extensions.h
//  ezClocker
//
//  Created by Kenneth Lewis on 12/14/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "ClockInfo.h"
#import <CoreLocation/CoreLocation.h>
#import "coredatadefines.h"

@interface ClockInfo (CoreDataExtensions)

- (CLLocationCoordinate2D)location;
- (void)updateFromDict:(NSDictionary*)dict;

- (void)assign:(ClockInfo*)clockInfo;

- (void)saveToDictForClockSubmission:(NSMutableDictionary*)dict isClockIn:(BOOL)bIsClockIn;
- (void)saveToDictForCreateSubmission:(NSMutableDictionary*)dict isClockIn:(BOOL)bIsClockIn;

- (DBStatus)getDBStatus;
- (void)setDBStatus:(DBStatus)value;

- (NSString*)getDBStatusString;

- (BOOL)isNeedingSubmission;

@end
