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
        _readConnection = [self.database newConnection];
        [self registerViews];
    }
    return self;
}

- (void) registerViews {
    [self registerAllRemotePeersView];
    [self registerAllMessagesView];
    [self registerOutgoingMessagesView];
    
}

- (void) registerAllRemotePeersView {
    _allRemotePeersViewName = @"BLEAllRemotePeersView";
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[BLERemotePeer class]]) {
            BLERemotePeer *remotePeer = object;
            if (remotePeer.lastReceivedDate) {
                return [remotePeer yapGroup];
            }
            return nil;
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, BLERemotePeer *remotePeer1, NSString *collection2, NSString *key2, BLERemotePeer *remotePeer2) {
        return [remotePeer2.lastReceivedDate compare:remotePeer1.lastReceivedDate];
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
            return @"all";
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, BLEMessage *message1, NSString *collection2, NSString *key2, BLEMessage *message2) {
        return [message1.timestampDate compare:message2.timestampDate];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:[NSUUID UUID].UUIDString options:nil];
    [self.database asyncRegisterExtension:databaseView withName:self.allMessagesViewName completionBlock:^(BOOL ready) {
        DDLogInfo(@"%@ ready %d", self.allMessagesViewName, ready);
    }];
}

- (void) registerOutgoingMessagesView {
    _outgoingMessagesViewName = @"BLEOutgoingMessagesView";
    // Group by sender
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[BLEMessage class]]) {
            BLEMessage *message = object;
            NSString *base64SenderPublicKey = [message.senderPublicKey base64EncodedStringWithOptions:0];
            return base64SenderPublicKey;
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, BLEMessage *message1, NSString *collection2, NSString *key2, BLEMessage *message2) {
        NSComparisonResult result = [@(message1.numberOfTimesBroadcast) compare:@(message2.numberOfTimesBroadcast)];
        if (result == NSOrderedSame) {
            result = [message1.lastBroadcastDate compare:message2.lastBroadcastDate];
        }
        return result;
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:[NSUUID UUID].UUIDString options:nil];
    [self.database asyncRegisterExtension:databaseView withName:self.outgoingMessagesViewName completionBlock:^(BOOL ready) {
        DDLogInfo(@"%@ ready %d", self.outgoingMessagesViewName, ready);
    }];
}

- (void) registerOutgoingPeersView {
    _outgoingPeersViewName = @"BLEOutgoingPeersView";
    // Send all types of identities
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[BLEIdentityPacket class]]) {
            return @"all";
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id<BLETransportStats> peer1, NSString *collection2, NSString *key2, id<BLETransportStats> peer2) {
        NSComparisonResult result = [@(peer2.numberOfTimesBroadcast) compare:@(peer1.numberOfTimesBroadcast)];
        if (result == NSOrderedSame) {
            result = [peer2.lastBroadcastDate compare:peer1.lastBroadcastDate];
        }
        return result;
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:[NSUUID UUID].UUIDString options:nil];
    [self.database asyncRegisterExtension:databaseView withName:self.outgoingPeersViewName completionBlock:^(BOOL ready) {
        DDLogInfo(@"%@ ready %d", self.outgoingPeersViewName, ready);
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
