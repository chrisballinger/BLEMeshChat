//
//  BLEInputChannel.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEInputChannel : NSObject

@property (nonatomic, strong) CBMutableService *inputService;

@end
