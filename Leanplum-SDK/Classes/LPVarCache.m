//
//  VarCache.m
//  Leanplum
//
//  Created by Andrew First on 5/2/12.
//  Copyright (c) 2012 Leanplum. All rights reserved.
//

#import "Constants.h"
#import "LPFileManager.h"
#import "LPVarCache.h"
#import "LeanplumInternal.h"
#import "LeanplumRequest.h"
#import "LPActionManager.h"
#import "FileMD5Hash.h"
#import "LPKeychainWrapper.h"
#import "LPAES.h"
#import "Leanplum_SocketIO.h"
#import "Utils.h"

static NSRegularExpression *varNameRegex;
static NSMutableDictionary *vars;
static NSMutableDictionary *filesToInspect;
static NSMutableDictionary *fileAttributes;
static NSMutableDictionary *valuesFromClient;
static NSMutableDictionary *defaultKinds;
static NSMutableDictionary *actionDefinitions;
static NSDictionary *diffs;
static NSDictionary *messageDiffs;
static NSMutableArray *updateRulesDiffs;
static NSArray *eventRulesDiffs;
static NSDictionary *devModeValuesFromServer;
static NSDictionary *devModeFileAttributesFromServer;
static NSDictionary *devModeActionDefinitionsFromServer;
static NSArray *variants;
static NSMutableDictionary *userAttributes;
static NSDictionary *regions;
static CacheUpdateBlock updateBlock;
static CacheUpdateBlock interfaceUpdateBlock;
static CacheUpdateBlock eventsUpdateBlock;
static BOOL hasReceivedDiffs;
static NSMutableDictionary *messages;
static id merged;
static BOOL silent;
static int contentVersion;
static BOOL hasTooManyFiles;
static RegionInitBlock regionInitBlock;

@implementation LPVarCache

+ (void)initialize
{
    vars = [NSMutableDictionary dictionary];
    filesToInspect = [NSMutableDictionary dictionary];
    fileAttributes = [NSMutableDictionary dictionary];
    valuesFromClient = [NSMutableDictionary dictionary];
    diffs = [NSMutableDictionary dictionary];
    updateRulesDiffs = [NSMutableArray array];
    eventRulesDiffs = [NSArray array];
    defaultKinds = [NSMutableDictionary dictionary];
    actionDefinitions = [NSMutableDictionary dictionary];
    hasReceivedDiffs = NO;
    silent = NO;
    NSError *error = NULL;
    varNameRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:[^\\.\\[.(\\\\]+|\\\\.)+"
                                                             options:NSRegularExpressionCaseInsensitive error:&error];
}

+ (void)registerRegionInitBlock:(void (^)(NSDictionary *, NSSet *, NSSet *))block
{
    regionInitBlock = block;
}

+ (LPVar *)define:(NSString *)name with:(NSObject *)defaultValue kind:(NSString *)kind
{
    if ([Utils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPVarCache define:with:kind:] Empty name parameter provided."];
        return nil;
    }

    @synchronized (vars) {
        LP_TRY
        LPVar *existing = [LPVarCache getVariable:name];
        if (existing) {
            return existing;
        }
        LP_END_TRY
        LPVar *var = [[LPVar alloc] initWithName:name
                                  withComponents:[LPVarCache getNameComponents:name]
                                withDefaultValue:defaultValue
                                        withKind:kind];
        return var;
    }
}

+ (NSArray *)getNameComponents:(NSString *)name
{
    NSArray *matches = [Leanplum_SocketIO arrayOfCaptureComponentsOfString:name matchedBy:varNameRegex];
    NSMutableArray *nameComponents = [NSMutableArray array];
    for (NSArray *matchArray in matches) {
        [nameComponents addObject:matchArray[0]];
    }
    NSArray *result = [NSArray arrayWithArray:nameComponents];
    
    // iOS 3.x compatability. NSRegularExpression is not available, so there will be no components.
    if (result.count == 0) {
        return @[name];
    }
    
    return result;
}

