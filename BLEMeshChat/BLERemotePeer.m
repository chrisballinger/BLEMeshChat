//
//  BLERemotePeer.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLERemotePeer.h"

static const

@interface BLERemotePeer()
@end

@implementation BLERemotePeer

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

- (NSString*) yapKey {
    return [self.senderPublicKey base64EncodedStringWithOptions:0];
}

- (NSString*) yapGroup {
    if (self.isLocallyVerified) {
        return [[self class] verifiedGroupName];
    } else {
        return [[self class] unverifiedGroupName];
    }
}

+ (NSString*) verifiedGroupName {
    return @"verified";
    
}

+ (NSString*) unverifiedGroupName {
    return @"unverified";
}


@end
