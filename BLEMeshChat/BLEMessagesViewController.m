//
//  BLEMessagesViewController.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEMessagesViewController.h"
#import "BLEMessage.h"
#import "BLEDatabaseManager.h"
#import "JSQMessagesTimestampFormatter.h"
#import "JSQMessagesAvatarImageFactory.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "UIColor+JSQMessages.h"
#import "BLERemotePeerTableViewController.h"
#import "IASKAppSettingsViewController.h"

@interface BLEMessagesViewController()
@property (nonatomic, strong, readonly) YapDatabaseConnection *readConnection;
@property (nonatomic, strong, readonly) YapDatabaseViewMappings *mappings;

@property (strong, nonatomic, readonly) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic, readonly) JSQMessagesBubbleImage *incomingBubbleImageData;
@end

@implementation BLEMessagesViewController

#pragma mark - View lifecycle

/**
 *  Override point for customization.
 *
 *  Customize your view.
 *  Look at the properties on `JSQMessagesViewController` and `JSQMessagesCollectionView` to see what is possible.
 *
 *  Customize your layout.
 *  Look at the properties on `JSQMessagesCollectionViewFlowLayout` to see what is possible.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    _outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    _incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(25, 25);
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeMake(25, 25);
    /**
     *  You MUST set your senderId and display name
     */
    self.senderId = self.localPeer.yapKey;
    self.senderDisplayName = self.localPeer.displayName;
    [self setupMappings];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BLEUserProfileIcon"] style:UIBarButtonItemStyleBordered target:self action:@selector(profileButtonPressed:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BLEGroupIcon"] style:UIBarButtonItemStyleBordered target:self action:@selector(peersButtonPressed:)];
}

- (void) peersButtonPressed:(id)sender {
    
    BLERemotePeerTableViewController *peersVC = [[BLERemotePeerTableViewController alloc] initWithYapView:[BLEDatabaseManager sharedInstance].allRemotePeersViewName];
    peersVC.title = NSLocalizedString(@"Peers", nil);
    [self.navigationController pushViewController:peersVC animated:YES];
}

- (void) profileButtonPressed:(id)sender {
    IASKAppSettingsViewController *profileVC = [[IASKAppSettingsViewController alloc] init];
    profileVC.title = NSLocalizedString(@"Profile", nil);
    [self.navigationController pushViewController:profileVC animated:YES];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    BLEMessage *message = [[BLEMessage alloc] initWithMessageBody:text keyPair:self.localPeer.keyPair];
    NSString *key = message.yapKey;
    NSString *collection = [[message class] yapCollection];
    [[BLEDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:message forKey:key inCollection:collection];
    } completionBlock:^{
        [self finishSendingMessage];
    }];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Send photo", @"Send location", @"Send video", nil];
    
    [sheet showFromToolbar:self.inputToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    switch (buttonIndex) {
        case 0:
            //[self.demoData addPhotoMediaMessage];
            break;
            
        case 1:
        {
            //__weak UICollectionView *weakView = self.collectionView;
            
            //[self.demoData addLocationMediaMessageCompletion:^{
            //    [weakView reloadData];
            //}];
        }
            break;
            
        case 2:
            //[self.demoData addVideoMediaMessage];
            break;
    }
    
    [self finishSendingMessage];
}

- (BLEMessage*) messageForIndexPath:(NSIndexPath*)indexPath {
    __block BLEMessage *message = nil;
    
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        message = [[transaction extension:[BLEDatabaseManager sharedInstance].allMessagesViewName] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    NSAssert(message != nil, @"Message must not be nil!");
    return message;
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self messageForIndexPath:indexPath];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BLEMessage *message = [self messageForIndexPath:indexPath];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    __block BLERemotePeer *sender = nil;
    
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        BLEMessage *message = [[transaction extension:[BLEDatabaseManager sharedInstance].allMessagesViewName] objectAtIndexPath:indexPath withMappings:self.mappings];
        sender = [message senderWithTransaction:transaction];
    }];
    return sender;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        BLEMessage *message = [self messageForIndexPath:indexPath];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    BLEMessage *message = [self messageForIndexPath:indexPath];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
        BLEMessage *previousMessage = [self messageForIndexPath:previousIndexPath];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.mappings numberOfItemsInSection:section];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    BLEMessage *msg = [self messageForIndexPath:indexPath];
    
    
    if ([msg.senderId isEqualToString:self.senderId]) {
        cell.textView.textColor = [UIColor blackColor];
    }
    else {
        cell.textView.textColor = [UIColor whiteColor];
    }
    
    cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                          NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    cell.textView.text = msg.messageBody;
    
    return cell;
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    BLEMessage *currentMessage = [self messageForIndexPath:indexPath];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
        BLEMessage *previousMessage = [self messageForIndexPath:previousIndexPath];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark YapDatabase


- (void) setupMappings {
    _readConnection = [[BLEDatabaseManager sharedInstance].database newConnection];
    _mappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:[BLEDatabaseManager sharedInstance].allMessagesViewName];
    
    // Freeze our databaseConnection on the current commit.
    // This gives us a snapshot-in-time of the database,
    // and thus a stable data source for our UI thread.
    [self.readConnection beginLongLivedReadTransaction];
    
    // Initialize our mappings.
    // Note that we do this after we've started our database longLived transaction.
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        
        // Calling this for the first time will initialize the mappings,
        // and will allow mappings to cache certain information
        // such as the counts for each section.
        [self.mappings updateWithTransaction:transaction];
    }];
    
    // And register for notifications when the database changes.
    // Our method will be invoked on the main-thread,
    // and will allow us to move our stable data-source from our existing state to an updated state.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.readConnection.database];
    
    [self.collectionView reloadData];
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    
    NSArray *notifications = [self.readConnection beginLongLivedReadTransaction];
    
    // If the view isn't visible, we might decide to skip the UI animation stuff.
    if (![self ble_isVisible])
    {
        // Since we moved our databaseConnection to a new commit,
        // we need to update the mappings too.
        [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
            [self.mappings updateWithTransaction:transaction];
        }];
        return;
    }
    
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    //
    // Note: the getSectionChanges:rowChanges:forNotifications:withMappings: method
    // automatically invokes the equivalent of [mappings updateWithTransaction:] for you.
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    NSString *allMessagesViewName = [BLEDatabaseManager sharedInstance].allMessagesViewName;
    
    [[self.readConnection ext:allMessagesViewName] getSectionChanges:&sectionChanges
                                                             rowChanges:&rowChanges
                                                       forNotifications:notifications
                                                           withMappings:self.mappings];
    
    // No need to update mappings.
    // The above method did it automatically.
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        return;
    }
    
    // Replace this with fancypants animations
    [self.collectionView reloadData];
}


@end
