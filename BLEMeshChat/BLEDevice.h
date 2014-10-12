//
//  BLEDevice.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

@interface BLEDevice : MTLModel

@property (nonatomic) NSUInteger maximumUpdateValueLength;
@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic) CBPeripheralState state;
@property (nonatomic, strong) NSArray *advertisedServices;

@property (nonatomic, strong) NSDate *lastSeenDate;
@property (nonatomic, strong) NSNumber *lastSeenRSSI;
@property (nonatomic, strong) NSData *lastSeenAdvertisementData;

/** Returns the YapDatabase collection */
+ (NSString*) collection;

/** Returns the YapDatabase key */
- (NSString*) uniqueIdentifier;

@end
