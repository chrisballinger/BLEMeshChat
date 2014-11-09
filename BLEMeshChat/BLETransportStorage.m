//
//  BLETransportStorage.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/20/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLETransportStorage.h"
#import "BLEMessage.h"
#import "BLERemotePeer.h"
#import "BLEDatabaseManager.h"
#import "BLELocalPeer.h"
#import "BLEDataReceipt.h"

@interface BLETransportStorage()
@property (nonatomic, strong) YapDatabaseConnection *readConnection;
// identityCache may be accessed from broadcaster or scanner on different queues
@property (atomic, strong) NSMutableDictionary *identityCache;
@end

@implementation BLETransportStorage

- (instancetype) init {
    if (self = [super init]) {
        self.readConnection = [[BLEDatabaseManager sharedInstance].database newConnection];
        _identityCache = [NSMutableDictionary dictionary];
    }
    return self;
}

/** Return NO if you've already sent this data to a peer */
- (BOOL) shouldWriteData:(BLEDataPacket*)data
            toPeer:(BLEIdentityPacket*)peer {
    __block BOOL shouldWriteData = YES;
    id<BLEYapObjectProtocol> remotePeer = (id<BLEYapObjectProtocol>)peer;
    id<BLEYapObjectProtocol> outgoingData = (id<BLEYapObjectProtocol>)data;
    
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        BOOL receiptExists = [BLEDataReceipt receiptExistsForPeer:remotePeer data:outgoingData readTransaction:transaction];
        if (receiptExists) {
            shouldWriteData = NO;
        }
    }];
    return shouldWriteData;
}

#pragma mark BLEDataStorage methods

/** Override this if you are using a custom subclass of BLEIdentityPacket */
- (BLEIdentityPacket*) transport:(BLETransport*)transport
         identityForIdentityData:(NSData*)identityData {
    NSError *error = nil;
    BLERemotePeer *identity = [[BLERemotePeer alloc] initWithPacketData:identityData error:&error];
    if (error) {
        DDLogError(@"Error parsing identity: %@", error);
    }
    NSAssert(identity != nil, @"Could not parse identity data!");
    return identity;
}

/** Override this if you are using a custom subclass of BLEMessagePacket */
- (BLEMessagePacket*) transport:(BLETransport*)transport
          messageForMessageData:(NSData*)messageData {
    NSError *error = nil;
    BLEMessage *message = [[BLEMessage alloc] initWithPacketData:messageData error:&error];
    if (error) {
        DDLogError(@"Error parsing message: %@", error);
    }
    NSAssert(message != nil, @"Could not parse message data!");
    return message;
}

/** Called when new identities are discovered from a peer */
- (void) transport:(BLETransport*)transport
  receivedIdentity:(BLEIdentityPacket*)identity
          fromPeer:(BLEIdentityPacket*)peer {
    if ([identity isKindOfClass:[BLERemotePeer class]]) {
        BLERemotePeer *incomingPeer = (BLERemotePeer*)identity;
        NSString *key = incomingPeer.yapKey;
        NSString *collection = [[incomingPeer class] yapCollection];
        [[BLEDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            BLERemotePeer *remotePeer = [transaction objectForKey:key inCollection:collection];
            if (remotePeer) {
                remotePeer = [remotePeer copy];
            } else {
                // new identity found
                remotePeer = incomingPeer;
                [BLEDataReceipt setReceiptForPeer:(BLERemotePeer*)peer
                                             data:incomingPeer
                             readWriteTransaction:transaction];
            }
            remotePeer.lastReceivedDate = [NSDate date];
            remotePeer.numberOfTimesReceived = remotePeer.numberOfTimesReceived + 1;
            [transaction setObject:remotePeer forKey:key inCollection:collection];
        }];
        
        // A wild Peer found!
        dispatch_async(dispatch_get_main_queue(), ^{
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertBody = [NSString stringWithFormat:@"%@ %@", incomingPeer.displayName, NSLocalizedString(@"is nearby!", nil)];
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        });
    } else {
        DDLogError(@"Wrong peer class: %@", identity);
    }
}

/** Called when new messages are discovered from a peer */
- (void) transport:(BLETransport*)transport
   receivedMessage:(BLEMessagePacket*)message
          fromPeer:(BLEIdentityPacket*)peer {
    if ([message isKindOfClass:[BLEMessage class]]) {
        BLEMessage *incomingMessage = (BLEMessage*)message;
        NSString *key = incomingMessage.yapKey;
        NSString *collection = [[incomingMessage class] yapCollection];
        [[BLEDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            BLEMessage *message = [transaction objectForKey:key inCollection:collection];
            if (message) {
                message = [message copy];
            } else {
                // new message received
                message = incomingMessage;
                
                [BLEDataReceipt setReceiptForPeer:(BLERemotePeer*)peer
                                             data:(BLEMessage*)message
                             readWriteTransaction:transaction];
                
                // A wild unique Message found!
                BLERemotePeer *sender = [message senderWithTransaction:transaction];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody = [NSString stringWithFormat:@"%@: %@", sender.displayName, message.messageBody];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                });
            }
            message.lastReceivedDate = [NSDate date];
            message.numberOfTimesReceived = message.numberOfTimesReceived + 1;
            [transaction setObject:message forKey:key inCollection:collection];
        }];
    } else {
        DDLogError(@"Wrong message class: %@", message);
    }
}

