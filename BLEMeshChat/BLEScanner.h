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

@class BLEScanner;

@protocol BLEScannerDelegate <NSObject>
@required

- (void)      scanner:(BLEScanner*)scanner
receivedMessagePacket:(NSData*)messagePacket
       fromPeripheral:(CBPeripheral*)peripheral;

- (void)       scanner:(BLEScanner*)scanner
receivedIdentityPacket:(NSData*)identityPacket
        fromPeripheral:(CBPeripheral*)peripheral;

- (void)        scanner:(BLEScanner*)scanner
willWriteIdentityPacket:(NSData*)identityPacket
           toPeripheral:(CBPeripheral*)peripheral;

- (void)       scanner:(BLEScanner*)scanner
willWriteMessagePacket:(NSData*)messagePacket
          toPeripheral:(CBPeripheral*)peripheral;
@end

@interface BLEScanner : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, weak, readonly) id<BLEScannerDelegate> delegate;
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;
@property (nonatomic, strong, readonly) BLEIdentityPacket *identity;

- (instancetype) initWithIdentity:(BLEIdentityPacket*)identity
                          keyPair:(BLEKeyPair*)keyPair
                         delegate:(id<BLEScannerDelegate>)delegate
                    delegateQueue:(dispatch_queue_t)delegateQueue;
/**
 * Starts scanning.
 * @return success
 */
- (BOOL) startScanning;
- (void) stopScanning;

- (void) broadcastMessagePacket:(BLEMessagePacket*)messagePacket;

@end
