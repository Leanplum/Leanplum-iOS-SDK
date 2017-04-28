//
//  VarCache.h
//  Leanplum
//
//  Created by Andrew First on 5/2/12.
//  Copyright (c) 2012 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LPVar;

typedef void (^CacheUpdateBlock)();
typedef void (^RegionInitBlock)(NSDictionary *, NSSet *, NSSet *);

@interface LPVarCache : NSObject

// Location initialization
+ (void)registerRegionInitBlock:(RegionInitBlock)block;

// Handling variables.
+ (LPVar *)define:(NSString *)name with:(NSObject *)defaultValue kind:(NSString *)kind;
+ (NSArray *)getNameComponents:(NSString *)name;
+ (void)loadDiffs;
+ (void)saveDiffs;
// Returns YES if the file was registered.
+ (void)registerVariable:(LPVar *)var;
+ (LPVar *)getVariable:(NSString *)name;

// Handling values.
+ (id)getValueFromComponentArray:(NSArray *) components fromDict:(NSDictionary *)values;
+ (id)getMergedValueFromComponentArray:(NSArray *) components;
+ (NSDictionary *)diffs;
+ (NSDictionary *)messageDiffs;
+ (NSArray *)updateRulesDiffs;
+ (NSArray *)eventRulesDiffs;
+ (BOOL)hasReceivedDiffs;
+ (void)applyVariableDiffs:(NSDictionary *)diffs_
                  messages:(NSDictionary *)messages_
               updateRules:(NSArray *)updateRules_
                eventRules:(NSArray *)eventRules_
                  variants:(NSArray *)variants_
                   regions:(NSDictionary *)regions_;
+ (void)applyUpdateRuleDiffs:(NSArray *)updateRuleDiffs;
+ (void)onUpdate:(CacheUpdateBlock)block;
+ (void)onInterfaceUpdate:(CacheUpdateBlock)block;
+ (void)onEventsUpdate:(CacheUpdateBlock)block;
+ (void)setSilent:(BOOL)silent;
+ (BOOL)silent;
+ (id)mergeHelper:(id)vars withDiffs:(id)diff;
+ (int)contentVersion;
+ (NSArray *)variants;
+ (NSDictionary *)regions;
+ (NSDictionary *)defaultKinds;

// Handling actions.
+ (NSDictionary *)actionDefinitions;
+ (NSDictionary *)messages;
+ (void)registerActionDefinition:(NSString *)name
                          ofKind:(int)kind
                   withArguments:(NSArray *)args
                      andOptions:(NSDictionary *)options;

// Development mode.
+ (void)setDevModeValuesFromServer:(NSDictionary *)values
                    fileAttributes:(NSDictionary *)fileAttributes
                 actionDefinitions:(NSDictionary *)actionDefinitions;
+ (BOOL)sendVariablesIfChanged;
+ (BOOL)sendActionsIfChanged;

// Handling files.
+ (void)registerFile:(NSString *)stringValue withDefaultValue:(NSString *)defaultValue;
+ (void)maybeUploadNewFiles;
+ (NSDictionary *)fileAttributes;

+ (NSMutableDictionary *)userAttributes;
+ (void)saveUserAttributes;

@end
