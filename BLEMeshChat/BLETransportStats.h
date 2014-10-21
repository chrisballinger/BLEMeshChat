//
//  BLETransportStats.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/20/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLETransportStats <NSObject>
@required

@property (nonatomic, strong) NSDate *lastSeenDate;
@property (nonatomic) NSUInteger numberOfTimesReceived;
@property (nonatomic) NSUInteger numberOfTimesBroadcast;


@end
