//
//  BLEMessage.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEMessagePacket.h"
#import "BLEYapObjectProtocol.h"
#import  "BLERemotePeer.h"

@interface BLEMessage : BLEMessagePacket <BLEYapObjectProtocol>

//readwrite
@property (nonatomic, strong) NSDate *lastSeenDate;
@property (nonatomic) NSUInteger numberOfTimesSeen;

// Dynamic Properties
/** "foreign key" to sender */
@property (nonatomic, strong, readonly) NSString *senderYapKey;

- (BLERemotePeer*) senderWithTransaction:(YapDatabaseReadTransaction*)transaction;

@end
