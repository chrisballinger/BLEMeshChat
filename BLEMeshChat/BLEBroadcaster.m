//
//  BLEBroadcaster.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEBroadcaster.h"

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
@end

@implementation BLEBroadcaster

- (instancetype) init {
    if (self = [super init]) {
        _eventQueue = dispatch_queue_create("BLEBroadcaster Event Queue", 0);
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBPeripheralManagerOptionRestoreIdentifierKey: kBLEBroadcasterRestoreIdentifier,
                                                                             CBPeripheralManagerOptionShowPowerAlertKey: @YES}];
    }
    return self;
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
            *stop = YES;
            DDLogInfo(@"Restored service: %@", service);
            [self.meshChatService.characteristics enumerateObjectsUsingBlock:^(CBMutableCharacteristic *characteristic, NSUInteger idx, BOOL *stop) {
                CBUUID *uuid = characteristic.UUID;
                if ([uuid isEqual:[BLEBroadcaster messagesReadCharacteristicUUID]]) {
                    self.messagesReadCharacteristic = characteristic;
                } else if ([uuid isEqual:[BLEBroadcaster messagesWriteCharacteristicUUID]]) {
                    self.messagesWriteCharacteristic = characteristic;
                } else if ([uuid isEqual:[BLEBroadcaster identityReadCharacteristicUUID]]) {
                    self.identityReadCharacteristic = characteristic;
                }
                DDLogInfo(@"Restored characteristic: %@", characteristic);
            }];
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
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, request);
    CBUUID *requestUUID = request.characteristic.UUID;
    NSData *responseData = nil;
    if ([requestUUID isEqual:self.messagesReadCharacteristic.UUID]) {
        responseData = [@"msg_ack" dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([requestUUID isEqual:self.identityReadCharacteristic.UUID]) {
        responseData = [@"ident_ack" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (responseData) {
        request.value = responseData;
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    } else {
        [peripheral respondToRequest:request withResult:CBATTErrorReadNotPermitted];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, requests);
    [requests enumerateObjectsUsingBlock:^(CBATTRequest *request, NSUInteger idx, BOOL *stop) {
        CBUUID *uuid = request.characteristic.UUID;
        CBATTError result;
        NSString *writeString = nil;
        NSData *writeData = request.value;
        if (writeData) {
            uint8_t *writeDataBytes = (uint8_t *)[writeData bytes];
            NSUInteger writeDataLength = writeData.length;
            writeString = [[NSString alloc] initWithBytes:writeDataBytes length:writeDataLength encoding:NSUTF8StringEncoding];
        }
        if ([uuid isEqual:self.messagesWriteCharacteristic.UUID]) {
            result = CBATTErrorSuccess;
            DDLogInfo(@"incoming message: %@", writeString);
        } else if ([uuid isEqual:self.identityWriteCharacteristic.UUID]) {
            result = CBATTErrorSuccess;
            DDLogInfo(@"incoming identity: %@", writeString);
        } else {
            DDLogError(@"unrecognized write: %@", writeString);
            result = CBATTErrorWriteNotPermitted;
        }
        [peripheral respondToRequest:request withResult:result];
    }];
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end
