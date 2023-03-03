//
//  LocationsWebService.m
//  ezClocker
//
//  Created by Raya Khashab on 2/7/17.
//  Copyright © 2017 ezNova Technologies LLC. All rights reserved.
//

#import "LocationsWebService.h"
#import "user.h"
#import "SharedUICode.h"
#import "threaddefines.h"
#import "CommonLib.h"
#import "NSData+Extensions.h"


@implementation LocationsWebService

-(void) callGetAllLocations:(bool)useSavedValues withCompletion:(ServerResponseCompletionBlock)completion

{
    UserClass *user = [UserClass getInstance];
    
    NSString *curEmployerID = [user.employerID stringValue];
    NSString *curAuthToken = user.authToken;
    
    NSString *httpPostString = [NSString stringWithFormat:@"%@api/v1/location", SERVER_URL];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:httpPostString]];
    
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:curEmployerID forHTTPHeaderField:@"employerId"];
    [request setValue:curAuthToken forHTTPHeaderField:@"authToken"];
    
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resultData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            MAINTHREAD_BLOCK_START()
            completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        NSInteger statusCode = [(NSHTTPURLResponse*) response statusCode];
        if (statusCode == SERVICE_UNAVAILABLE_ERROR){
            MAINTHREAD_BLOCK_START()
            completion(SERVICE_UNAVAILABLE_ERROR, nil, nil, error);
            THREAD_BLOCK_END()
            return;
        }
        @autoreleasepool {
            [NSData checkData:resultData withCompletion:^(NSInteger errorCode, NSString * _Nullable resultMessage, NSDictionary * _Nullable results, NSError * _Nullable aError) {
                
//                [self stopSpinner];
                
                //               if (errorCode == SERVICE_ERRORCODE_UNKNOWN_ERROR) {
                MAINTHREAD_BLOCK_START()
                completion(errorCode, resultMessage, results, aError);
                THREAD_BLOCK_END()
                return;
                //                }
            }];
        }
    }];
    [dataTask resume];
    
}

-(void) fetchAllLocations
{
    UserClass *user = [UserClass getInstance];
    
//    [self startSpinnerWithMessage:@"Refreshing, please wait..."];
    
    [self callGetAllLocations:YES withCompletion:^(NSInteger aErrorCode, NSString * _Nullable aResultMessage, NSDictionary * _Nullable aResults, NSError * _Nullable aError) {
 //       [self stopSpinner];
        if (aErrorCode != 0) {
            [SharedUICode messageBox:nil message:@"There was an issue fetching the locations from the server. Please try again later" withCompletion:^{
                return;
            }];
            
        }
        NSArray *locations = [aResults valueForKey:@"locations"];
        NSString *_name;
        NSString *_fullAddress;
        NSString *_streetAddress;
        NSString *_csz;
        NSString *_id;
        NSString *_phoneNumber;
        NSMutableDictionary *_location;
        [user.locationNameAddressList removeAllObjects];
        for (NSDictionary *location in locations){
            _name = [location valueForKey:@"name"];
            _id = [location valueForKey:@"id"];
            _phoneNumber = [location valueForKey:@"phoneNumber"];
            _fullAddress = [NSString stringWithFormat:@"%@ %@ %@, %@ %@", [location valueForKey:@"streetNumber"], [location valueForKey:@"streetName"] ,[location valueForKey:@"city"], [location valueForKey:@"_state"], [location valueForKey:@"postalCode"]];
            _streetAddress = [NSString stringWithFormat:@"%@ %@", [location valueForKey:@"streetNumber"], [location valueForKey:@"streetName"]];
            _csz = [NSString stringWithFormat:@"%@, %@ %@", [location valueForKey:@"city"], [location valueForKey:@"_state"], [location valueForKey:@"postalCode"]];
            
            _location = [[NSMutableDictionary alloc] init];
            @try{
                [_location setValue:_name forKey:@"name"];
                [_location setValue:[location valueForKey:@"streetNumber"] forKey:@"streetNumber"];
                [_location setValue:[location valueForKey:@"streetName"] forKey:@"streetName"];
                [_location setValue:[location valueForKey:@"city"] forKey:@"city"];
                [_location setValue:[location valueForKey:@"_state"] forKey:@"_state"];
                [_location setValue:[location valueForKey:@"postalCode"] forKey:@"postalCode"];
                [_location setValue:_fullAddress forKey:@"fullAddress"];
                [_location setValue:_streetAddress forKey:@"streetAddress"];
                [_location setValue:_csz forKey:@"csz"];
                [_location setValue:_phoneNumber forKey:@"phoneNumber"];
                [_location setValue:_id forKey:@"id"];
            }
            @catch(NSException* ex) {
                NSLog(@"Exception: %@", ex);
            }

            [user.locationNameAddressList addObject: _location];
            
            
            
        }
        [self.delegate LocationsServiceCallDidFinish:self ErrorCode:SERVICE_ERRORCODE_SUCCESSFUL];

//        [_locationListTable reloadData];
        
    }];
    
}


@end
