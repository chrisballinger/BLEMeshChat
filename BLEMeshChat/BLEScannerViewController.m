//
//  BLEScannerViewController.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/11/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEScannerViewController.h"
#import "BLEScanner.h"
#import "BLEDatabaseManager.h"
#import "BLEPeripheralDevice.h"
#import "BLEPeripheralDeviceTableViewCell.h"

static NSString * const kBLEPeripheralDeviceCellIdentifier = @"kBLEPeripheralDeviceCellIdentifier";

@interface BLEScannerViewController ()
@property (nonatomic) BOOL hasUpdatedConstraints;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseConnection *readConnection;
@property (nonatomic, strong) NSString *allDevicesViewName;
@end

@implementation BLEScannerViewController

- (instancetype) init {
    if (self = [super init]) {
        self.title = NSLocalizedString(@"Scan", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDeviceTableView];
    [self setupMappings];
    [self.view updateConstraintsIfNeeded]; // why is this needed?
}

- (void) setupDeviceTableView {
    _deviceTableView = [[UITableView alloc] init];
    self.deviceTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.deviceTableView.delegate = self;
    self.deviceTableView.dataSource = self;
    self.deviceTableView.rowHeight = 80.0f;
    [self.deviceTableView registerClass:[BLEPeripheralDeviceTableViewCell class] forCellReuseIdentifier:kBLEPeripheralDeviceCellIdentifier];
    [self.view addSubview:self.deviceTableView];
}

- (void) updateViewConstraints {
    [super updateViewConstraints];
    if (self.hasUpdatedConstraints) {
        return;
    }
    [self.deviceTableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    self.hasUpdatedConstraints = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableViewDelegate methods

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    NSInteger numberOfSections = [self.mappings numberOfSections];
    return numberOfSections;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = [self.mappings numberOfItemsInSection:section];
    return numberOfRows;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Active";
    } else if (section == 1) {
        return @"History";
    }
    return @"";
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BLEPeripheralDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kBLEPeripheralDeviceCellIdentifier forIndexPath:indexPath];
    __block BLEPeripheralDevice *device = nil;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        device = [[transaction extension:self.allDevicesViewName] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    [cell setDevice:device];
    return cell;
}

#pragma mark YapDatabase

- (void) setupMappings {
    self.readConnection = [[BLEDatabaseManager sharedInstance].database newConnection];
    self.allDevicesViewName = [BLEDatabaseManager sharedInstance].allDevicesViewName;
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        if ([group isEqualToString:[BLEPeripheralDevice activeGroupName]]) {
            return YES;
        }
        return NO;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.allDevicesViewName];
    
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
    
    [[self.readConnection ext:self.allDevicesViewName] getSectionChanges:&sectionChanges
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
    
    [self.deviceTableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.deviceTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.deviceTableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove:
            {
                break;
            }
            case YapDatabaseViewChangeUpdate:
            {
                break;
            }
        }
    }
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.deviceTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.deviceTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.deviceTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.deviceTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.deviceTableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.deviceTableView endUpdates];
}

@end
