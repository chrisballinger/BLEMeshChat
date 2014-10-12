//
//  UIViewController+BLE.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/12/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "UIViewController+BLE.h"

@implementation UIViewController (BLE)

- (BOOL)ble_isVisible {
    return [self isViewLoaded] && self.view.window;
}

@end
