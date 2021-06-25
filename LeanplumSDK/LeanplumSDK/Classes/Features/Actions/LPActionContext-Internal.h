//
//  LPActionContext.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LeanplumInternal.h"
#import "LPActionContext.h"

NS_ASSUME_NONNULL_BEGIN

@class LPContextualValues;

@interface LPActionContext ()

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(nullable NSDictionary *)args
                                 messageId:(nullable NSString *)messageId;

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(nullable NSDictionary *)args
                                 messageId:(nullable NSString *)messageId
                         originalMessageId:(nullable NSString *)originalMessageId
                                  priority:(nullable NSNumber *)priority;

@property (readonly, strong) NSString *name;
@property (readonly, strong) NSString *originalMessageId;
@property (readonly, strong) NSNumber *priority;
@property (readonly) int contentVersion;
@property (readonly, strong, nullable) NSString *key;
@property (assign) BOOL preventRealtimeUpdating;
@property (nonatomic, assign) BOOL isRooted;
@property (nonatomic, assign) BOOL isPreview;
@property (nonatomic, strong) LPContextualValues *contextualValues;

- (void)maybeDownloadFiles;
- (void)preventRealtimeUpdating;
+ (void)sortByPriority:(NSMutableArray *)actionContexts;

@end

NS_ASSUME_NONNULL_END
