//
//  LPActionContext.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//  Copyright (c) 2023 Leanplum, Inc. All rights reserved.

#import "LeanplumInternal.h"
#import "LPVarCache.h"
#import "LPFileManager.h"
#import "LPUtils.h"
#import "LPCountAggregator.h"
#import <Leanplum/Leanplum-Swift.h>

typedef void (^LPFileCallback)(NSString* value, NSString *defaultValue);

@interface LPActionContext (PrivateProperties)

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *originalMessageId;
@property (nonatomic, strong) NSNumber *priority;
@property (nonatomic, strong) NSDictionary *args;
@property (nonatomic, strong) LPActionContext *parentContext;
@property (nonatomic) int contentVersion;
@property (nonatomic, strong) NSString *key;
@property (nonatomic) BOOL preventRealtimeUpdating;

@end

@interface LPActionContext()

@property (nonatomic, strong) LPCountAggregator *countAggregator;
@property (strong, nonatomic) LeanplumActionBlock actionNamedResponder;

@end


@implementation LPActionContext

@synthesize args=_args;

- (instancetype)initWithName:(NSString *)name
                        args:(NSDictionary *)args
                   messageId:(NSString *)messageId
           originalMessageId:(NSString *)originalMessageId
                    priority:(NSNumber *)priority
{
    self = [super init];
    if (self) {
        _name = name;
        _args = args;
        _messageId = messageId;
        _originalMessageId = originalMessageId;
        _contentVersion = [[LPVarCache sharedCache] contentVersion];
        _preventRealtimeUpdating = NO;
        _isRooted = YES;
        _isPreview = NO;
        _priority = priority;
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    
    return self;
}

- (instancetype)init:(NSString *)name
                args:(NSDictionary *)args
           messageId:(NSString *)messageId
preventRealtimeUpdating:(BOOL)preventRealtimeUpdating;
{
    self = [self initWithName:name
                         args:args
                    messageId:messageId
            originalMessageId:nil
                     priority:[NSNumber numberWithInt:DEFAULT_PRIORITY]];
    _preventRealtimeUpdating = preventRealtimeUpdating;
    
    return self;
}

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId
{
    return [LPActionContext actionContextWithName:name
                                             args:args
                                        messageId:messageId
                                originalMessageId:nil
                                         priority:[NSNumber numberWithInt:DEFAULT_PRIORITY]];
}

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId
                         originalMessageId:(NSString *)originalMessageId
                                  priority:(NSNumber *)priority

{
    return [[LPActionContext alloc] initWithName:name
                                            args:args
                                       messageId:messageId
                               originalMessageId:originalMessageId
                                        priority:priority];
}

- (NSDictionary *)defaultValues
{
    return [[[LPActionManager shared] definitionWithName:_name] values];
}

/**
 * Downloads missing files that are part of this action.
 */
- (void)maybeDownloadFiles
{
    NSDictionary *kinds = [[[LPActionManager shared] definitionWithName:_name] kinds];
    [[LPActionManager shared] downloadFilesWithActionArgs:_args defaultValues:[self defaultValues] definitionKinds:kinds];
}

- (BOOL)hasMissingFiles
{
    NSDictionary *kinds = [[[LPActionManager shared] definitionWithName:_name] kinds];
    return [[LPActionManager shared] hasMissingFilesWithActionArgs:_args defaultValues:[self defaultValues] definitionKinds:kinds];
}

- (NSString *)actionName
{
    return _name;
}

- (NSDictionary *)args
{
    [self setProperArgs];
    return [_args copy];
}

- (void)setProperArgs
{
    if (!_preventRealtimeUpdating && [[LPVarCache sharedCache] contentVersion] > _contentVersion) {
        LPActionContext *parent = _parentContext;
        if (parent) {
            _args = [parent getChildArgs:_key];
        } else if (_messageId) {
            NSDictionary *message = [[LPActionManager shared] messages][_messageId];
            if (message) {
                _args = message[LP_KEY_VARS];
            }
        }
    }
}

- (id)objectNamed:(NSString *)name
{
    LP_TRY
    [self setProperArgs];
    return [[LPVarCache sharedCache] getValueFromComponentArray:[[LPVarCache sharedCache] getNameComponents:name]
                                                       fromDict:_args];
    LP_END_TRY
    return nil;
}

- (NSString *)stringNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext stringNamed:] Empty name parameter provided."];
        return nil;
    }
    return [self fillTemplate:[[self objectNamed:name] description]];
}

