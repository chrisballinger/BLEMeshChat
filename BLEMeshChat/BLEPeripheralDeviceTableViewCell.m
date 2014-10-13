//
//  BLEDeviceTableViewCell.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/12/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEPeripheralDeviceTableViewCell.h"

@interface BLEPeripheralDeviceTableViewCell()
@property (nonatomic) BOOL hasAddedConstraints;
@end

@implementation BLEPeripheralDeviceTableViewCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupDisplayNameLabel];
        [self setupSignalStrengthLabel];
        [self setupLastSeenDateLabel];
        [self setupConnectionStateLabel];
        [self updateConstraintsIfNeeded];
    }
    return self;
}

- (void) setupSignalStrengthLabel {
    _signalStrengthLabel = [[UILabel alloc] init];
    self.signalStrengthLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.signalStrengthLabel];
}

- (void) setupDisplayNameLabel {
    _displayNameLabel = [[UILabel alloc] init];
    self.displayNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.displayNameLabel];
}

- (void) setupLastSeenDateLabel {
    _lastSeenDateLabel = [[UILabel alloc] init];
    self.lastSeenDateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.lastSeenDateLabel];
}

- (void) setupConnectionStateLabel {
    _connectionStateLabel = [[UILabel alloc] init];
    self.connectionStateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.connectionStateLabel];
}

- (void) updateConstraints {
    if (!self.hasAddedConstraints) {
        [self.displayNameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:5];
        [self.displayNameLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:5];
        [self.displayNameLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.lastSeenDateLabel];
        [self.displayNameLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.signalStrengthLabel];
        [self.signalStrengthLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:5];
        [self.signalStrengthLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:5];
        [self.signalStrengthLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.connectionStateLabel];
        [self.signalStrengthLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.displayNameLabel];
        [self.lastSeenDateLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:5];
        [self.lastSeenDateLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:5];
        [self.connectionStateLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:5];
        [self.connectionStateLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:5];
        [self.displayNameLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.lastSeenDateLabel];
        [self.signalStrengthLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.connectionStateLabel];
        [self.signalStrengthLabel autoSetDimension:ALDimensionWidth toSize:30];
        self.hasAddedConstraints = YES;
    }
    [super updateConstraints];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setDevice:(BLEPeripheralDevice*)device {
    NSString *name = nil;
    if (device.name) {
        name = [device.name stringByAppendingFormat:@" %@", device.uniqueIdentifier];
    } else {
        name = device.uniqueIdentifier;
    }
    self.displayNameLabel.text = name;
    self.signalStrengthLabel.text = device.lastSeenRSSI.stringValue;
    self.lastSeenDateLabel.text = device.lastSeenDate.description;
    self.connectionStateLabel.text = [NSString stringWithFormat:@"%d", (int)device.numberOfTimesSeen];
}

@end
