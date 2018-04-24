//
//  LPActionContext.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "Leanplum-Internal.h"

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

@property (readonly, strong) NSString *private_Name;
@property (readonly, strong) NSString *private_MessageId;
@property (readonly, strong) NSString *private_OriginalMessageId;
@property (readonly, strong) NSNumber *private_Priority;
@property (readonly, strong) NSDictionary *private_Args;
@property (readonly, strong) LPActionContext *private_ParentContext;
@property (readonly) int private_ContentVersion;
@property (readonly, strong) NSString *private_Key;
@property (readonly) BOOL private_PreventRealtimeUpdating;
@property (readonly) BOOL private_IsRooted;
@property (readonly) BOOL private_IsPreview;
@property (nonatomic, strong) LPContextualValues *contextualValues;

- (NSString *)messageId;
- (NSString *)originalMessageId;
- (NSNumber *)priority;
- (void)maybeDownloadFiles;
- (id)objectNamed:(NSString *)name;
- (void)preventRealtimeUpdating;
- (void)setIsRooted:(BOOL)value;
- (void)setIsPreview:(BOOL)preview;
- (NSDictionary *)args;
+ (void)sortByPriority:(NSMutableArray *)actionContexts;

@end