- (NSString *)fillTemplate:(NSString *)value
{
    if (!_contextualValues || !value || [value rangeOfString:@"##"].location == NSNotFound) {
        return value;
    }
    
    NSDictionary *parameters = _contextualValues.parameters;
    
    for (NSString *parameterName in [parameters keyEnumerator]) {
        NSString *placeholder = [NSString stringWithFormat:@"##Parameter %@##", parameterName];
        value = [value stringByReplacingOccurrencesOfString:placeholder
                                                 withString:[parameters[parameterName]
                                                             description]];
    }
    if (_contextualValues.previousAttributeValue) {
        value = [value
                 stringByReplacingOccurrencesOfString:@"##Previous Value##"
                 withString:[_contextualValues
                     .previousAttributeValue description]];
    }
    if (_contextualValues.attributeValue) {
        value = [value stringByReplacingOccurrencesOfString:@"##Value##"
                                                 withString:[_contextualValues.attributeValue
                                                             description]];
    }
    return value;
}

/// Replace file arguments keys and values to match HTML template vars
/// "__file__CSS File": "lp_public_sf_ui_font.css" -> "CSS File": "file:///.../Leanplum_Resources/lp_public_sf_ui_font.css"
/// Does not replace "templateName" key and value
- (NSMutableDictionary *)replaceFileNameToLocalFilePath:(NSMutableDictionary *)vars preserveFileNamed:(NSString *)reserveName
{
    for (NSString *key in [vars allKeys]) {
        id obj = vars[key];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            // Ensure obj is mutable as well
            vars[key] = [self replaceFileNameToLocalFilePath:[obj mutableCopy] preserveFileNamed:reserveName];
        } else if ([key hasPrefix:LPActionManager.ActionArgFilePrefix] && [obj isKindOfClass:[NSString class]]
                   && [obj length] > 0 && ![key isEqualToString:reserveName]) {
            NSString *filePath = [LPFileManager fileValue:obj withDefaultValue:@""];
            NSString *prunedKey = [key stringByReplacingOccurrencesOfString:LPActionManager.ActionArgFilePrefix
                                                                 withString:@""];
            vars[prunedKey] = [self asciiEncodedFileURL:filePath];
            [vars removeObjectForKey:key];
        }
    }
    return vars;
}

- (NSURL *)htmlWithTemplateNamed:(NSString *)templateName
{
    if ([LPUtils isNullOrEmpty:templateName]) {
        [Leanplum throwError:@"[LPActionContext htmlWithTemplateNamed:] "
         "Empty name parameter provided."];
        return nil;
    }
    
    LP_TRY
    [self setProperArgs];
    
    NSMutableDictionary *htmlVars = [self replaceFileNameToLocalFilePath:[_args mutableCopy]
                                                       preserveFileNamed:templateName];
    htmlVars[@"messageId"] = self.messageId;
    
    // Triggering Event.
    if (self.contextualValues && self.contextualValues.arguments) {
        htmlVars[@"displayEvent"] = self.contextualValues.arguments;
    }
    
    // Add HTML Vars.
    NSString *jsonString = [LPJSON stringFromJSON:htmlVars];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    
    // Template.
    NSString *htmlString = [self htmlStringContentsOfFile:[self fileNamed:templateName]];
    if (!htmlString) {
        LPLog(LPError, @"Fail to get HTML template.");
        return nil;
    }
    
    if ([[htmlVars valueForKey:@"Height"] isEqualToString:@"100%"] && [[htmlVars valueForKey:@"Width"] isEqualToString:@"100%"]) {
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"/*##MEDIAQUERY##" withString:@""];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"##MEDIAQUERY##*/" withString:@""];
    }
    
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"/*##BANNER_MEDIAQUERY##" withString:@""];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"##BANNER_MEDIAQUERY##*/" withString:@""];
    
    
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"##Vars##"
                                                       withString:jsonString];
    
    htmlString = [self fillTemplate:htmlString];
    
    // Save filled template to temp file which will be used by WebKit
    NSString *randomUUID = [[[NSUUID UUID] UUIDString] lowercaseString];
    NSString *tmpPath = [LPFileManager fileRelativeToDocuments:randomUUID createMissingDirectories:YES];
    NSURL *tmpURL = [[NSURL fileURLWithPath:tmpPath] URLByAppendingPathExtension:@"html"];
    
    [htmlString writeToURL:tmpURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    return tmpURL;
    LP_END_TRY
    return nil;
}

- (NSString *)asciiEncodedFileURL:(NSString *)filePath {
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet illegalCharacterSet];
    [allowed formUnionWithCharacterSet:[NSMutableCharacterSet controlCharacterSet]];
    [allowed invert];
    return [[NSString stringWithFormat:@"file://%@", filePath] stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}

