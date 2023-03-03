//
//  LocationManager.h
//  ezClocker
//
//  Created by johnny_bynum on 12/20/13.
//  Copyright (c) 2013 ezNova Technologies LLC. All rights reserved.
//
// *** IMPORTANT- when using this singleton, you must link the
// CoreLocation lib else you will get a link error on compile **


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol LocationManagerDelegate <NSObject>
@optional
    -(void) locationUpdate:(CLLocation *) location;
    -(void) locationError:(NSError *) error;
    -(void) locationTrackingDidStop;
@end

@interface LocationManager : NSObject <CLLocationManagerDelegate> {}
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, assign) id<LocationManagerDelegate> delegate;
@property (nonatomic, readonly, copy) CLLocation *lastKnownLocation;

+(LocationManager*)defaultLocationManager;
-(void) startTracking;
-(void) startSignificantLocationChangeTracking;
-(void) giveUpdatesOnlyMovedThanThisDistance:(CLLocationDistance)distance;
-(void) stopTracking;
@end
