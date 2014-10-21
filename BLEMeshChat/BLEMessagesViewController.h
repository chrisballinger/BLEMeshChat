//
//  BLEMessagesViewController.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "JSQMessagesViewController.h"
#import "BLELocalPeer.h"

@interface BLEMessagesViewController : JSQMessagesViewController <UIActionSheetDelegate>

@property (nonatomic, strong) BLELocalPeer *localPeer;

@end
