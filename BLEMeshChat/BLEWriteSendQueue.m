//
//  BLEWriteSendQueue.m
//  BLEMeshChat
//
//  Created by John Rogers on 1/3/15.
//  Copyright (c) 2015 Christopher Ballinger. All rights reserved.
//

#import "BLEWriteSendQueue.h"
#import "BLETransportManager.h"

@interface WriteData : NSObject

@property (strong, nonatomic) BLERemotePeer *peer;
@property (strong, nonatomic) NSData *data;
@property (strong, nonatomic) NSString *characteristic;

@end

@implementation WriteData

- (id)initWithData:(NSData*)data peer:(BLERemotePeer*)peer andCharacteristic:(NSString*)characteristic {
    self = [super init];
    _data = data;
    _peer = peer;
    _characteristic = characteristic;
    return self;
}

@end

@implementation BLEWriteSendQueue

+ (instancetype)sharedManager {
    static BLEWriteSendQueue *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    self = [super init];
    _queue = [NSMutableArray array];
    _readyToUpdate = YES;
    return self;
}

- (void)addMessageToQueue:(NSData*)data forPeer:(BLERemotePeer*)peer onCharacteristic:(NSString*)characteristic {
    CBPeripheral *peripheral = [peer peripheral];
    if (peripheral.state == CBPeripheralStateConnected) {
        NSLog(@"adding data with length %lu", (unsigned long)data.length);
        while (data.length) {
            NSInteger lengthToIncremenent = 512 < data.length ? 512 : data.length;
            NSData *chunk = [data subdataWithRange:NSMakeRange(0, lengthToIncremenent)];
            [_queue addObject:[[WriteData alloc] initWithData:chunk peer:peer andCharacteristic:characteristic]];
            NSInteger length = data.length - lengthToIncremenent;
            if (length < 0) length = 0;
            data = [data subdataWithRange:NSMakeRange(lengthToIncremenent, length)];
        }
        if ([characteristic isEqualToString:[[BLEBroadcaster messagesWriteCharacteristicUUID] UUIDString]]) {
            [_queue addObject:[[WriteData alloc] initWithData:[NSData data] peer:peer andCharacteristic:characteristic]];
        }
        if (_readyToUpdate) {
            [self sendNextChunk];
        }
    }
}

- (void)addSuccessBlockToQueue:(void (^)())success {
    [_queue addObject:success];
}

- (void)sendNextChunk {
    if (_queue.count) {
        if ([[_queue objectAtIndex:0] isKindOfClass:[WriteData class]]) {
            NSLog(@"sending next chunk from queue: %@", _queue);
            WriteData *writeData = [_queue objectAtIndex:0];
            if (!writeData.peer.peripheralConnected) {
                NSLog(@"Peripheral is not connected, aborting send.");
                return;
            }
            [_queue removeObjectAtIndex:0];
            _readyToUpdate = NO;
            [[BLETransportManager sharedManager].scanner writeMessage:writeData.data forPeer:writeData.peer onCharacteristic:writeData.characteristic];
        } else {
            void (^success)() = [_queue objectAtIndex:0];
            [_queue removeObjectAtIndex:0];
            success();
            [self sendNextChunk];
        }
    } else {
        _readyToUpdate = YES;
    }
}



@end
