//
//  BLEBroadcaster.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEBroadcaster.h"
#import "BLECrypto.h"
#import "BLEMessagePacket.h"
#import "BLEIdentityPacket.h"
#import "BLETransportManager.h"
#import "BLEReadSendQueue.h"
#import "BLEDatabaseManager.h"


static NSString * const kBLEBroadcasterRestoreIdentifier = @"kBLEBroadcasterRestoreIdentifier";

// Service
static NSString * const kBLEMeshChatServiceUUIDString = @"96F22BCA-F08C-43F9-BF7D-EEBC579C94D2";
// Characteristics
static NSString * const kBLEIdentityReadCharacteristicUUIDString = @"21C7DE8E-B0D0-4A41-9B22-78221277E2AA";
static NSString * const kBLEIdentityWriteCharacteristicUUIDString = @"00E12465-2E2F-4C6B-9FD2-E84A8A088C68";
static NSString * const kBLEMessagesReadCharacteristicUUIDString = @"A109B433-96A0-463A-A070-542C5A15E177";
static NSString * const kBLEMessagesWriteCharacteristicUUIDString = @"6EAEC220-5EB0-4181-8858-D40E1EE072F6";


@interface BLEBroadcaster()
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableService *meshChatService;
@property (nonatomic, strong) CBMutableCharacteristic *messagesReadCharacteristic;
@property (nonatomic, strong) CBMutableCharacteristic *messagesWriteCharacteristic;
@property (nonatomic, strong) CBMutableCharacteristic *identityReadCharacteristic;
@property (nonatomic, strong) CBMutableCharacteristic *identityWriteCharacteristic;
@property (nonatomic) dispatch_queue_t eventQueue;
/** Characterisitic CBUUID -> payload data. Used for requests / responses requiring packetization 
 * TODO : We really need a key that's unique to the request chain or central device on the other end
 * to avoid 'crossing the streams'
 */
@property (nonatomic, strong) NSMutableDictionary *payloadCache;


@property (nonatomic, strong) NSMutableDictionary *identitiesToCentralCache;
@end

@implementation BLEBroadcaster

- (instancetype) initWithDataStorage:(id<BLEDataStorage>)dataStorage

 {
    if (self = [super initWithDataStorage:dataStorage]) {
        _eventQueue = dispatch_queue_create("BLEBroadcaster Event Queue", 0);
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBPeripheralManagerOptionRestoreIdentifierKey: kBLEBroadcasterRestoreIdentifier,
                                                                             CBPeripheralManagerOptionShowPowerAlertKey: @YES}];
        _payloadCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL) start {
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        if (!self.meshChatService) {
            self.meshChatService = [[CBMutableService alloc] initWithType:[BLEBroadcaster meshChatServiceUUID] primary:YES];
            
            self.messagesReadCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[BLEBroadcaster messagesReadCharacteristicUUID]
                                                                                 properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyIndicate
                                                                                      value:nil
                                                                                permissions:CBAttributePermissionsReadable];
            self.messagesWriteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[BLEBroadcaster messagesWriteCharacteristicUUID]
                                                                                  properties:CBCharacteristicPropertyWrite
                                                                                       value:nil
                                                                                 permissions:CBAttributePermissionsWriteable];

            self.identityReadCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[BLEBroadcaster identityReadCharacteristicUUID]
                                                                                 properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyIndicate
                                                                                      value:nil
                                                                                permissions:CBAttributePermissionsReadable];
            self.identityWriteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[BLEBroadcaster identityWriteCharacteristicUUID]
                                                                                  properties:CBCharacteristicPropertyWrite
                                                                                       value:nil
                                                                                 permissions:CBAttributePermissionsWriteable];
            
            self.meshChatService.characteristics = @[self.messagesReadCharacteristic, self.identityReadCharacteristic, self.messagesWriteCharacteristic, self.identityWriteCharacteristic];
            [self.peripheralManager addService:self.meshChatService];
        } else {
            DDLogWarn(@"Peripheral Manager already running services");
        }
        if (!self.peripheralManager.isAdvertising) {
            [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.meshChatService.UUID],
                                                       CBAdvertisementDataLocalNameKey: @"MeshChat"}];
            return YES;
        } else {
            DDLogWarn(@"Peripheral Manager already advertising");
        }
        
    } else {
        DDLogWarn(@"Peripheral Manager not powered on! %d", (int)self.peripheralManager.state);
    }
    return NO;
}

