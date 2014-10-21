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
#import "BLERemotePeer.h"
#import "BLEMessage.h"

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
    [self registerAllRemotePeersView];
    [self registerAllMessagesView];
}

- (void) registerAllRemotePeersView {
    _allRemotePeersViewName = @"BLEAllRemotePeersView";
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[BLERemotePeer class]]) {
            BLERemotePeer *remotePeer = object;
            return [remotePeer yapGroup];
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, BLERemotePeer *remotePeer1, NSString *collection2, NSString *key2, BLERemotePeer *remotePeer2) {
        return [remotePeer2.lastSeenDate compare:remotePeer1.lastSeenDate];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:[NSUUID UUID].UUIDString options:nil];
    [self.database asyncRegisterExtension:databaseView withName:self.allRemotePeersViewName completionBlock:^(BOOL ready) {
        DDLogInfo(@"%@ ready %d", self.allRemotePeersViewName, ready);
    }];
}

- (void) registerAllMessagesView {
    _allMessagesViewName = @"BLEAllMessagesView";
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[BLEMessage class]]) {
            BLEMessage *message = object;
            return [message yapGroup];
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, BLEMessage *message1, NSString *collection2, NSString *key2, BLEMessage *message2) {
        return [message2.lastSeenDate compare:message1.lastSeenDate];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:[NSUUID UUID].UUIDString options:nil];
    [self.database asyncRegisterExtension:databaseView withName:self.allMessagesViewName completionBlock:^(BOOL ready) {
        DDLogInfo(@"%@ ready %d", self.allMessagesViewName, ready);
    }];
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
