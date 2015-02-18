//
//  BLEScanner.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLETransport.h"

@interface BLEScanner : BLETransport <CBCentralManagerDelegate, CBPeripheralDelegate>

- (void)writeMessage:(NSData*)data forPeer:(BLERemotePeer*)peer onCharacteristic:(NSString*)characteristic;
- (void)sendMessagesToPeer:(BLERemotePeer*)peer;
- (void)disconnectFrom:(CBPeripheral*)peripheral;
- (void)connectTo:(CBPeripheral*)peripheral;

@end
