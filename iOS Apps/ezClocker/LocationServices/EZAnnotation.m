//
//  EZAnnotation.m
//  ezClocker
//
//  Created by johnny_bynum on 1/15/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "EZAnnotation.h"
#import <MapKit/MapKit.h>

#pragma mark EZAnnotation Class

@implementation EZAnnotation
@synthesize image, clockMode, isEmployee, key=_key;

+(EZAnnotation*)addEmployeeAnnotation:(MKMapView*)mapView Title:(NSString*)title SubTitle:(NSString*)subTitle Coordinate:(CLLocationCoordinate2D)coordinate ClockMode:(ClockMode)clockMode{
    EZAnnotation* ezAnnotation = [EZAnnotation createBaseAnnotation:mapView Title:title SubTitle:subTitle Coordinate:coordinate];
    ezAnnotation.clockMode = clockMode;
    ezAnnotation.isEmployee = YES;
    return ezAnnotation;
}

+(EZAnnotation*)addEmployerAnnotation:(MKMapView*)mapView Title:(NSString*)title SubTitle:(NSString*)subTitle Coordinate:(CLLocationCoordinate2D)coordinate{
    EZAnnotation* ezAnnotation = [EZAnnotation createBaseAnnotation:mapView Title:title SubTitle:subTitle Coordinate:coordinate];
    ezAnnotation.isEmployee = NO;
    return ezAnnotation;
}

+(EZAnnotation*)createBaseAnnotation:(MKMapView*)mapView Title:(NSString*)title SubTitle:(NSString*)subTitle Coordinate:(CLLocationCoordinate2D)coordinate{
    EZAnnotation* ezAnnotation = [[EZAnnotation alloc] init];
    ezAnnotation.coordinate = coordinate;
    ezAnnotation.title = title;
    ezAnnotation.subtitle = subTitle;
    ezAnnotation.isEmployee = NO;
    [mapView addAnnotation:ezAnnotation];
    return ezAnnotation;
}

-(UIImage*)image{
    if (!isEmployee) return nil;
    
    if (image) return image;
    
    UIImage *tmpImage;
    
    if (clockMode == ClockModeIn)
        tmpImage = [UIImage imageNamed:@"green_pin.png"];
    else
        tmpImage = [UIImage imageNamed:@"blue_pin.png"];
    
    if (tmpImage != nil)
    {
        self.image = tmpImage;
        return image;
    }
    else
        return nil;
}

-(void)setClockMode:(ClockMode)aClockMode{
    clockMode = aClockMode;
    self.image = nil;
}

-(NSString*)key{
    if (_key)
        return _key;
    
    self.key = [NSString stringWithFormat:@"%f%@%@", [[NSDate date] timeIntervalSince1970], self.subtitle, self.title];

    return _key;
}
@end


