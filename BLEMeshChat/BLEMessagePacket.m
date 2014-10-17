//
//  BLEMessagePacket.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEMessagePacket.h"
#import "BLECrypto.h"

const NSUInteger kBLEMessageBodyLength = 140;

//full: [[version=1][timestamp=8][sender_public_key=32][message=140][reply_signature=64]][signature=64]
@interface BLEMessagePacket()
@property (nonatomic, strong) NSData *messageBodyData;
@property (nonatomic, strong) NSData *replyToSignatureData;
@end

@implementation BLEMessagePacket
@dynamic messageBody;

- (instancetype) initWithPacketData:(NSData *)packetData error:(NSError *__autoreleasing *)error {
    if (self = [super initWithPacketData:packetData error:error]) {
        NSUInteger messgeBodyOffset = kBLEDataPacketVersionLength + kBLEDataPacketTimestampLength + kBLECryptoEd25519PublicKeyLength;
        _messageBodyData = [packetData subdataWithRange:NSMakeRange(messgeBodyOffset, kBLEMessageBodyLength)];
        _replyToSignatureData = [packetData subdataWithRange:NSMakeRange(messgeBodyOffset + kBLEMessageBodyLength, kBLECryptoEd25519SignatureLength)];
    }
    return self;
}

- (instancetype) initWithMessageBody:(NSString*)messageBody
                             keyPair:(BLEKeyPair *)keyPair {
    if (self = [self initWithReplyToSignature:nil messageBody:messageBody keyPair:keyPair]) {
    }
    return self;
}

- (instancetype) initWithReplyToSignature:(NSData*)replyToSignatureData
                              messageBody:(NSString*)messageBody
                                  keyPair:(BLEKeyPair *)keyPair {
    NSString *paddedMessageBody = [messageBody stringByPaddingToLength:kBLEMessageBodyLength withString:@" " startingAtIndex:0];
    NSData *messageBodyData = [paddedMessageBody dataUsingEncoding:NSUTF8StringEncoding];
    if (replyToSignatureData.length == 0) {
        replyToSignatureData = [NSMutableData dataWithLength:kBLECryptoEd25519SignatureLength];
    }
    NSMutableData *payloadData = [NSMutableData dataWithData:messageBodyData];
    [payloadData appendData:replyToSignatureData];
    
    if (self = [super initWithPayloadData:payloadData keyPair:keyPair]) {
        _messageBodyData = messageBodyData;
        _replyToSignatureData = replyToSignatureData;
    }
    return self;
}

- (NSString*) messageBody {
    NSAssert(self.messageBodyData.length > 0, @"must have a body!");
    if (self.messageBodyData.length == 0) {
        return @"";
    }
    NSString *messageBody = [[NSString alloc] initWithData:self.messageBodyData encoding:NSUTF8StringEncoding];
    return messageBody;
}

@end