/** Called before identities are written to a peer */
- (void) transport:(BLETransport*)transport
 willWriteIdentity:(BLEIdentityPacket*)identity
            toPeer:(BLEIdentityPacket*)peer {
    if ([identity isKindOfClass:[BLERemotePeer class]]) {
        BLERemotePeer *outgoingPeer = (BLERemotePeer*)identity;
        NSString *key = outgoingPeer.yapKey;
        NSString *collection = [[outgoingPeer class] yapCollection];
        [[BLEDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            BLERemotePeer *remotePeer = [transaction objectForKey:key inCollection:collection];
            if (remotePeer) {
                remotePeer = [remotePeer copy];
            } else {
                // new identity found
                remotePeer = outgoingPeer;
            }
            remotePeer.lastBroadcastDate = [NSDate date];
            remotePeer.numberOfTimesBroadcast = remotePeer.numberOfTimesBroadcast + 1;
            [transaction setObject:remotePeer forKey:key inCollection:collection];
            BLERemotePeer *toPeer = (BLERemotePeer*)peer;
            [BLEDataReceipt setReceiptForPeer:toPeer data:outgoingPeer readWriteTransaction:transaction];
        }];
    } else {
        DDLogError(@"Wrong peer class: %@", identity);
    }
}

/** Called before messages are written to a peer */
- (void) transport:(BLETransport*)transport
  willWriteMessage:(BLEMessagePacket*)message
            toPeer:(BLEIdentityPacket*)peer {
    if ([message isKindOfClass:[BLEMessage class]]) {
        BLEMessage *outgoingMessage = (BLEMessage*)message;
        NSString *key = outgoingMessage.yapKey;
        NSString *collection = [[outgoingMessage class] yapCollection];
        [[BLEDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            BLEMessage *message = [transaction objectForKey:key inCollection:collection];
            if (message) {
                message = [message copy];
            } else {
                // new outgoing message
                message = outgoingMessage;
            }
            message.lastBroadcastDate = [NSDate date];
            message.numberOfTimesBroadcast = message.numberOfTimesBroadcast + 1;
            [transaction setObject:message forKey:key inCollection:collection];
            BLERemotePeer *remotePeer = (BLERemotePeer*)peer;
            [BLEDataReceipt setReceiptForPeer:remotePeer data:message readWriteTransaction:transaction];
        }];
    } else {
        DDLogError(@"Wrong message class: %@", message);
    }
}

/** Called when a peer is requesting outgoing messages from you */
- (BLEMessagePacket*) transport:(BLETransport*)transport
     nextOutgoingMessageForPeer:(BLEIdentityPacket*)peer {
    __block BLEMessagePacket *message = nil;
    BLELocalPeer *myIdentity = [BLELocalPeer primaryIdentity];
    NSString *myBase64PublicKey = [myIdentity.senderPublicKey base64EncodedStringWithOptions:0];
    
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseViewTransaction *viewTransaction = [transaction ext:[BLEDatabaseManager sharedInstance].outgoingMessagesViewName];
        message =  [viewTransaction firstObjectInGroup:myBase64PublicKey];
    }];
    BOOL shouldSend = [self shouldWriteData:message toPeer:peer];
    if (!shouldSend) {
        DDLogVerbose(@"Already sent message %@ to peer %@", message, peer);
        return nil;
    }
    DDLogVerbose(@"Fetched outgoing message %@ for peer %@", message, peer);
    return message;
}

/** Called when a peer is requesting outgoing identities from you */
- (BLEIdentityPacket*) transport:(BLETransport*)transport
     nextOutgoingIdentityForPeer:(BLEIdentityPacket*)peer {
    __block BLEIdentityPacket *identity = nil;
    
    BLEIdentityPacket *sentIdentity = [self.identityCache objectForKey:peer];
    if (sentIdentity) {
        [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            YapDatabaseViewTransaction *viewTransaction = [transaction ext:[BLEDatabaseManager sharedInstance].outgoingPeersViewName];
            identity = [viewTransaction firstObjectInGroup:@"all"];
        }];
        DDLogVerbose(@"Fetched outgoing identity %@ for peer %@", identity, peer);
        BOOL shouldSend = [self shouldWriteData:identity toPeer:peer];
        if (!shouldSend) {
            DDLogVerbose(@"Already sent identity %@ to peer %@", identity, peer);
            return nil;
        }
        return identity;
    } else {
        // always return primary identity for now
        identity = [BLELocalPeer primaryIdentity];
        if (identity) {
            if (peer) {
                [self.identityCache setObject:identity forKey:peer];
            }
            return identity;
        }
    }
    return nil;
}

@end

