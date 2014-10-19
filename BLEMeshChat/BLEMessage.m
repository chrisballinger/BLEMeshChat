//
//  BLEMessage.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEMessage.h"

@implementation BLEMessage
@dynamic senderYapKey;

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

- (NSString*) yapKey {
    return [self.signature base64EncodedStringWithOptions:0];
}

- (NSString*) yapGroup {
    return [self senderYapKey];
}

- (NSString*) senderYapKey {
    return [self.senderPublicKey base64EncodedStringWithOptions:0];
}

- (BLERemotePeer*) senderWithTransaction:(YapDatabaseReadTransaction*)transaction {
    BLERemotePeer *remotePeer = [transaction objectForKey:self.senderYapKey inCollection:[BLERemotePeer yapCollection]];
    return remotePeer;
}


@end
