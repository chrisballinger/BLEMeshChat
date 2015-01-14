//
//  BLEReadSendQueue.h
//  BLEMeshChat
//
//  Created by John Rogers on 1/3/15.
//  Copyright (c) 2015 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLERemotePeer.h"

@interface BLEReadSendQueue : NSObject

@property (strong, nonatomic) NSMutableArray *queue;
@property (nonatomic) BOOL readyToUpdate;

+ (instancetype)sharedManager;
- (void)sendNextChunk;
- (void)sentLastChunk;
- (void)addMessageToQueue:(NSData*)data forPeer:(BLERemotePeer*)peer;
- (void)addMessageToQueue:(NSData *)data forPeer:(BLERemotePeer *)peer success:(void (^)())success;
- (void)addSuccessBlockToQueue:(void (^)())success;

@end
