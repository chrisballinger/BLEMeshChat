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

@implementation BLETransportStorage

#pragma mark BLEDataParser methods

- (BLEIdentityPacket*) identityForIdentityData:(NSData*)identityData {
    NSError *error = nil;
    BLERemotePeer *identity = [[BLERemotePeer alloc] initWithPacketData:identityData error:&error];;
    if (error) {
        DDLogError(@"Error parsing identity: %@", error);
    }
    NSAssert(identity != nil, @"Could not parse identity data!");
    return identity;
}

- (BLEMessagePacket*) messageForMessageData:(NSData*)messageData {
    NSError *error = nil;
    BLEMessage *message = [[BLEMessage alloc] initWithPacketData:messageData error:&error];;
    if (error) {
        DDLogError(@"Error parsing message: %@", error);
    }
    NSAssert(message != nil, @"Could not parse message data!");
    return message;
}

#pragma mark BLETransportManagerDelegate methods

- (void) transportManager:(BLETransportManager*)transportManager
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
- (void) transportManager:(BLETransportManager*)transportManager
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

- (void) transportManager:(BLETransportManager*)transportManager
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
        }];
    } else {
        DDLogError(@"Wrong peer class: %@", identity);
    }
}

- (void) transportManager:(BLETransportManager*)transportManager
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
        }];
    } else {
        DDLogError(@"Wrong message class: %@", message);
    }
}

/** Called when a peer is requesting outgoing messages from you */
- (BLEMessagePacket*) nextOutgoingMessageForPeer:(BLEIdentityPacket*)peer {
#warning Return a message here
    return nil;
}

/** Called when a peer is requesting outgoing identities from you */
- (BLEIdentityPacket*) nextOutgoingIdentityForPeer:(BLEIdentityPacket*)peer {
#warning Return an identity here
    return nil;
}

@end

