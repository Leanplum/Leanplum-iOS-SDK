//
//  LPABTest.h
//  Leanplum-iOS-Location-source
//
//  Created by Mayank Sanganeria on 6/20/18.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface LPABTest : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSNumber *id;
@property (nonatomic, copy, readonly) NSNumber *variantId;
@property (nonatomic, copy, readonly) NSDictionary *vars;

@end
