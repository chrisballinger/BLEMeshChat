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

- (void) transportManager:(BLETransportManager*)transportManager
   receivedIdentityPacket:(NSData*)identityPacket {
    NSError *error = nil;
    BLERemotePeer *incomingPeer = [[BLERemotePeer alloc] initWithPacketData:identityPacket error:&error];
    if (error) {
        DDLogError(@"Error parsing incoming identity: %@", error);
    } else {
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

    }
}

- (void) transportManager:(BLETransportManager*)transportManager
    receivedMessagePacket:(NSData*)messagePacket {
    NSError *error = nil;
    BLEMessage *incomingMessage = [[BLEMessage alloc] initWithPacketData:messagePacket error:&error];
    if (error) {
        DDLogError(@"Error parsing incoming message: %@", error);
    } else {
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
    }
}

- (void) transportManager:(BLETransportManager*)transportManager
  willWriteIdentityPacket:(NSData*)identityPacket {
    NSError *error = nil;
    BLERemotePeer *outgoingPeer = [[BLERemotePeer alloc] initWithPacketData:identityPacket error:&error];
    if (error) {
        DDLogError(@"Error parsing outgoing identity: %@", error);
    } else {
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
    }

}

- (void) transportManager:(BLETransportManager*)transportManager
   willWriteMessagePacket:(NSData*)messagePacket {
    NSError *error = nil;
    BLEMessage *outgoingMessage = [[BLEMessage alloc] initWithPacketData:messagePacket error:&error];
    if (error) {
        DDLogError(@"Error parsing outgoing message: %@", error);
    } else {
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
    }
}

@end

