
#import "LPRequestFactory.h"
#import "LeanplumRequest.h"

@interface LPRequestFactory()

@property (nonatomic, strong) LPFeatureFlagManager *featureFlagManager;

@end

@implementation LPRequestFactory

-(instancetype)initWithFeatureFlagManager:(LPFeatureFlagManager *)featureFlagManager
{
    self = [super init];
    if (self) {
        _featureFlagManager = featureFlagManager;
    }
    return self;
}

- (id<LPRequesting>)createGetForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params {
    return [[LeanplumRequest alloc] initWithHttpMethod:@"GET" apiMethod:apiMethod params:params];
}

- (id<LPRequesting>)createPostForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params {
    return [[LeanplumRequest alloc] initWithHttpMethod:@"POST" apiMethod:apiMethod params:params];
}

@end
