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
#import "BLERemotePeer.h"
#import "BLETransportManager.h"
#import "BLEWriteSendQueue.h"
#import "BLEDatabaseManager.h"

static NSString * const kBLEScannerRestoreIdentifier = @"kBLEScannerRestoreIdentifier";

@interface BLEScanner()
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic) dispatch_queue_t eventQueue;

@property (nonatomic, strong) NSMutableDictionary *peerToPeripheralCache;

@property (nonatomic, strong) NSMutableSet *allDiscoveredPeripherals;

@property (nonatomic, strong) NSMutableDictionary *characteristicsDictionary;
@property (nonatomic, strong) NSMutableArray *writeSendQueue;

@end

@implementation BLEScanner

- (instancetype) initWithDataStorage:(id<BLEDataStorage>)dataStorage
 {
    if (self = [super initWithDataStorage:dataStorage]) {
        _eventQueue = dispatch_queue_create("BLEScanner Event Queue", 0);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBCentralManagerOptionRestoreIdentifierKey: kBLEScannerRestoreIdentifier}];
        _writeSendQueue = [NSMutableArray array];
        _characteristicsDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL) start {
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        BOOL allowDuplicates = NO;
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

- (CBCharacteristic*) characteristicForUUID:(CBUUID*)uuid {
    return [self.characteristicsDictionary objectForKey:uuid.UUIDString];
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
        [[BLETransportManager sharedManager].remoteDevices removeObjectForKey:peripheral.identifier.UUIDString];
    } else {
        DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        //only want to not dismiss ref to peer if the connection timed out before data transfer finished.
        //for now lets always remove the reference on disconnect.
    } else {
        BLERemotePeer *peer = [self.dataStorage transport:self peerForDevice:peripheral];
        NSLog(@"did disconnect");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    peripheral.delegate = self;
    if (peripheral.state == CBPeripheralStateDisconnected) {
        NSLog(@"peripheral discovered: %@", peripheral);
        for (id device in [BLETransportManager sharedManager].remoteDevices) {
            NSLog(@"device already: %@", [[BLETransportManager sharedManager].remoteDevices objectForKey:device]);
        }
        BLERemotePeer *peer = [self.dataStorage transport:self peerForDevice:peripheral];
        [BLETransportManager doubleConnectionGuard:peer type:CentralGuard success:^{
            [central connectPeripheral:peripheral options:nil];
        } failure:^{
            DDLogError(@"Error: Double connection guard stopping connection, %@: %@", THIS_FILE, THIS_METHOD);
        }];
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
        [peripheral discoverCharacteristics:@[[BLEBroadcaster identityReadCharacteristicUUID], [BLEBroadcaster messagesReadCharacteristicUUID],
                                              [BLEBroadcaster identityWriteCharacteristicUUID], [BLEBroadcaster messagesWriteCharacteristicUUID]]
                                 forService:service];
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    BLERemotePeer *peer = [self.dataStorage transport:self peerForDevice:peripheral];
    [self readIdentity:peer]; //don't double connection guard yet because we don't yet have an identity for the other device
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    BLERemotePeer *peer = [self.dataStorage transport:self peerForDevice:peripheral];
    
    if ([characteristic.UUID.UUIDString isEqualToString:[[BLEBroadcaster identityReadCharacteristicUUID] UUIDString]]) {
        NSLog(@"Received identity from peer: %@", peer.peripheral.identifier.UUIDString);
        if (characteristic.value.length < 1) { //sometimes it reads an empty identity. Not sure why.
            return;
        }
        [self.dataStorage transport:self addIdentity:characteristic.value forPeer:peer];
        [BLETransportManager doubleConnectionGuard:peer type:CentralGuard success:^() {
            [self subscribeToReadCharacteristic:peer];
            [self writeIdentity:peer];
            [self sendMessagesToPeer:peer];
        } failure:^() {
            NSLog(@"In didUpdate for Identity Char, shouldn't be central, disconnecting.");
            [_centralManager cancelPeripheralConnection:peripheral];
            return;
        }];
    } else { //data characteristic
        NSLog(@"Received data from peer: %@", peer.peripheral.identifier.UUIDString);
        int length = (int)characteristic.value.length;
        if (length > 0) {
            [peer.receivedData appendData:characteristic.value];
        } else { //finished reading data
            if (peer.receivedData.length > 0) {
                NSData *receivedData = [peer.receivedData copy];
                [peer.receivedData setLength:0];
                BLEMessagePacket *message = [self.dataStorage transport:self messageForMessageData:receivedData];
                [self.dataStorage transport:self receivedMessage:message fromPeer:peer];
            } else {
                [peer doneReceivingMessages];
            }
        }
    }
}

- (void)writeIdentity:(BLERemotePeer*)peer {
    //don't need to worry about packetization here.
    BLERemotePeer *myIdentity = [self.dataStorage transport:self nextOutgoingIdentityForPeer:peer];
    NSLog(@"length of packet data to send: %lu", (unsigned long)myIdentity.packetData.length);
    [[BLEWriteSendQueue sharedManager] addMessageToQueue:myIdentity.packetData forPeer:peer onCharacteristic:[[BLEBroadcaster identityWriteCharacteristicUUID] UUIDString]];
    NSLog(@"writing identity to %@", peer.peripheral.identifier.UUIDString);
}

- (void)sendMessagesToPeer:(BLERemotePeer*)peer {
    [self.dataStorage transport:self getAllOutgoingMessagesForPeer:peer success:^(NSArray *messages) {
        for (BLEMessagePacket *message in messages) {
            [self.dataStorage transport:self willWriteMessage:message toPeer:peer];
            [[BLEWriteSendQueue sharedManager] addMessageToQueue:message.packetData forPeer:peer onCharacteristic:[[BLEBroadcaster messagesWriteCharacteristicUUID] UUIDString]];
        }
        [[BLEWriteSendQueue sharedManager] addMessageToQueue:[NSData data] forPeer:peer onCharacteristic:[[BLEBroadcaster messagesWriteCharacteristicUUID] UUIDString]];
        [[BLEWriteSendQueue sharedManager] addSuccessBlockToQueue:^{
            [peer doneSendingMessages];
        }];
    }];
}

- (void)writeMessage:(NSData*)data forPeer:(BLERemotePeer*)peer onCharacteristic:(NSString*)characteristic {
    CBPeripheral *peripheral = [peer peripheral];
    [peripheral writeValue:data forCharacteristic:[self getCharacteristicOfType:characteristic fromPeripheral:peripheral] type:CBCharacteristicWriteWithResponse];
    NSLog(@"writing value");
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"wrote value");
    NSLog(@"did write to peer");
    [BLEWriteSendQueue sharedManager].readyToUpdate = YES;
    [[BLEWriteSendQueue sharedManager] sendNextChunk];
}

- (CBCharacteristic*)getCharacteristicOfType:(NSString*)type fromPeripheral:(CBPeripheral*)peripheral {
    NSArray *services = peripheral.services;
    for (CBService *service in services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:type]) {
                return characteristic;
            }
        }
    }
    NSLog(@"Warning: Didn't find characteristic on peripheral %@ for type %@", peripheral, type);
    return nil;
}

