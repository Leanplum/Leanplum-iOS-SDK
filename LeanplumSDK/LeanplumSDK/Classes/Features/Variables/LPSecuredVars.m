//
//  LPSecuredVars.m
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 5/31/21.
//

#import "LPSecuredVars.h"
#import "LeanplumInternal.h"

@interface LPSecuredVars()
@property (nonatomic, retain) NSString *json;
@property (nonatomic, retain) NSString *signature;
@end

@implementation LPSecuredVars

- (instancetype)initWithJson:(NSString*)json andSignature:(NSString*)signature
{
    self = [super init];
    if (self) {
        _json = json;
        _signature = signature;
    }
    return self;
}

- (NSString *)varsJson
{
    return self.json;
}

- (NSString *)varsSignature
{
    return self.signature;
}

@end
