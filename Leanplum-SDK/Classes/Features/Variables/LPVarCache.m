//
//  VarCache.m
//  Leanplum
//
//  Created by Andrew First on 5/2/12.
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LPConstants.h"
#import "LPFileManager.h"
#import "LPVarCache.h"
#import "LeanplumInternal.h"
#import "LPActionManager.h"
#import "FileMD5Hash.h"
#import "LPKeychainWrapper.h"
#import "LPAES.h"
#import "Leanplum_SocketIO.h"
#import "LPUtils.h"
#import "LPRequestFactory.h"
#import "LPRequestSender.h"
#import "LPAPIConfig.h"
#import "LPCountAggregator.h"
#import "LPFileTransferManager.h"

@interface LPVarCache()
@property (strong, nonatomic) NSRegularExpression *varNameRegex;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *vars;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *filesToInspect;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *fileAttributes;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *valuesFromClient;
@property (readwrite, nonatomic) NSMutableDictionary<NSString *, id> *defaultKinds;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *actionDefinitions;
@property (strong, nonatomic) NSDictionary<NSString *, id> *diffs;
@property (strong, nonatomic) NSDictionary<NSString *, id> *messageDiffs;
@property (strong, nonatomic) NSDictionary<NSString *, id> *devModeValuesFromServer;
@property (strong, nonatomic) NSDictionary<NSString *, id> *devModeFileAttributesFromServer;
@property (strong, nonatomic) NSDictionary<NSString *, id> *devModeActionDefinitionsFromServer;
@property (strong, nonatomic) NSArray<NSString *> *variants;
@property (strong, nonatomic) NSArray<NSDictionary *> *localCaps;
@property (strong, nonatomic) NSDictionary<NSString *, id> *variantDebugInfo;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *userAttributes;
@property (strong, nonatomic) NSDictionary<NSString *, id> *regions;
@property (strong, nonatomic) CacheUpdateBlock updateBlock;
@property (assign, nonatomic) BOOL hasReceivedDiffs;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *messages;
@property (strong, nonatomic) id merged;
@property (assign, nonatomic) BOOL silent;
@property (assign, nonatomic) int contentVersion;
@property (assign, nonatomic) BOOL hasTooManyFiles;
@property (strong, nonatomic) RegionInitBlock regionInitBlock;
@property (strong, nonatomic) LPCountAggregator *countAggregator;
@property (strong, nonatomic) NSString *varsJson;
@property (strong, nonatomic) NSString *varsSignature;
@end

static LPVarCache *sharedInstance = nil;
static dispatch_once_t leanplum_onceToken;

@implementation LPVarCache

+(instancetype)sharedCache
{
    dispatch_once(&leanplum_onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

- (void)initialize
{
    self.vars = [NSMutableDictionary dictionary];
    self.messages = [NSMutableDictionary dictionary];
    self.filesToInspect = [NSMutableDictionary dictionary];
    self.fileAttributes = [NSMutableDictionary dictionary];
    self.valuesFromClient = [NSMutableDictionary dictionary];
    self.diffs = [NSMutableDictionary dictionary];
    self.defaultKinds = [NSMutableDictionary dictionary];
    self.actionDefinitions = [NSMutableDictionary dictionary];
    self.localCaps = [NSArray array];
    self.hasReceivedDiffs = NO;
    self.silent = NO;
    NSError *error = NULL;
    self.varNameRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:[^\\.\\[.(\\\\]+|\\\\.)+"
                                                             options:NSRegularExpressionCaseInsensitive error:&error];
}

- (void)registerRegionInitBlock:(void (^)(NSDictionary *, NSSet *, NSSet *))block
{
    self.regionInitBlock = block;
}

- (LPVar *)define:(NSString *)name with:(NSObject *)defaultValue kind:(NSString *)kind
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPVarCache define:with:kind:] Empty name parameter provided."];
        return nil;
    }
    
    [self.countAggregator incrementCount:@"define_varcache"];

    @synchronized (self.vars) {
        LP_TRY
        LPVar *existing = [self getVariable:name];
        if (existing) {
            return existing;
        }
        LP_END_TRY
        LPVar *var = [[LPVar alloc] initWithName:name
                                  withComponents:[self getNameComponents:name]
                                withDefaultValue:defaultValue
                                        withKind:kind];
        return var;
    }
}

