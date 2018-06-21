//
//  LPVariantDebugInfo.m
//  Leanplum-iOS-Location-source
//
//  Created by Mayank Sanganeria on 6/20/18.
//

#import "LPVariantDebugInfo.h"
#import "LPABTest.h"

@implementation LPVariantDebugInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"abTests": @"abTests"
             };
}

+ (NSValueTransformer *)abTestsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:LPABTest.class];
}

@end
