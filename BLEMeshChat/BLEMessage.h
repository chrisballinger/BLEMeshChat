//
//  BLEMessage.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEYapObject.h"

@interface BLEMessage : BLEYapObject

@property (nonatomic, strong, readonly) NSString *body;
@property (nonatomic, readonly) uint64_t timestamp;
@property (nonatomic, strong, readonly) NSData *signature;
@property (nonatomic, strong, readonly) NSDate *receivedDate;

@end
