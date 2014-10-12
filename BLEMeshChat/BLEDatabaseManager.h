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

@end
