//
//  BLEScanner.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLETransport.h"

@interface BLEScanner : BLETransport <CBCentralManagerDelegate, CBPeripheralDelegate>

@end
