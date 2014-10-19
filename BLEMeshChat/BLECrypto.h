//
//  BLECrypto.h
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, BLEKeyType) {
    BLEKeyTypeEd25519,
    BLEKeyTypeCurve25519
};

@interface BLEKeyPair : NSObject
@property (nonatomic, strong, readonly) NSData *publicKey;
@property (nonatomic, strong, readonly) NSData *privateKey;
@property (nonatomic, readonly) BLEKeyType type;
- (instancetype) initWithPublicKey:(NSData*)publicKey
                        privateKey:(NSData*)privateKey
                              type:(BLEKeyType)type;

/** Generates a new key pair, only Ed25519 is supported right now. */
+ (instancetype) keyPairWithType:(BLEKeyType)type;

@end

@interface BLECrypto : NSObject

+ (NSData*) signatureForData:(NSData*)data privateKey:(NSData*)privateKey;
+ (BOOL) verifyData:(NSData*)data signature:(NSData*)signature publicKey:(NSData*)publicKey;


/*
+ (BLEKeyPair*) convertKeyPair:(BLEKeyPair*)keyPair toType:(BLEKeyType)outputType;
+ (NSData*) convertPrivateKey:(NSData*)privateKey fromType:(BLEKeyType)fromType toType:(BLEKeyType)toType;
+ (NSData*) convertPublicKey:(NSData*)publicKey fromType:(BLEKeyType)fromType toType:(BLEKeyType)toType;
*/

+ (NSString*) libsodiumVersion;

@end

extern const NSUInteger kBLECryptoEd25519PublicKeyLength; // 32 bytes
extern const NSUInteger kBLECryptoEd25519PrivateKeyLength; // 64 bytes
extern const NSUInteger kBLECryptoEd25519SignatureLength; // 64 bytes
extern const NSUInteger kBLECryptoCurve25519PublicKeyLength; // 32 bytes
extern const NSUInteger kBLECryptoCurve25519PrivateKeyLength; // 32 bytes
