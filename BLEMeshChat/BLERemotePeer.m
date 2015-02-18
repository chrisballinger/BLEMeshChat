//
//  BLERemotePeer.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLERemotePeer.h"
#import "IGGitHubIdenticon.h"
#import "BLETransportManager.h"

@interface BLERemotePeer()
@property (nonatomic, strong, readonly) UIImage *generatedAvatarImage;
@end

@implementation BLERemotePeer
@synthesize lastReceivedDate;
@synthesize lastBroadcastDate;
@synthesize numberOfTimesReceived;
@synthesize numberOfTimesBroadcast;

- (id)initWithDevice:(id)device {
    self = [super init];
    _deviceID = [self getDeviceID:device];
    _receivedData = [[NSMutableData alloc] init];
    NSMutableDictionary *deviceDictionary = [NSMutableDictionary dictionary];
    if ([device isKindOfClass:[CBPeripheral class]]) {
        [deviceDictionary setObject:device forKey:[NSNumber numberWithInt:PeripheralDevice]];
    } else if ([device isKindOfClass:[CBCentral class]]) {
        [deviceDictionary setObject:device forKey:[NSNumber numberWithInt:CentralDevice]];
    }
    [[BLETransportManager sharedManager].remoteDevices setObject:deviceDictionary forKey:_deviceID];
    return self;
}

- (NSString*)getDeviceID:(id)device {
    CBUUID *identifier = (CBUUID*)[device identifier];
    return identifier.UUIDString;
}

- (void)addDevice:(id)device {
    if (device == [self peripheral] || device == [self central]) return;
    NSMutableDictionary *deviceDict = [[BLETransportManager sharedManager].remoteDevices objectForKey:_deviceID];
    if (!deviceDict) {
        deviceDict = [NSMutableDictionary dictionary];
    }
    if ([device isKindOfClass:[CBPeripheral class]]) {
        [deviceDict setObject:device forKey:[NSNumber numberWithInt:PeripheralDevice]];
    } else if ([device isKindOfClass:[CBCentral class]]) {
        [deviceDict setObject:device forKey:[NSNumber numberWithInt:CentralDevice]];
    }
    [[BLETransportManager sharedManager].remoteDevices setObject:deviceDict forKey:_deviceID];
}


- (CBPeripheral*)peripheral {
    CBPeripheral *peripheral = [[[BLETransportManager sharedManager].remoteDevices objectForKey:_deviceID] objectForKey:[NSNumber numberWithInt:PeripheralDevice]];
    return peripheral;
}

- (CBCentral*)central {
    CBCentral *central = [[[BLETransportManager sharedManager].remoteDevices objectForKey:_deviceID] objectForKey:[NSNumber numberWithInt:CentralDevice]];
    return central;
}

- (BOOL)peripheralConnected {
    return ([self peripheral].state == CBPeripheralStateConnected);
}

- (BOOL)centralConnected {
    return _centralConnected;
}

- (void)doneSendingMessages {
    NSLog(@"done sending");
    doneSendingMessages = YES;
    if (doneReceivingMessages) {
        NSLog(@"should disconnect");
        [[BLETransportManager sharedManager] disconnectFromPeer:self];
    }
}

- (void)doneReceivingMessages {
    NSLog(@"done receiving");
    doneReceivingMessages = YES;
    if (doneSendingMessages) {
        NSLog(@"should disconnect");
        [[BLETransportManager sharedManager] disconnectFromPeer:self];
    }
}

- (void)startReconnectTimer {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 10.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        doneReceivingMessages = NO;
        doneSendingMessages = NO;
        [[BLETransportManager sharedManager] reconnectToPeer:self];
    });
}

#pragma mark BLEYapObjectProtocol methods

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

- (NSString*) yapKey {
    if (self.senderPublicKey) {
        return [self.senderPublicKey base64EncodedStringWithOptions:0];
    } else {
        return [BLETransportManager randomString:10];
    }
}

- (NSString*) yapGroup {
    return @"all";
}

#pragma mark JSQMessageAvatarImageDataSource methods

/**
 *  @return The avatar image for a regular display state.
 *
 *  @discussion You may return `nil` from this method while the image is being downloaded.
 */
- (UIImage *)avatarImage {
    if (!self.generatedAvatarImage) {
        _generatedAvatarImage = [IGGitHubIdenticon identiconWithString:self.yapKey size:150];
    }
    return self.generatedAvatarImage;
}

/**
 *  @return The avatar image for a highlighted display state.
 *
 *  @discussion You may return `nil` from this method if this does not apply.
 */
- (UIImage *)avatarHighlightedImage {
    return nil;
}

/**
 *  @return A placeholder avatar image to be displayed if avatarImage is not yet available, or `nil`.
 *  For example, if avatarImage needs to be downloaded, this placeholder image
 *  will be used until avatarImage is not `nil`.
 *
 *  @discussion If you do not need support for a placeholder image, that is, your images
 *  are stored locally on the device, then you may simply return the same value as avatarImage here.
 *
 *  @warning You must not return `nil` from this method.
 */
- (UIImage *)avatarPlaceholderImage {
    return self.avatarImage;
}

@end
