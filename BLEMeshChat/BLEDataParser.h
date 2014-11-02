//
//  BLEDataParser.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 11/1/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLEIdentityPacket;
@class BLEMessagePacket;

@protocol BLEDataParser <NSObject>
@required
/** Override this if you are using a custom subclass of BLEIdentityPacket */
- (BLEIdentityPacket*) identityForIdentityData:(NSData*)identityData;

/** Override this if you are using a custom subclass of BLEMessagePacket */
- (BLEMessagePacket*) messageForMessageData:(NSData*)messageData;
@end