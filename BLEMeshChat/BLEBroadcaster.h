//
//  BLEBroadcaster.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLETransport.h"

@interface BLEBroadcaster : BLETransport <CBPeripheralManagerDelegate>

+ (CBUUID*) meshChatServiceUUID;
+ (CBUUID*) messagesReadCharacteristicUUID;
+ (CBUUID*) messagesWriteCharacteristicUUID;
+ (CBUUID*) identityReadCharacteristicUUID;
+ (CBUUID*) identityWriteCharacteristicUUID;

- (void)writeMessage:(NSData*)data forPeer:(BLERemotePeer*)peer;
- (void)sendMessagesToPeer:(BLERemotePeer*)peer;


@end
