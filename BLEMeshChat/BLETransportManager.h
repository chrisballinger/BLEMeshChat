//
//  BLETransportManager.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEBroadcaster.h"
#import "BLEScanner.h"
#import "BLECrypto.h"
#import "BLERemotePeer.h"
#import "BLEDataStorage.h"

@class BLETransportManager;

typedef NS_ENUM(NSInteger, DeviceType) {
    CentralDevice,
    PeripheralDevice
};

//clean this up...

typedef NS_ENUM(NSInteger, ConnectionGuardType) {
    CentralGuard,
    PeripheralGuard
};

@interface BLETransportManager : NSObject

@property (nonatomic, weak, readonly) id<BLEDataStorage> dataStorage;
@property (nonatomic, strong) NSMutableDictionary *remoteDevices;
@property (nonatomic, strong, readonly) BLEBroadcaster *broadcaster;
@property (nonatomic, strong, readonly) BLEScanner *scanner;

+ (instancetype)sharedManager;
- (instancetype)addDataStorage:(id<BLEDataStorage>)dataStorage;
+ (void)doubleConnectionGuard:(BLERemotePeer*)peer type:(ConnectionGuardType)type success:(void (^)())success failure:(void (^)())failure;
+ (NSString*)randomString:(int)length;

- (void) start;
- (void) stop;
- (void) sendMessage;
- (void) disconnectFromPeers;
- (void) disconnectFromPeer:(BLERemotePeer*)peer;
- (void) reconnectToPeer:(BLERemotePeer*)peer;

@end
