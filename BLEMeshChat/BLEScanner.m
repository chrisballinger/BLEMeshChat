//
//  BLEScanner.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEScanner.h"

static const NSString *kBLEScannerRestoreIdentifier = @"kBLEScannerRestoreIdentifier";

@interface BLEScanner()
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic) dispatch_queue_t eventQueue;
@end

@implementation BLEScanner

- (instancetype) init {
    if (self = [super init]) {
        _eventQueue = dispatch_queue_create("BLEScanner Event Queue", 0);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBCentralManagerOptionRestoreIdentifierKey: kBLEScannerRestoreIdentifier}];
    }
    return self;
}

- (void) startScanning {
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

- (void) stopScanning {
    [self.centralManager stopScan];
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    DDLogVerbose(@"%@: %@ %d", THIS_FILE, THIS_METHOD, (int)central.state);
}

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, peripheral);
}

@end
