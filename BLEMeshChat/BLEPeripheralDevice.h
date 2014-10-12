//
//  BLEPeripheralDevice.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEYapObject.h"

@interface BLEPeripheralDevice : BLEYapObject

@property (nonatomic, strong, readonly) NSUUID *uuid;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic) CBPeripheralState state;

@property (nonatomic) NSUInteger maximumUpdateValueLength;
@property (nonatomic, strong) NSArray *advertisedServices;

@property (nonatomic, strong) NSDate *lastSeenDate;
@property (nonatomic, strong) NSNumber *lastSeenRSSI;
@property (nonatomic) BOOL lastSeenIsConnectable;
@property (nonatomic) NSArray *lastSeenServiceUUIDStrings;
@property (nonatomic) NSUInteger numberOfTimesSeen;

/** Sets uuid, deviceName, state from peripheral */
- (void) setPeripheral:(CBPeripheral*)peripheral;

/** 
 * Sets lastSeenIsConnectable lastSeenServiceUUIDStrings from advertisementData
 * @see centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 */
- (void) setAdvertisementDictionary:(NSDictionary*)dictionary;

@end
