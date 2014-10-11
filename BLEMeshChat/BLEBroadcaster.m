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
                                                                   options:@{CBPeripheralManagerOptionRestoreIdentifierKey: kBLEBroadcasterRestoreIdentifier}];
        CBUUID *meshChatUUID = [CBUUID UUIDWithString:kBLEMeshChatServiceUUID];
        _meshChatService = [[CBMutableService alloc] initWithType:meshChatUUID primary:YES];
        CBUUID *uuid = [CBUUID UUIDWithNSUUID:[NSUUID UUID]];
        CBMutableCharacteristic *test = [[CBMutableCharacteristic alloc] initWithType:uuid properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
        _meshChatService.characteristics = @[test];
        [_peripheralManager addService:_meshChatService];
    }
    return self;
}

- (BOOL) startBroadcasting {
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.meshChatService.UUID]}];
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

@end
