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
#import "BLEDataParser.h"
#import "BLEDataProvider.h"

@class BLETransportManager;

@protocol BLETransportManagerDelegate <NSObject>
@required

/** Called when new identities are discovered from a peer */
- (void) transportManager:(BLETransportManager*)transportManager
         receivedIdentity:(BLEIdentityPacket*)identity
                 fromPeer:(BLEIdentityPacket*)peer;

/** Called when new messages are discovered from a peer */
- (void) transportManager:(BLETransportManager*)transportManager
          receivedMessage:(BLEMessagePacket*)message
                 fromPeer:(BLEIdentityPacket*)peer;

@optional

/** Called before messages are written to a peer */
- (void) transportManager:(BLETransportManager*)transportManager
         willWriteMessage:(BLEMessagePacket*)message
                   toPeer:(BLEIdentityPacket*)peer;

/** Called before identities are written to a peer */
- (void) transportManager:(BLETransportManager*)transportManager
        willWriteIdentity:(BLEIdentityPacket*)identity
                   toPeer:(BLEIdentityPacket*)peer;

@end

@interface BLETransportManager : NSObject <BLEBroadcasterDelegate, BLEScannerDelegate, BLEDataParser>

@property (nonatomic, weak, readonly) id<BLETransportManagerDelegate> delegate;
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;

/** Set this if you'd like to customize parsing of network data */
@property (nonatomic, weak, readwrite) id<BLEDataParser> dataParser;

@property (nonatomic, strong, readonly) BLEBroadcaster *broadcaster;
@property (nonatomic, strong, readonly) BLEScanner *scanner;

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair
                        delegate:(id<BLETransportManagerDelegate>)delegate
                   delegateQueue:(dispatch_queue_t)delegateQueue
                    dataProvider:(id<BLEDataProvider>)dataProvider;

- (void) start;
- (void) stop;

@end
