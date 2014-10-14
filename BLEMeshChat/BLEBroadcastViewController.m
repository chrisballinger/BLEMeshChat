//
//  BLEBroadcastViewController.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEBroadcastViewController.h"
#import "BLEBroadcaster.h"

#import <sodium/core.h>
#import <sodium/crypto_sign.h>

@interface BLEBroadcastViewController ()
@end

@implementation BLEBroadcastViewController

- (instancetype) init {
    if (self = [super init]) {
        self.title = NSLocalizedString(@"Broadcast", nil);
        [self setupBroadcaster];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*if (sodium_init() == -1) {
        DDLogError(@"Sodium failed to initialize!");
    }*/

#define MESSAGE (const unsigned char *) "test"
#define MESSAGE_LEN 4
    
    unsigned char pk[crypto_sign_PUBLICKEYBYTES];
    unsigned char sk[crypto_sign_SECRETKEYBYTES];
    crypto_sign_keypair(pk, sk);
    
    unsigned char sealed_message[crypto_sign_BYTES + MESSAGE_LEN];
    unsigned long long sealed_message_len;
    
    crypto_sign(sealed_message, &sealed_message_len,
                MESSAGE, MESSAGE_LEN, sk);
    
    unsigned char unsealed_message[MESSAGE_LEN];
    unsigned long long unsealed_message_len;
    if (crypto_sign_open(unsealed_message, &unsealed_message_len,
                         sealed_message, sealed_message_len, pk) != 0) {
        DDLogInfo(@"Incorrect signature!");
    } else {
        DDLogInfo(@"Signature correct!");
    }
}

- (void) setupBroadcaster {
    self.broadcaster = [[BLEBroadcaster alloc] init];
    [self.broadcaster startBroadcasting];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
