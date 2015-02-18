//
//  BLEWriteSendQueue.h
//  BLEMeshChat
//
//  Created by John Rogers on 1/3/15.
//  Copyright (c) 2015 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLERemotePeer.h"

@interface BLEWriteSendQueue : NSObject

@property (strong, nonatomic) NSMutableArray *queue;
@property (nonatomic) BOOL readyToUpdate;

+ (instancetype)sharedManager;
- (void)addMessageToQueue:(NSData*)data forPeer:(BLERemotePeer*)peer onCharacteristic:(NSString*)characteristic;
- (void)addSuccessBlockToQueue:(void (^)())success;
- (void)sendNextChunk;

@end
