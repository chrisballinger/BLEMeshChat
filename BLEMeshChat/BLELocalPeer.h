//
//  BLELocalPeer.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLERemotePeer.h"
#import "BLEYapObjectProtocol.h"

extern NSString * const kBLEPrimaryLocalPeerKey;

@interface BLELocalPeer : BLERemotePeer

// static properties
/** Ed25519 private key */
@property (nonatomic, strong, readonly) NSData *privateKey;

// dynamic properties
@property (nonatomic, strong, readonly) BLEKeyPair *keyPair;

+ (NSString*) allIdentitiesGroupName;

+ (BLELocalPeer*) primaryIdentity;
+ (void) setPrimaryIdentity:(BLELocalPeer*)primaryIdentity;

@end

