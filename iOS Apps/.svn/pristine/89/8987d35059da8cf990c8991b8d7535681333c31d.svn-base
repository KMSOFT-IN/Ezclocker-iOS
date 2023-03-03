//
//  NSString+Extensions.h
//  ezClocker
//
//  Created by Kenneth Lewis on 12/14/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSStringExtensions)

+ (BOOL)isNilOrEmpty:(NSString *)str;
+ (NSString *)trim:(NSString *)str;

- (NSString*)URLUTF8Encode;

// yyyy-MM-dd'T'HH:mm:ssZ timeZone UTC
- (NSDate*)toUTCDateTime;

// MM/dd/yyyy
- (NSDate*)toDefaultDate;

- (NSDate*)toLongDateTime;

- (NSString*)toUTCDateTimeForURL;

+ (NSString*)cstr:(const char*)cstr;

- (NSString*)cleanUpDeviceToken;

+ (BOOL)isEquals:(NSString*)src dest:(NSString*)aDest;

@end
