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


@class BLEBroadcaster;

@protocol BLEBroadcasterDelegate <NSObject>
@required

- (void)  broadcaster:(BLEBroadcaster*)broadcaster
receivedMessagePacket:(NSData*)messagePacket
          fromCentral:(CBCentral*)central;

- (void)   broadcaster:(BLEBroadcaster*)broadcaster
receivedIdentityPacket:(NSData*)identityPacket
           fromCentral:(CBCentral*)central;

- (void)    broadcaster:(BLEBroadcaster*)broadcaster
willWriteIdentityPacket:(NSData*)identityPacket
              toCentral:(CBCentral*)central;

- (void)   broadcaster:(BLEBroadcaster*)broadcaster
willWriteMessagePacket:(NSData*)messagePacket
             toCentral:(CBCentral*)central;

@end

@interface BLEBroadcaster : NSObject <CBPeripheralManagerDelegate>

@property (nonatomic, weak, readonly) id<BLEBroadcasterDelegate> delegate;
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;
@property (nonatomic, strong, readonly) BLEIdentityPacket *identity;

- (instancetype) initWithIdentity:(BLEIdentityPacket*)identity
                          keyPair:(BLEKeyPair*)keyPair
                         delegate:(id<BLEBroadcasterDelegate>)delegate
                    delegateQueue:(dispatch_queue_t)delegateQueue;
/** 
 * Starts broadcasting.
 * @return success
 */
- (BOOL) startBroadcasting;
- (void) stopBroadcasting;

- (void) broadcastMessagePacket:(BLEMessagePacket*)messagePacket;

+ (CBUUID*) meshChatServiceUUID;
+ (CBUUID*) messagesReadCharacteristicUUID;
+ (CBUUID*) messagesWriteCharacteristicUUID;
+ (CBUUID*) identityReadCharacteristicUUID;
+ (CBUUID*) identityWriteCharacteristicUUID;

@end
