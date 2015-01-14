//
//  BLEDataStorage.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 11/8/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLETransport;
@class BLEIdentityPacket;
@class BLEMessagePacket;
@class BLEDataPacket;
@class BLERemotePeer;

/** Hook this up to some persistent storage */
@protocol BLEDataStorage <NSObject>
@required

/***** Incoming Data ******/

/** Called when new identities are discovered from a peer */
- (void) transport:(BLETransport*)transport
  receivedIdentity:(BLEIdentityPacket*)identity
          fromPeer:(BLEIdentityPacket*)peer;

/** Called when new messages are discovered from a peer */
- (void) transport:(BLETransport*)transport
   receivedMessage:(BLEMessagePacket*)message
          fromPeer:(BLEIdentityPacket*)peer;

/** Called when a new device is seen */
- (BLERemotePeer*) transport:(BLETransport*)transport
               peerForDevice:(id)device;

/** Called when an identity is seen */
- (BLERemotePeer*) transport:(BLETransport *)transport
                 addIdentity:(NSData*)identity
                     forPeer:(BLERemotePeer*)peer;

/***** Outgoing Data ******/

/**
 *  Called when a peer is requesting outgoing identities from you,
 *  if nil we are finished
 */
- (BLERemotePeer*) transport:(BLETransport*)transport
     nextOutgoingIdentityForPeer:(BLERemotePeer*)peer;

/**
 *  Called when a peer is requesting outgoing messages from you,
 *  if nil we are finished
 */
- (BLEMessagePacket*) transport:(BLETransport*)transport
     nextOutgoingMessageForPeer:(BLEIdentityPacket*)peer;

/** Called when a peer is requesting all outgoing messages from you */
- (void)transport:(BLETransport *)transport getAllOutgoingMessagesForPeer:(BLEIdentityPacket *)peer success:(void(^)(NSArray *messages))success;

/** Called before messages are written to a peer */
- (void) transport:(BLETransport*)transport
  willWriteMessage:(BLEMessagePacket*)message
            toPeer:(BLEIdentityPacket*)peer;

/** Called before identities are written to a peer */
- (void) transport:(BLETransport*)transport
 willWriteIdentity:(BLEIdentityPacket*)identity
            toPeer:(BLEIdentityPacket*)peer;

/***** Message Parsing ******/

/** Override this if you are using a custom subclass of BLEIdentityPacket */
- (BLEIdentityPacket*) transport:(BLETransport*)transport
         identityForIdentityData:(NSData*)identityData;

/** Override this if you are using a custom subclass of BLEMessagePacket */
- (BLEMessagePacket*) transport:(BLETransport*)transport
          messageForMessageData:(NSData*)messageData;

@end
