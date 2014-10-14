//
//  BLEPeer.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEYapObject.h"

@interface BLEPeer : BLEYapObject

/** Ed25519 public key */
@property (nonatomic, strong, readonly) NSData *publicKeyData;
@property (nonatomic, strong) NSString *displayName;

@end
