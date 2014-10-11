//
//  BLEOutputChannel.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEOutputChannel : NSObject

@property (nonatomic, strong) CBMutableService *outputService;

@end
