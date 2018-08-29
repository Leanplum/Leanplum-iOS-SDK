#import <Foundation/Foundation.h>
#import "LPRequesting.h"
#import "LPFeatureFlagManager.h"

@interface LPRequestFactory : NSObject

-(instancetype)initWithFeatureFlagManager:(LPFeatureFlagManager *)featureFlagManager;

- (id<LPRequesting>)createGetForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params;
- (id<LPRequesting>)createPostForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params;

@end