- (NSString *)htmlStringContentsOfFile:(NSString *)file {
    NSError *error;
    NSString *htmlString = [NSString stringWithContentsOfFile:file
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    if (error) {
        LPLog(LPError, @"Fail to get HTML template. Error: %@", [error description]);
        return nil;
    }
    return htmlString;
}

- (NSString *)getDefaultValue:(NSString *)name
{
    NSArray *components = [name componentsSeparatedByString:@"."];
    NSDictionary *defaultValues = self.defaultValues;
    for (int i = 0; i < components.count; i++) {
        if (defaultValues == nil) {
            return nil;
        }
        id value = defaultValues[components[i]];
        if (i == components.count - 1) {
            return (NSString *) value;
        }
        defaultValues = (NSDictionary *) value;
    }
    return nil;
}

- (NSString *)fileNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext fileNamed:] Empty name parameter provided."];
        return nil;
    }
    LP_TRY
    NSString *stringValue = [self stringNamed:name];
    NSString *defaultValue = [self getDefaultValue:name];
    return [LPFileManager fileValue:stringValue withDefaultValue:defaultValue];
    LP_END_TRY
}

- (NSNumber *)numberNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext numberNamed:] Empty name parameter provided."];
        return nil;
    }
    LP_TRY
    id object = [self objectNamed:name];
    if ([object isKindOfClass:NSNumber.class]) {
        return object;
    }
    return [NSNumber numberWithDouble:[[object description] doubleValue]];
    LP_END_TRY
}

- (BOOL)boolNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext boolNamed:] Empty name parameter provided."];
        return NO;
    }
    LP_TRY
    id object = [self objectNamed:name];
    if ([object isKindOfClass:NSNumber.class]) {
        return [(NSNumber *) object boolValue];
    }
    return [[object description] boolValue];
    LP_END_TRY
}

- (NSDictionary *)dictionaryNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext dictionaryNamed:] Empty name parameter provided."];
        return nil;
    }
    LP_TRY
    id object = [self objectNamed:name];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *) object;
    }
    
    if ([object isKindOfClass:[NSString class]]) {
        return [LPJSON JSONFromString:object];
    }
    LP_END_TRY
    return nil;
}

- (NSArray *)arrayNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext arrayNamed:] Empty name parameter provided."];
        return nil;
    }
    return (NSArray *) [self objectNamed:name];
}

- (UIColor *)colorNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext colorNamed:] Empty name parameter provided."];
        return nil;
    }
    return leanplum_intToColor([[self numberNamed:name] longLongValue]);
}

