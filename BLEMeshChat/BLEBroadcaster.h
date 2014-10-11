//
//  BLEBroadcaster.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

@interface BLEBroadcaster : NSObject <CBPeripheralManagerDelegate>

- (void) startBroadcasting;
- (void) stopBroadcasting;

@end
