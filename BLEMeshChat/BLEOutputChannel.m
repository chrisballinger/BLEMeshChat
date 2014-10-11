//
//  BLEOutputChannel.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEOutputChannel.h"

static NSString * const kBLEOutputServiceUUID = @"579B65C8-1B9A-42C1-9011-0B3EE0BC00CB";

@implementation BLEOutputChannel

- (instancetype) init {
    if (self = [super init]) {
        CBUUID *uuid = [CBUUID UUIDWithString:kBLEOutputServiceUUID];
        _outputService = [[CBMutableService alloc] initWithType:uuid primary:NO];
    }
    return self;
}

@end
