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
#import "BLELocalPeer.h"
#import "BLEDatabaseManager.h"

@implementation BLETransportManager

+ (instancetype)sharedManager {
    static BLETransportManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)addDataStorage:(id<BLEDataStorage>)dataStorage {
    _dataStorage = dataStorage;
    _scanner = [[BLEScanner alloc] initWithDataStorage:dataStorage];
    _broadcaster = [[BLEBroadcaster alloc] initWithDataStorage:dataStorage];
    _remoteDevices = [NSMutableDictionary dictionary];
    return self;
}

- (void) start {
    [self.scanner start];
    [self.broadcaster start];
}

- (void) stop {
    [self.scanner stop];
    [self.broadcaster stop];
}

- (void)sendMessage {
    //first get all peers...
    NSLog(@"Send message");
    [[BLEDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction enumerateKeysInCollection:[[BLERemotePeer class] yapCollection] usingBlock:^(NSString *key, BOOL *stop) {
            BLERemotePeer *peer = [transaction objectForKey:key inCollection:[[BLERemotePeer class] yapCollection]];
            if (peer.senderPublicKey) {
                [self is:peer central:^{
                    NSLog(@"will send to message to peer (scanner): %@", peer);
                    [_scanner sendMessagesToPeer:peer];
                } orPeripheral:^{
                    NSLog(@"will send message to peer (broadcaster): %@", peer);
                    [_broadcaster sendMessagesToPeer:peer];
                }];
            }
        }];
    }];
}

- (void)disconnectFromPeers {
    for (id device in _remoteDevices) {
        if ([device isKindOfClass:[CBPeripheral class]]) {
            [_scanner disconnectFrom:device];
        }
    }
}

- (void)disconnectFromPeer:(BLERemotePeer*)peer {
    CBPeripheral *peripheral = peer.peripheral;
    if (peripheral && peripheral.state == CBPeripheralStateConnected) {
        [_scanner disconnectFrom:peripheral];
        [peer startReconnectTimer];
    }
}

- (void)reconnectToPeer:(BLERemotePeer*)peer {
    [_scanner connectTo:peer.peripheral];
}

#pragma mark utils

- (void)is:(BLERemotePeer*)peer central:(void(^)())central orPeripheral:(void (^)())peripheral {
    if (peer.deviceID.length < 1) {
        return;
    } else {
        [[self class] doubleConnectionGuard:peer type:CentralGuard success:^{
            if (peer.peripheralConnected) {
                central();
            } else {
                NSLog(@"Double connection guard returned CENTRAL but remote peripheral is not connected, not sending");
            }
        } failure:^{
            if (peer.centralConnected) {
                peripheral();
            } else {
                NSLog(@"Double connection guard returned PERIPHERAL but remote central is not connected, not sending");
            }
        }];
    }
}

+ (void)doubleConnectionGuard:(BLERemotePeer*)peer type:(ConnectionGuardType)type success:(void (^)())success failure:(void (^)())failure {
    NSLog(@"Double connection guard for peer %@", peer.deviceID);
    CBPeripheral *peripheral = [peer peripheral];
    CBCentral *central = [peer central];
    if (peer) {
        if (!peer.senderPublicKey) {
            NSLog(@"no public key yet, no guard");
            success();
        } else if (peripheral && central) {
            if (memcmp([BLELocalPeer primaryIdentity].senderPublicKey.bytes, peer.senderPublicKey.bytes, 64) > 0) {
                NSLog(@"GUARD for %@ - Device should be CENTRAL", peer.deviceID);
                if (type == CentralGuard) {
                    success();
                } else if (type == PeripheralGuard) {
                    failure();
                }
            } else {
                NSLog(@"GUARD for %@ - Device should be PERIPHERAL", peer.deviceID);
                if (type == CentralGuard) {
                    failure();
                } else if (type == PeripheralGuard) {
                    success();
                }
            }
        } else {
            NSLog(@"Only one device so far, success");
            success();
        }
    } else {
        NSLog(@"no peer");
        success();
    }
}

+ (NSString*)randomString:(int)length {
    NSMutableString *str = [[NSMutableString alloc] init];
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (int i=0; i<length; i++) {
        [str appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((u_int32_t)[letters length]) % [letters length]]];
    }
    return str;
}

@end
