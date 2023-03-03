//
//  LocationsWebService.h
//  ezClocker
//
//  Created by Raya Khashab on 2/7/17.
//  Copyright © 2017 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LocationsWebService;

@protocol LocationsWebServicesDelegate
- (void)LocationsServiceCallDidFinish:(LocationsWebService *)controller ErrorCode: (int) errorValue;
@end

@interface LocationsWebService : NSObject

-(void) fetchAllLocations;

@property (assign, nonatomic) IBOutlet id <LocationsWebServicesDelegate> delegate;

@end
