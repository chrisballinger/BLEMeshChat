//
//  BLEYapObjectTableViewController.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/11/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEYapObjectProtocol.h"

@interface BLERemotePeerTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readonly) UITableView *yapObjectTableView;

- (instancetype) initWithYapView:(NSString*)yapViewName;

@end
