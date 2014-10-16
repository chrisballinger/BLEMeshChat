//
//  BLEPeer.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEPeer.h"

@interface BLEPeer()
@end

@implementation BLEPeer

- (NSString*) uniqueIdentifier {
    return [self.publicKeyData base64EncodedStringWithOptions:0];
}

@end
