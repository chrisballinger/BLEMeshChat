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
@end

@implementation BLEScanner

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair
                        delegate:(id<BLEScannerDelegate>)delegate
                   delegateQueue:(dispatch_queue_t)delegateQueue                       dataParser:(id<BLEDataParser>)dataParser
                    dataProvider:(id<BLEDataProvider>)dataProvider {
    if (self = [super init]) {
        _keyPair = keyPair;
        _eventQueue = dispatch_queue_create("BLEScanner Event Queue", 0);
        _delegate = delegate;
        if (!delegateQueue) {
            _delegateQueue = dispatch_queue_create("BLEScanner Delegate Queue", 0);
        } else {
            _delegateQueue = delegateQueue;
        }
        _dataParser = dataParser;
        _dataProvider = dataProvider;
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

- (BLEIdentityPacket*) identityForPeripheral:(CBPeripheral*)peripheral {
#warning Implement this method!
    return nil;
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
    if (peripheral.state != CBPeripheralStateConnected) {
        DDLogVerbose(@"didDiscoverPeripheral: %@\tadvertisementData: %@\tRSSI:%@", peripheral, advertisementData, RSSI);
    }
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
        if ([uuid isEqual:[BLEBroadcaster messagesReadCharacteristicUUID]]) {
            NSData *messagePacketData = characteristic.value;
            BLEMessagePacket *message = [self.dataParser messageForMessageData:messagePacketData];
            BLEIdentityPacket *peer = [self identityForPeripheral:peripheral];
            if (messagePacketData.length) {
                dispatch_async(self.delegateQueue, ^{
                    [self.delegate scanner:self receivedMessage:message fromPeer:peer];
                });
            }
            // Keep reading outgoing messages
            [peripheral readValueForCharacteristic:characteristic];
        } else if ([uuid isEqual:[BLEBroadcaster identityReadCharacteristicUUID]]) {
            NSData *identityPacketData = characteristic.value;
            BLEIdentityPacket *identity = [self.dataParser identityForIdentityData:identityPacketData];
            BLEIdentityPacket *peer = [self identityForPeripheral:peripheral];
            if (identityPacketData.length) {
                dispatch_async(self.delegateQueue, ^{
                    [self.delegate scanner:self receivedIdentity:identity fromPeer:peer];
                });
            }
            // Keep reading outgoing identities
            [peripheral readValueForCharacteristic:characteristic];
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
                BLEIdentityPacket *peer = [self identityForPeripheral:peripheral];
                BLEMessagePacket *message = [self.dataProvider nextOutgoingMessageForPeer:peer];
                NSData *messagePacketData = [message packetData];
                dispatch_async(self.delegateQueue, ^{
                    [self.delegate scanner:self willWriteMessage:message toPeer:peer];
                });
                [peripheral writeValue:messagePacketData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            } else if ([uuid isEqual:[BLEBroadcaster identityWriteCharacteristicUUID]]) {
                // Start writing your outgoing identities
                BLEIdentityPacket *peer = [self identityForPeripheral:peripheral];
                BLEIdentityPacket *identity = [self.dataProvider nextOutgoingIdentityForPeer:peer];
                NSData *identityPacketData = [identity packetData];
                dispatch_async(self.delegateQueue, ^{
                    [self.delegate scanner:self willWriteIdentity:identity toPeer:peer];
                });
                [peripheral writeValue:identityPacketData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            }
        }];
    }
}


@end