- (void) stop {
    [self.peripheralManager stopAdvertising];
}

#pragma mark Static Methods


+ (CBUUID*) meshChatServiceUUID {
    return [CBUUID UUIDWithString:kBLEMeshChatServiceUUIDString];
}

+ (CBUUID*) messagesReadCharacteristicUUID {
    return [CBUUID UUIDWithString:kBLEMessagesReadCharacteristicUUIDString];
}

+ (CBUUID*) messagesWriteCharacteristicUUID {
    return [CBUUID UUIDWithString:kBLEMessagesWriteCharacteristicUUIDString];
}

+ (CBUUID*) identityReadCharacteristicUUID {
    return [CBUUID UUIDWithString:kBLEIdentityReadCharacteristicUUIDString];
}

+ (CBUUID*) identityWriteCharacteristicUUID {
    return [CBUUID UUIDWithString:kBLEIdentityWriteCharacteristicUUIDString];
}

#pragma mark - CBPeripheralManagerDelegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    //DDLogVerbose(@"%@: %@ %d", THIS_FILE, THIS_METHOD, (int)peripheral.state);
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [self start];
    }
}

- (void) peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        DDLogError(@"Error starting advertisement: %@", error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@ success!", THIS_FILE, THIS_METHOD);
    }
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSArray *restoredServices = dict[CBPeripheralManagerRestoredStateServicesKey];
    
    [restoredServices enumerateObjectsUsingBlock:^(CBMutableService *service, NSUInteger idx, BOOL *stop) {
        if ([service.UUID isEqual:[BLEBroadcaster meshChatServiceUUID]]) {
            self.meshChatService = service;
            DDLogInfo(@"Restored service: %@", service);
            [self.meshChatService.characteristics enumerateObjectsUsingBlock:^(CBMutableCharacteristic *characteristic, NSUInteger idx, BOOL *stop) {
                CBUUID *uuid = characteristic.UUID;
                if ([uuid isEqual:[BLEBroadcaster messagesReadCharacteristicUUID]]) {
                    self.messagesReadCharacteristic = characteristic;
                } else if ([uuid isEqual:[BLEBroadcaster messagesWriteCharacteristicUUID]]) {
                    self.messagesWriteCharacteristic = characteristic;
                } else if ([uuid isEqual:[BLEBroadcaster identityReadCharacteristicUUID]]) {
                    self.identityReadCharacteristic = characteristic;
                } else if ([uuid isEqual:[BLEBroadcaster identityWriteCharacteristicUUID]]) {
                    self.identityWriteCharacteristic = characteristic;
                }
                //DDLogInfo(@"Restored characteristic: %@", characteristic);
            }];
            *stop = YES;
        }
    }];
    NSDictionary *restoredAdvertisementDict = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey];
    NSLog(@"Restored advertisements: %@", restoredAdvertisementDict);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        //DDLogError(@"Error starting service: %@", error.description);
    } else {
        //DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, service);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    BLERemotePeer *peer = [self.dataStorage transport:self peerForDevice:central];
    peer.centralConnected = YES;
    NSLog(@"Central did subscribe to us");
    //DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, central, characteristic);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    BLERemotePeer *peer = [self.dataStorage transport:self peerForDevice:central];
    peer.centralConnected = NO;
    NSLog(@"did unsubscribe");
    NSLog(@"peer: %@", peer);
    NSLog(@"peripheral: %@ . central: %@", peer.peripheral, peer.central);
    //did disconnect.
    //remove peer for device
    //DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, central, characteristic);
}

