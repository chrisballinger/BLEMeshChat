//
//  BLETransport.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 11/8/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLETransport.h"

@implementation BLETransport

- (instancetype) initWithDataStorage:(id<BLEDataStorage>)dataStorage
{
    if (self = [super init]) {
        _dataStorage = dataStorage;
    }
    return self;
}

- (BOOL) start {
    return NO;
}

- (void) stop {
}

@end
