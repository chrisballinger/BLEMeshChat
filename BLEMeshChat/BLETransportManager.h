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
#import "BLEIdentityPacket.h"

@interface BLETransportManager : NSObject

@property (nonatomic, strong, readonly) BLEBroadcaster *broadcaster;
@property (nonatomic, strong, readonly) BLEScanner *scanner;

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair;

- (void) start;
- (void) stop;

- (void) broadcastMessagePacket:(BLEMessagePacket*)messagePacket;
- (void) broadcastIdentityPacket:(BLEIdentityPacket*)identityPacket;

@end
