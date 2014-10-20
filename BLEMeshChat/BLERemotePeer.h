//
//  BLERemotePeer.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEIdentityPacket.h"
#import "BLEYapObjectProtocol.h"


@interface BLERemotePeer : BLEIdentityPacket <BLEYapObjectProtocol>

@property (nonatomic, strong) NSDate *lastSeenDate;
@property (nonatomic) NSUInteger numberOfTimesSeen;

@property (nonatomic) BOOL isLocallyVerified;

+ (NSString*) verifiedGroupName;
+ (NSString*) unverifiedGroupName;

@end
