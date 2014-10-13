//
//  BLEDatabaseManager.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/11/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEDatabaseManager.h"
#import "YapDatabaseView.h"
#import "YapDatabaseViewTypes.h"
#import "BLEPeripheralDevice.h"

@implementation BLEDatabaseManager

- (instancetype) init {
    if (self = [super init]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        NSString *databaseDirectoryName = @"BLEMeshChat.database";
        NSString *databaseDirectoryPath = [applicationSupportDirectory stringByAppendingPathComponent:databaseDirectoryName];
        [[NSFileManager defaultManager] createDirectoryAtPath:databaseDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *databaseName = @"BLEMeshChat.sqlite";
        NSString *databasePath = [databaseDirectoryPath stringByAppendingPathComponent:databaseName];
        _database = [[YapDatabase alloc] initWithPath:databasePath];
        _readWriteConnection = [self.database newConnection];
        [self registerViews];
    }
    return self;
}

- (void) registerViews {
    [self registerAllDevicesView];
}

- (void) registerAllDevicesView {
    _allDevicesViewName = @"BLEAllDevicesView";
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, BLEPeripheralDevice *device) {
        NSTimeInterval oldnessThreshold = 60; // devices older than 60 sec are considered old
        NSTimeInterval timeIntervalSinceNow = [device.lastSeenDate timeIntervalSinceNow];
        if (timeIntervalSinceNow < -oldnessThreshold) {
            return [BLEPeripheralDevice pastGroupName];
        } else {
            return [BLEPeripheralDevice activeGroupName];
        }
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, BLEPeripheralDevice *device1, NSString *collection2, NSString *key2, BLEPeripheralDevice *device2) {
        return [device2.lastSeenDate compare:device1.lastSeenDate];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:[NSUUID UUID].UUIDString options:nil];
    [self.database asyncRegisterExtension:databaseView withName:self.allDevicesViewName completionBlock:nil];
}

+ (instancetype) sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

@end
