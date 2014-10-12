//
//  BLEDevice.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

@interface BLEDevice : MTLModel

@property (nonatomic, strong, readonly) NSUUID *uuid;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic) CBPeripheralState state;

@property (nonatomic) NSUInteger maximumUpdateValueLength;
@property (nonatomic, strong) NSArray *advertisedServices;

@property (nonatomic, strong) NSDate *lastSeenDate;
@property (nonatomic, strong) NSNumber *lastSeenRSSI;
@property (nonatomic, strong) NSDictionary *lastSeenAdvertisements;

/** Sets uuid, deviceName, state from peripheral */
- (void) setPeripheral:(CBPeripheral*)peripheral;

/** Returns the YapDatabase collection */
+ (NSString*) collection;

/** Returns the YapDatabase key */
- (NSString*) uniqueIdentifier;

@end
