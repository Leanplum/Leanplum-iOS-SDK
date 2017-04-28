//
//  LeanplumInternal.h
//  Leanplum
//
//  Created by Andrew First on 4/30/15.
//
//

#import "Leanplum.h"
#import "Constants.h"
#import "LPActionManager.h"
#import "LPJSON.h"

@class LeanplumSocket;
@class LPRegisterDevice;

#pragma mark - LPInternalState interface

@interface LPInternalState : NSObject
{
    NSMutableArray *_startBlocks, *_variablesChangedBlocks, *_interfaceChangedBlocks,
        *_eventsChangedBlocks, *_noDownloadsBlocks, *_onceNoDownloadsBlocks;
    NSMutableDictionary *_actionBlocks, *_actionResponders;
    NSMutableSet *_startResponders, *_variablesChangedResponders, *_interfaceChangedResponders,
        *_eventsChangedResponders, *_noDownloadsResponders;
    NSUncaughtExceptionHandler *_customExceptionHandler;
    LPRegisterDevice *_registration;
    BOOL _calledStart, _hasStarted, _hasStartedAndRegisteredAsDeveloper, _startSuccessful,
        _issuedStart;
    BOOL _initializedMessageTemplates;
    BOOL _stripViewControllerFromState;
    LPActionManager *_actionManager;
    NSString *_deviceId;
    NSString *_appVersion;
    NSMutableArray *_userAttributeChanges;
    BOOL _calledHandleNotification;
}

#pragma mark - LPInternalState properties

@property(strong, nonatomic) NSMutableArray *startBlocks, *variablesChangedBlocks,
    *interfaceChangedBlocks, *eventsChangedBlocks, *noDownloadsBlocks, *onceNoDownloadsBlocks,
    *startIssuedBlocks;
@property(strong, nonatomic) NSMutableDictionary *actionBlocks, *actionResponders;
@property(strong, nonatomic) NSMutableSet *startResponders, *variablesChangedResponders,
    *interfaceChangedResponders, *eventsChangedResponders, *noDownloadsResponders;
@property(assign, nonatomic) NSUncaughtExceptionHandler *customExceptionHandler;
@property(strong, nonatomic) LPRegisterDevice *registration;
@property(assign, nonatomic) BOOL calledStart, hasStarted, hasStartedAndRegisteredAsDeveloper,
    startSuccessful, issuedStart, initializedMessageTemplates, stripViewControllerFromState;
@property(strong, nonatomic) LPActionManager *actionManager;
@property(strong, nonatomic) NSString *deviceId;
@property(strong, nonatomic) NSString *appVersion;
@property(strong, nonatomic) NSMutableArray *userAttributeChanges;
@property(assign, nonatomic) BOOL calledHandleNotification;

#pragma mark - LPInternalState method declaration

+ (LPInternalState *)sharedState;

@end

#pragma mark - Leanplum class

@interface Leanplum ()

typedef void (^LeanplumStartIssuedBlock)();
typedef void (^LeanplumEventsChangedBlock)();
typedef void (^LeanplumHandledBlock)(BOOL success);

typedef enum {
    LPError,
    LPWarning,
    LPInfo,
    LPVerbose,
    LPInternal,
    LPDebug
} LPLogType;

+ (void)throwError:(NSString *)reason;

+ (void)onHasStartedAndRegisteredAsDeveloper;

+ (void)pause;
+ (void)resume;

+ (void)track:(NSString *)event
    withValue:(double)value
      andArgs:(NSDictionary *)args
andParameters:(NSDictionary *)params;

+ (void)track:(NSString *)event
    withValue:(double)value
      andInfo:(NSString *)info
      andArgs:(NSDictionary *)args
andParameters:(NSDictionary *)params;

+ (void)setUserLocationAttributeWithLatitude:(double)latitude
                                   longitude:(double)longitude
                                        city:(NSString *)city
                                      region:(NSString *)region
                                     country:(NSString *)country
                                        type:(LPLocationAccuracyType)type
                             responseHandler:(LeanplumSetLocationBlock)response;

