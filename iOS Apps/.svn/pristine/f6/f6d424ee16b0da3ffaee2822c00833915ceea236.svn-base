//
//  Singletondef.h
//  ezClocker
//
//  Created by Kenneth Lewis on 12/14/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#ifndef Singletondef_h
#define Singletondef_h

@protocol SingletonRequirements <NSObject>

@required
- (void)releaseAll;

@end

#define SINGLETON_HEADER_DEF(OBJC_CLASS_TYPE) \
+ (OBJC_CLASS_TYPE *) sharedManager; \
+ (void)closeManager;

#define SINGLETON_IMPLEMENTATION_DEF(OBJC_CLASS_TYPE) \
\
static OBJC_CLASS_TYPE* __sharedManager = nil; \
static dispatch_once_t once_token = 0; \
\
- (void)dealloc { \
    [self releaseAll]; \
} \
\
+ (OBJC_CLASS_TYPE*)sharedManager { \
    dispatch_once(&once_token, ^{ \
        if (nil == __sharedManager) { \
            __sharedManager = [[OBJC_CLASS_TYPE alloc] init]; \
        } \
    }); \
    return __sharedManager; \
} \
 \
+ (void)closeManager { \
    if (nil == __sharedManager) { \
        return; \
    } \
\
    @synchronized([OBJC_CLASS_TYPE class]) { \
        @try { \
            if (__sharedManager) { \
                [__sharedManager releaseAll]; \
            } \
        } \
        @finally { \
            once_token = 0; \
            __sharedManager = nil; \
        } \
    } \
}

#endif /* Singletondef_h */
