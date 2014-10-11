//
//  BLEBroadcaster.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEBroadcaster.h"

static const NSString *kBLEBroadcasterRestoreIdentifier = @"kBLEBroadcasterRestoreIdentifier";

@interface BLEBroadcaster()
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic) dispatch_queue_t eventQueue;
@end

@implementation BLEBroadcaster

- (instancetype) init {
    if (self = [super init]) {
        _eventQueue = dispatch_queue_create("BLEBroadcaster Event Queue", 0);
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBPeripheralManagerOptionRestoreIdentifierKey: kBLEBroadcasterRestoreIdentifier}];
    }
    return self;
}

- (void) startBroadcasting {
    [self.peripheralManager startAdvertising:nil];
}

- (void) stopBroadcasting {
    [self.peripheralManager stopAdvertising];
}

#pragma mark - CBPeripheralManagerDelegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    DDLogVerbose(@"%@: %@ %d", THIS_FILE, THIS_METHOD, (int)peripheral.state);
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end
