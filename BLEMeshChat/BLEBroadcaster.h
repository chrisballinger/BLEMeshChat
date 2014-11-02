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
#import "BLEDataParser.h"
#import "BLEDataProvider.h"

@class BLEBroadcaster;

@protocol BLEBroadcasterDelegate <NSObject>
@required

- (void)  broadcaster:(BLEBroadcaster*)broadcaster
      receivedMessage:(BLEMessagePacket*)message
             fromPeer:(BLEIdentityPacket*)peer;

- (void)   broadcaster:(BLEBroadcaster*)broadcaster
      willWriteMessage:(BLEMessagePacket*)message
                toPeer:(BLEIdentityPacket*)peer;

- (void)   broadcaster:(BLEBroadcaster*)broadcaster
      receivedIdentity:(BLEIdentityPacket*)identity
              fromPeer:(BLEIdentityPacket*)peer;

- (void)    broadcaster:(BLEBroadcaster*)broadcaster
      willWriteIdentity:(BLEIdentityPacket*)identity
                 toPeer:(BLEIdentityPacket*)peer;

@end

@interface BLEBroadcaster : NSObject <CBPeripheralManagerDelegate>

@property (nonatomic, weak, readonly) id<BLEBroadcasterDelegate> delegate;
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;
@property (nonatomic, weak, readonly) id<BLEDataParser> dataParser;
@property (nonatomic, weak, readonly) id<BLEDataProvider> dataProvider;

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair
                         delegate:(id<BLEBroadcasterDelegate>)delegate
                    delegateQueue:(dispatch_queue_t)delegateQueue                       dataParser:(id<BLEDataParser>)dataParser
                     dataProvider:(id<BLEDataProvider>)dataProvider;
/** 
 * Starts broadcasting.
 * @return success
 */
- (BOOL) startBroadcasting;
- (void) stopBroadcasting;

+ (CBUUID*) meshChatServiceUUID;
+ (CBUUID*) messagesReadCharacteristicUUID;
+ (CBUUID*) messagesWriteCharacteristicUUID;
+ (CBUUID*) identityReadCharacteristicUUID;
+ (CBUUID*) identityWriteCharacteristicUUID;

@end
