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
        DDLogError(@"Error parsing identity: %@", error);
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
            remotePeer.lastSeenDate = [NSDate date];
            remotePeer.numberOfTimesSeen = remotePeer.numberOfTimesSeen + 1;
            [transaction setObject:remotePeer forKey:key inCollection:collection];
        }];
    }
}

- (void) transportManager:(BLETransportManager*)transportManager
    receivedMessagePacket:(NSData*)messagePacket {
    NSError *error = nil;
    BLEMessage *incomingMessage = [[BLEMessage alloc] initWithPacketData:messagePacket error:&error];
    if (error) {
        DDLogError(@"Error parsing message: %@", error);
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
            }
            message.lastSeenDate = [NSDate date];
            message.numberOfTimesSeen = message.numberOfTimesSeen + 1;
            [transaction setObject:message forKey:key inCollection:collection];
        }];
    }
}

- (void) transportManager:(BLETransportManager*)transportManager
  willWriteIdentityPacket:(NSData*)identityPacket {
    
}

- (void) transportManager:(BLETransportManager*)transportManager
   willWriteMessagePacket:(NSData*)messagePacket {
    
}

@end

