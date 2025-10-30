//
//  LPSecuredVars.h
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 5/31/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPSecuredVars : NSObject

- (instancetype)initWithJson:(NSString*)json andSignature:(NSString*)signature;
- (NSString *)varsJson;
- (NSString *)varsSignature;

@end

NS_ASSUME_NONNULL_END
