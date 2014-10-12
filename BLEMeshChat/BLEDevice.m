//
//  BLEDevice.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEDevice.h"

@implementation BLEDevice

+ (NSString*) collection {
    return NSStringFromClass([self class]);
}

- (NSString*) uniqueIdentifier {
    return self.uuid.UUIDString;
}

@end
