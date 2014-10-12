//
//  BLEYapObject.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/12/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEYapObject.h"

@implementation BLEYapObject

+ (NSString*) collection {
    return NSStringFromClass([self class]);
}

- (NSString*) uniqueIdentifier {
    NSAssert(YES, @"You must implement this method in your subclass!");
    return nil;
}

@end
