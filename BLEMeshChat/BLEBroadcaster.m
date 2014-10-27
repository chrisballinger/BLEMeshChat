//
//  BLEBroadcaster.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEBroadcaster.h"
#import "BLECrypto.h"

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

@property (nonatomic, strong) BLEKeyPair *keyPair;
@property (nonatomic, strong) BLEMessagePacket *messagePacket;

@end

@implementation BLEBroadcaster

- (instancetype) initWithIdentity:(BLEIdentityPacket*)identity
                          keyPair:(BLEKeyPair*)keyPair
                         delegate:(id<BLEBroadcasterDelegate>)delegate
                    delegateQueue:(dispatch_queue_t)delegateQueue {
    if (self = [super init]) {
        _keyPair = keyPair;
        _identity = identity;
        _eventQueue = dispatch_queue_create("BLEBroadcaster Event Queue", 0);
        if (!delegateQueue) {
            _delegateQueue = dispatch_queue_create("BLEBroadcaster Delegate Queue", 0);
        } else {
            _delegateQueue = delegateQueue;
        }
        _delegate = delegate;
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBPeripheralManagerOptionRestoreIdentifierKey: kBLEBroadcasterRestoreIdentifier,
                                                                             CBPeripheralManagerOptionShowPowerAlertKey: @YES}];
        _payloadCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) broadcastMessagePacket:(BLEMessagePacket *)messagePacket {
    self.messagePacket = messagePacket;
}

- (BOOL) startBroadcasting {
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

- (void) stopBroadcasting {
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
        [self startBroadcasting];
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

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    CBUUID *requestUUID = request.characteristic.UUID;
    NSData *responseData = nil;
    CBATTError result = CBATTErrorReadNotPermitted;
    CBCentral *central = request.central;
    
    if (request.offset > 0) {
        // This is a framework-generated follow-up request for another section of data
        NSMutableData *cachedResponse = [[_payloadCache objectForKey:requestUUID] mutableCopy];
        DDLogInfo(@"Peripheral Responding to message read request with offset %lu. len: %lu", request.offset, responseData.length);
        [self sendResponseToPeripheral:peripheral withRequest:request payload:cachedResponse result:CBATTErrorSuccess];
        
    } else {
        // This is a fresh request. Send complete data payload and cache it
        // in case we get a follow-up request for a later offset
        if ([requestUUID isEqual:self.messagesReadCharacteristic.UUID]) {
            result = CBATTErrorSuccess;
            responseData = [self.messagePacket packetData];
            [_payloadCache setObject:responseData forKey:requestUUID];
            dispatch_async(self.delegateQueue, ^{
                [self.delegate broadcaster:self willWriteMessagePacket:responseData toCentral:central];
            });
            [self sendResponseToPeripheral:peripheral withRequest:request payload:responseData result:result];
            DDLogInfo(@"Peripheral Responding to message read with %lu bytes", responseData.length);
            
        } else if ([requestUUID isEqual:self.identityReadCharacteristic.UUID]) {
            result = CBATTErrorSuccess; // For now let the remote central decide when to stop re-issuing idenetity requests
            responseData = [self.identity packetData];
            [_payloadCache setObject:responseData forKey:requestUUID]; // We shouldn't ever have to packetize identity responses in the v1 protocol

            dispatch_async(self.delegateQueue, ^{
                [self.delegate broadcaster:self willWriteIdentityPacket:responseData toCentral:central];
            });
            DDLogInfo(@"Peripheral Responding to id read with %lu bytes", responseData.length);
            [self sendResponseToPeripheral:peripheral withRequest:request payload:responseData result:result];
            
        } else {
            DDLogInfo(@"Peripheral did not recognize read characteristic %@", requestUUID);
        }
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
        DDLogInfo(@"Peripheral Sending data len %lu", request.value.length);
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
        DDLogInfo(@"Peripheral Consuming write with %lu bytes", requestData.length);

        CBCentral *central = request.central;
        if (request.offset > 0) {
            // This is a framework-generated follow-up request for another section of data
            NSMutableData *accumulatedRequestData = [[_payloadCache objectForKey:uuid] mutableCopy];
            [accumulatedRequestData appendData:requestData];
            if (accumulatedRequestData.length == 309) { // TODO remove hardcode
                DDLogInfo(@"Peripheral received complete message write!");
                // We've received a complete message
                dispatch_async(self.delegateQueue, ^{
                    [self.delegate broadcaster:self receivedIdentityPacket:accumulatedRequestData fromCentral:central];
                });
            }
            
        } else {
            //This is a fresh request
            if ([uuid isEqual:self.messagesWriteCharacteristic.UUID]) {
                // Messages always need packetization
                [_payloadCache setObject:requestData forKey:uuid];

                // Identities never need packetization
                result = CBATTErrorSuccess;
                [_payloadCache setObject:requestData forKey:uuid];
                dispatch_async(self.delegateQueue, ^{
                    [self.delegate broadcaster:self receivedIdentityPacket:requestData fromCentral:central];
                });
            } else {
                DDLogError(@"Peripheral unrecognized write: %@", request.value);
            }
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
