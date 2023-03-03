//
//  MetricsLogWebService.h
//  ezClocker
//
//  Created by Raya Khashab on 3/3/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MetricsLogWebService : NSObject <NSURLConnectionDataDelegate>
{
    NSMutableData *data;

}
+(void) LogException:(NSString*) message;

@end
