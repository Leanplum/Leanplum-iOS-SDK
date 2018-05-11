//
//  LPActionArg.m
//  Leanplum-iOS-SDK-source
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "LeanplumInternal.h"
#import "Utils.h"
#import "LPVarCache.h"

@implementation LPActionArg : NSObject

@synthesize private_Name=_name;
@synthesize private_Kind=_kind;
@synthesize private_DefaultValue=_defaultValue;

+ (LPActionArg *)argNamed:(NSString *)name with:(NSObject *)defaultValue kind:(NSString *)kind
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPVar argNamed:with:kind:] Empty name parameter provided."];
        return nil;
    }
    LPActionArg *arg = [LPActionArg new];
    LP_TRY
    arg->_name = name;
    arg->_kind = kind;
    arg->_defaultValue = defaultValue;
    if ([kind isEqualToString:LP_KIND_FILE]) {
        [LPVarCache registerFile:(NSString *) defaultValue
                withDefaultValue:(NSString *) defaultValue];
    }
    LP_END_TRY
    return arg;
}

+ (LPActionArg *)argNamed:(NSString *)name withNumber:(NSNumber *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_FLOAT];
}

+ (LPActionArg *)argNamed:(NSString *)name withString:(NSString *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_STRING];
}

+ (LPActionArg *)argNamed:(NSString *)name withBool:(BOOL)defaultValue
{
    return [self argNamed:name with:@(defaultValue) kind:LP_KIND_BOOLEAN];
}

+ (LPActionArg *)argNamed:(NSString *)name withFile:(NSString *)defaultValue
{
    if (defaultValue == nil) {
        defaultValue = @"";
    }
    return [self argNamed:name with:defaultValue kind:LP_KIND_FILE];
}

+ (LPActionArg *)argNamed:(NSString *)name withDict:(NSDictionary *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_DICTIONARY];
}

+ (LPActionArg *)argNamed:(NSString *)name withArray:(NSArray *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_ARRAY];
}

+ (LPActionArg *)argNamed:(NSString *)name withAction:(NSString *)defaultValue
{
    if (defaultValue == nil) {
        defaultValue = @"";
    }
    return [self argNamed:name with:defaultValue kind:LP_KIND_ACTION];
}

+ (LPActionArg *)argNamed:(NSString *)name withColor:(UIColor *)defaultValue
{
    return [self argNamed:name with:@(leanplum_colorToInt(defaultValue)) kind:LP_KIND_COLOR];
}

- (NSString *)name
{
    return _name;
}

- (id)defaultValue
{
    return _defaultValue;
}

- (NSString *)kind
{
    return _kind;
}

@end
