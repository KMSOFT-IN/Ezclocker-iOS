//
//  debugdefines.h
//  ezClocker
//
//  Created by Kenneth Lewis on 12/20/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#ifndef debugdefines_h
#define debugdefines_h

// Must add NSString+Extensions.h to the unit that uses DEBUG_MSG for [NSString cstr:__FUNCTION__]
#define DEBUG_MSG NSString* msg = [NSString stringWithFormat:@"in call to %@ in %@", [NSString cstr:__FUNCTION__], NSStringFromClass([self class])];

#endif /* debugdefines_h */
