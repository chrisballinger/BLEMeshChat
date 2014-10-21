//
//  BLERemotePeerTableViewCell.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/12/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEObservableProtocol.h"
#import "BLEYapObjectProtocol.h"

@class BLERemotePeer;

@interface BLERemotePeerTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) UILabel *displayNameLabel;
@property (nonatomic, strong, readonly) UILabel *lastSeenDateLabel;
@property (nonatomic, strong, readonly) UILabel *observationCountLabel;

- (void) setRemotePeer:(BLERemotePeer*)remotePeer;

+ (NSString*) cellIdentifier;

@end
