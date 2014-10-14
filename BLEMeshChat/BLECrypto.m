//
//  BLECrypto.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/13/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLECrypto.h"
#import <sodium.h>

const NSUInteger kBLECryptoEd25519PublicKeyLength = crypto_sign_ed25519_PUBLICKEYBYTES; // 32 bytes
const NSUInteger kBLECryptoEd25519PrivateKeyLength = crypto_sign_ed25519_SECRETKEYBYTES; // 64 bytes
const NSUInteger kBLECryptoEd25519SignatureKeyLength = crypto_sign_ed25519_BYTES; // 64 bytes
const NSUInteger kBLECryptoCurve25519KeyLength = crypto_scalarmult_curve25519_BYTES; // 32 bytes

@interface BLEKeyPair()
@property (nonatomic, strong, readwrite) NSData *publicKey;
@property (nonatomic, strong, readwrite) NSData *privateKey;
@property (nonatomic, readwrite) BLEKeyType type;
@end
@implementation BLEKeyPair
@end

@implementation BLECrypto


+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sodium_init() == -1) {
            @throw [NSException exceptionWithName:@"BLESodiumException" reason:@"sodium_init failed!" userInfo:nil];
        }
    });
}


+ (BLEKeyPair*) generateKeyPair {
    // Can we use sodium_malloc for privateKeyBytes?
    uint8_t *publicKeyBytes = malloc(sizeof(uint8_t) * kBLECryptoEd25519PublicKeyLength);
    uint8_t *privateKeyBytes = malloc(sizeof(uint8_t) * kBLECryptoEd25519PrivateKeyLength);
    crypto_sign_keypair(publicKeyBytes, privateKeyBytes);
    NSData *publicKeyData = [NSData dataWithBytesNoCopy:publicKeyBytes length:kBLECryptoEd25519PublicKeyLength freeWhenDone:YES];
    NSData *privateKeyData = [NSData dataWithBytesNoCopy:privateKeyBytes length:kBLECryptoEd25519PrivateKeyLength freeWhenDone:YES];
    BLEKeyPair *keyPair = [[BLEKeyPair alloc] init];
    keyPair.publicKey = publicKeyData;
    keyPair.privateKey = privateKeyData;
    keyPair.type = BLEKeyTypeEd25519;
    return keyPair;
}

+ (NSData*) signData:(NSData*)data privateKey:(NSData*)privateKey {
    NSAssert(data.length != 0, @"Data to be signed should have a length!");
    NSAssert(privateKey.length == kBLECryptoEd25519PrivateKeyLength, @"privateKey should be 64 bytes!");
    if (data.length == 0 || privateKey.length != kBLECryptoEd25519PrivateKeyLength) {
        return nil;
    }
    size_t dataWithSignatureMaxLength = data.length + sizeof(uint8_t) * kBLECryptoEd25519SignatureKeyLength;
    uint8_t *dataWithSignatureBytes = malloc(dataWithSignatureMaxLength);
    
    uint64_t dataWithSignatureActualLength = 0;
    
    crypto_sign(dataWithSignatureBytes, &dataWithSignatureActualLength,
                data.bytes, data.length, privateKey.bytes);
    
    NSData *dataWithSignature = [NSData dataWithBytesNoCopy:dataWithSignatureBytes length:dataWithSignatureActualLength freeWhenDone:YES];
    return dataWithSignature;
}

+ (NSData*) verifyData:(NSData*)dataWithSignature publicKey:(NSData*)publicKey {
    NSAssert(dataWithSignature.length != 0, @"dataWithSignature should have a length!");
    NSAssert(publicKey.length == kBLECryptoEd25519PublicKeyLength, @"publicKey should be 32 bytes");
    if (dataWithSignature.length == 0 || publicKey.length != kBLECryptoEd25519PublicKeyLength) {
        return nil;
    }
    uint8_t *dataBytes = malloc(dataWithSignature.length);
    uint64_t dataActualLength = 0;
    if (crypto_sign_open(dataBytes, &dataActualLength,
                         dataWithSignature.bytes, dataWithSignature.length, publicKey.bytes) == 0) {
        NSData *data = [NSData dataWithBytesNoCopy:dataBytes length:dataActualLength freeWhenDone:YES];
        return data;
    }
    return nil;
}

- (BLEKeyPair*) convertKeyPair:(BLEKeyPair*)keyPair toType:(BLEKeyType)outputType {
    NSAssert(keyPair.type == BLEKeyTypeEd25519, @"Cannot convert Curve25519 to Ed25519");
    NSAssert(outputType == BLEKeyTypeCurve25519, @"Cannot convert Curve25519 to Ed25519");
    if (keyPair.type != BLEKeyTypeEd25519 || outputType != BLEKeyTypeCurve25519) {
        return nil;
    }
    NSAssert(keyPair != nil, @"keyPair must not be nil!");
    if (!keyPair) {
        return nil;
    }

    uint8_t *publicKeyBytes = malloc(sizeof(uint8_t) * kBLECryptoCurve25519KeyLength);

    //crypto_sign_ed25519_pk_to_curve25519(publicKeyBytes, ed25519_pk);
    return nil;
}

- (NSData*) convertPrivateKey:(NSData*)privateKey fromType:(BLEKeyType)fromType toType:(BLEKeyType)toType {
    NSAssert(privateKey.length == kBLECryptoEd25519PrivateKeyLength, @"privateKey must be 32 bytes!");
    NSAssert(fromType == BLEKeyTypeEd25519 && toType == BLEKeyTypeCurve25519, @"Must be converting from Ed25519 to Curve 25519");
    if (privateKey.length != kBLECryptoEd25519PrivateKeyLength) {
        return nil;
    }
    uint8_t *privateKeyBytes = malloc(sizeof(uint8_t) * kBLECryptoCurve25519KeyLength);
    crypto_sign_ed25519_sk_to_curve25519(privateKeyBytes, privateKey.bytes);
    NSData *curve25519PrivateKey = [NSData dataWithBytesNoCopy:privateKeyBytes length:kBLECryptoCurve25519KeyLength freeWhenDone:YES];
    return curve25519PrivateKey;
}

/*
- (NSData*) convertPublicKey:(NSData*)publicKey fromType:(BLEKeyType)fromType toType:(BLEKeyType)toType {
    NSAssert(privateKey.length == kBLECryptoEd25519PrivateKeyLength, @"privateKey must be 32 bytes!");
    NSAssert(fromType == BLEKeyTypeEd25519 && toType == BLEKeyTypeCurve25519, @"Must be converting from Ed25519 to Curve 25519");
    if (privateKey.length != kBLECryptoEd25519PrivateKeyLength) {
        return nil;
    }
    uint8_t *privateKeyBytes = malloc(sizeof(uint8_t) * kBLECryptoCurve25519KeyLength);
    crypto_sign_ed25519_sk_to_curve25519(privateKeyBytes, privateKey.bytes);
    NSData *curve25519PrivateKey = [NSData dataWithBytesNoCopy:privateKeyBytes length:kBLECryptoCurve25519KeyLength freeWhenDone:YES];
    return curve25519PrivateKey;
}
 */

+ (NSString*) libsodiumVersion {
    return [NSString stringWithUTF8String:SODIUM_VERSION_STRING];
}

@end