+ (id)traverse:(id)collection withKey:(id)key autoInsert:(BOOL)autoInsert
{
    if ([collection respondsToSelector:@selector(objectForKey:)]) {
        id result = [collection objectForKey:key];
        if (autoInsert && !result && [key isKindOfClass:NSString.class]) {
            result = [NSMutableDictionary dictionary];
            [collection setObject:result forKey:key];
        }
        return result;
    } else if ([collection isKindOfClass:[NSArray class]]) {
        int index = [key intValue];
        NSArray *arrayCollection = collection;
        if (arrayCollection.count > index) {
            id result = arrayCollection[index];
            if (autoInsert && !result && [key isKindOfClass:NSString.class]) {
                result = [NSMutableArray array];
                [collection setObject:result atIndex:index];
            }
            return result;
        }
    }
    return nil;
}

+ (void)registerFile:(NSString *)stringValue withDefaultValue:(NSString *)defaultValue
{
    if (stringValue.length == 0) {
        return;
    }
    NSString *path = [LPFileManager fileValue:stringValue withDefaultValue:defaultValue];
    if (!path) {
        return;
    }
    filesToInspect[stringValue] = path;
}

+ (void)computeFileInfo
{
    for (NSString *fileName in filesToInspect) {
        NSString *path = filesToInspect[fileName];
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        NSString *hash = (__bridge_transfer NSString *) Leanplum_FileMD5HashCreateWithPath(
            (__bridge CFStringRef) path, FileHashDefaultChunkSizeForReadingData);
        if (hash) {
            attributes[LP_KEY_HASH] = hash;
        }
        NSNumber *size = [[[NSFileManager defaultManager]
                           attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize];
        attributes[LP_KEY_SIZE] = size;
        fileAttributes[fileName] = @{@"": attributes};
    }
    [filesToInspect removeAllObjects];
}

// Updates a JSON structure of variable values, and a dictionary of variable kinds.
+ (void)updateValues:(NSString *)name
      nameComponents:(NSArray *)nameComponents
               value:(id)value
                kind:(NSString *)kind
              values:(NSMutableDictionary *)values
               kinds:(NSMutableDictionary *)kinds
{
    if (value) {
        id valuesPtr = values;
        for (int i = 0; i < nameComponents.count - 1; i++) {
            valuesPtr = [self traverse:valuesPtr withKey:nameComponents[i] autoInsert:YES];
        }
        
        // Make the value mutable. That way, if we add a dictionary variable,
        // we can still add subvariables.
        if ([value isKindOfClass:NSDictionary.class] &&
            [value class] != [NSMutableDictionary class]) {
            value = [NSMutableDictionary dictionaryWithDictionary:value];
        }
        if ([value isKindOfClass:NSArray.class] &&
            [value class] != [NSMutableArray class]) {
            value = [NSMutableArray arrayWithArray:value];
        }
        [valuesPtr setObject:value forKey:nameComponents.lastObject];
    }
    if (kind) {
        kinds[name] = kind;
    }
}

+ (void)registerVariable:(LPVar *)var
{
    [vars setObject:var forKey:var.name];
    [self updateValues:var.name
        nameComponents:var.nameComponents
                 value:var.defaultValue
                  kind:var.kind
                values:valuesFromClient
                 kinds:defaultKinds];
}

+ (LPVar *)getVariable:(NSString *)name
{
    return [vars objectForKey:name];
}

+ (void)computeMergedDictionary
{
    merged = [self mergeHelper:valuesFromClient withDiffs:diffs];
}

+ (id)mergeHelper:(id)vars withDiffs:(id)diff
{
    if ([vars isKindOfClass:NSNull.class]) {
        vars = nil;
    }
    if ([diff isKindOfClass:NSNumber.class] ||
        [diff isKindOfClass:NSString.class] ||
        [diff isKindOfClass:NSNull.class]) {
        return diff;
    }
    if (diff == nil) {
        return vars;
    }
    if ([vars isKindOfClass:NSNumber.class] ||
        [vars isKindOfClass:NSString.class] ||
        [vars isKindOfClass:NSNull.class]) {
        return diff;
    }

    // Infer that the diffs is an array if the vars value doesn't exist to tell us the type.
    BOOL isArray = NO;
    if (vars == nil) {
        if ([diff isKindOfClass:NSDictionary.class] && [diff count] > 0) {
            isArray = YES;
            for (id var in diff) {
                if (![var isKindOfClass:NSString.class]
                    || ([var length] < 3)
                    || ([var characterAtIndex:0] != '[' || [var characterAtIndex:[var length] - 1] != ']')) {
                    isArray = NO;
                    break;
                }
                NSString *varSubscript = [var substringWithRange:NSMakeRange(1, [var length] - 2)];
                if (![[NSString stringWithFormat:@"%d", [varSubscript intValue]] isEqualToString:varSubscript]) {
                    isArray = NO;
                    break;
                }
            }
        }
    }

    // Merge arrays.
    if ([vars isKindOfClass:NSArray.class] || isArray) {
        NSMutableArray *merged = [NSMutableArray array];
        for (id var in vars) {
            [merged addObject:var];
        }
        for (id varSubscript in diff) {
            int subscript = [[varSubscript substringWithRange:NSMakeRange(1, [varSubscript length] - 2)] intValue];
            id var = [diff objectForKey:varSubscript];
            while (subscript >= [merged count]) {
                [merged addObject:[NSNull null]];
            }
            [merged replaceObjectAtIndex:subscript
                              withObject:[self mergeHelper:merged[subscript] withDiffs:var]];
        }
        return merged;
    }

    // Merge dictionaries.
    if ([vars isKindOfClass:NSDictionary.class] || [diff isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *merged = [NSMutableDictionary dictionary];
        for (id var in vars) {
            if ([diff objectForKey:var] == nil) {
                merged[var] = [vars objectForKey:var];
            }
        }
        for (id var in diff) {
            merged[var] = [self mergeHelper:[vars objectForKey:var]
                                  withDiffs:[diff objectForKey:var]];
        }
        return merged;
    }
    return nil;
}

+ (id)getValueFromComponentArray:(NSArray *) components fromDict:(NSDictionary *)values
{
    id mergedPtr = values;
    for (id component in components) {
        mergedPtr = [self traverse:mergedPtr withKey:component autoInsert:NO];
    }
    return mergedPtr;
}

+ (id)getMergedValueFromComponentArray:(NSArray *)components
{
    return [self getValueFromComponentArray:components fromDict:merged ? merged : valuesFromClient];
}

+ (NSDictionary *)diffs
{
    return diffs;
}

+ (NSDictionary *)messageDiffs
{
    return messageDiffs;
}

+ (NSArray *)updateRulesDiffs
{
    return updateRulesDiffs;
}

+ (NSArray *)eventRulesDiffs
{
    return eventRulesDiffs;
}

+ (BOOL)hasReceivedDiffs
{
    return hasReceivedDiffs;
}

+ (NSArray *)variants
{
    return variants;
}

+ (NSDictionary *)regions
{
    return regions;
}

+ (NSDictionary *)fileAttributes
{
    return fileAttributes;
}

+ (NSDictionary *)defaultKinds
{
    return defaultKinds;
}

+ (void)loadDiffs
{
    RETURN_IF_NOOP;
    @try {
        NSData *encryptedDiffs = [[NSUserDefaults standardUserDefaults] dataForKey:LEANPLUM_DEFAULTS_VARIABLES_KEY];
        NSDictionary *diffs;
        NSDictionary *messages;
        NSArray *updateRules;
        NSArray *eventRules;
        NSArray *variants;
        NSDictionary *regions;
        if (encryptedDiffs) {
            NSData *diffsData = [LPAES decryptedDataFromData:encryptedDiffs];
            if (!diffsData) {
                return;
            }

            NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:diffsData];
            diffs = (NSDictionary *) [archiver decodeObjectForKey:LEANPLUM_DEFAULTS_VARIABLES_KEY];
            messages = (NSDictionary *) [archiver decodeObjectForKey:LEANPLUM_DEFAULTS_MESSAGES_KEY];
            updateRules = (NSArray *)[archiver decodeObjectForKey:LEANPLUM_DEFAULTS_UPDATE_RULES_KEY];
            eventRules = (NSArray *)[archiver decodeObjectForKey:LEANPLUM_DEFAULTS_EVENT_RULES_KEY];
            regions = (NSDictionary *)[archiver decodeObjectForKey:LP_KEY_REGIONS];
            variants = (NSArray *)[archiver decodeObjectForKey:LP_KEY_VARIANTS];
            NSString *deviceId = [archiver decodeObjectForKey:LP_PARAM_DEVICE_ID];
            NSString *userId = [archiver decodeObjectForKey:LP_PARAM_USER_ID];
            BOOL loggingEnabled = [archiver decodeBoolForKey:LP_KEY_LOGGING_ENABLED];

            if (deviceId) {
                [LeanplumRequest setDeviceId:deviceId];
            }
            if (userId) {
                [LeanplumRequest setUserId:userId];
            }
            if (loggingEnabled) {
                [LPConstantsState sharedState].loggingEnabled = YES;
            }
        }

        [self applyVariableDiffs:diffs
                        messages:messages
                     updateRules:updateRules
                      eventRules:eventRules
                        variants:variants
                         regions:regions];
    } @catch (NSException *exception) {
        NSLog(@"Leanplum: Could not load variable diffs: %@", exception);
    }
    [self userAttributes];
}

+ (void)saveDiffs
{
    RETURN_IF_NOOP;
    // Stores the variables on the device in case we don't have a connection
    // next time the app is opened.

    NSMutableData *diffsData = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:diffsData];
    [archiver encodeObject:diffs forKey:LEANPLUM_DEFAULTS_VARIABLES_KEY];
    [archiver encodeObject:messages forKey:LEANPLUM_DEFAULTS_MESSAGES_KEY];
    [archiver encodeObject:updateRulesDiffs forKey:LEANPLUM_DEFAULTS_UPDATE_RULES_KEY];
    [archiver encodeObject:eventRulesDiffs forKey:LEANPLUM_DEFAULTS_EVENT_RULES_KEY];
    [archiver encodeObject:variants forKey:LP_KEY_VARIANTS];
    [archiver encodeObject:regions forKey:LP_KEY_REGIONS];
    [archiver encodeObject:[LPConstantsState sharedState].sdkVersion forKey:LP_PARAM_SDK_VERSION];
    [archiver encodeObject:LeanplumRequest.deviceId forKey:LP_PARAM_DEVICE_ID];
    [archiver encodeObject:LeanplumRequest.userId forKey:LP_PARAM_USER_ID];
    [archiver encodeBool:[LPConstantsState sharedState].loggingEnabled forKey:LP_KEY_LOGGING_ENABLED];
    [archiver finishEncoding];

    NSData *encryptedDiffs = [LPAES encryptedDataFromData:diffsData];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:encryptedDiffs forKey:LEANPLUM_DEFAULTS_VARIABLES_KEY];
    
    [defaults setObject:LEANPLUM_SDK_VERSION forKey:LEANPLUM_DEFAULTS_SDK_VERSION];
    
    [Leanplum synchronizeDefaults];
}

