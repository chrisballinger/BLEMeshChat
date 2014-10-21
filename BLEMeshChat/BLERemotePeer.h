//
//  BLERemotePeer.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEIdentityPacket.h"
#import "BLEYapObjectProtocol.h"
#import "BLEObservableProtocol.h"


@interface BLERemotePeer : BLEIdentityPacket <BLEYapObjectProtocol, BLEObservableProtocol>

@property (nonatomic) BOOL isLocallyVerified;

@end
