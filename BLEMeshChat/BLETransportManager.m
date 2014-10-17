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
@property (nonatomic, strong) BLEIdentityPacket *myIdentity;
@property (nonatomic, strong) BLEMessagePacket *testMessage;
@end

@implementation BLETransportManager

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair {
    if (self = [super init]) {
        _keyPair = keyPair;
        [self setupIdentityWithKeyPair:keyPair];
        _scanner = [[BLEScanner alloc] initWithKeyPair:keyPair];
        _broadcaster = [[BLEBroadcaster alloc] initWithKeyPair:keyPair];
        
        [self.scanner broadcastIdentityPacket:self.myIdentity];
        [self.scanner broadcastMessagePacket:self.testMessage];
        [self.broadcaster broadcastIdentityPacket:self.myIdentity];
        [self.broadcaster broadcastMessagePacket:self.testMessage];
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

- (void) setupIdentityWithKeyPair:(BLEKeyPair*)keyPair {
    if (!self.myIdentity) {
        self.myIdentity = [[BLEIdentityPacket alloc] initWithDisplayName:@"Test Identity" keyPair:keyPair];
    }
    if (!self.testMessage) {
        self.testMessage = [[BLEMessagePacket alloc] initWithMessageBody:@"Test Broadcast" keyPair:keyPair];
    }
}

- (void) broadcastMessagePacket:(BLEMessagePacket*)messagePacket {
    [self.scanner broadcastMessagePacket:messagePacket];
    [self.broadcaster broadcastMessagePacket:messagePacket];
}
- (void) broadcastIdentityPacket:(BLEIdentityPacket*)identityPacket {
    [self.scanner broadcastIdentityPacket:identityPacket];
    [self.broadcaster broadcastIdentityPacket:identityPacket];
}


@end
