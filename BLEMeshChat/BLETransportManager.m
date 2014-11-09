//
//  BLETransportManager.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLETransportManager.h"
#import "BLECrypto.h"
#import "BLEIdentityPacket.h"

@interface BLETransportManager()
@property (nonatomic, strong, readonly) BLEBroadcaster *broadcaster;
@property (nonatomic, strong, readonly) BLEScanner *scanner;
@end

@implementation BLETransportManager

- (instancetype) initWithDataStorage:(id<BLEDataStorage>)dataStorage
 {
    if (self = [super init]) {
        _dataStorage = dataStorage;
        _scanner = [[BLEScanner alloc] initWithDataStorage:dataStorage];
        _broadcaster = [[BLEBroadcaster alloc] initWithDataStorage:dataStorage];
    }
    return self;
}

- (void) start {
    [self.scanner start];
    [self.broadcaster start];
}

- (void) stop {
    [self.scanner stop];
    [self.broadcaster stop];
}

@end
