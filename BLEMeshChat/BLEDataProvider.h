//
//  BLEDataProvider.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 11/1/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLEDataProvider <NSObject>
/** Called when a peer is requesting outgoing identities from you */
- (BLEIdentityPacket*) nextOutgoingIdentityForPeer:(BLEIdentityPacket*)peer;

/** Called when a peer is requesting outgoing messages from you */
- (BLEMessagePacket*) nextOutgoingMessageForPeer:(BLEIdentityPacket*)peer;
@end
