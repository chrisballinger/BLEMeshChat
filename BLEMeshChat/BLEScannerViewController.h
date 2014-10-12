//
//  BLEScannerViewController.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/11/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLEScanner;

@interface BLEScannerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *deviceTableView;
@property (nonatomic, strong) BLEScanner *scanner;

@end