+ (LPActionContext *)createActionContextForMessageId:(NSString *)messageId;
+ (void)triggerAction:(LPActionContext *)context;
+ (void)triggerAction:(LPActionContext *)context handledBlock:(LeanplumHandledBlock)handledBlock;
+ (void)maybePerformActions:(NSArray *)whenConditions
              withEventName:(NSString *)eventName
                 withFilter:(LeanplumActionFilter)filter
              fromMessageId:(NSString *)sourceMessage
       withContextualValues:(LPContextualValues *)contextualValues;

+ (NSInvocation *)createInvocationWithResponder:(id)responder selector:(SEL)selector;
+ (void)addInvocation:(NSInvocation *)invocation toSet:(NSMutableSet *)responders;
+ (void)removeResponder:(id)responder withSelector:(SEL)selector fromSet:(NSMutableSet *)responders;

+ (void)onStartIssued:(LeanplumStartIssuedBlock)block;
+ (void)onEventsChanged:(LeanplumEventsChangedBlock)block;
+ (void)synchronizeDefaults;

void LPLog(LPLogType type, NSString* format, ...);

@end

#pragma mark - LPInbox class

@interface LPInbox () {
@private
    BOOL _didLoad;
}

typedef void (^LeanplumInboxCacheUpdateBlock)();

#pragma mark - LPInbox properties

@property(assign, nonatomic) NSUInteger unreadCount;
@property(strong, nonatomic) NSMutableDictionary *messages;
@property(strong, nonatomic) NSMutableArray *inboxChangedBlocks;
@property(strong, nonatomic) NSMutableSet *inboxChangedResponders;
@property(strong, nonatomic) NSMutableSet *downloadedImageUrls;

#pragma mark - LPInbox method declaration

+ (LPInbox *)sharedState;

- (void)downloadMessages;
- (void)load;
- (void)save;
- (void)updateUnreadCount:(NSUInteger)unreadCount;
- (void)updateMessages:(NSMutableDictionary *)messages unreadCount:(NSUInteger)unreadCount;
- (void)removeMessageForId:(NSString *)messageId;
- (void)reset;
- (void)triggerInboxChanged;

@end

#pragma mark - LPInboxMessage class

@interface LPInboxMessage ()

#pragma mark - LPInboxMessage properties

@property(strong, nonatomic) NSString *messageId;
@property(strong, nonatomic) NSDate *deliveryTimestamp;
@property(strong, nonatomic) NSDate *expirationTimestamp;
@property(assign, nonatomic) BOOL isRead;
@property(strong, nonatomic) LPActionContext *context;

@end

#pragma mark - LPVar class

@interface LPVar ()

- (instancetype)initWithName:(NSString *)name withComponents:(NSArray *)components
            withDefaultValue:(NSObject *)defaultValue withKind:(NSString *)kind;

@property (readonly) BOOL private_IsInternal;
@property (readonly, strong) NSString *private_Name;
@property (readonly, strong) NSArray *private_NameComponents;
@property (readonly, strong) NSString *private_StringValue;
@property (readonly, strong) NSNumber *private_NumberValue;
@property (readonly) BOOL private_HadStarted;
@property (readonly, strong) id private_Value;
@property (readonly, strong) id private_DefaultValue;
@property (readonly, strong) NSString *private_Kind;
@property (readonly, strong) NSMutableArray *private_FileReadyBlocks;
@property (readonly, strong) NSMutableArray *private_valueChangedBlocks;
@property (readonly) BOOL private_FileIsPending;
@property (nonatomic, unsafe_unretained) id <LPVarDelegate> private_Delegate;
@property (readonly) BOOL private_HasChanged;

- (void) update;
- (void) cacheComputedValues;
- (void) triggerFileIsReady;
- (void) triggerValueChanged;

@end

#pragma mark - LPActionArg class

@interface LPActionArg ()

@property (readonly, strong) NSString *private_Name;
@property (readonly, strong) id private_DefaultValue;
@property (readonly, strong) NSString *private_Kind;

@end

#pragma mark - LPActionContext class

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
