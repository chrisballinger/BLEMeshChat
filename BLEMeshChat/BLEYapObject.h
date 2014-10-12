//
//  BLEYapObject.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/12/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "MTLModel.h"

@interface BLEYapObject : MTLModel

/** Returns the YapDatabase collection */
+ (NSString*) collection;

/** Returns the YapDatabase key */
- (NSString*) uniqueIdentifier;

@end
