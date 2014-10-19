//
//  BLEScanner.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEScanner.h"
#import "BLEDatabaseManager.h"
#import "BLEBroadcaster.h"
#import "BLERemotePeer.h"
#import "BLEMessage.h"

static NSString * const kBLEScannerRestoreIdentifier = @"kBLEScannerRestoreIdentifier";

@interface BLEScanner()
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic) dispatch_queue_t eventQueue;
@property (nonatomic, strong) YapDatabaseConnection *readConnection;
/** obj: remotePeerYapKey, key: peripheral */
@property (nonatomic, strong) NSMutableDictionary *primaryRemotePeerForPeripheral;
@property (nonatomic, strong) NSMutableSet *allDiscoveredPeripherals;

@property (nonatomic, strong) BLEKeyPair *keyPair;
@property (nonatomic, strong) BLEMessagePacket *messagePacket;
@property (nonatomic, strong) BLEIdentityPacket *identity;
@end

@implementation BLEScanner

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair {
    if (self = [super init]) {
        _keyPair = keyPair;
        _eventQueue = dispatch_queue_create("BLEScanner Event Queue", 0);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBCentralManagerOptionRestoreIdentifierKey: kBLEScannerRestoreIdentifier}];
        _readConnection = [[BLEDatabaseManager sharedInstance].database newConnection];
        _primaryRemotePeerForPeripheral = [NSMutableDictionary dictionary];
        _allDiscoveredPeripherals = [NSMutableSet set];
    }
    return self;
}

- (BOOL) startScanning {
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        BOOL allowDuplicates = YES;
        NSArray *services = @[[BLEBroadcaster meshChatServiceUUID]];
        [self.centralManager scanForPeripheralsWithServices:services
                                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @(allowDuplicates)}];
        DDLogInfo(@"Scanning for %@", services);
        return YES;
    } else {
        DDLogWarn(@"Central Manager not powered on!");
        return NO;
    }
}

- (void) stopScanning {
    [self.centralManager stopScan];
}

- (void) broadcastMessagePacket:(BLEMessagePacket *)messagePacket {
    self.messagePacket = messagePacket;
}

- (void) broadcastIdentityPacket:(BLEIdentityPacket *)identityPacket {
    self.identity = identityPacket;
}

- (void) updateStatsForRemotePeerFromPeripheral:(CBPeripheral*)peripheral {
    NSString *remotePeerYapKey = [self.primaryRemotePeerForPeripheral objectForKey:peripheral];
    if (!remotePeerYapKey) {
        return;
    }
    [[BLEDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        BLERemotePeer *remotePeer = [transaction objectForKey:remotePeerYapKey inCollection:[BLERemotePeer yapCollection]];
        if (!remotePeer) {
            remotePeer = [[BLERemotePeer alloc] init];
        } else {
            remotePeer = [remotePeer copy];
        }
        remotePeer.lastSeenDate = [NSDate date];
        remotePeer.numberOfTimesSeen = remotePeer.numberOfTimesSeen + 1;
        remotePeer.lastSeenPeripherhalUUID = peripheral.identifier.UUIDString;
        [transaction setObject:remotePeer forKey:remotePeerYapKey inCollection:[BLERemotePeer yapCollection]];
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
        if (peripheral.state == CBPeripheralStateDisconnected) {
            [central connectPeripheral:peripheral options:nil];
        }
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
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    DDLogVerbose(@"didDiscoverPeripheral: %@\tadvertisementData: %@\tRSSI:%@", peripheral, advertisementData, RSSI);
    [self.allDiscoveredPeripherals addObject:peripheral];
    peripheral.delegate = self;
    if (peripheral.state == CBPeripheralStateDisconnected) {
        [central connectPeripheral:peripheral options:nil];
    }
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
        [peripheral discoverCharacteristics:@[[BLEBroadcaster identityReadCharacteristicUUID], [BLEBroadcaster messagesReadCharacteristicUUID],
                                              [BLEBroadcaster identityWriteCharacteristicUUID], [BLEBroadcaster messagesWriteCharacteristicUUID]]
                                 forService:service];
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.description);
    } else {
        DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, characteristic);
        CBUUID *uuid = characteristic.UUID;
        id<BLEYapObjectProtocol> yapObject = nil;
        if ([uuid isEqual:[BLEBroadcaster messagesReadCharacteristicUUID]]) {
            NSData *messagePacketData = characteristic.value;
            NSError *messageParseError = nil;
            BLEMessage *message = [[BLEMessage alloc] initWithPacketData:messagePacketData error:&messageParseError];
            if (messageParseError) {
                DDLogError(@"message parse error: %@", messageParseError);
            } else {
                yapObject = message;
            }
            // Keep reading outgoing messages
            [peripheral readValueForCharacteristic:characteristic];
        } else if ([uuid isEqual:[BLEBroadcaster identityReadCharacteristicUUID]]) {
            NSData *identityPacketData = characteristic.value;
            NSError *identityParseError = nil;
            BLERemotePeer *remotePeer = [[BLERemotePeer alloc] initWithPacketData:identityPacketData error:&identityParseError];
            if (identityParseError) {
                DDLogError(@"identity parse error: %@", identityParseError);
            } else {
                yapObject = remotePeer;
            }
            // Keep reading outgoing identities
            [peripheral readValueForCharacteristic:characteristic];
        }
        if (yapObject) {
            [[BLEDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [transaction setObject:yapObject forKey:yapObject.yapKey inCollection:[[yapObject class] yapCollection]];
            }];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, characteristic);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        DDLogError(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
        [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic *characteristic, NSUInteger idx, BOOL *stop) {
            DDLogInfo(@"Discovered characteristic: %@", characteristic);
            CBUUID *uuid = characteristic.UUID;
            if ([uuid isEqual:[BLEBroadcaster messagesReadCharacteristicUUID]]) {
                // Start reading outgoing messages
                [peripheral readValueForCharacteristic:characteristic];
            } else if ([uuid isEqual:[BLEBroadcaster identityReadCharacteristicUUID]]) {
                // Start reading outgoing identities
                [peripheral readValueForCharacteristic:characteristic];
            } else if ([uuid isEqual:[BLEBroadcaster messagesWriteCharacteristicUUID]]) {
                // Start sending your outgoing messages
                [peripheral writeValue:[self.messagePacket packetData] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            } else if ([uuid isEqual:[BLEBroadcaster identityWriteCharacteristicUUID]]) {
                // Start writing your outgoing identities
                [peripheral writeValue:[self.identity packetData] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            }
        }];
    }
}


@end
