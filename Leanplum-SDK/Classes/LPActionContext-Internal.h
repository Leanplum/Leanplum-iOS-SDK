//
//  LPActionContext.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LeanplumInternal.h"

@class LPContextualValues;

@interface LPActionContext ()

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId
                         originalMessageId:(NSString *)originalMessageId
                                  priority:(NSNumber *)priority;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *originalMessageId;
@property (nonatomic, strong) NSNumber *priority;
@property (nonatomic, strong) NSDictionary *args;
@property (nonatomic, strong) LPActionContext *parentContext;
@property (nonatomic, assign) int contentVersion;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, assign) BOOL shouldPreventRealtimeUpdating;
@property (nonatomic, assign) BOOL isRooted;
@property (nonatomic, assign) BOOL isPreview;
@property (nonatomic, strong) LPContextualValues *contextualValues;

- (void)maybeDownloadFiles;
- (id)objectNamed:(NSString *)name;
- (void)preventRealtimeUpdating;
- (void)setIsRooted:(BOOL)value;
- (void)setIsPreview:(BOOL)preview;
+ (void)sortByPriority:(NSMutableArray *)actionContexts;

@end
