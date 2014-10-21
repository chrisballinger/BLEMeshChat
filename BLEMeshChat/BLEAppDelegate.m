//
//  BLEAppDelegate.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEAppDelegate.h"
#import "BLERemotePeerTableViewController.h"
#import "BLEMessagesViewController.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "BLELocalPeer.h"
#import "BLEDatabaseManager.h"
#import "BLETransportManager.h"
#import "BLETransportStorage.h"

static NSString * const kBLEPrimaryLocalPeerKey = @"kBLEPrimaryLocalPeerKey";

@interface BLEAppDelegate ()
@property (nonatomic, strong) BLETransportManager *transportManager;
@property (nonatomic, strong) BLETransportStorage *transportStorage;
@end

@implementation BLEAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    NSArray *centralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey];
    if (centralManagerIdentifiers) {
        DDLogInfo(@"didFinishLaunchingWithOptions with UIApplicationLaunchOptionsBluetoothCentralsKey");
    }
    NSArray *peripheralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothPeripheralsKey];
    if (peripheralManagerIdentifiers) {
        DDLogInfo(@"didFinishLaunchingWithOptions with UIApplicationLaunchOptionsBluetoothPeripheralsKey");
    }
    if (centralManagerIdentifiers || peripheralManagerIdentifiers) {
        NSMutableString *body = [NSMutableString stringWithString:@"Launched with "];
        if (centralManagerIdentifiers) {
            [body appendString:@"central "];
        }
        if (peripheralManagerIdentifiers) {
            [body appendString:@"peripheral "];
        }
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertBody = body;
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
    
    __block BLELocalPeer *localPeer = nil;
    BLEKeyPair *keyPair = nil;
    NSString *primaryLocalPeerYapKey = [[NSUserDefaults standardUserDefaults] objectForKey:kBLEPrimaryLocalPeerKey];
    if (primaryLocalPeerYapKey) {
        [[BLEDatabaseManager sharedInstance].readWriteConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            localPeer = [transaction objectForKey:primaryLocalPeerYapKey inCollection:[BLELocalPeer yapCollection]];
        }];
    }
    if (!localPeer) {
        keyPair = [BLEKeyPair keyPairWithType:BLEKeyTypeEd25519];
        localPeer = [[BLELocalPeer alloc] initWithDisplayName:@"Test User" keyPair:keyPair];
        [[BLEDatabaseManager sharedInstance].readWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:localPeer forKey:primaryLocalPeerYapKey inCollection:[BLELocalPeer yapCollection]];
        }];
        [[NSUserDefaults standardUserDefaults] setObject:localPeer.yapKey forKey:kBLEPrimaryLocalPeerKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        keyPair = localPeer.keyPair;
    }
    self.transportStorage = [[BLETransportStorage alloc] init];
    self.transportManager = [[BLETransportManager alloc] initWithIdentity:localPeer keyPair:keyPair delegate:self.transportStorage delegateQueue:nil];
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    
    BLEMessagesViewController *chatVC = [BLEMessagesViewController messagesViewController];
    chatVC.localPeer = localPeer;
    UINavigationController *chatNav = [[UINavigationController alloc] initWithRootViewController:chatVC];
    chatVC.title = NSLocalizedString(@"Chat", nil);
    chatNav.tabBarItem.image = [UIImage imageNamed:@"BLEChatIcon"];
    
    BLERemotePeerTableViewController *peersVC = [[BLERemotePeerTableViewController alloc] initWithYapView:[BLEDatabaseManager sharedInstance].allRemotePeersViewName];
    UINavigationController *peersNav = [[UINavigationController alloc] initWithRootViewController:peersVC];
    peersVC.title = NSLocalizedString(@"Peers", nil);
    peersNav.tabBarItem.image = [UIImage imageNamed:@"BLEGroupIcon"];
    
    UIViewController *profileVC = [[UIViewController alloc] init];
    UINavigationController *profileNav = [[UINavigationController alloc] initWithRootViewController:profileVC];
    profileVC.title = NSLocalizedString(@"Profile", nil);
    profileNav.tabBarItem.image = [UIImage imageNamed:@"BLEUserProfileIcon"];
    
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[chatNav, peersNav, profileNav];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
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
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