+ (void)applyVariableDiffs:(NSDictionary *)diffs_
                  messages:(NSDictionary *)messages_
               updateRules:(NSArray *)updateRules_
                eventRules:(NSArray *)eventRules_
                  variants:(NSArray *)variants_
                   regions:(NSDictionary *)regions_
{
    @synchronized (vars) {
        if (diffs_ || (!silent && !hasReceivedDiffs)) {
            diffs = diffs_;
            [self computeMergedDictionary];
            
            // Update variables with new values.
            // Have to extract the keys because a dictionary variable may add a new sub-variable,
            // modifying the variable dictionary.
            for (NSString *name in [vars allKeys]) {
                [vars[name] update];
            }
        }
        
        if (regions_) {
            // Store regions.
            regions = regions_;
        }
        
        if (messages_) {
            // Store messages.
            messageDiffs = messages_;
            messages = [NSMutableDictionary dictionary];
            for (NSString *name in messages_) {
                NSDictionary *messageConfig = messages_[name];
                NSMutableDictionary *newConfig = [messageConfig mutableCopy];
                NSDictionary *actionArgs = messageConfig[LP_KEY_VARS];
                NSDictionary *defaultArgs = actionDefinitions
                                              [newConfig[LP_PARAM_ACTION]][@"values"];
                NSDictionary *messageVars = [self mergeHelper:defaultArgs
                                                    withDiffs:actionArgs];
                messages[name] = newConfig;
                newConfig[LP_KEY_VARS] = messageVars;
                
                // Download files.
                [[LPActionContext actionContextWithName:messageConfig[@"action"]
                                                   args:actionArgs
                                              messageId:name]
                 maybeDownloadFiles];
            }
        }
    }
    
    // If LeanplumLocation is linked in, setup region monitoring.
    if (messages_ || regions_) {
        if (!regionInitBlock) {
                if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
                    if ([regions_ count] > 0) {
                        NSLog(@"Leanplum: Regions have been defined in dashboard, but the app is not built to handle them.");
                        NSLog(@"Leanplum: Add LeanplumLocation.framework or LeanplumBeacon.framework to Build Settings -> Link Binary With Libraries.");
                        NSLog(@"Leanplum: Disregard warning if there are no plans to utilize iBeacon or Geofencing within the app");
                    }
                }
        } else {
            NSSet *foregroundRegionNames;
            NSSet *backgroundRegionNames;
            [LPActionManager getForegroundRegionNames:&foregroundRegionNames
                             andBackgroundRegionNames:&backgroundRegionNames];
            regionInitBlock([LPVarCache regions], foregroundRegionNames, backgroundRegionNames);
        }
    }

    BOOL interfaceUpdated = NO;
    if (updateRules_) {
        interfaceUpdated = ![updateRules_ isEqual:updateRulesDiffs];
        updateRulesDiffs = [updateRules_ mutableCopy];
        [self downloadUpdateRulesImages];
    }
    
    BOOL eventsUpdated = NO;
    if (eventRules_ && ![eventRules_ isKindOfClass:NSNull.class]) {
        eventsUpdated = ![eventRules_ isEqual:eventRulesDiffs];
        eventRulesDiffs = eventRules_;
    }

    if (variants_) {
        variants = variants_;
    }
    
    contentVersion++;

    if (!silent) {
        [self saveDiffs];

        hasReceivedDiffs = YES;
        if (updateBlock) {
            updateBlock();
        }
        
        if (interfaceUpdated) {
            interfaceUpdateBlock();
        }
        
        if (eventsUpdated) {
            eventsUpdateBlock();
        }
    }
}

