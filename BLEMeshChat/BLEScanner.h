//
//  BLEScanner.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLECrypto.h"
#import "BLEIdentityPacket.h"
#import "BLEMessagePacket.h"

@interface BLEScanner : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair;

/**
 * Starts scanning.
 * @return success
 */
- (BOOL) startScanning;
- (void) stopScanning;

- (void) broadcastMessagePacket:(BLEMessagePacket*)messagePacket;
- (void) broadcastIdentityPacket:(BLEIdentityPacket*)identityPacket;

@end
