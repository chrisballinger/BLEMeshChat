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
static NSString * const kBLEMeshChatCharacteristicUUID = @"21C7DE8E-B0D0-4A41-9B22-78221277E2AA";

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
        CBUUID *meshChatCharacteristicUUID = [CBUUID UUIDWithString:kBLEMeshChatCharacteristicUUID];
        
        NSString *testValue = @"testValue";
        NSData *testData = [testValue dataUsingEncoding:NSUTF8StringEncoding];
        
        CBMutableCharacteristic *test = [[CBMutableCharacteristic alloc] initWithType:meshChatCharacteristicUUID properties:CBCharacteristicPropertyRead value:testData permissions:CBAttributePermissionsReadable];
        self.meshChatService.characteristics = @[test];
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
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, requests);
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end
