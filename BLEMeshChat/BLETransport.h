//
//  BLETransport.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 11/8/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEDataStorage.h"
#import "BLECrypto.h"

/** 
 * Abstract class for a Bluetooth Transport encompassing both
 * peripheral mode and central mode.
 * @see BLEScanner
 * @see BLEBroadcaster
 */
@interface BLETransport : NSObject

@property (nonatomic, weak, readonly) id<BLEDataStorage> dataStorage;

- (instancetype) initWithDataStorage:(id<BLEDataStorage>)dataStorage;

/**
 * @return success
 */
- (BOOL) start;
- (void) stop;

@end
