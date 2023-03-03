//
//  MapViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 3/5/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import "MapViewController.h"
#import "EZAnnotation.h"
#import "user.h"
#import "NSNumber+Extensions.h"


@implementation MapViewController

@synthesize _mapView, selectedMode;

-(void) viewWillDisappear:(BOOL)animated{
    //remove all annotations
    [_mapView removeAnnotations:_mapView.annotations];
    
    [super viewWillDisappear:animated];
}

-(void) viewWillAppear:(BOOL)animated{
    
    self.title = NSLocalizedString(@"GPS Location", @"GPS Location");

    
    self.accuracyLabel.alpha = 0.0;
    self.accuracyVisualEffectView.alpha = 0.0;
    
    user = [UserClass getInstance];
   
    [self.parentViewController.navigationItem setTitle:@"Location View"];
    
//    NSString *empName = self.employeeName;
    
    NSLog(@"CLOCK IN ACCURACY: %f, CLOCK OUT ACCURACY: %f", self.clockInAccuracy.doubleValue, self.clockOutAccuracy.doubleValue);
    //add employee clock in annoation
    if (self.clockInLocation.latitude != 0 && self.clockInLocation.longitude != 0){
        EZAnnotation* ezAnn = [EZAnnotation addEmployeeAnnotation:_mapView
                                                            Title:(self.employeeName)?self.employeeName:@"Clocked IN"
                                                         SubTitle:(!self.employeeName)?@"":@"Clocked IN"
                                                       Coordinate:self.clockInLocation
                                                        ClockMode:ClockModeIn];
        if (selectedMode == ClockModeIn)
            [_mapView selectAnnotation:ezAnn animated:YES];
        
    }
    
    //add employee clock out annoation
    if (self.clockOutLocation.latitude != 0 && self.clockOutLocation.longitude != 0){
        EZAnnotation* ezAnn = [EZAnnotation addEmployeeAnnotation:_mapView
                                                            Title:(self.employeeName)?self.employeeName:@"Clocked OUT"
                                                         SubTitle:(!self.employeeName)?@"":@"Clocked OUT"
                                                       Coordinate:self.clockOutLocation
                                                        ClockMode:ClockModeOut];
        
        if (selectedMode == ClockModeOut) {
            [_mapView selectAnnotation:ezAnn animated:YES];
        }
    }
    
    if ([_mapView.annotations count] == 0) {
        //nothing to show, remove map
        _mapView.hidden = YES;
    } else {
        _mapView.hidden = NO;
        if (user.employerLocation.location.latitude != 0 && user.employerLocation.location.longitude != 0){
            [EZAnnotation addEmployerAnnotation:_mapView
                                          Title:user.employerLocation.name
                                       SubTitle:@"Work site"
                                     Coordinate:user.employerLocation.location];
        }
    }
    [self zoomMapViewToFitAnnotations:_mapView animated:YES];
    
}

-(void)removeCurrentAccuracyCircle
{
    for (id overlay in _mapView.overlays) {
        MKCircle *circleOverlay = (MKCircle *)overlay;
        
        if (circleOverlay != nil) {
            [_mapView removeOverlay:circleOverlay];
        }
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.accuracyLabel.alpha = 0.0;
        self.accuracyVisualEffectView.alpha = 0.0;
    }];
}

#pragma mark MapView Helper Methods
#define MINIMUM_ZOOM 0.014
#define ANNOTATION_REGION_PAD_FACTOR 3.15
#define MAX_DEGREES 360
- (void)zoomMapViewToFitAnnotations:(MKMapView *)mapView animated:(BOOL)animated
{
    NSArray *annotations = mapView.annotations;
    int count = (int)[mapView.annotations count];
    if (count == 0) return;  //early out
    
    MKMapPoint points[count];
    for(int i=0; i<count; i++){
        CLLocationCoordinate2D coordinate = [(id <MKAnnotation>)[annotations objectAtIndex:i] coordinate];
        points[i] = MKMapPointForCoordinate(coordinate);
    }
    
    MKMapRect mapRect = [[MKPolygon polygonWithPoints:points count:count] boundingMapRect];
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
    region.span.latitudeDelta  *= ANNOTATION_REGION_PAD_FACTOR;
    region.span.longitudeDelta *= ANNOTATION_REGION_PAD_FACTOR;
    
    if (region.span.latitudeDelta  < MINIMUM_ZOOM) region.span.latitudeDelta  = MINIMUM_ZOOM;
    if (region.span.longitudeDelta < MINIMUM_ZOOM) region.span.longitudeDelta = MINIMUM_ZOOM;
    if (region.span.latitudeDelta > MAX_DEGREES)   region.span.latitudeDelta  = MAX_DEGREES;
    if (region.span.longitudeDelta > MAX_DEGREES)  region.span.longitudeDelta = MAX_DEGREES;
    
    if (count == 1){
        region.span.latitudeDelta = MINIMUM_ZOOM;
        region.span.longitudeDelta = MINIMUM_ZOOM;
    }
    
    [mapView setRegion:region animated:animated];
}

#pragma mark MapView Delegate Methods
-(void)setRegionWithinLocation:(CLLocation*)location{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance (location.coordinate, 10000, 10000);
    [_mapView setRegion:region animated:YES];
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    EZAnnotation* ezAnnotation = (EZAnnotation*)view.annotation;
    
    //mistakenly required both clickInAccuracy & clockOutAccuracy to both not be nil, which caused it not to show the accuracy circle in cases where only clock in was present. 
    if ((ezAnnotation.clockMode == ClockModeIn && self.clockInAccuracy != nil) || (ezAnnotation.clockMode == ClockModeOut && self.clockOutAccuracy != nil)) {
        [self removeCurrentAccuracyCircle];
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:ezAnnotation.coordinate radius:(ezAnnotation.clockMode == ClockModeIn) ? self.clockInAccuracy.doubleValue : self.clockOutAccuracy.doubleValue];
        [_mapView addOverlay:circle];
        
        NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:(ezAnnotation.clockMode == ClockModeIn) ? @"Clock In Accuracy: " : @"Clock Out Accuracy: " attributes:@{}];
        
        [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:[CommonLib accuracyString:ezAnnotation.clockMode == ClockModeIn ? self.clockInAccuracy.doubleValue : self.clockOutAccuracy.doubleValue] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:self.accuracyLabel.font.pointSize]}]];
        
        self.accuracyLabel.attributedText = attributed;
        
        self.accuracyLabel.alpha = 0.0;
        self.accuracyVisualEffectView.alpha = 0.0;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.accuracyLabel.alpha = 1.0;
            self.accuracyVisualEffectView.alpha = 1.0;
        }];
    }
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    [self removeCurrentAccuracyCircle];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)overlay
{
    MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithOverlay:overlay];
    renderer.fillColor = [[UIColor alloc] initWithRed:23.0/255.0 green:123.0/255.0 blue:253.0/255.0 alpha:0.2];
    
    return renderer;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    EZAnnotation* ezAnnotation = (EZAnnotation*)annotation;
    
    //dequeue pins
    MKAnnotationView *annView = (MKAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:ezAnnotation.key];
    
    if (!annView){
        if (ezAnnotation.isEmployee){
            annView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ezAnnotation.key];
            annView.image = ezAnnotation.image;
        } else
            annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ezAnnotation.key];
        
        //annView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annView.canShowCallout = YES;
        annView.calloutOffset = CGPointMake(-2, 2);
    }
    
    annView.centerOffset = CGPointMake(0.25 * annView.frame.size.width, -0.5 * annView.frame.size.height + 4.0);
    
    return annView;
}



@end