- (CBCharacteristic*)getWriteCharacteristicOfPeripheral:(CBPeripheral*)peripheral {
    return [self getCharacteristicOfType:[[BLEBroadcaster messagesWriteCharacteristicUUID] UUIDString] fromPeripheral:peripheral];
}

- (CBCharacteristic*)getIdentityWriteCharacteristicOfPeripheral:(CBPeripheral*)peripheral {
    return [self getCharacteristicOfType:[[BLEBroadcaster identityWriteCharacteristicUUID] UUIDString] fromPeripheral:peripheral];
}

- (void)readIdentity:(BLERemotePeer*)peer {
    for (CBService *service in [peer peripheral].services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:[[BLEBroadcaster identityReadCharacteristicUUID] UUIDString]]) {
                [peer.peripheral readValueForCharacteristic:characteristic];
            }
        }
    }
}

- (void)subscribeToReadCharacteristic:(BLERemotePeer*)peer {
    for (CBService *service in [peer peripheral].services) {
        if ([service.UUID.UUIDString isEqualToString:[[BLEBroadcaster meshChatServiceUUID] UUIDString]]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID.UUIDString isEqualToString:[[BLEBroadcaster messagesReadCharacteristicUUID] UUIDString]]) {
                    [peer.peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (void)disconnectFrom:(CBPeripheral*)peripheral {
    [_centralManager cancelPeripheralConnection:peripheral];
}

- (void)connectTo:(CBPeripheral*)peripheral {
    NSLog(@"will reconnect to peripheral");
    [_centralManager connectPeripheral:peripheral options:nil];
}

@end
