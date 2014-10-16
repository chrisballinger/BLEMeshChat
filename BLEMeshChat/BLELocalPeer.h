//
//  BLELocalPeer.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEPeer.h"

@interface BLELocalPeer : BLEPeer

/** Ed25519 private key */
@property (nonatomic, strong, readonly) NSData *privateKeyData;

@end
