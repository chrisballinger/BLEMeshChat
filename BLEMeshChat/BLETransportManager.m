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
@property (nonatomic) dispatch_queue_t eventQueue;
@end

@implementation BLETransportManager

- (instancetype) initWithIdentity:(BLEIdentityPacket*)identity
                          keyPair:(BLEKeyPair*)keyPair
                         delegate:(id<BLETransportManagerDelegate>)delegate
                    delegateQueue:(dispatch_queue_t)delegateQueue {
    if (self = [super init]) {
        _delegate = delegate;
        _keyPair = keyPair;
        _myIdentity = identity;
        _eventQueue = dispatch_queue_create("BLETransportManager Event Queue", 0);
        if (!delegateQueue) {
            _delegateQueue = dispatch_queue_create("BLETransportManager Delegate Queue", 0);
        } else {
            _delegateQueue = delegateQueue;
        }
        [self setupIdentityWithKeyPair:keyPair];
        _scanner = [[BLEScanner alloc] initWithIdentity:identity keyPair:keyPair delegate:self delegateQueue:self.eventQueue];
        _broadcaster = [[BLEBroadcaster alloc] initWithIdentity:identity keyPair:keyPair delegate:self delegateQueue:self.eventQueue];
        
        [self.scanner broadcastMessagePacket:self.testMessage];
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
    if (!self.testMessage) {
        self.testMessage = [[BLEMessagePacket alloc] initWithMessageBody:@"Test Broadcast" keyPair:keyPair];
    }
}

- (void) broadcastMessagePacket:(BLEMessagePacket*)messagePacket {
    [self.scanner broadcastMessagePacket:messagePacket];
    [self.broadcaster broadcastMessagePacket:messagePacket];
}


#pragma mark BLEBroadcasterDelegate methods

- (void)  broadcaster:(BLEBroadcaster*)broadcaster
receivedMessagePacket:(NSData*)messagePacket
          fromCentral:(CBCentral*)central {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self receivedMessagePacket:messagePacket];
    });
}

- (void)   broadcaster:(BLEBroadcaster*)broadcaster
receivedIdentityPacket:(NSData*)identityPacket
           fromCentral:(CBCentral*)central {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self receivedIdentityPacket:identityPacket];
    });
}

- (void)    broadcaster:(BLEBroadcaster*)broadcaster
willWriteIdentityPacket:(NSData*)identityPacket
              toCentral:(CBCentral*)central {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self willWriteIdentityPacket:identityPacket];
    });
}

- (void)   broadcaster:(BLEBroadcaster*)broadcaster
willWriteMessagePacket:(NSData*)messagePacket
             toCentral:(CBCentral*)central {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self willWriteMessagePacket:messagePacket];
    });
}

#pragma mark BLEScannerDelegate methods

- (void)      scanner:(BLEScanner*)scanner
receivedMessagePacket:(NSData*)messagePacket
       fromPeripheral:(CBPeripheral*)peripheral {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self receivedMessagePacket:messagePacket];
    });
}

- (void)       scanner:(BLEScanner*)scanner
receivedIdentityPacket:(NSData*)identityPacket
        fromPeripheral:(CBPeripheral*)peripheral {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self receivedIdentityPacket:identityPacket];
    });
}

- (void)        scanner:(BLEScanner*)scanner
willWriteIdentityPacket:(NSData*)identityPacket
           toPeripheral:(CBPeripheral*)peripheral {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self willWriteIdentityPacket:identityPacket];
    });
}

- (void)       scanner:(BLEScanner*)scanner
willWriteMessagePacket:(NSData*)messagePacket
          toPeripheral:(CBPeripheral*)peripheral {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transportManager:self willWriteMessagePacket:messagePacket];
    });
}

@end
