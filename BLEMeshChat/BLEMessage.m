//
//  BLEMessage.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEMessage.h"
#import "BLEDatabaseManager.h"

@implementation BLEMessage
@synthesize lastReceivedDate;
@synthesize lastBroadcastDate;
@synthesize numberOfTimesReceived;
@synthesize numberOfTimesBroadcast;
@dynamic senderYapKey;

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

- (NSString*) yapKey {
    return [self.signature base64EncodedStringWithOptions:0];
}

- (NSString*) yapGroup {
    return [self senderYapKey];
}

- (NSString*) senderYapKey {
    return [self.senderPublicKey base64EncodedStringWithOptions:0];
}

- (BLERemotePeer*) senderWithTransaction:(YapDatabaseReadTransaction*)transaction {
    BLERemotePeer *remotePeer = [transaction objectForKey:self.senderYapKey inCollection:[BLERemotePeer yapCollection]];
    return remotePeer;
}

#pragma mark JSQMessageData

/**
 *  @return A string identifier that uniquely identifies the user who sent the message.
 *
 *  @discussion If you need to generate a unique identifier, consider using
 *  `[[NSProcessInfo processInfo] globallyUniqueString]`
 *
 *  @warning You must not return `nil` from this method. This value must be unique.
 */
- (NSString *)senderId {
    return self.senderYapKey;
}

/**
 *  @return The display name for the user who sent the message.
 *
 *  @warning You must not return `nil` from this method.
 */
- (NSString *)senderDisplayName {
    NSString *displayName = nil;
    __block BLERemotePeer *sender = nil;
    NSString *key = self.senderYapKey;
    
    // It would probably be better to do this some other way
    [[BLEDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        sender = [transaction objectForKey:key inCollection:[BLERemotePeer yapCollection]];
    }];
    if (sender.displayName.length > 0) {
        displayName = [NSString stringWithFormat:@"%@ - %@", sender.displayName, self.senderYapKey];
    } else {
        displayName = self.senderYapKey;
    }
    return displayName;
}

/**
 *  @return The date that the message was sent.
 *
 *  @warning You must not return `nil` from this method.
 */
- (NSDate *)date {
    return self.timestampDate;
}

/**
 *  This method is used to determine if the message data item contains text or media.
 *  If this method returns `YES`, an instance of `JSQMessagesViewController` will ignore
 *  the `text` method of this protocol when dequeuing a `JSQMessagesCollectionViewCell`
 *  and only call the `media` method.
 *
 *  Similarly, if this method returns `NO` then the `media` method will be ignored and
 *  and only the `text` method will be called.
 *
 *  @return A boolean value specifying whether or not this is a media message or a text message.
 *  Return `YES` if this item is a media message, and `NO` if it is a text message.
 */
- (BOOL)isMediaMessage {
    return NO;
}


/**
 *  @return The body text of the message.
 *
 *  @warning You must not return `nil` from this method.
 */
- (NSString *)text {
    return self.messageBody;
}

@end
