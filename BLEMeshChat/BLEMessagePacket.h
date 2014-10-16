//
//  BLEMessagePacket.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEDataPacket.h"
#import "BLECrypto.h"

//[message=140][reply_signature=64]
@interface BLEMessagePacket : BLEDataPacket

// Static Properties
@property (nonatomic, strong, readonly) NSData *messageBodyData;
@property (nonatomic, strong, readonly) NSData *replyToSignatureData;

// Dynamic Properties
@property (nonatomic, strong, readonly) NSString *messageBody;


- (instancetype) initWithMessageBody:(NSString*)messageBody keyPair:(BLEKeyPair*)keyPair;
- (instancetype) initWithReplyToSignature:(NSData*)replyToSignatureData
                              messageBody:(NSString*)messageBody
                                  keyPair:(BLEKeyPair*)keyPair;

@end
