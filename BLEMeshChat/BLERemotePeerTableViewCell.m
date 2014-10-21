//
//  BLERemotePeerTableViewCell.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/12/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLERemotePeerTableViewCell.h"
#import "BLERemotePeer.h"
#import "TTTTimeIntervalFormatter.h"

@interface BLERemotePeerTableViewCell()
@property (nonatomic) BOOL hasAddedConstraints;
@property (nonatomic, strong) TTTTimeIntervalFormatter *timeFormatter;
@end

@implementation BLERemotePeerTableViewCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _timeFormatter = [[TTTTimeIntervalFormatter alloc] init];
        [self setupDisplayNameLabel];
        [self setupLastSeenDateLabel];
        [self setupConnectionStateLabel];
        [self updateConstraintsIfNeeded];
    }
    return self;
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
    _observationCountLabel = [[UILabel alloc] init];
    self.observationCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.observationCountLabel];
}

- (void) updateConstraints {
    if (!self.hasAddedConstraints) {
        [self.displayNameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:5];
        [self.displayNameLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:5];
        [self.displayNameLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:5];
        [self.displayNameLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.lastSeenDateLabel];
        [self.lastSeenDateLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:5];
        [self.lastSeenDateLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:5];
        [self.lastSeenDateLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:5];
        [self.observationCountLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:5];
        [self.observationCountLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:5];
        [self.displayNameLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.lastSeenDateLabel];
        self.hasAddedConstraints = YES;
    }
    [super updateConstraints];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setRemotePeer:(BLERemotePeer*)remotePeer {
    NSString *displayName = nil;
    if (remotePeer.displayName.length) {
        displayName = [NSString stringWithFormat:@"%@ %@", remotePeer.displayName, remotePeer.yapKey];
    } else {
        displayName = remotePeer.yapKey;
    }
    self.displayNameLabel.text = displayName;
    NSString *lastSeenString = NSLocalizedString(@"Last seen", nil);
    
    self.lastSeenDateLabel.text = [NSString stringWithFormat:@"%@ %@", lastSeenString, [self.timeFormatter stringForTimeIntervalFromDate:[NSDate date] toDate:remotePeer.lastSeenDate]];
    self.observationCountLabel.text = [NSString stringWithFormat:@"%d", (int)remotePeer.numberOfTimesSeen];
}

+ (NSString*) cellIdentifier {
    return NSStringFromClass([self class]);
}

@end
