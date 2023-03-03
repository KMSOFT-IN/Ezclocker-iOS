//
//  CheckClockStatusWebService.h
//  ezClocker
//
//  Created by Raya Khashab on 11/6/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

@class CheckClockStatusWebService;

@protocol checkClockStatusWebServicesDelegate
- (void)checkClockStatusServiceCallDidFinish:(CheckClockStatusWebService *)controller timeEntryRec:(NSDictionary*)timeEntryRec ErrorCode: (int) errorValue;
@end

@interface CheckClockStatusWebService : NSObject <NSURLConnectionDataDelegate>{
    NSMutableData *data;
    NSDateFormatter *formatterISO8601DateTime, *formatterDateTime12hr;

}

-(void) checkClockStatus: (NSNumber*) employeeId;

@property (assign, nonatomic) IBOutlet id <checkClockStatusWebServicesDelegate> delegate;


@end
