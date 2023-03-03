//
//  ClockWebServices.h
//  ezClocker
//
//  Created by Raya Khashab on 11/5/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "CommonLib.h"
#import <CoreData/CoreData.h>


@class ClockWebServices;

@protocol clockWebServicesDelegate
- (void)clockServiceCallDidFinish:(ClockWebServices *)controller timeEntryRec:(NSDictionary*)timeEntryRec ErrorCode: (int) errorValue resultMessage: (NSString *) resultMessage ClockMode: (ClockMode) clockMode;
@end

@interface ClockWebServices : NSObject{
//    NSMutableData *data;
//    ClockMode clockModeFlag;
//    NSDateFormatter *formatterISO8601DateTime, *formatterDateTime12hr, *formatterTime;


}
-(void) callTCSWebService:(ClockMode) clockMode timeEntryObjectID:(NSManagedObjectID*)timeEntryObjectID dateTime:(NSDate*) currentDateTime jobCodeId: (NSNumber *) selectedJobCodeId employeeID: (NSNumber*) selEmployeeID locOverride:(bool) bOverrideLocationCheck;

@property (assign, nonatomic) IBOutlet id <clockWebServicesDelegate> delegate;


@end
