//
//  BLEYapObjectProtocol.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/18/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLEYapObjectProtocol <NSObject>

@required

/** Returns the YapDatabase collection */
+ (NSString*) yapCollection;

/** Returns the YapDatabase key */
- (NSString*) yapKey;

/** Returns the YapDatabase group */
- (NSString*) yapGroup;

@end