+ (void)applyUpdateRuleDiffs:(NSArray *)updateRuleDiffs
{
    updateRulesDiffs = [updateRuleDiffs mutableCopy];
    [LPVarCache downloadUpdateRulesImages];
    if (interfaceUpdateBlock) {
        interfaceUpdateBlock();
    }
    [self saveDiffs];
}

+ (void)downloadUpdateRulesImages
{
    for (NSDictionary *updateRule in updateRulesDiffs) {
        NSArray *changes = updateRule[@"changes"];
        if (changes != nil) {
            for (NSDictionary *change in changes) {
                NSString *key = change[@"key"];
                if (key &&
                    [[key lowercaseString] rangeOfString:@"image"].location == key.length - 5) {
                    id name = change[@"value"];
                    if ([name isKindOfClass:[NSString class]]) {
                        [LPFileManager maybeDownloadFile:name
                                            defaultValue:nil
                                              onComplete:^{}];
                    }
                }
            }
        }
    }
}

+ (int)contentVersion
{
    return contentVersion;
}

+ (BOOL)areActionDefinitionsEqual:(NSDictionary *)a other:(NSDictionary *)b
{
    if (a.count != b.count) {
        return NO;
    }
    for (NSString *key in a) {
        NSDictionary *aItem = a[key];
        NSDictionary *bItem = b[key];
        if (!bItem) {
            return NO;
        }
        if ((aItem[@"kind"] != bItem[@"kind"]) ||
            (aItem[@"values"] != bItem[@"values"]) ||
            (aItem[@"kinds"] != bItem[@"kinds"]) ||
            aItem[@"options"] != bItem[@"options"]) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)sendVariablesIfChanged
{
    return [self sendContentIfChanged:YES actions:NO];
}

+ (BOOL)sendActionsIfChanged
{
    return [self sendContentIfChanged:NO actions:YES];
}

+ (BOOL)sendContentIfChanged:(BOOL)variables actions:(BOOL)actions
{
    [self computeFileInfo];

    BOOL changed = NO;
    if (variables && devModeValuesFromServer &&
        (![valuesFromClient isEqualToDictionary:devModeValuesFromServer])) {
        changed = YES;
    }
    if (actions && ![self areActionDefinitionsEqual:actionDefinitions
                                              other:devModeActionDefinitionsFromServer]) {
        changed = YES;
    }
    if (changed) {
         NSDictionary *limitedFileAttributes = fileAttributes;
         NSDictionary *limitedValues = valuesFromClient;
         if ([fileAttributes count] > MAX_FILES_SUPPORTED) {
             limitedValues = [valuesFromClient mutableCopy];
             [(NSMutableDictionary *)limitedValues removeObjectForKey:LP_VALUE_RESOURCES_VARIABLE];
             NSLog(@"Leanplum: ERROR: You are trying to sync %lu files, which is more than "
                   @"we support (%d). If you are calling [Leanplum syncResources], try adding "
                   @"regex filters to limit the number of files you are syncing.",
                   (unsigned long) fileAttributes.count, MAX_FILES_SUPPORTED);
             limitedFileAttributes = [NSDictionary dictionary];
             hasTooManyFiles = YES;
         }
         @try {
             NSMutableDictionary *args = [NSMutableDictionary dictionary];
             if (variables) {
                 args[LP_PARAM_VARS] = [LPJSON stringFromJSON:limitedValues];
                 args[LP_PARAM_KINDS] = [LPJSON stringFromJSON:defaultKinds];
             }
             if (actions) {
                 args[LP_PARAM_ACTION_DEFINITIONS] = [LPJSON stringFromJSON:actionDefinitions];
             }
             args[LP_PARAM_FILE_ATTRIBUTES] = [LPJSON stringFromJSON:limitedFileAttributes];
             [[LeanplumRequest post:LP_METHOD_SET_VARS
                             params:args] send];
             return YES;
         } @catch (NSException *e) {
             [Leanplum throwError:@"Cannot serialize variable values. "
              @"Make sure your variables are JSON serializable."];
         }
     }
    return NO;
}

+ (void)maybeUploadNewFiles
{
    RETURN_IF_NOOP;
    if (hasTooManyFiles ||
        !devModeFileAttributesFromServer ||
        ![Leanplum hasStartedAndRegisteredAsDeveloper]) {
        return;
    }

    NSMutableArray *filenames = [NSMutableArray array];
    NSMutableArray *fileData = [NSMutableArray array];
    int totalSize = 0;
    for (NSString *name in fileAttributes) {
        NSDictionary *variationAttributes = fileAttributes[name];
        NSDictionary *localAttributes = variationAttributes[@""];
        NSDictionary *serverAttributes = devModeFileAttributesFromServer[name][@""];
        if ([LPFileManager isNewerLocally:localAttributes orRemotely:serverAttributes]) {
            NSString *hash = [localAttributes valueForKey:LP_KEY_HASH];
            if (!hash) {
                hash = @"";
            }
            NSString *variationPath = [LPFileManager fileRelativeToAppBundle:name];
            if ((totalSize > MAX_UPLOAD_BATCH_SIZES &&
                 filenames.count > 0) || filenames.count >= MAX_UPLOAD_BATCH_FILES) {
                [[LeanplumRequest post:LP_METHOD_UPLOAD_FILE
                                params:@{LP_PARAM_DATA: [LPJSON stringFromJSON:fileData]}]
                 sendFilesNow:filenames];
                filenames = [NSMutableArray array];
                fileData = [NSMutableArray array];
                totalSize = 0;
            }
            NSNumber *size = [localAttributes valueForKey:LP_KEY_SIZE];
            totalSize += [size intValue];
            [fileData addObject:@{
                    LP_KEY_HASH: hash,
                    LP_KEY_SIZE: size,
                LP_KEY_FILENAME: name
             }];
            [filenames addObject:variationPath];
        }
    }
    if (filenames.count > 0) {
        [[LeanplumRequest post:LP_METHOD_UPLOAD_FILE
                        params:@{LP_PARAM_DATA: [LPJSON stringFromJSON:fileData]}]
         sendFilesNow:filenames];
    }
}

+ (void)setSilent:(BOOL)silent_
{
    silent = silent_;
}

+ (BOOL)silent
{
    return silent;
}

+ (void)setDevModeValuesFromServer:(NSDictionary *)values
                    fileAttributes:(NSDictionary *)fileAttributes
                 actionDefinitions:(NSDictionary *)actionDefinitions
{
    devModeValuesFromServer = values;
    devModeActionDefinitionsFromServer = actionDefinitions;
    devModeFileAttributesFromServer = fileAttributes;
}

+ (void)onUpdate:(CacheUpdateBlock) block
{
    updateBlock = block;
}

+ (void)onInterfaceUpdate:(CacheUpdateBlock)block
{
    interfaceUpdateBlock = block;
}

+ (void)onEventsUpdate:(CacheUpdateBlock)block
{
    eventsUpdateBlock = block;
}

+ (NSDictionary *)actionDefinitions
{
    return actionDefinitions;
}

+ (NSDictionary *)messages
{
    return messages;
}

+ (NSMutableDictionary *)userAttributes
{
    if (!userAttributes) {
        @try {
            NSString *token = [LeanplumRequest token];
            if (token) {
                NSData *encryptedValue = [[NSUserDefaults standardUserDefaults] dataForKey:LEANPLUM_DEFAULTS_ATTRIBUTES_KEY];
                if (encryptedValue) {
                    NSData *decryptedData = [LPAES decryptedDataFromData:encryptedValue];
                    if (decryptedData) {
                        NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData
                                                       :decryptedData];
                        userAttributes = [(NSDictionary *)[archiver decodeObjectForKey:LP_PARAM_USER_ATTRIBUTES] mutableCopy];
                    }
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"Leanplum: Could not load user attributes: %@", exception);
        }
    }
    if (!userAttributes) {
        userAttributes = [NSMutableDictionary dictionary];
    }
    return userAttributes;
}

+ (void)saveUserAttributes
{
    RETURN_IF_NOOP;
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:userAttributes forKey:LP_PARAM_USER_ATTRIBUTES];
    [archiver finishEncoding];
    
    NSData *encryptedData = [LPAES encryptedDataFromData:data];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:encryptedData forKey:LEANPLUM_DEFAULTS_ATTRIBUTES_KEY];
    [Leanplum synchronizeDefaults];
}

