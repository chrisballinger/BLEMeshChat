//
//  BLERemotePeer.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLERemotePeer.h"
#import "IGGitHubIdenticon.h"

@interface BLERemotePeer()
@property (nonatomic, strong, readonly) UIImage *generatedAvatarImage;
@end

@implementation BLERemotePeer
@synthesize lastReceivedDate;
@synthesize lastBroadcastDate;
@synthesize numberOfTimesReceived;
@synthesize numberOfTimesBroadcast;

#pragma mark BLEYapObjectProtocol methods

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

- (NSString*) yapKey {
    return [self.senderPublicKey base64EncodedStringWithOptions:0];
}

- (NSString*) yapGroup {
    return @"all";
}

#pragma mark JSQMessageAvatarImageDataSource methods

/**
 *  @return The avatar image for a regular display state.
 *
 *  @discussion You may return `nil` from this method while the image is being downloaded.
 */
- (UIImage *)avatarImage {
    if (!self.generatedAvatarImage) {
        _generatedAvatarImage = [IGGitHubIdenticon identiconWithString:self.yapKey size:150];
    }
    return self.generatedAvatarImage;
}

/**
 *  @return The avatar image for a highlighted display state.
 *
 *  @discussion You may return `nil` from this method if this does not apply.
 */
- (UIImage *)avatarHighlightedImage {
    return nil;
}

/**
 *  @return A placeholder avatar image to be displayed if avatarImage is not yet available, or `nil`.
 *  For example, if avatarImage needs to be downloaded, this placeholder image
 *  will be used until avatarImage is not `nil`.
 *
 *  @discussion If you do not need support for a placeholder image, that is, your images
 *  are stored locally on the device, then you may simply return the same value as avatarImage here.
 *
 *  @warning You must not return `nil` from this method.
 */
- (UIImage *)avatarPlaceholderImage {
    return self.avatarImage;
}

@end
