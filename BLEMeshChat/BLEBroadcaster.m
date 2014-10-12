//
//  BLEBroadcaster.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEBroadcaster.h"

static NSString * const kBLEBroadcasterRestoreIdentifier = @"kBLEBroadcasterRestoreIdentifier";
static NSString * const kBLEMeshChatServiceUUID = @"96F22BCA-F08C-43F9-BF7D-EEBC579C94D2";
static NSString * const kBLEMeshChatReadCharacteristicUUID = @"21C7DE8E-B0D0-4A41-9B22-78221277E2AA";
static NSString * const kBLEMeshChatWriteCharacteristicUUID = @"63D14BAD-ABDE-44BC-BFCC-453AE2C8D2C8";

@interface BLEBroadcaster()
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableService *meshChatService;
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
        CBUUID *meshChatServiceUUID = [CBUUID UUIDWithString:kBLEMeshChatServiceUUID];
        self.meshChatService = [[CBMutableService alloc] initWithType:meshChatServiceUUID primary:YES];
        CBUUID *meshChatReadCharacteristicUUID = [CBUUID UUIDWithString:kBLEMeshChatReadCharacteristicUUID];
        CBUUID *meshChatWriteCharacteristicUUID = [CBUUID UUIDWithString:kBLEMeshChatWriteCharacteristicUUID];
        
        //NSString *testValue = @"testValue";
        //NSData *testData = [testValue dataUsingEncoding:NSUTF8StringEncoding];
        
        CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc] initWithType:meshChatReadCharacteristicUUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
        
        CBMutableCharacteristic *writeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:meshChatWriteCharacteristicUUID properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
        
        self.meshChatService.characteristics = @[readCharacteristic, writeCharacteristic];
        [self.peripheralManager addService:self.meshChatService];
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.meshChatService.UUID],
                                                   CBAdvertisementDataLocalNameKey: @"BLEMeshChat"}];
        return YES;
    } else {
        DDLogWarn(@"Peripheral Manager not powered on! %d", (int)self.peripheralManager.state);
        return NO;
    }
}

- (void) stopBroadcasting {
    [self.peripheralManager stopAdvertising];
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
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        DDLogError(@"Error starting service: %@", error.userInfo);
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
    
    NSString *testResponse = @"testResponse";
    NSData *testResponseData = [testResponse dataUsingEncoding:NSUTF8StringEncoding];
    
    request.value = testResponseData;
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, requests);
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end
