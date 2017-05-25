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
        _identitiesToCentralCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL) start {
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        if (!self.meshChatService) {
            self.meshChatService = [[CBMutableService alloc] initWithType:[BLEBroadcaster meshChatServiceUUID] primary:YES];
            
            self.messagesReadCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[BLEBroadcaster messagesReadCharacteristicUUID]
                                                                                 properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyIndicate
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
    DDLogVerbose(@"%@: %@ %d", THIS_FILE, THIS_METHOD, (int)peripheral.state);
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
            [self.meshChatService.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull characteristic, NSUInteger idx, BOOL * _Nonnull stop) {
                CBUUID *uuid = characteristic.UUID;
                if ([uuid isEqual:[BLEBroadcaster messagesReadCharacteristicUUID]]) {
                    self.messagesReadCharacteristic = characteristic.mutableCopy;
                } else if ([uuid isEqual:[BLEBroadcaster messagesWriteCharacteristicUUID]]) {
                    self.messagesWriteCharacteristic = characteristic.mutableCopy;
                } else if ([uuid isEqual:[BLEBroadcaster identityReadCharacteristicUUID]]) {
                    self.identityReadCharacteristic = characteristic.mutableCopy;
                } else if ([uuid isEqual:[BLEBroadcaster identityWriteCharacteristicUUID]]) {
                    self.identityWriteCharacteristic = characteristic.mutableCopy;
                }
                DDLogInfo(@"Restored characteristic: %@", characteristic);
            }];
            *stop = YES;
        }
    }];
    NSDictionary *restoredAdvertisementDict = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey];
    NSLog(@"Restored advertisements: %@", restoredAdvertisementDict);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        DDLogError(@"Error starting service: %@", error.description);
    } else {
        DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, service);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, central, characteristic);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, central, characteristic);
}

- (BLEIdentityPacket*) identityForCentral:(CBCentral*)central {
    BLEIdentityPacket *identity = [self.identitiesToCentralCache objectForKey:central.identifier];
    return identity;
}

- (void) setIdentity:(BLEIdentityPacket*)identity
          forCentral:(CBCentral*)central {
    [self.identitiesToCentralCache setObject:identity forKey:central.identifier];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    CBUUID *requestUUID = request.characteristic.UUID;
    NSData *responseData = nil;
    CBATTError result = CBATTErrorReadNotPermitted;
    CBCentral *central = request.central;
    

    // This is a fresh request. Send complete data payload and cache it
    // in case we get a follow-up request for a later offset
    if ([requestUUID isEqual:self.messagesReadCharacteristic.UUID]) {
        result = CBATTErrorSuccess;
        BLEIdentityPacket *peer = [self identityForCentral:central];
        if (request.offset > 0) {
            responseData = [self.payloadCache objectForKey:requestUUID];
        } else {
            BLEMessagePacket *messagePacket = [self.dataStorage transport:self nextOutgoingMessageForPeer:peer];
            if (!messagePacket) {
                return;
            }
            responseData = [messagePacket packetData];
            BOOL shouldSendData = YES;
            if (peer) {
                
                // Don't send dupe packets
                if (shouldSendData == NO) {
                    return;
                }
            }
            [self.payloadCache setObject:responseData forKey:requestUUID];
            [self.dataStorage transport:self willWriteMessage:messagePacket toPeer:peer];
        }
        [self sendResponseToPeripheral:peripheral withRequest:request payload:responseData result:result];
        DDLogInfo(@"Peripheral Responding to message read with %d bytes", (int)responseData.length);
    } else if ([requestUUID isEqual:self.identityReadCharacteristic.UUID]) {
        BLEIdentityPacket *centralPeer = [self identityForCentral:central];
        
        BLEIdentityPacket *identity = [self.dataStorage transport:self nextOutgoingIdentityForPeer:centralPeer];
        if (identity) {
            result = CBATTErrorSuccess; // For now let the remote central decide when to stop re-issuing idenetity requests
            responseData = [identity packetData];
            [_payloadCache setObject:responseData forKey:requestUUID]; // We shouldn't ever have to packetize identity responses in the v1 protocol
                [self.dataStorage transport:self willWriteIdentity:identity toPeer:centralPeer];
            DDLogInfo(@"Peripheral Responding to id read with %d bytes", (int)responseData.length);
        } else {
            DDLogInfo(@"No more identities to send");
        }
        [self sendResponseToPeripheral:peripheral withRequest:request payload:responseData result:result];
    } else {
        DDLogInfo(@"Peripheral did not recognize read characteristic %@", requestUUID);
    }
}

- (void) sendResponseToPeripheral:(CBPeripheralManager *)peripheral withRequest:(CBATTRequest *)request payload:(NSData *) responseData result:(CBATTError) result{
    if (responseData != nil) {
        if (request.offset > responseData.length) {
            [peripheral respondToRequest:request
                              withResult:CBATTErrorInvalidOffset];
            return;
        }
        request.value = [responseData
                         subdataWithRange:NSMakeRange(request.offset,
                                                      responseData.length - request.offset)];
        DDLogInfo(@"Peripheral Sending data len %d", (int)request.value.length);
    }
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, request);
    [peripheral respondToRequest:request withResult:result];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, requests);
    [requests enumerateObjectsUsingBlock:^(CBATTRequest *request, NSUInteger idx, BOOL *stop) {
        CBUUID *uuid = request.characteristic.UUID;
        CBATTError result = CBATTErrorWriteNotPermitted;
        NSData *requestData = request.value;
        DDLogInfo(@"Peripheral Consuming write with %d bytes", (int)requestData.length);

        CBCentral *central = request.central;
        if ([uuid isEqual:self.messagesWriteCharacteristic.UUID]) {
            NSData *fullPacketData = nil;
            if (requestData.length == kBLEMessageTotalLength) {
                fullPacketData = requestData;
            } else if (request.offset > 0) {
                // This is a framework-generated follow-up request for another section of data
                NSMutableData *accumulatedRequestData = [[self.payloadCache objectForKey:uuid] mutableCopy];
                [accumulatedRequestData appendData:requestData];
                if (accumulatedRequestData.length == kBLEMessageTotalLength) { // TODO remove hardcode
                    fullPacketData = accumulatedRequestData;
                } else {
                    [self.payloadCache setObject:accumulatedRequestData forKey:uuid];
                }
            }
            if (fullPacketData) {
                DDLogInfo(@"Peripheral received complete message write!");
                // We've received a complete message
                BLEMessagePacket *message = [self.dataStorage transport:self messageForMessageData:fullPacketData];
                BLEIdentityPacket *centralPeer = [self identityForCentral:central];
                [self.dataStorage transport:self receivedMessage:message fromPeer:centralPeer];
            }
        } else if ([uuid isEqual:self.identityWriteCharacteristic.UUID]) {
            // Identities never need packetization
            result = CBATTErrorSuccess;
            BLEIdentityPacket *centralPeer = [self identityForCentral:central];
            BLEIdentityPacket *incomingIdentity = [self.dataStorage transport:self identityForIdentityData:requestData];
            if (!centralPeer) {
                [self setIdentity:incomingIdentity forCentral:central];
                centralPeer = incomingIdentity;
            }
            [self.dataStorage transport:self receivedIdentity:incomingIdentity fromPeer:centralPeer];
        } else {
            DDLogError(@"Peripheral unrecognized write: %@", request.value);
        }
        // Always send response. It will be interpreted by the remote central as "ready for more data",
        // or "request complete" depending on what state of the request we're at
        [peripheral respondToRequest:request withResult:result];
    }];
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end
