//
//  BLEObservableProtocol.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/20/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLEObservableProtocol <NSObject>
@required

@property (nonatomic, strong) NSDate *lastSeenDate;
@property (nonatomic) NSUInteger numberOfTimesSeen;

@end
