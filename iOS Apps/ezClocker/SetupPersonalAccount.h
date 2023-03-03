//
//  SetupPersonalAccount.h
//  ezClocker
//
//  Created by Raya Khashab on 2/16/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "user.h"


@protocol AddIndividualAccountDelegate
//This protocol is used when we are done with registering an indivdual account
- (void)RegisterationFinished;
- (void)RegisterationFailed;
@end

@interface SetupPersonalAccount : NSObject <NSURLConnectionDataDelegate>{
    NSMutableData *data;
    NSURLConnection *addIndivdualConnection;
    NSURLConnection *getAccountConnection;
    NSURLConnection *getAuthConnection;


}
@property (assign, nonatomic) IBOutlet id <AddIndividualAccountDelegate> delegate;


-(void) setupIndivdualAccount;


@end
