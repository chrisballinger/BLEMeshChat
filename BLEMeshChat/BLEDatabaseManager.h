//
//  BLEDatabaseManager.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/11/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEDatabaseManager : NSObject

@property (nonatomic, strong, readonly) YapDatabase *database;
@property (nonatomic, strong, readonly) YapDatabaseConnection *readWriteConnection;

@property (nonatomic, strong, readonly) NSString *allDevicesViewName;

+ (instancetype) sharedInstance;

@end
