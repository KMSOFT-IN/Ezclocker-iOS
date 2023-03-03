//
//  MapViewController.h
//  ezClocker
//
//  Created by Raya Khashab on 3/5/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "CommonLib.h"
#import "user.h"
#import "UIViewControllerEx.h"


@interface MapViewController : UIViewControllerEx<MKMapViewDelegate>
{
    UserClass *user;
}

@property (nonatomic, retain) IBOutlet MKMapView* _mapView;
@property (weak, nonatomic) IBOutlet UILabel *accuracyLabel;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *accuracyVisualEffectView; //provides a cool blurring effect behind the accuracy label
@property (nonatomic, assign) CLLocationCoordinate2D clockInLocation;
@property (nonatomic, copy) NSNumber* clockInAccuracy;
@property (nonatomic, assign) CLLocationCoordinate2D clockOutLocation;
@property (nonatomic, copy) NSNumber* clockOutAccuracy;
@property (nonatomic, assign) ClockMode selectedMode;
@property (nonatomic, retain) NSString *employeeName;

@end
