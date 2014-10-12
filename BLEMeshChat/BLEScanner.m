//
//  BLEScanner.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEScanner.h"
#import "BLEDatabaseManager.h"
#import "BLEDevice.h"

static NSString * const kBLEScannerRestoreIdentifier = @"kBLEScannerRestoreIdentifier";

@interface BLEScanner()
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic) dispatch_queue_t eventQueue;
@property (nonatomic, strong) YapDatabaseConnection *readConnection;
@end

@implementation BLEScanner

- (instancetype) init {
    if (self = [super init]) {
        _eventQueue = dispatch_queue_create("BLEScanner Event Queue", 0);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBCentralManagerOptionRestoreIdentifierKey: kBLEScannerRestoreIdentifier}];
        _readConnection = [[BLEDatabaseManager sharedInstance].database newConnection];
    }
    return self;
}

- (BOOL) startScanning {
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
        return YES;
    } else {
        DDLogWarn(@"Central Manager not powered on!");
        return NO;
    }
}

- (void) stopScanning {
    [self.centralManager stopScan];
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    DDLogVerbose(@"%@: %@ %d", THIS_FILE, THIS_METHOD, (int)central.state);
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self startScanning];
    }
}

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    DDLogVerbose(@"didDiscoverPeripheral: %@\tadvertisementData: %@\tRSSI:%@", peripheral, advertisementData, RSSI);
    NSString *key = peripheral.identifier.UUIDString;
    [self.readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        BLEDevice *device = [transaction objectForKey:key inCollection:[BLEDevice collection]];
        if (!device) {
            device = [[BLEDevice alloc] init];
        } else {
            device = [device copy];
        }
        [device setPeripheral:peripheral];
        device.lastSeenRSSI = RSSI;
        device.lastSeenAdvertisements = advertisementData;
        device.lastSeenDate = [NSDate date];
        [[BLEDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:device forKey:device.uniqueIdentifier inCollection:[BLEDevice collection]];
        }];
    }];
}

@end
