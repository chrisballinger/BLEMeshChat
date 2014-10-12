//
//  BLEDeviceTableViewCell.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/12/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEPeripheralDevice.h"

@interface BLEPeripheralDeviceTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) UILabel *displayNameLabel;
@property (nonatomic, strong, readonly) UILabel *signalStrengthLabel;

- (void) setDevice:(BLEPeripheralDevice*)device;

@end
