//
//  BLETransportManager.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEBroadcaster.h"
#import "BLEScanner.h"
#import "BLECrypto.h"
#import "BLEIdentityPacket.h"

@class BLETransportManager;

@protocol BLETransportManagerDelegate <NSObject>
@required
- (void) transportManager:(BLETransportManager*)transportManager
   receivedIdentityPacket:(NSData*)identityPacket;
- (void) transportManager:(BLETransportManager*)transportManager
   willWriteIdentityPacket:(NSData*)identityPacket;
- (void) transportManager:(BLETransportManager*)transportManager
   receivedMessagePacket:(NSData*)messagePacket;
- (void) transportManager:(BLETransportManager*)transportManager
   willWriteMessagePacket:(NSData*)messagePacket;
@end

@interface BLETransportManager : NSObject <BLEBroadcasterDelegate, BLEScannerDelegate>

@property (nonatomic, strong, readonly) id<BLETransportManagerDelegate> delegate;
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;

@property (nonatomic, strong, readonly) BLEBroadcaster *broadcaster;
@property (nonatomic, strong, readonly) BLEScanner *scanner;

- (instancetype) initWithIdentity:(BLEIdentityPacket*)identity
                          keyPair:(BLEKeyPair*)keyPair
                         delegate:(id<BLETransportManagerDelegate>)delegate
                    delegateQueue:(dispatch_queue_t)delegateQueue;

- (void) start;
- (void) stop;

- (void) broadcastMessagePacket:(BLEMessagePacket*)messagePacket;

@end
