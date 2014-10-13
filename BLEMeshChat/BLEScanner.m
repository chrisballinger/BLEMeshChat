//
//  BLEScanner.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEScanner.h"
#import "BLEDatabaseManager.h"
#import "BLEPeripheralDevice.h"
#import "BLEBroadcaster.h"

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
        BOOL allowDuplicates = NO;
        [self.centralManager scanForPeripheralsWithServices:@[[BLEBroadcaster meshChatServiceUUID]]
                                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @(allowDuplicates)}];
        return YES;
    } else {
        DDLogWarn(@"Central Manager not powered on!");
        return NO;
    }
}

- (void) stopScanning {
    [self.centralManager stopScan];
}

- (void) updateDeviceFromPeripheral:(CBPeripheral*)peripheral {
    NSString *key = peripheral.identifier.UUIDString;
    [self.readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        BLEPeripheralDevice *device = [transaction objectForKey:key inCollection:[BLEPeripheralDevice collection]];
        if (!device) {
            device = [[BLEPeripheralDevice alloc] init];
        } else {
            device = [device copy];
        }
        [device setPeripheral:peripheral];
        device.lastSeenRSSI = peripheral.RSSI;
        device.lastSeenDate = [NSDate date];
        device.numberOfTimesSeen = device.numberOfTimesSeen + 1;
        [[BLEDatabaseManager sharedInstance].readWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:device forKey:device.uniqueIdentifier inCollection:[BLEPeripheralDevice collection]];
        }];
    }];
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    DDLogVerbose(@"%@: %@ %d", THIS_FILE, THIS_METHOD, (int)central.state);
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self startScanning];
    }
}

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)state {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSArray *peripherals = state[CBCentralManagerRestoredStatePeripheralsKey];
    if (peripherals.count) {
        DDLogInfo(@"Restored peripherals: %@", peripherals);
    }
    [peripherals enumerateObjectsUsingBlock:^(CBPeripheral *peripheral, NSUInteger idx, BOOL *stop) {
        peripheral.delegate = self;
        if (peripheral.state != CBPeripheralStateConnected) {
            [central connectPeripheral:peripheral options:nil];
        }
        [self updateDeviceFromPeripheral:peripheral];
    }];
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [peripheral discoverServices:@[[BLEBroadcaster meshChatServiceUUID]]];
    [self updateDeviceFromPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    }
    [self updateDeviceFromPeripheral:peripheral];
    if (peripheral.state != CBPeripheralStateConnected) {
        [central connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    }
    [self updateDeviceFromPeripheral:peripheral];
    if (peripheral.state != CBPeripheralStateConnected) {
        [central connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    DDLogVerbose(@"didDiscoverPeripheral: %@\tadvertisementData: %@\tRSSI:%@", peripheral, advertisementData, RSSI);
    peripheral.delegate = self;
    if (peripheral.state != CBPeripheralStateConnected) {
        [central connectPeripheral:peripheral options:nil];
    }
    [self updateDeviceFromPeripheral:peripheral];
}

#pragma mark CBPeripheralDelegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    }
    NSArray *services = peripheral.services;
    [services enumerateObjectsUsingBlock:^(CBService *service, NSUInteger idx, BOOL *stop) {
        DDLogInfo(@"Discovered service: %@", service);
        [peripheral discoverCharacteristics:@[[BLEBroadcaster meshChatIdentityCharacteristicUUID], [BLEBroadcaster meshChatReadCharacteristicUUID]]
                                 forService:service];
    }];
    [self updateDeviceFromPeripheral:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.description);
    } else {
        DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, characteristic);
    }
    [self updateDeviceFromPeripheral:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, characteristic);
    }
    [self updateDeviceFromPeripheral:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
        [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic *characteristic, NSUInteger idx, BOOL *stop) {
            DDLogInfo(@"Discovered characteristic: %@", characteristic);
            [peripheral readValueForCharacteristic:characteristic];
        }];
    }
    [self updateDeviceFromPeripheral:peripheral];
}


@end
