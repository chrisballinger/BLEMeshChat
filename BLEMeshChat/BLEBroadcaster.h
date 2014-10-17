//
//  BLEBroadcaster.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLECrypto.h"
#import "BLEMessagePacket.h"
#import "BLEIdentityPacket.h"

@interface BLEBroadcaster : NSObject <CBPeripheralManagerDelegate>

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair;

/** 
 * Starts broadcasting.
 * @return success
 */
- (BOOL) startBroadcasting;
- (void) stopBroadcasting;

- (void) broadcastMessagePacket:(BLEMessagePacket*)messagePacket;
- (void) broadcastIdentityPacket:(BLEIdentityPacket*)identityPacket;

+ (CBUUID*) meshChatServiceUUID;
+ (CBUUID*) messagesReadCharacteristicUUID;
+ (CBUUID*) messagesWriteCharacteristicUUID;
+ (CBUUID*) identityReadCharacteristicUUID;
+ (CBUUID*) identityWriteCharacteristicUUID;

@end
