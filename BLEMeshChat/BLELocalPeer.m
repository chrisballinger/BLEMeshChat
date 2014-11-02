//
//  BLELocalPeer.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/15/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLELocalPeer.h"
#import "BLEDatabaseManager.h"

NSString * const kBLEPrimaryLocalPeerKey = @"kBLEPrimaryLocalPeerKey";

@implementation BLELocalPeer
@dynamic keyPair, displayName;

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

- (NSString*) yapKey {
    return [self.senderPublicKey base64EncodedStringWithOptions:0];
}

- (NSString*) yapGroup {
    return [[self class] allIdentitiesGroupName];
}

+ (NSString*) allIdentitiesGroupName {
    return @"all";
}

- (instancetype) initWithDisplayName:(NSString*)displayName keyPair:(BLEKeyPair*)keyPair {
    if (self = [super initWithDisplayName:displayName keyPair:keyPair]) {
        _privateKey = keyPair.privateKey;
    }
    return self;
}

- (BLEKeyPair*) keyPair {
    return [[BLEKeyPair alloc] initWithPublicKey:self.senderPublicKey privateKey:self.privateKey type:BLEKeyTypeEd25519];
}

+ (BLELocalPeer*) primaryIdentity {
    NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:kBLEPrimaryLocalPeerKey];
    if (!key) {
        return nil;
    }
    __block BLELocalPeer *localPeer = nil;
    [[BLEDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        localPeer = [transaction objectForKey:key inCollection:[BLELocalPeer yapCollection]];
    }];
    return localPeer;
}

+ (void) setPrimaryIdentity:(BLELocalPeer *)primaryIdentity {
    [[BLEDatabaseManager sharedInstance].readWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:primaryIdentity forKey:primaryIdentity.yapKey inCollection:[BLELocalPeer yapCollection]];
    }];
    [[NSUserDefaults standardUserDefaults] setObject:primaryIdentity.yapKey forKey:kBLEPrimaryLocalPeerKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