- (NSArray *)getNameComponents:(NSString *)name
{
    NSArray *matches = [Leanplum_SocketIO arrayOfCaptureComponentsOfString:name matchedBy:self.varNameRegex];
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

- (id)traverse:(id)collection withKey:(id)key autoInsert:(BOOL)autoInsert
{
    id result = nil;
    if ([collection respondsToSelector:@selector(objectForKey:)]) {
        result = [collection objectForKey:key];
        if (autoInsert && !result && [key isKindOfClass:NSString.class]) {
            result = [NSMutableDictionary dictionary];
            [collection setObject:result forKey:key];
        }
    } else if ([collection isKindOfClass:[NSArray class]]) {
        int index = [key intValue];
        NSArray *arrayCollection = collection;
        if (arrayCollection.count > index) {
            result = arrayCollection[index];
            if (autoInsert && !result && [key isKindOfClass:NSString.class]) {
                result = [NSMutableArray array];
                [collection setObject:result atIndex:index];
            }
        }
    }
    
    if ([result isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    return result;
}

- (void)registerFile:(NSString *)stringValue withDefaultValue:(NSString *)defaultValue
{
    if (stringValue.length == 0) {
        return;
    }
    NSString *path = [LPFileManager fileValue:stringValue withDefaultValue:defaultValue];
    if (!path) {
        return;
    }
    self.filesToInspect[stringValue] = path;
}

- (void)computeFileInfo
{
    for (NSString *fileName in self.filesToInspect) {
        NSString *path = self.filesToInspect[fileName];
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        NSString *hash = (__bridge_transfer NSString *) Leanplum_FileMD5HashCreateWithPath(
            (__bridge CFStringRef) path, FileHashDefaultChunkSizeForReadingData);
        if (hash) {
            attributes[LP_KEY_HASH] = hash;
        }
        NSNumber *size = [[[NSFileManager defaultManager]
                           attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize];
        attributes[LP_KEY_SIZE] = size;
        _fileAttributes[fileName] = @{@"": attributes};
    }
    [self.filesToInspect removeAllObjects];
}

// Updates a JSON structure of variable values, and a dictionary of variable kinds.
- (void)updateValues:(NSString *)name
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

- (void)registerVariable:(LPVar *)var
{
    [self.vars setObject:var forKey:var.name];
    [self updateValues:var.name
        nameComponents:var.nameComponents
                 value:var.defaultValue
                  kind:var.kind
                values:self.valuesFromClient
                 kinds:_defaultKinds];
}

- (LPVar *)getVariable:(NSString *)name
{
    return [self.vars objectForKey:name];
}

- (void)computeMergedDictionary
{
    if (!self.diffs) {
        self.merged = [self mergeHelper:self.valuesFromClient withDiffs:self.diffs];
        return;
    }
    
    // Merger helper will mutate diffs.
    // We need to lock it in case multiple threads will be accessing this.
    @synchronized (self.diffs) {
        self.merged = [self mergeHelper:self.valuesFromClient withDiffs:self.diffs];
    }
}

- (id)mergeHelper:(id)vars withDiffs:(id)diff
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
        
        // Merge values from server
        // Array values from server come as Dictionary
        // Example:
        // string[] items = new string[] { "Item 1", "Item 2"};
        // args.With<string[]>("Items", items); // Action Context arg value
        // "vars": {
        //      "Items": {
        //                  "[1]": "Item 222", // Modified value from server
        //                  "[0]": "Item 111"  // Modified value from server
        //              }
        //  }
        // Prevent crashing when loading variable diffs where the diff is an Array and not Dictionary
        if ([diff isKindOfClass:NSDictionary.class]) {
            for (id varSubscript in diff) {
                // Get the index from the string key: "[0]" -> 0
                if ([varSubscript isKindOfClass:NSString.class]) {
                    NSString *varSubscriptStr = (NSString*)varSubscript;
                    if ([varSubscriptStr length] > 2 && [varSubscriptStr hasPrefix:@"["] && [varSubscriptStr hasSuffix:@"]"]) {
                        int subscript = [[varSubscriptStr substringWithRange:NSMakeRange(1, [varSubscriptStr length] - 2)] intValue];
                        id var = [diff objectForKey:varSubscriptStr];
                        while (subscript >= [merged count]) {
                            [merged addObject:[NSNull null]];
                        }
                        [merged replaceObjectAtIndex:subscript
                                          withObject:[self mergeHelper:merged[subscript] withDiffs:var]];
                    }
                }
            }
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

- (id)getValueFromComponentArray:(NSArray *) components fromDict:(NSDictionary *)values
{
    id mergedPtr = values;
    for (id component in components) {
        mergedPtr = [self traverse:mergedPtr withKey:component autoInsert:NO];
    }
    return mergedPtr;
}

- (id)getMergedValueFromComponentArray:(NSArray *)components
{
    return [self getValueFromComponentArray:components fromDict:self.merged ? self.merged : self.valuesFromClient];
}

- (void)loadDiffs
{
    RETURN_IF_NOOP;
    @try {
        NSData *encryptedDiffs = [[NSUserDefaults standardUserDefaults] dataForKey:LEANPLUM_DEFAULTS_VARIABLES_KEY];
        NSDictionary *diffs;
        NSDictionary *messages;
        NSArray *variants;
        NSArray *localCaps;
        NSDictionary *variantDebugInfo;
        NSDictionary *regions;
        NSString *varsJson;
        NSString *varsSignature;
        if (encryptedDiffs) {
            NSData *diffsData = [LPAES decryptedDataFromData:encryptedDiffs];
            if (!diffsData) {
                return;
            }

            NSKeyedUnarchiver *unarchiver;
            if (@available(iOS 12.0, *)) {
                NSError *error = nil;
                unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:diffsData error:&error];
                if (error != nil) {
                    LPLog(LPError, error.localizedDescription);
                    return;
                }
                unarchiver.requiresSecureCoding = NO;
            } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:diffsData];
#pragma clang diagnostic pop
            }
            diffs = (NSDictionary *) [unarchiver decodeObjectForKey:LEANPLUM_DEFAULTS_VARIABLES_KEY];
            messages = (NSDictionary *) [unarchiver decodeObjectForKey:LEANPLUM_DEFAULTS_MESSAGES_KEY];
            regions = (NSDictionary *)[unarchiver decodeObjectForKey:LP_KEY_REGIONS];
            variants = (NSArray *)[unarchiver decodeObjectForKey:LP_KEY_VARIANTS];
            variantDebugInfo = (NSDictionary *)[unarchiver decodeObjectForKey:LP_KEY_VARIANT_DEBUG_INFO];
            varsJson = [unarchiver decodeObjectForKey:LEANPLUM_DEFAULTS_VARS_JSON_KEY];
            varsSignature = [unarchiver decodeObjectForKey:LEANPLUM_DEFAULTS_VARS_SIGNATURE_KEY];
            NSString *deviceId = [unarchiver decodeObjectForKey:LP_PARAM_DEVICE_ID];
            NSString *userId = [unarchiver decodeObjectForKey:LP_PARAM_USER_ID];
            BOOL loggingEnabled = [unarchiver decodeBoolForKey:LP_KEY_LOGGING_ENABLED];
            localCaps = [unarchiver decodeObjectForKey:LEANPLUM_DEFAULTS_LOCAL_CAPS_KEY];
            if (deviceId) {
                [[LPAPIConfig sharedConfig] setDeviceId:deviceId];
            }
            if (userId) {
                [[LPAPIConfig sharedConfig] setUserId:userId];
            }
            if (loggingEnabled) {
                [LPConstantsState sharedState].loggingEnabled = YES;
            }
        }

        [self applyVariableDiffs:diffs
                        messages:messages
                        variants:variants
                       localCaps:localCaps
                         regions:regions
                variantDebugInfo:variantDebugInfo
                        varsJson:varsJson
                   varsSignature:varsSignature];
    } @catch (NSException *exception) {
        LPLog(LPError, @"Could not load variable diffs: %@", exception);
    }
    [self userAttributes];
    
    [self.countAggregator incrementCount:@"load_diffs"];
}

- (void)saveDiffs
{
    RETURN_IF_NOOP;
    // Stores the variables on the device in case we don't have a connection.
    // Restores next time when the app is opened.
    // Diffs need to be locked incase other thread changes the diffs using
    // mergeHelper:.
    @synchronized (self.diffs) {
        NSMutableData *diffsData = [[NSMutableData alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:diffsData];
#pragma clang diagnostic pop
        [archiver encodeObject:self.diffs forKey:LEANPLUM_DEFAULTS_VARIABLES_KEY];
        [archiver encodeObject:self.messages forKey:LEANPLUM_DEFAULTS_MESSAGES_KEY];
        [archiver encodeObject:self.variants forKey:LP_KEY_VARIANTS];
        [archiver encodeObject:self.variantDebugInfo forKey:LP_KEY_VARIANT_DEBUG_INFO];
        [archiver encodeObject:self.regions forKey:LP_KEY_REGIONS];
        [archiver encodeObject:[LPConstantsState sharedState].sdkVersion forKey:LP_PARAM_SDK_VERSION];
        [archiver encodeObject:[LPAPIConfig sharedConfig].deviceId forKey:LP_PARAM_DEVICE_ID];
        [archiver encodeObject:[LPAPIConfig sharedConfig].userId forKey:LP_PARAM_USER_ID];
        [archiver encodeBool:[LPConstantsState sharedState].loggingEnabled forKey:LP_KEY_LOGGING_ENABLED];
        [archiver encodeObject:self.varsJson forKey:LEANPLUM_DEFAULTS_VARS_JSON_KEY];
        [archiver encodeObject:self.varsSignature forKey:LEANPLUM_DEFAULTS_VARS_SIGNATURE_KEY];
        [archiver encodeObject:self.localCaps forKey:LEANPLUM_DEFAULTS_LOCAL_CAPS_KEY];
        [archiver finishEncoding];

        NSData *encryptedDiffs = [LPAES encryptedDataFromData:diffsData];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [defaults setObject:encryptedDiffs forKey:LEANPLUM_DEFAULTS_VARIABLES_KEY];
        
        [defaults setObject:LEANPLUM_SDK_VERSION forKey:LEANPLUM_DEFAULTS_SDK_VERSION];
        
        [Leanplum synchronizeDefaults];
    }
    [self.countAggregator incrementCount:@"save_diffs"];
}

- (void)applyVariableDiffs:(NSDictionary *)diffs_
                  messages:(NSDictionary *)messages_
                  variants:(NSArray *)variants_
                 localCaps:(NSArray *)localCaps_
                   regions:(NSDictionary *)regions_
          variantDebugInfo:(NSDictionary *)variantDebugInfo_
                  varsJson:(NSString *)varsJson_
             varsSignature:(NSString *)varsSignature_
{
    @synchronized (self.vars) {
        if (diffs_ || (!self.silent && !self.hasReceivedDiffs)) {
            self.diffs = diffs_;
            [self computeMergedDictionary];
            
            // Update variables with new values.
            // Have to extract the keys because a dictionary variable may add a new sub-variable,
            // modifying the variable dictionary.
            for (NSString *name in [self.vars allKeys]) {
                [self.vars[name] update];
            }
        }
        
        if (regions_) {
            // Store regions.
            self.regions = regions_;
        }
        
        if (messages_) {
            // Store messages.
            self.messageDiffs = messages_;
            self.messages = [NSMutableDictionary dictionary];
            for (NSString *name in messages_) {
                NSDictionary *messageConfig = messages_[name];
                NSMutableDictionary *newConfig = [messageConfig mutableCopy];
                NSDictionary *actionArgs = messageConfig[LP_KEY_VARS];
                NSDictionary *defaultArgs = self.actionDefinitions
                                              [newConfig[LP_PARAM_ACTION]][@"values"];
                NSDictionary *messageVars = [self mergeHelper:defaultArgs
                                                    withDiffs:actionArgs];
                _messages[name] = newConfig;
                newConfig[LP_KEY_VARS] = messageVars;
                
                // Download files.
                [[LPActionContext actionContextWithName:messageConfig[@"action"]
                                                   args:actionArgs
                                              messageId:name]
                 maybeDownloadFiles];
            }
        }
    
        // If LeanplumLocation is linked in, setup region monitoring.
        if (messages_ || regions_) {
            if (!self.regionInitBlock) {
                    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
                        if ([regions_ count] > 0) {
                            LPLog(LPInfo, @"Regions have been defined in dashboard, but the app is not built to handle them.");
                            LPLog(LPInfo, @"Add LeanplumLocation.framework or LeanplumBeacon.framework to Build Settings -> Link Binary With Libraries.");
                            LPLog(LPInfo, @"Disregard warning if there are no plans to utilize iBeacon or Geofencing within the app");
                        }
                    }
            } else {
                NSSet *foregroundRegionNames;
                NSSet *backgroundRegionNames;
                [LPActionManager getForegroundRegionNames:&foregroundRegionNames
                                 andBackgroundRegionNames:&backgroundRegionNames];
                self.regionInitBlock(self.regions, foregroundRegionNames, backgroundRegionNames);
            }
        }

        if (variants_) {
            self.variants = variants_;
        }
        
        if (localCaps_) {
            self.localCaps = localCaps_;
        }

        if (variantDebugInfo_) {
            self.variantDebugInfo = variantDebugInfo_;
        }

        self.contentVersion++;
        
        if (varsJson_) {
            self.varsJson = varsJson_;
            self.varsSignature = varsSignature_;
        }

        if (!self.silent) {
            [self saveDiffs];

            self.hasReceivedDiffs = YES;
            if (self.updateBlock) {
                self.updateBlock();
            }
        }
    }
    [self.countAggregator incrementCount:@"apply_variable_diffs"];
}

- (BOOL)areActionDefinitionsEqual:(NSDictionary *)a other:(NSDictionary *)b
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

- (BOOL)sendVariablesIfChanged
{
    return [self sendContentIfChanged:YES actions:NO];
}

- (BOOL)sendActionsIfChanged
{
    return [self sendContentIfChanged:NO actions:YES];
}

- (BOOL)sendContentIfChanged:(BOOL)variables actions:(BOOL)actions
{
    [self computeFileInfo];

    BOOL changed = NO;
    if (variables && self.devModeValuesFromServer &&
        (![self.valuesFromClient isEqualToDictionary:self.devModeValuesFromServer])) {
        changed = YES;
    }
    if (actions && ![self areActionDefinitionsEqual:self.actionDefinitions
                                              other:self.devModeActionDefinitionsFromServer]) {
        changed = YES;
    }
    if (changed) {
         NSDictionary *limitedFileAttributes = self.fileAttributes;
         NSDictionary *limitedValues = self.valuesFromClient;
         if ([self.fileAttributes count] > MAX_FILES_SUPPORTED) {
             limitedValues = [self.valuesFromClient mutableCopy];
             [(NSMutableDictionary *)limitedValues removeObjectForKey:LP_VALUE_RESOURCES_VARIABLE];
             LPLog(LPError, @"You are trying to sync %lu files, which is more than "
                   @"we support (%d). If you are calling [Leanplum syncResources], try adding "
                   @"regex filters to limit the number of files you are syncing.",
                   (unsigned long) self.fileAttributes.count, MAX_FILES_SUPPORTED);
             limitedFileAttributes = [NSDictionary dictionary];
             self.hasTooManyFiles = YES;
         }
         @try {
             NSMutableDictionary *args = [NSMutableDictionary dictionary];
             if (variables) {
                 args[LP_PARAM_VARS] = [LPJSON stringFromJSON:limitedValues];
                 args[LP_PARAM_KINDS] = [LPJSON stringFromJSON:self.defaultKinds];
             }
             if (actions) {
                 args[LP_PARAM_ACTION_DEFINITIONS] = [LPJSON stringFromJSON:self.actionDefinitions];
             }
             args[LP_PARAM_FILE_ATTRIBUTES] = [LPJSON stringFromJSON:limitedFileAttributes];
             LPRequest *request = [LPRequestFactory setVarsWithParams:args];
             [[LPRequestSender sharedInstance] send:request];
             return YES;
         } @catch (NSException *e) {
             [Leanplum throwError:@"Cannot serialize variable values. "
              @"Make sure your variables are JSON serializable."];
         }
     }
    return NO;
}

- (void)maybeUploadNewFiles
{
    RETURN_IF_NOOP;
    if (self.hasTooManyFiles ||
        !self.devModeFileAttributesFromServer ||
        ![Leanplum hasStartedAndRegisteredAsDeveloper]) {
        return;
    }

    NSMutableArray *filenames = [NSMutableArray array];
    NSMutableArray *fileData = [NSMutableArray array];
    int totalSize = 0;
    for (NSString *name in self.fileAttributes) {
        NSDictionary *variationAttributes = self.fileAttributes[name];
        NSDictionary *localAttributes = variationAttributes[@""];
        NSDictionary *serverAttributes = self.devModeFileAttributesFromServer[name][@""];
        if ([LPFileManager isNewerLocally:localAttributes orRemotely:serverAttributes]) {
            NSString *hash = [localAttributes valueForKey:LP_KEY_HASH];
            if (!hash) {
                hash = @"";
            }
            NSString *variationPath = [LPFileManager fileRelativeToAppBundle:name];
            if ((totalSize > MAX_UPLOAD_BATCH_SIZES &&
                 filenames.count > 0) || filenames.count >= MAX_UPLOAD_BATCH_FILES) {
                LPRequest *request = [LPRequestFactory uploadFileWithParams:@{LP_PARAM_DATA: [LPJSON stringFromJSON:fileData]}];
                [[LPRequestSender sharedInstance] send:request];
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
        [[LPFileTransferManager sharedInstance] sendFilesNow:filenames fileData:fileData];
    }
}

- (void)setDevModeValuesFromServer:(NSDictionary *)values
                    fileAttributes:(NSDictionary *)fileAttributes
                 actionDefinitions:(NSDictionary *)actionDefinitions
{
    self.devModeValuesFromServer = values;
    self.devModeActionDefinitionsFromServer = actionDefinitions;
    self.devModeFileAttributesFromServer = fileAttributes;
}

- (void)onUpdate:(CacheUpdateBlock) block
{
    self.updateBlock = block;
    
    [self.countAggregator incrementCount:@"on_update_varcache"];
}

- (NSMutableDictionary *)userAttributes
{
    if (!_userAttributes) {
        @try {
            NSString *token = [[LPAPIConfig sharedConfig] token];
            if (token) {
                NSData *encryptedValue = [[NSUserDefaults standardUserDefaults] dataForKey:LEANPLUM_DEFAULTS_ATTRIBUTES_KEY];
                if (encryptedValue) {
                    NSData *decryptedData = [LPAES decryptedDataFromData:encryptedValue];
                    if (decryptedData) {
                        NSKeyedUnarchiver *unarchiver;
                        if (@available(iOS 12.0, *)) {
                            NSError *error = nil;
                            unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:decryptedData error:&error];
                            if (error != nil) {
                                LPLog(LPError, error.localizedDescription);
                                //in case of error returning empty dictionary to avoid crash
                                return [NSMutableDictionary dictionary];
                            }
                            unarchiver.requiresSecureCoding = NO;
                        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                            unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData
                                                       :decryptedData];
#pragma clang diagnostic pop
                        }
                        self.userAttributes = [(NSDictionary *)[unarchiver decodeObjectForKey:LP_PARAM_USER_ATTRIBUTES] mutableCopy];
                    }
                }
            }
        } @catch (NSException *exception) {
            LPLog(LPError, @"Could not load user attributes: %@", exception);
        }
    }
    if (!_userAttributes) {
        _userAttributes = [NSMutableDictionary dictionary];
    }
    return _userAttributes;
}

- (void)saveUserAttributes
{
    RETURN_IF_NOOP;
    NSMutableData *data = [[NSMutableData alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
#pragma clang diagnostic pop
    [archiver encodeObject:self.userAttributes forKey:LP_PARAM_USER_ATTRIBUTES];
    [archiver finishEncoding];
    
    NSData *encryptedData = [LPAES encryptedDataFromData:data];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:encryptedData forKey:LEANPLUM_DEFAULTS_ATTRIBUTES_KEY];
    [Leanplum synchronizeDefaults];
    
    [self.countAggregator incrementCount:@"save_user_attributes"];
}

- (void)registerActionDefinition:(NSString *)name
                          ofKind:(int)kind
                   withArguments:(NSArray *)args
                      andOptions:(NSDictionary *)options
{
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    NSMutableDictionary *kinds = [NSMutableDictionary dictionary];
    NSMutableArray *order = [NSMutableArray array];
    for (LPActionArg *arg in args) {
        [self updateValues:arg.name
            nameComponents:[self getNameComponents:arg.name]
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
    _actionDefinitions[name] = definition;
}

- (LPSecuredVars *)securedVars
{
    if ([LPUtils isNullOrEmpty:self.varsJson] || [LPUtils isNullOrEmpty:self.varsSignature]) {
        return nil;
    }
    return [[LPSecuredVars alloc] initWithJson:self.varsJson andSignature:self.varsSignature];
}

- (NSArray *)getLocalCaps
{
    return self.localCaps;
}

- (NSUInteger)getActionDefinitionType:(NSString *)actionName
{
    id actionDef = [self.actionDefinitions objectForKey:actionName];
    if ([actionDef isKindOfClass:[NSDictionary class]]) {
        LeanplumActionKind kind = (LeanplumActionKind)[(NSDictionary *)actionDef valueForKey:@"kind"];
        return kind;
    }
    
    return 0;
}

- (void)clearUserContent
{
    self.diffs = nil;
    self.messageDiffs = nil;
    self.messages = nil;
    self.variants = nil;
    self.localCaps = nil;
    self.variantDebugInfo = nil;
    self.vars = nil;
    self.userAttributes = nil;
    self.merged = nil;
    self.varsJson = nil;
    self.varsSignature = nil;

    self.devModeValuesFromServer = nil;
    self.devModeFileAttributesFromServer = nil;
    self.devModeActionDefinitionsFromServer = nil;

}

// Resets the VarCache to stock state. Used for testing purposes.
- (void)reset
{
    self.vars = nil;
    self.filesToInspect = nil;
    self.fileAttributes = nil;
    self.valuesFromClient = nil;
    self.defaultKinds = nil;
    self.actionDefinitions = nil;
    self.diffs = nil;
    self.messageDiffs = nil;
    self.devModeValuesFromServer = nil;
    self.devModeFileAttributesFromServer = nil;
    self.devModeActionDefinitionsFromServer = nil;
    self.variants = nil;
    self.localCaps = nil;
    self.variantDebugInfo = nil;
    self.userAttributes = nil;
    self.updateBlock = nil;
    self.hasReceivedDiffs = NO;
    self.messages = nil;
    self.merged = nil;
    self.silent = NO;
    self.contentVersion = 0;
    self.hasTooManyFiles = NO;
    self.varsJson = nil;
    self.varsSignature = nil;
}

@end
