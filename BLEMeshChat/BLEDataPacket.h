//
//  BLEDataPacket.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLECrypto.h"

// [[version=1][timestamp=8][sender_public_key=32][data=n]][signature=64]
@interface BLEDataPacket : NSObject

// Static Properties
@property (nonatomic, readonly) NSData *versionData;
@property (nonatomic, readonly) NSData *timestampData;
@property (nonatomic, strong, readonly) NSData *senderPublicKey;
@property (nonatomic, strong, readonly) NSData *payloadData;
@property (nonatomic, strong, readonly) NSData *signature;
/** full raw packet data */
@property (nonatomic, strong, readonly) NSData *packetData;

// Dynamic Properties
@property (nonatomic, readonly) uint8_t version;
@property (nonatomic, strong, readonly) NSDate *timestampDate;
@property (nonatomic, readonly) uint64_t timestamp;

// Incoming Data
- (instancetype) initWithPacketData:(NSData*)packetData
                              error:(NSError**)error;
/** @return success */
- (BOOL) hasValidSignature;

// Outgoing Data
- (instancetype) initWithPayloadData:(NSData*)payloadData keyPair:(BLEKeyPair*)keyPair;

@end

extern const NSUInteger kBLEDataPacketCurrentProtocolVersion;
extern const NSUInteger kBLEDataPacketVersionOffset;
extern const NSUInteger kBLEDataPacketVersionLength;
extern const NSUInteger kBLEDataPacketTimestampOffset;
extern const NSUInteger kBLEDataPacketTimestampLength;
extern const NSUInteger kBLEDataPacketSenderPublicKeyOffset;
