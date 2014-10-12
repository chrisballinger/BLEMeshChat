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

- (void) setAdvertisementDictionary:(NSDictionary*)dictionary {
    
}

@end
