//
//  BLEScannerViewController.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/11/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEScannerViewController.h"
#import "BLEScanner.h"

static NSString * const kBLEDeviceCellIdentifier = @"kBLEDeviceCellIdentifier";

@interface BLEScannerViewController ()
@property (nonatomic) BOOL hasUpdatedConstraints;
@end

@implementation BLEScannerViewController

- (instancetype) init {
    if (self = [super init]) {
        self.title = NSLocalizedString(@"Scan", nil);
        [self setupScanner];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDeviceTableView];
    [self.view updateConstraintsIfNeeded];
}

- (void) setupScanner {
    self.scanner = [[BLEScanner alloc] init];
    [self.scanner startScanning];
}

- (void) setupDeviceTableView {
    self.deviceTableView = [[UITableView alloc] init];
    self.deviceTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.deviceTableView.delegate = self;
    self.deviceTableView.dataSource = self;
    [self.deviceTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kBLEDeviceCellIdentifier];
    [self.view addSubview:self.deviceTableView];
}

- (void) updateViewConstraints {
    [super updateViewConstraints];
    if (self.hasUpdatedConstraints) {
        return;
    }
    [self.deviceTableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    self.hasUpdatedConstraints = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableViewDelegate methods

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kBLEDeviceCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = @"Test";
    return cell;
}

@end
