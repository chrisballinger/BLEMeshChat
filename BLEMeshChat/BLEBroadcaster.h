//
//  BLEBroadcaster.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

@interface BLEBroadcaster : NSObject <CBPeripheralManagerDelegate>

/** 
 * Starts broadcasting.
 * @return success
 */
- (BOOL) startBroadcasting;
- (void) stopBroadcasting;

+ (CBUUID*) meshChatServiceUUID;
+ (CBUUID*) meshChatReadCharacteristicUUID;
+ (CBUUID*) meshChatIdentityCharacteristicUUID;

@end
