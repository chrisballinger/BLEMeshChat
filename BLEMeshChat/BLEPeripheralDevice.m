//
//  BLEPeripheralDevice.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEPeripheralDevice.h"

@implementation BLEPeripheralDevice

- (NSString*) uniqueIdentifier {
    return self.uuid.UUIDString;
}

- (void) setPeripheral:(CBPeripheral*)peripheral {
    _uuid = peripheral.identifier;
    _name = peripheral.name;
}

/** Group current devices as "active" */
+ (NSString*) activeGroupName {
    return @"active";
}
/** Group old devices as "past" */
+ (NSString*) pastGroupName {
    return @"past";
}

@end
