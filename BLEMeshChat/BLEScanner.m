//
//  BLEScanner.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEScanner.h"
#import "BLEBroadcaster.h"
#import "BLEMessagePacket.h"
#import "BLEIdentityPacket.h"

static NSString * const kBLEScannerRestoreIdentifier = @"kBLEScannerRestoreIdentifier";

@interface BLEScanner()
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic) dispatch_queue_t eventQueue;

@property (nonatomic, strong) NSMutableDictionary *identitiesToPeripheralCache;

@property (nonatomic, strong) NSMutableSet *allDiscoveredPeripherals;

@end

@implementation BLEScanner

- (instancetype) initWithDataStorage:(id<BLEDataStorage>)dataStorage
 {
    if (self = [super initWithDataStorage:dataStorage]) {
        _eventQueue = dispatch_queue_create("BLEScanner Event Queue", 0);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBCentralManagerOptionRestoreIdentifierKey: kBLEScannerRestoreIdentifier}];
        _identitiesToPeripheralCache = [NSMutableDictionary dictionary];
        _allDiscoveredPeripherals = [NSMutableSet set];
    }
    return self;
}

- (BOOL) start {
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

- (void) stop {
    [self.centralManager stopScan];
}

- (BLEIdentityPacket*) identityForPeripheral:(CBPeripheral*)peripheral {
    BLEIdentityPacket *identity = [self.identitiesToPeripheralCache objectForKey:peripheral.identifier];
    return identity;
}

- (void) setIdentity:(BLEIdentityPacket*)identity forPeripheral:(CBPeripheral*)peripheral {
    [self.identitiesToPeripheralCache setObject:identity forKey:peripheral.identifier];
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    DDLogVerbose(@"%@: %@ %d", THIS_FILE, THIS_METHOD, (int)central.state);
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self start];
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
            BLEMessagePacket *message = [self.dataStorage transport:self messageForMessageData:messagePacketData];
            BLEIdentityPacket *peer = [self identityForPeripheral:peripheral];
            if (messagePacketData.length) {
                    [self.dataStorage transport:self receivedMessage:message fromPeer:peer];
            }
            // Keep reading outgoing messages
            [peripheral readValueForCharacteristic:characteristic];
        } else if ([uuid isEqual:[BLEBroadcaster identityReadCharacteristicUUID]]) {
            NSData *identityPacketData = characteristic.value;
            BLEIdentityPacket *identity = [self.dataStorage transport:self identityForIdentityData:identityPacketData];
            BLEIdentityPacket *peer = [self identityForPeripheral:peripheral];
            if (identityPacketData.length) {
                    [self.dataStorage transport:self receivedIdentity:identity fromPeer:peer];
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
                BLEMessagePacket *message = [self.dataStorage transport:self nextOutgoingMessageForPeer:peer];
                if (!message) {
                    return;
                }
                BOOL shouldSendData = YES;
                if (peer) {
                    //shouldSendData = [self.dataProvider hasAlreadySentData:message toPeer:peer];
                    // Don't send dupe packets
                    if (shouldSendData == NO) {
                        return;
                    }
                }
                NSData *messagePacketData = [message packetData];
                    [self.dataStorage transport:self willWriteMessage:message toPeer:peer];
                [peripheral writeValue:messagePacketData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            } else if ([uuid isEqual:[BLEBroadcaster identityWriteCharacteristicUUID]]) {
                // Start writing your outgoing identities
                BLEIdentityPacket *peer = [self identityForPeripheral:peripheral];
                BLEIdentityPacket *identity = [self.dataStorage transport:self nextOutgoingIdentityForPeer:peer];
                BOOL shouldSendData = YES;
                if (peer) {
                    //shouldSendData = [self.dataProvider hasAlreadySentData:identity toPeer:peer];
                    // Don't send dupe packets
                    if (shouldSendData == NO) {
                        return;
                    }
                }
                NSData *identityPacketData = [identity packetData];
                [self.dataStorage transport:self willWriteIdentity:identity toPeer:peer];
                [peripheral writeValue:identityPacketData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            }
        }];
    }
}


@end
