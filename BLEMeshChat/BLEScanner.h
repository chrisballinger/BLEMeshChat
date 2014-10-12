//
//  BLEScanner.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

@interface BLEScanner : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

/**
 * Starts scanning.
 * @return success
 */
- (BOOL) startScanning;
- (void) stopScanning;

@end
