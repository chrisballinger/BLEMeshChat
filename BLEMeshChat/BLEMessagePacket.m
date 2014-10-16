//
//  BLEMessagePacket.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEMessagePacket.h"
#import "BLECrypto.h"

static const NSUInteger kBLEMessageBodyMaxLength = 140;

@interface BLEMessagePacket()
@property (nonatomic, strong) NSData *messageBodyData;
@property (nonatomic, strong) NSData *replyToSignatureData;
@end

@implementation BLEMessagePacket
@dynamic messageBody;

- (instancetype) initWithMessageBody:(NSString*)messageBody
                             keyPair:(BLEKeyPair *)keyPair {
    if (self = [self initWithReplyToSignature:nil messageBody:messageBody keyPair:keyPair]) {
    }
    return self;
}

- (instancetype) initWithReplyToSignature:(NSData*)replyToSignatureData
                              messageBody:(NSString*)messageBody
                                  keyPair:(BLEKeyPair *)keyPair {
    NSAssert(replyToSignatureData.length == kBLECryptoEd25519SignatureLength, @"replyToSignatureData must be 64 bytes");
    if (replyToSignatureData.length != kBLECryptoEd25519SignatureLength) {
        return nil;
    }
    NSString *paddedMessageBody = [messageBody stringByPaddingToLength:kBLEMessageBodyMaxLength withString:@" " startingAtIndex:0];
    NSData *messageBodyData = [paddedMessageBody dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *payloadData = [NSMutableData dataWithData:messageBodyData];
    [payloadData appendData:replyToSignatureData];
    
    if (self = [super initWithPayloadData:payloadData keyPair:keyPair]) {
        _messageBodyData = messageBodyData;
        _replyToSignatureData = replyToSignatureData;
    }
    return self;
}

@end
