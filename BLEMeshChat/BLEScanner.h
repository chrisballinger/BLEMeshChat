//
//  BLEScanner.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLECrypto.h"
#import "BLEIdentityPacket.h"
#import "BLEMessagePacket.h"
#import "BLEDataParser.h"
#import "BLEDataProvider.h"

@class BLEScanner;

@protocol BLEScannerDelegate <NSObject>
@required

- (void)      scanner:(BLEScanner*)scanner
      receivedMessage:(BLEMessagePacket*)message
             fromPeer:(BLEIdentityPacket*)peer;

- (void)       scanner:(BLEScanner*)scanner
      willWriteMessage:(BLEMessagePacket*)message
                toPeer:(BLEIdentityPacket*)peer;

- (void)       scanner:(BLEScanner*)scanner
      receivedIdentity:(BLEIdentityPacket*)identity
              fromPeer:(BLEIdentityPacket*)peer;

- (void)        scanner:(BLEScanner*)scanner
      willWriteIdentity:(BLEIdentityPacket*)identity
                 toPeer:(BLEIdentityPacket*)peer;

@end

@interface BLEScanner : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, weak, readonly) id<BLEScannerDelegate> delegate;
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;
@property (nonatomic, weak, readonly) id<BLEDataParser> dataParser;
@property (nonatomic, weak, readonly) id<BLEDataProvider> dataProvider;

- (instancetype) initWithKeyPair:(BLEKeyPair*)keyPair
                        delegate:(id<BLEScannerDelegate>)delegate
                   delegateQueue:(dispatch_queue_t)delegateQueue                       dataParser:(id<BLEDataParser>)dataParser
                    dataProvider:(id<BLEDataProvider>)dataProvider;
/**
 * Starts scanning.
 * @return success
 */
- (BOOL) startScanning;
- (void) stopScanning;

@end