- (void)writeMessage:(NSData*)data forPeer:(BLERemotePeer*)peer {
    NSLog(@"remote central: %@", peer.central);
    if ([_peripheralManager updateValue:data forCharacteristic:self.messagesReadCharacteristic onSubscribedCentrals:@[[peer central]]]) {
        NSLog(@"updated value, %lu", (unsigned long)data.length);
        [[BLEReadSendQueue sharedManager] sentLastChunk];
        [[BLEReadSendQueue sharedManager] sendNextChunk];
    } else {
        NSLog(@"failed to update value");
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    NSLog(@"ready to update");
    [[BLEReadSendQueue sharedManager] sendNextChunk];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    
    NSLog(@"did receive read request");
    BLERemotePeer *peer = [self.dataStorage transport:self peerForDevice:request.central];
    if ([request.characteristic.UUID.UUIDString isEqualToString:[[BLEBroadcaster identityReadCharacteristicUUID] UUIDString]]) {
        if (request.offset > request.characteristic.value.length) {
            [_peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
        } else if (request.offset == 0) {
            BLEIdentityPacket *identity = [self.dataStorage transport:self nextOutgoingIdentityForPeer:peer];
            if (identity) {
                NSLog(@"Responding to read request with my identity");
                [self.dataStorage transport:self willWriteIdentity:identity toPeer:peer];
            }
            request.value = identity.packetData;
            [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        } else {
            NSAssert(true, @"request offset exceded in identity handler");
        }
    }

}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    
    NSLog(@"did receive write request");
    [requests enumerateObjectsUsingBlock:^(CBATTRequest* request, NSUInteger idx, BOOL *stop) {
        BLERemotePeer *peer = [self.dataStorage transport:self peerForDevice:request.central];
        if ([request.characteristic.UUID.UUIDString isEqualToString:[[BLEBroadcaster identityWriteCharacteristicUUID] UUIDString]]) {
            NSLog(@"received identity");
            [self.dataStorage transport:self addIdentity:request.value forPeer:peer];
            [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
            [BLETransportManager doubleConnectionGuard:peer type:PeripheralGuard success:^() {
                NSLog(@"Received write with identity, should be peripheral, sending response.");
                [self sendMessagesToPeer:peer];
                [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];   
            } failure:^() {
                NSLog(@"Received write with identity but shouldn't be peripheral.");
                [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
                return;
            }];
        } else if ([request.characteristic.UUID.UUIDString isEqualToString:[[BLEBroadcaster messagesWriteCharacteristicUUID] UUIDString]]) {
            NSLog(@"receiving write request with length: %lu", (unsigned long)request.characteristic.value.length);
            if (request.offset > request.characteristic.value.length) {
                [_peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
            } else {
                if (request.value.length > 0) {
                    NSLog(@"data to append: %@", [request.value subdataWithRange:NSMakeRange(request.offset, request.value.length - request.offset)]);
                    [peer.receivedData appendData:[request.value subdataWithRange:NSMakeRange(request.offset, request.value.length - request.offset)]];
                    [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
                } else {
                    if (peer.receivedData.length > 0) {
                        NSLog(@"received data length: %lu", (unsigned long)peer.receivedData.length);
                        BLEMessagePacket *message = [self.dataStorage transport:self messageForMessageData:peer.receivedData];
                        [self.dataStorage transport:self receivedMessage:message fromPeer:peer];
                        [peer.receivedData setLength:0];
                        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
                    } else {
                        [peer doneReceivingMessages];
                    }
                }
            }
        }
    }];
}

- (void)sendMessagesToPeer:(BLERemotePeer*)peer {
    [self.dataStorage transport:self getAllOutgoingMessagesForPeer:peer success:^(NSArray *messages) {
        for (BLEMessagePacket *message in messages) {
            [self.dataStorage transport:self willWriteMessage:message toPeer:peer];
            [[BLEReadSendQueue sharedManager] addMessageToQueue:message.packetData forPeer:peer];
        }
        [[BLEReadSendQueue sharedManager] addMessageToQueue:[NSData data] forPeer:peer success:^{
            NSLog(@"adding success block bc");
            [[BLEReadSendQueue sharedManager] addSuccessBlockToQueue:^{
                [peer doneSendingMessages];
            }];
        }];
    }];
}

@end
