//
//  BLERemotePeer.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEIdentityPacket.h"
#import "BLEYapObjectProtocol.h"
#import "BLETransportStats.h"
#import "JSQMessageAvatarImageDataSource.h"

@interface BLERemotePeer : BLEIdentityPacket <BLEYapObjectProtocol, BLETransportStats, JSQMessageAvatarImageDataSource>

@property (nonatomic) BOOL isLocallyVerified;

@end
