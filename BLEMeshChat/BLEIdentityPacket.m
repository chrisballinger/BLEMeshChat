//
//  BLEIdentityPacket.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEIdentityPacket.h"

const NSUInteger kBLEDisplayNameLength = 35; // 35 bytes

@implementation BLEIdentityPacket
@dynamic displayName;

- (instancetype) initWithDisplayName:(NSString*)displayName keyPair:(BLEKeyPair*)keyPair {
    if (!displayName) {
        displayName = @"";
    }
    NSString *paddedDisplayName = [displayName stringByPaddingToLength:kBLEDisplayNameLength withString:@" " startingAtIndex:0];
    NSData *displayNameData = [paddedDisplayName dataUsingEncoding:NSUTF8StringEncoding];
    
    if (self = [super initWithPayloadData:displayNameData keyPair:keyPair]) {
        _displayNameData = displayNameData;
    }
    return self;
}

- (NSString*) displayName {
    NSString *displayName = [[NSString alloc] initWithData:self.displayNameData encoding:NSUTF8StringEncoding];
    return displayName;
}


@end
