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
@synthesize lastSeenDate;
@synthesize numberOfTimesReceived;
@synthesize numberOfTimesBroadcast;

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

- (NSString*) yapKey {
    return [self.senderPublicKey base64EncodedStringWithOptions:0];
}

- (NSString*) yapGroup {
    return @"all";
}

@end
