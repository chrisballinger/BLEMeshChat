//
//  BLEReadSendQueue.m
//  BLEMeshChat
//
//  Created by John Rogers on 1/3/15.
//  Copyright (c) 2015 Christopher Ballinger. All rights reserved.
//

#import "BLEReadSendQueue.h"
#import "BLETransportManager.h"

@interface ReadData : NSObject

@property (strong, nonatomic) BLERemotePeer *peer;
@property (strong, nonatomic) NSData *data;

@end

@implementation ReadData

- (id)initWithData:(NSData*)data forPeer:(BLERemotePeer*)peer {
    self = [super init];
    _data = data;
    _peer = peer;
    return self;
}

@end

@implementation BLEReadSendQueue

+ (instancetype)sharedManager {
    static BLEReadSendQueue *sharedMyManager = nil;
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

- (void)addMessageToQueue:(NSData*)data forPeer:(BLERemotePeer*)peer {
    while (data.length) {
        NSLog(@"adding data of length %lu to read queue", (unsigned long)data.length);
        NSUInteger lengthToIncremenent = [peer central].maximumUpdateValueLength < data.length ? [peer central].maximumUpdateValueLength : data.length;
        NSData *chunk = [data subdataWithRange:NSMakeRange(0, lengthToIncremenent)];
        NSLog(@"adding chunk of length %lu to read queue", (unsigned long)chunk.length);
        [_queue addObject:[[ReadData alloc] initWithData:chunk forPeer:peer]];
        NSInteger length = data.length - lengthToIncremenent;
        data = [data subdataWithRange:NSMakeRange(lengthToIncremenent, length)];
    }
    [_queue addObject:[[ReadData alloc] initWithData:[NSData data] forPeer:peer]];
    NSLog(@"ready to update?");
    if (_readyToUpdate) {
        NSLog(@"ready to update");
        [self sendNextChunk];
    }
}

- (void)addMessageToQueue:(NSData *)data forPeer:(BLERemotePeer *)peer success:(void (^)())success {
    while (data.length) {
        NSLog(@"adding data of length %lu to read queue", (unsigned long)data.length);
        NSUInteger lengthToIncremenent = [peer central].maximumUpdateValueLength < data.length ? [peer central].maximumUpdateValueLength : data.length;
        NSData *chunk = [data subdataWithRange:NSMakeRange(0, lengthToIncremenent)];
        NSLog(@"adding chunk of length %lu to read queue", (unsigned long)chunk.length);
        [_queue addObject:[[ReadData alloc] initWithData:chunk forPeer:peer]];
        NSInteger length = data.length - lengthToIncremenent;
        data = [data subdataWithRange:NSMakeRange(lengthToIncremenent, length)];
    }
    [_queue addObject:[[ReadData alloc] initWithData:[NSData data] forPeer:peer]];
    success();
    NSLog(@"ready to update?");
    if (_readyToUpdate) {
        NSLog(@"ready to update");
        [self sendNextChunk];
    }
}

- (void)addSuccessBlockToQueue:(void (^)())success {
    [_queue addObject:success];
    NSLog(@"read queue after adding: %@", _queue);
}

- (void)sendNextChunk {
    if (_queue.count) {
        if ([[_queue objectAtIndex:0] isKindOfClass:[ReadData class]]) {
            NSLog(@"sending next read chunk from queue: %@", _queue);
            ReadData *readData = [_queue objectAtIndex:0];
            _readyToUpdate = NO;
            [[BLETransportManager sharedManager].broadcaster writeMessage:readData.data forPeer:readData.peer];
        } else {
            NSLog(@"found success block");
            void (^success)() = [_queue objectAtIndex:0];
            [_queue removeObjectAtIndex:0];
            success();
            [self sendNextChunk];
        }
    } else {
        _readyToUpdate = YES;
    }
}

- (void)sentLastChunk {
    [_queue removeObjectAtIndex:0];
    _readyToUpdate = YES;
}

@end
