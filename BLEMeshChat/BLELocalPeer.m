//
//  BLELocalPeer.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLELocalPeer.h"

@implementation BLELocalPeer
@dynamic keyPair, displayName;

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

- (NSString*) yapKey {
    return [self.senderPublicKey base64EncodedStringWithOptions:0];
}

- (NSString*) yapGroup {
    return [[self class] allIdentitiesGroupName];
}

+ (NSString*) allIdentitiesGroupName {
    return @"all";
}

- (instancetype) initWithDisplayName:(NSString*)displayName keyPair:(BLEKeyPair*)keyPair {
    if (self = [super initWithDisplayName:displayName keyPair:keyPair]) {
        _privateKey = keyPair.privateKey;
    }
    return self;
}

- (BLEKeyPair*) keyPair {
    return [[BLEKeyPair alloc] initWithPublicKey:self.senderPublicKey privateKey:self.privateKey type:BLEKeyTypeEd25519];
}

@end
