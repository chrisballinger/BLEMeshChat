//
//  BLEDataPacket.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEDataPacket.h"
#import "BLECrypto.h"

const NSUInteger kBLEDataPacketCurrentProtocolVersion = 1;
const NSUInteger kBLEDataPacketVersionOffset = 0;
const NSUInteger kBLEDataPacketVersionLength = 1;
const NSUInteger kBLEDataPacketTimestampOffset = kBLEDataPacketVersionOffset + kBLEDataPacketVersionLength;
const NSUInteger kBLEDataPacketTimestampLength = 8;
const NSUInteger kBLEDataPacketSenderPublicKeyOffset = kBLEDataPacketTimestampOffset + kBLEDataPacketTimestampLength;

@interface BLEDataPacket()
@end

@implementation BLEDataPacket
@dynamic version;
@dynamic timestampDate;
@dynamic timestamp;

- (instancetype) initWithPacketData:(NSData*)packetData error:(NSError**)error {
    if (self = [super init]) {
        BOOL packetDataHasValidLength = [self parsePacketData:packetData];
        if (!packetDataHasValidLength) {
            if (error) {
                *error = [NSError errorWithDomain:@"BLEDataPacketParseError" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Packet data has invalid length"}];
            }
            return nil;
        }
        BOOL validSig = [self hasValidSignature];
        if (!validSig) {
            if (error) {
                *error = [NSError errorWithDomain:@"BLEDataPacketParseError" code:101 userInfo:@{NSLocalizedDescriptionKey: @"Packet data has invalid signature"}];
            }
            return nil;
        }
    }
    return self;
}

//[[version=1][timestamp=8][sender_public_key=32][data=n]][signature=64]
- (BOOL) parsePacketData:(NSData*)packetData {
    NSUInteger kBLEMinimumDataPacketSize = kBLEDataPacketVersionLength + kBLEDataPacketTimestampLength + kBLECryptoEd25519PublicKeyLength + kBLECryptoEd25519SignatureLength;
    NSAssert(packetData.length > kBLEMinimumDataPacketSize, @"Packet must be of valid length!");
    if (packetData.length <= kBLEMinimumDataPacketSize) {
        return NO;
    }
    _packetData = packetData;
    _versionData = [packetData subdataWithRange:NSMakeRange(kBLEDataPacketVersionOffset, kBLEDataPacketVersionLength)];
    _timestampData = [packetData subdataWithRange:NSMakeRange(kBLEDataPacketTimestampOffset, kBLEDataPacketTimestampLength)];
    _senderPublicKey = [packetData subdataWithRange:NSMakeRange(kBLEDataPacketSenderPublicKeyOffset, kBLECryptoEd25519PublicKeyLength)];
    
    NSUInteger dataOffset = kBLEDataPacketSenderPublicKeyOffset + kBLECryptoEd25519PublicKeyLength;
    NSUInteger signatureOffset = packetData.length - kBLECryptoEd25519SignatureLength;

    NSUInteger dataLength = signatureOffset - dataOffset;
    
    _payloadData = [packetData subdataWithRange:NSMakeRange(dataOffset, dataLength)];
    _signature = [packetData subdataWithRange:NSMakeRange(signatureOffset, kBLECryptoEd25519SignatureLength)];
    return YES;
}

- (BOOL) hasValidSignature {
    NSData *signedPacketData = [self.packetData subdataWithRange:NSMakeRange(0, self.packetData.length - kBLECryptoEd25519SignatureLength)];
    BOOL hasValidSignature = [BLECrypto verifyData:signedPacketData signature:self.signature publicKey:self.senderPublicKey];
    return hasValidSignature;
}

- (uint8_t) version {
    NSAssert(self.versionData.length == 1, @"version must be 1 byte");
    uint8_t version = 0;
    version = *(uint8_t*)(self.versionData.bytes);
    return version;
}

+ (NSData*) versionDataFromVersion:(uint8_t)version {
    NSData *versionData = [NSData dataWithBytes:&version length:sizeof(uint8_t)];
    return versionData;
}

- (NSDate*) timestampDate {
    uint64_t timestamp = [self timestamp];
    NSTimeInterval timeInterval = timestamp / 1000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    return date;
}

- (uint64_t) timestamp {
    NSAssert(self.timestampData.length == 8, @"timestamp must be 8 bytes");
    uint64_t timestamp = 0;
    timestamp = CFSwapInt64LittleToHost(*(uint64_t*)(self.timestampData.bytes));
    return timestamp;
}

+ (NSData*) timestampDataFromDate:(NSDate*)date {
    NSTimeInterval timeIntervalSince1970 = [date timeIntervalSince1970];
    uint64_t unixTime = CFSwapInt64HostToLittle(timeIntervalSince1970 * 1000);
    NSData *timestampData = [NSData dataWithBytes:&unixTime length:sizeof(uint64_t)];
    return timestampData;
}

#pragma mark Outgoing Data

- (instancetype) initWithPayloadData:(NSData*)payloadData keyPair:(BLEKeyPair*)keyPair {
    if (self = [super init]) {
        _versionData = [[self class] versionDataFromVersion:kBLEDataPacketCurrentProtocolVersion];
        _timestampData = [[self class] timestampDataFromDate:[NSDate date]];
        _senderPublicKey = keyPair.publicKey;
        _payloadData = payloadData;

        NSMutableData *packetData = [NSMutableData dataWithCapacity:kBLEDataPacketVersionLength + kBLEDataPacketTimestampLength + kBLECryptoEd25519PublicKeyLength + payloadData.length + kBLECryptoEd25519SignatureLength];
        [packetData appendData:self.versionData];
        [packetData appendData:self.timestampData];
        [packetData appendData:self.senderPublicKey];
        [packetData appendData:self.payloadData];
        
        NSData *signature = [BLECrypto signatureForData:packetData privateKey:keyPair.privateKey];
        [packetData appendData:signature];
        
        _packetData = packetData;
        _signature = signature;
    }
    return self;
}

@end
