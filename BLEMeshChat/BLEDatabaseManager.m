//
//  BLEDatabaseManager.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/11/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEDatabaseManager.h"

@implementation BLEDatabaseManager

- (instancetype) init {
    if (self = [super init]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        NSString *databaseName = @"BLEMeshChat.sqlite";
        NSString *databasePath = [applicationSupportDirectory stringByAppendingPathComponent:databaseName];
        _database = [[YapDatabase alloc] initWithPath:databasePath];
    }
    return self;
}

@end
