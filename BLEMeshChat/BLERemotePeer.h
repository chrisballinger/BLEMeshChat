//
//  BLERemotePeer.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEIdentityPacket.h"
#import "BLEYapObjectProtocol.h"
#import "BLETransportStats.h"
#import "JSQMessageAvatarImageDataSource.h"

@interface BLERemotePeer : BLEIdentityPacket <BLEYapObjectProtocol, BLETransportStats, JSQMessageAvatarImageDataSource> {
    BOOL doneSendingMessages;
    BOOL doneReceivingMessages;
    NSTimer *reconnectTimer;
}

@property (nonatomic) BOOL isLocallyVerified;
@property (nonatomic, strong) NSString *deviceID;
@property (strong, nonatomic) NSMutableData *receivedData;
@property (nonatomic) BOOL centralConnected;

- (id)initWithDevice:(id)device;
- (NSString*)getDeviceID:(id)device;
- (void)addDevice:(id)device;
- (CBPeripheral*)peripheral;
- (CBCentral*)central;
- (BOOL)peripheralConnected;
- (BOOL)centralConnected;
- (void)doneSendingMessages;
- (void)doneReceivingMessages;
- (void)startReconnectTimer;

@end
