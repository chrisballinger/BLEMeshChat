//
//  BLETransportManager.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLETransportManager.h"
#import "BLECrypto.h"
#import "BLEIdentityPacket.h"

@interface BLETransportManager()
@property (nonatomic, strong) BLEKeyPair *keyPair;
@property (nonatomic) dispatch_queue_t eventQueue;
@end

@implementation BLETransportManager

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair
                        delegate:(id<BLETransportManagerDelegate>)delegate
                   delegateQueue:(dispatch_queue_t)delegateQueue
                    dataProvider:(id<BLEDataProvider>)dataProvider {
    if (self = [super init]) {
        _delegate = delegate;
        _keyPair = keyPair;
        _eventQueue = dispatch_queue_create("BLETransportManager Event Queue", 0);
        if (!delegateQueue) {
            _delegateQueue = dispatch_queue_create("BLETransportManager Delegate Queue", 0);
        } else {
            _delegateQueue = delegateQueue;
        }
        _scanner = [[BLEScanner alloc] initWithKeyPair:keyPair delegate:self delegateQueue:self.eventQueue dataParser:self dataProvider:dataProvider];
        _broadcaster = [[BLEBroadcaster alloc] initWithKeyPair:keyPair delegate:self delegateQueue:self.eventQueue dataParser:self dataProvider:dataProvider];
    }
    return self;
}

- (void) start {
    [self.scanner startScanning];
    [self.broadcaster startBroadcasting];
}

- (void) stop {
    [self.scanner stopScanning];
    [self.broadcaster stopBroadcasting];
}

- (BLEIdentityPacket*) identityForIdentityData:(NSData*)identityData {
    BLEIdentityPacket *identity = nil;
    if (self.dataParser) {
        identity = [self.dataParser identityForIdentityData:identityData];
    } else {
        NSError *error = nil;
        identity = [[BLEIdentityPacket alloc] initWithPacketData:identityData error:&error];
        if (error) {
            DDLogError(@"Error parsing identity: %@", error);
        }
    }
    NSAssert(identity != nil, @"Could not parse identity data!");
    return identity;
}

- (BLEMessagePacket*) messageForMessageData:(NSData*)messageData {
    BLEMessagePacket *message = nil;
    if (self.dataParser) {
        message = [self.dataParser messageForMessageData:messageData];
    } else {
        NSError *error = nil;
        message = [[BLEMessagePacket alloc] initWithPacketData:messageData error:&error];
        if (error) {
            DDLogError(@"Error parsing message: %@", error);
        }
    }
    NSAssert(message != nil, @"Could not parse message data!");
    return message;
}

#pragma mark BLEBroadcasterDelegate methods

- (id<BLEDataParser>) parserForBroadcaster:(BLEBroadcaster*)broadcaster {
    return self;
}

- (void)  broadcaster:(BLEBroadcaster*)broadcaster
      receivedMessage:(BLEMessagePacket*)message
             fromPeer:(BLEIdentityPacket*)peer {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self receivedMessage:message fromPeer:peer];
    });
}

- (void)   broadcaster:(BLEBroadcaster*)broadcaster
      receivedIdentity:(BLEIdentityPacket*)identity
              fromPeer:(BLEIdentityPacket*)peer {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self receivedIdentity:identity fromPeer:peer];
    });
}

- (void)    broadcaster:(BLEBroadcaster*)broadcaster
      willWriteIdentity:(BLEIdentityPacket*)identity
                 toPeer:(BLEIdentityPacket*)peer {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self willWriteIdentity:identity toPeer:peer];
    });
}

- (void)   broadcaster:(BLEBroadcaster*)broadcaster
      willWriteMessage:(BLEMessagePacket*)message
                toPeer:(BLEIdentityPacket*)peer {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self willWriteMessage:message toPeer:peer];
    });
}

#pragma mark BLEScannerDelegate methods

- (BLEIdentityPacket*) scanner:(BLEScanner*)scanner
       identityForIdentityData:(NSData*)identityData {
    return [self identityForIdentityData:identityData];
}

- (BLEMessagePacket*) scanner:(BLEScanner*)scanner
        messageForMessageData:(NSData*)messageData {
    return [self messageForMessageData:messageData];
}

- (void)      scanner:(BLEScanner*)scanner
      receivedMessage:(BLEMessagePacket*)message
             fromPeer:(BLEIdentityPacket*)peer {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self receivedMessage:message fromPeer:peer];
    });
}

- (void)       scanner:(BLEScanner*)scanner
      receivedIdentity:(BLEIdentityPacket*)identity
              fromPeer:(BLEIdentityPacket*)peer {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self receivedIdentity:identity fromPeer:peer];
    });
}

- (void)        scanner:(BLEScanner*)scanner
      willWriteIdentity:(BLEIdentityPacket*)identity
                 toPeer:(BLEIdentityPacket*)peer {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self willWriteIdentity:identity toPeer:peer];
    });
}

- (void)       scanner:(BLEScanner*)scanner
      willWriteMessage:(BLEMessagePacket*)message
                toPeer:(BLEIdentityPacket*)peer {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self willWriteMessage:message toPeer:peer];
    });
}

@end
