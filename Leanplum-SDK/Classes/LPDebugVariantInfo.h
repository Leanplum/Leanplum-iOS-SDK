//
//  LPDebugVariantInfo.h
//  Leanplum-iOS-Location-source
//
//  Created by Mayank Sanganeria on 6/20/18.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@class LPABTest;

@interface LPDebugVariantInfo : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSArray<LPABTest *> *abTests;

@end