- (NSDictionary *)getChildArgs:(NSString *)name
{
    LP_TRY
    NSDictionary *actionArgs = [self dictionaryNamed:name];
    if (![actionArgs isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *defaultArgs = [[[LPActionManager shared] definitionWithName:actionArgs[LP_VALUE_ACTION_ARG]] values];
    actionArgs = [ContentMerger mergeWithVars:defaultArgs diff:actionArgs];
    
    return actionArgs;
    LP_END_TRY
}

/**
 * Prefix given event with all parent actionContext names to while filtering out the string
 * "action" (used in ExperimentVariable names but filtered out from event names).
 */
- (NSString *)eventWithParentEventNamesFromEvent:(NSString *)event
{
    LP_TRY
    NSMutableString *fullEventName = [NSMutableString string];
    LPActionContext *context = self;
    NSMutableArray *parents = [NSMutableArray array];
    while (context->_parentContext != nil) {
        [parents addObject:context];
        context = context->_parentContext;
    }
    NSString *actionName;
    for (NSInteger i = parents.count - 1; i >= -1; i--) {
        if (i > -1) {
            actionName = ((LPActionContext *) parents[i])->_key;
        } else {
            actionName = event;
        }
        if (actionName == nil) {
            fullEventName = nil;
            break;
        }
        actionName = [actionName stringByReplacingOccurrencesOfString:@" action"
                                                           withString:@""
                                                              options:NSCaseInsensitiveSearch
                                                                range:NSMakeRange(0,
                                                                                  actionName.length)
        ];
        
        if (fullEventName.length) {
            [fullEventName appendString:@" "];
        }
        [fullEventName appendString:actionName];
    }
    
    return fullEventName;
    LP_END_TRY
}

- (void)runActionNamed:(NSString *)name
{
    LP_TRY
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext runActionNamed:] Empty name parameter provided."];
        return;
    }
    NSDictionary *args = [self getChildArgs:name];
    
    __weak LPActionContext *weakSelf = self;
    if ([self actionDidExecute]) {
        LPActionContext *actionNamedContext = [LPActionContext
                                               actionContextWithName:name
                                               args:args messageId:_messageId];
        actionNamedContext->_parentContext = weakSelf;
        // notifies our LPActionManager that the action was executed
        self.actionDidExecute(actionNamedContext);
    }
    
    if (!args) {
        return;
    }
    
    // Chain to existing message.
    NSString *messageId = args[LP_VALUE_CHAIN_MESSAGE_ARG];
    NSString *actionType = args[LP_VALUE_ACTION_ARG];
    
    void (^executeChainedMessage)(void) = ^void(void) {
        LPActionContext *chainedActionContext = [Leanplum createActionContextForMessageId:messageId];
        chainedActionContext.contextualValues = self.contextualValues;
        chainedActionContext->_preventRealtimeUpdating = self->_preventRealtimeUpdating;
        chainedActionContext->_isRooted = self->_isRooted;
        chainedActionContext->_isChainedMessage = YES;
        chainedActionContext->_parentContext = weakSelf;
        [LPUtils dispatchOnMainQueue:^{
            [[LPActionManager shared] triggerWithContexts:@[chainedActionContext] priority:PriorityHigh trigger:nil];
        }];
    };
    
    if (messageId && [actionType isEqualToString:LP_VALUE_CHAIN_MESSAGE_ACTION_NAME]) {
        NSDictionary *message = [[LPActionManager shared] messages][messageId];
        if (message) {
            executeChainedMessage();
        } else {
            BOOL previousPauseState = LPActionManager.shared.isPaused;
            LPActionManager.shared.isPaused = YES;
            // Message doesn't seem to be on the device,
            // so let's forceContentUpdate and retry showing it.
            [Leanplum forceContentUpdate: ^(void) {
                NSDictionary *message = [[LPActionManager shared] messages][messageId];
                if (message) {
                    executeChainedMessage();
                }
                if ([[LPActionManager shared] useAsyncHandlers]) {
                    dispatch_async([[LPActionManager shared] actionQueue], ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            LPActionManager.shared.isPaused = previousPauseState;
                        });
                    });
                } else {
                    LPActionManager.shared.isPaused = previousPauseState;
                }
            }];
        }
    } else {
        LPActionContext *childContext = [LPActionContext
                                         actionContextWithName:args[LP_VALUE_ACTION_ARG]
                                         args:args
                                         messageId:_messageId];
        childContext.contextualValues = self.contextualValues;
        childContext->_preventRealtimeUpdating = _preventRealtimeUpdating;
        childContext->_isRooted = _isRooted;
        childContext->_parentContext = weakSelf;
        childContext->_key = name;
        [LPUtils dispatchOnMainQueue:^{
            [[LPActionManager shared] triggerWithContexts:@[childContext] priority:PriorityHigh trigger:nil];
        }];
    }
    
    LP_END_TRY
    
    [self.countAggregator incrementCount:@"run_action_named"];
}

- (void)runTrackedActionNamed:(NSString *)name
{
    if (!IS_NOOP && _messageId && _isRooted) {
        if ([LPUtils isNullOrEmpty:name]) {
            [Leanplum throwError:@"[LPActionContext runTrackedActionNamed:] Empty name parameter "
             @"provided."];
            return;
        }
        
        [self trackMessageEvent:name withValue:0.0 andInfo:nil andParameters:nil];
    }
    [self runActionNamed:name];
    
    [self.countAggregator incrementCount:@"run_tracked_action_named"];
}

- (void)trackMessageEvent:(NSString *)event withValue:(double)value andInfo:(NSString *)info
            andParameters:(NSDictionary *)params
{
    if (!IS_NOOP && _messageId) {
        event = [self eventWithParentEventNamesFromEvent:event];
        if (event) {
            [Leanplum track:event
                  withValue:value
                    andInfo:info
                    andArgs:@{LP_PARAM_MESSAGE_ID: _messageId}
              andParameters:params];
        }
    }
}

- (void)track:(NSString *)event withValue:(double)value andParameters:(NSDictionary *)params
{
    if (!IS_NOOP && _messageId) {
        [Leanplum track:event
              withValue:value
                andInfo:nil
                andArgs:@{LP_PARAM_MESSAGE_ID: _messageId}
          andParameters:params];
    }
}


+ (void)sortByPriority:(NSMutableArray *)actionContexts
{
    [actionContexts sortUsingComparator:^(LPActionContext *contextA, LPActionContext *contextB) {
        NSNumber *priorityA = [contextA priority];
        NSNumber *priorityB = [contextB priority];
        return [priorityA compare:priorityB];
    }];
}

- (void)actionDismissed
{
    if (self.actionDidDismiss) {
        self.actionDidDismiss();
    } else {
        LPLog(LPError, @"%@: actionDidDismiss not set for context %@", [self class], self);
    }
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%p>%@:%@", self, self.name, self.messageId];
}

@end
