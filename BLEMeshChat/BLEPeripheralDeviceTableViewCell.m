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

- (void) updateConstraints {
    if (!self.hasAddedConstraints) {
        [self.displayNameLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(5, 5, 5, 5) excludingEdge:ALEdgeRight];
        [self.displayNameLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.signalStrengthLabel];
        [self.signalStrengthLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(5, 5, 5, 5) excludingEdge:ALEdgeLeft];
        [self.signalStrengthLabel autoSetDimension:ALDimensionWidth toSize:40.0f];
        self.hasAddedConstraints = YES;
    }
    [super updateConstraints];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setDevice:(BLEPeripheralDevice*)device {
    if (device.name) {
        self.displayNameLabel.text = device.name;
    } else {
        self.displayNameLabel.text = device.uniqueIdentifier;
    }
    self.signalStrengthLabel.text = device.lastSeenRSSI.stringValue;
}

@end
