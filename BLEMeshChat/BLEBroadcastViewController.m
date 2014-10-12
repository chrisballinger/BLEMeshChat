//
//  BLEBroadcastViewController.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEBroadcastViewController.h"
#import "BLEBroadcaster.h"

@interface BLEBroadcastViewController ()
@end

@implementation BLEBroadcastViewController

- (instancetype) init {
    if (self = [super init]) {
        self.title = NSLocalizedString(@"Broadcast", nil);
        //[self setupBroadcaster];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

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
