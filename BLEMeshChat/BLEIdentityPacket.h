//
//  BLEIdentityPacket.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEDataPacket.h"

// payload_data: [display_name=35]
// full: [[version=1][timestamp=8][sender_public_key=32][display_name=35]][signature=64]
@interface BLEIdentityPacket : BLEDataPacket

// Static Properties
@property (nonatomic, strong, readonly) NSData *displayNameData;

// Dynamic Properties
@property (nonatomic, strong, readonly) NSString *displayName;

// Outgoing
- (instancetype) initWithDisplayName:(NSString*)displayName keyPair:(BLEKeyPair*)keyPair;

@end

extern const NSUInteger kBLEDisplayNameLength; // 35 bytes