+ (void)registerActionDefinition:(NSString *)name
                          ofKind:(int)kind
                   withArguments:(NSArray *)args
                      andOptions:(NSDictionary *)options
{
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    NSMutableDictionary *kinds = [NSMutableDictionary dictionary];
    NSMutableArray *order = [NSMutableArray array];
    for (LPActionArg *arg in args) {
        [self updateValues:arg.name
            nameComponents:[LPVarCache getNameComponents:arg.name]
                     value:arg.defaultValue
                      kind:arg.kind
                    values:values
                     kinds:kinds];
        [order addObject:arg.name];
    }
    NSDictionary *definition = @{
                                 @"kind": @(kind),
                                 @"values": values,
                                 @"kinds": kinds,
                                 @"order": order,
                                 @"options": options
                                 };
    actionDefinitions[name] = definition;
}

// Resets the VarCache to stock state. Used for testing purposes.
+ (void)reset
{
    vars = nil;
    filesToInspect = nil;
    fileAttributes = nil;
    valuesFromClient = nil;
    defaultKinds = nil;
    actionDefinitions = nil;
    diffs = nil;
    messageDiffs = nil;
    updateRulesDiffs = nil;
    eventRulesDiffs = nil;
    devModeValuesFromServer = nil;
    devModeFileAttributesFromServer = nil;
    devModeActionDefinitionsFromServer = nil;
    variants = nil;
    userAttributes = nil;
    updateBlock = nil;
    interfaceUpdateBlock = nil;
    eventsUpdateBlock = nil;
    hasReceivedDiffs = NO;
    messages = nil;
    merged = nil;
    silent = NO;
    contentVersion = 0;
    hasTooManyFiles = NO;
}

@end
