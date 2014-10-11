//
//  BLEInputChannel.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEInputChannel.h"

static NSString * const kBLEInputServiceUUID = @"6F7DA405-C554-4AD2-8FF4-9057BB04E526";

@implementation BLEInputChannel


- (instancetype) init {
    if (self = [super init]) {
        CBUUID *uuid = [CBUUID UUIDWithString:kBLEInputServiceUUID];
        _inputService = [[CBMutableService alloc] initWithType:uuid primary:NO];
    }
    return self;
}

@end
