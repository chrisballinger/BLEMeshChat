//
//  BLEMessagePacket.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEDataPacket.h"
#import "BLECrypto.h"

//payload: [message=140][reply_signature=64]
//full: [[version=1][timestamp=8][sender_public_key=32][message=140][reply_signature=64]][signature=64]
@interface BLEMessagePacket : BLEDataPacket

// Static Properties
@property (nonatomic, strong, readonly) NSData *messageBodyData;
@property (nonatomic, strong, readonly) NSData *replyToSignatureData;

// Dynamic Properties
@property (nonatomic, strong, readonly) NSString *messageBody;

// Outgoing
- (instancetype) initWithMessageBody:(NSString*)messageBody keyPair:(BLEKeyPair*)keyPair;
- (instancetype) initWithReplyToSignature:(NSData*)replyToSignatureData
                              messageBody:(NSString*)messageBody
                                  keyPair:(BLEKeyPair*)keyPair;

extern const NSUInteger kBLEMessageBodyLength; // 140 bytes

@end
