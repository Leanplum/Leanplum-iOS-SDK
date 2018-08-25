#import <Foundation/Foundation.h>
#import "LPRequesting.h"

@interface LPRequestFactory : NSObject

+ (id<LPRequesting>)get:(NSString *)apiMethod params:(NSDictionary *)params;
+ (id<LPRequesting>)post:(NSString *)apiMethod params:(NSDictionary *)params;

@end
