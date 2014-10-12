//
//  BLEMainViewController.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEMainViewController.h"
#import "BLEBroadcaster.h"
#import "BLEScanner.h"

@interface BLEMainViewController ()
@property (nonatomic, strong) BLEBroadcaster *broadcaster;
@property (nonatomic, strong) BLEScanner *scanner;
@end

@implementation BLEMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.broadcaster = [[BLEBroadcaster alloc] init];
    [self.broadcaster startBroadcasting];
    //self.scanner = [[BLEScanner alloc] init];
    //[self.scanner startScanning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
