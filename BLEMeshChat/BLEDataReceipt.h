//
//  BLEDataReceipt.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 11/8/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "MTLModel.h"
#import "BLEYapObjectProtocol.h"

/** For knowing what data you've sent to peers, to prevent dupes */
@interface BLEDataReceipt : MTLModel <BLEYapObjectProtocol>

/** base64 of data signature */
@property (nonatomic, strong, readonly) NSString *dataYapKey;
/** base64 of peer public key */
@property (nonatomic, strong, readonly) NSString *peerYapKey;

- (instancetype) initWithPeer:(id<BLEYapObjectProtocol>)peer
                         data:(id<BLEYapObjectProtocol>)data;

+ (BOOL) receiptExistsForPeer:(id<BLEYapObjectProtocol>)peer
                         data:(id<BLEYapObjectProtocol>)data
              readTransaction:(YapDatabaseReadTransaction*)readTransaction;

+ (void) setReceiptFor:(id<BLEYapObjectProtocol>)peer
                  data:(id<BLEYapObjectProtocol>)data
  readWriteTransaction:(YapDatabaseReadWriteTransaction*)readWriteTransaction;

@end
