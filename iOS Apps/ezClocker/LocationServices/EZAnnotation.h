//
//  EZAnnotation.h
//  ezClocker
//
//  Created by johnny_bynum on 1/15/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "CommonLib.h"

@interface EZAnnotation : MKPointAnnotation<MKAnnotation>{}
@property (nonatomic, assign) UIImage* image;
@property (nonatomic, assign) ClockMode clockMode;
@property (nonatomic, assign) BOOL isEmployee;
@property (nonatomic, retain) NSString* key;
+(EZAnnotation*)addEmployeeAnnotation:(MKMapView*)mapView Title:(NSString*)title SubTitle:(NSString*)subTitle Coordinate:(CLLocationCoordinate2D)coordinate ClockMode:(ClockMode)clockMode;
+(EZAnnotation*)addEmployerAnnotation:(MKMapView*)mapView Title:(NSString*)title SubTitle:(NSString*)subTitle Coordinate:(CLLocationCoordinate2D)coordinate;
+(EZAnnotation*)createBaseAnnotation:(MKMapView*)mapView Title:(NSString*)title SubTitle:(NSString*)subTitle Coordinate:(CLLocationCoordinate2D)coordinate;

@end
