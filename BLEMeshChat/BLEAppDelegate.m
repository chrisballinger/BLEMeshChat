//
//  BLEAppDelegate.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEAppDelegate.h"
#import "BLEMessagesViewController.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "BLELocalPeer.h"
#import "BLEDatabaseManager.h"
#import "BLETransportManager.h"
#import "BLETransportStorage.h"

@interface BLEAppDelegate ()
@property (nonatomic, strong) BLETransportManager *transportManager;
@property (nonatomic, strong) BLETransportStorage *transportStorage;
@end

@implementation BLEAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    /*
    [[BLEDatabaseManager sharedInstance].readWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeAllObjectsInAllCollections];
    }];
    */
     
    NSArray *centralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey];
    if (centralManagerIdentifiers) {
        DDLogInfo(@"didFinishLaunchingWithOptions with UIApplicationLaunchOptionsBluetoothCentralsKey %@", centralManagerIdentifiers);
    }
    NSArray *peripheralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothPeripheralsKey];
    if (peripheralManagerIdentifiers) {
        DDLogInfo(@"didFinishLaunchingWithOptions with UIApplicationLaunchOptionsBluetoothPeripheralsKey %@", peripheralManagerIdentifiers);
    }
    
    BLELocalPeer *localPeer = [BLELocalPeer primaryIdentity];
    BLEKeyPair *keyPair = nil;
    if (localPeer) {
        keyPair = localPeer.keyPair;
    }
    NSString *publicName = [[NSUserDefaults standardUserDefaults] objectForKey:@"kBLEPublicNameKey"];
    
    if (!localPeer || (localPeer && ![localPeer.displayName isEqualToString:publicName])) {
        if (publicName.length == 0) {
            publicName = NSLocalizedString(@"Test User", nil);
        }
        if (!keyPair) {
            DDLogWarn(@"No existing keys found, generating new ones");
            keyPair = [BLEKeyPair keyPairWithType:BLEKeyTypeEd25519];
        }
        localPeer = [[BLELocalPeer alloc] initWithDisplayName:publicName keyPair:keyPair];
        [BLELocalPeer setPrimaryIdentity:localPeer];
    }
    self.transportStorage = [[BLETransportStorage alloc] init];
    self.transportManager = [[BLETransportManager sharedManager] addDataStorage:self.transportStorage];
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    BLEMessagesViewController *chatVC = [BLEMessagesViewController messagesViewController];
    chatVC.title = NSLocalizedString(@"Chat", nil);
    chatVC.localPeer = localPeer;
    UINavigationController *chatNav = [[UINavigationController alloc] initWithRootViewController:chatVC];
    
    self.window.rootViewController = chatNav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    DDLogInfo(@"Received local notification: %@", notification);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[BLETransportManager sharedManager] disconnectFromPeers];
    [BLETransportManager sharedManager].remoteDevices = nil;
    [[BLEDatabaseManager sharedInstance].readWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction enumerateKeysInCollection:[[BLERemotePeer class] yapCollection] usingBlock:^(NSString *key, BOOL *stop) {
            BLERemotePeer *peer = [transaction objectForKey:key inCollection:[[BLERemotePeer class] yapCollection]];
            //NSLog(@"possible messages to send: %@", message);
            peer.deviceID = nil;
        }];
    }];
}

@end
