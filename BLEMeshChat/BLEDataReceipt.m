//
//  BLEDataReceipt.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 11/8/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEDataReceipt.h"

@implementation BLEDataReceipt

- (instancetype) initWithPeer:(id<BLEYapObjectProtocol>)peer
                         data:(id<BLEYapObjectProtocol>)data {
    if (self = [super init]) {
        _peerYapKey = peer.yapKey;
        _dataYapKey = data.yapKey;
    }
    return self;
}

+ (NSString*) yapKeyForPeerYapKey:(NSString*)peerYapKey
                       dataYapKey:(NSString*)messageYapKey {
    return [NSString stringWithFormat:@"%@-%@",peerYapKey, messageYapKey];
}

/** Returns the YapDatabase collection */
+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

/** Returns the YapDatabase key */
- (NSString*) yapKey {
    return [[self class] yapKeyForPeerYapKey:self.peerYapKey dataYapKey:self.dataYapKey];
}

/** Returns the YapDatabase group */
- (NSString*) yapGroup {
    return @"all";
}

+ (BOOL) receiptExistsForPeer:(id<BLEYapObjectProtocol>)peer
                         data:(id<BLEYapObjectProtocol>)data
              readTransaction:(YapDatabaseReadTransaction*)readTransaction {
    if (!peer || !data) {
        return NO;
    }
    __block BOOL exists = NO;
    NSString *key = [[self class] yapKeyForPeerYapKey:peer.yapKey dataYapKey:data.yapKey];
    BLEDataReceipt *receipt = [readTransaction objectForKey:key inCollection:[BLEDataReceipt yapCollection]];
    if (receipt) {
        exists = YES;
    }
    return exists;
}

+ (void) setReceiptForPeer:(id<BLEYapObjectProtocol>)peer
                      data:(id<BLEYapObjectProtocol>)data
      readWriteTransaction:(YapDatabaseReadWriteTransaction*)readWriteTransaction {
    BLEDataReceipt *receipt = [[BLEDataReceipt alloc] initWithPeer:peer data:data];
    [readWriteTransaction setObject:receipt forKey:receipt.yapKey inCollection:[[receipt class] yapCollection]];
}

@end
