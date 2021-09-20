
//  Leanplum.h
//  Leanplum iOS SDK Version 2.0.6
//
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LeanplumVariablesChangedBlock)(void);

@class LPVar;

/**
 * Receives callbacks for {@link LPVar}
 */
NS_SWIFT_NAME(VarDelegate)
@protocol LPVarDelegate <NSObject>
@optional
/**
 * For file variables, called when the file is ready.
 */
- (void)fileIsReady:(LPVar *)var;
/**
 * Called when the value of the variable changes.
 */
- (void)valueDidChange:(LPVar *)var;
@end

/**
 * A variable is any part of your application that can change from an experiment.
 * Check out {@link Macros the macros} for defining variables more easily.
 */
NS_SWIFT_NAME(Var)
@interface LPVar : NSObject

@property (readonly, strong, nullable) NSString *stringValue;
@property (readonly, strong, nullable) NSNumber *numberValue;
@property (readonly, strong, nullable) id value;
@property (readonly, strong, nullable) id defaultValue;

/**
 * @{
 * Defines a {@link LPVar}
 */
- (instancetype)init NS_UNAVAILABLE;

+ (LPVar *)define:(NSString *)name
NS_SWIFT_NAME(init(name:));
+ (LPVar *)define:(NSString *)name withInt:(int)defaultValue
NS_SWIFT_NAME(init(name:integer:));
+ (LPVar *)define:(NSString *)name withFloat:(float)defaultValue
NS_SWIFT_NAME(init(name:float:));
+ (LPVar *)define:(NSString *)name withDouble:(double)defaultValue
NS_SWIFT_NAME(init(name:double:));
+ (LPVar *)define:(NSString *)name withCGFloat:(CGFloat)cgFloatValue
NS_SWIFT_NAME(init(name:cgFloat:));
+ (LPVar *)define:(NSString *)name withShort:(short)defaultValue
NS_SWIFT_NAME(init(name:integer:));
+ (LPVar *)define:(NSString *)name withChar:(char)defaultValue
NS_SWIFT_NAME(init(name:integer:));
+ (LPVar *)define:(NSString *)name withBool:(BOOL)defaultValue
NS_SWIFT_NAME(init(name:boolean:));
+ (LPVar *)define:(NSString *)name withString:(nullable NSString *)defaultValue
NS_SWIFT_NAME(init(name:string:));
+ (LPVar *)define:(NSString *)name withNumber:(nullable NSNumber *)defaultValue
NS_SWIFT_NAME(init(name:number:));
+ (LPVar *)define:(NSString *)name withInteger:(NSInteger)defaultValue
NS_SWIFT_NAME(init(name:integer:));
+ (LPVar *)define:(NSString *)name withLong:(long)defaultValue
NS_SWIFT_NAME(init(name:integer:));
+ (LPVar *)define:(NSString *)name withLongLong:(long long)defaultValue
NS_SWIFT_NAME(init(name:integer:));
+ (LPVar *)define:(NSString *)name withUnsignedChar:(unsigned char)defaultValue
NS_SWIFT_NAME(init(name:uinteger:));
+ (LPVar *)define:(NSString *)name withUnsignedInt:(unsigned int)defaultValue
NS_SWIFT_NAME(init(name:uinteger:));
+ (LPVar *)define:(NSString *)name withUnsignedInteger:(NSUInteger)defaultValue
NS_SWIFT_NAME(init(name:uinteger:));
+ (LPVar *)define:(NSString *)name withUnsignedLong:(unsigned long)defaultValue
NS_SWIFT_NAME(init(name:uinteger:));
+ (LPVar *)define:(NSString *)name withUnsignedLongLong:(unsigned long long)defaultValue
NS_SWIFT_NAME(init(name:uinteger:));
+ (LPVar *)define:(NSString *)name withUnsignedShort:(unsigned short)defaultValue
NS_SWIFT_NAME(init(name:uinteger:));
+ (LPVar *)define:(NSString *)name withFile:(nullable NSString *)defaultFilename
NS_SWIFT_NAME(init(name:file:));
+ (LPVar *)define:(NSString *)name withDictionary:(nullable NSDictionary *)defaultValue
NS_SWIFT_NAME(init(name:dictionary:));
+ (LPVar *)define:(NSString *)name withArray:(nullable NSArray *)defaultValue
NS_SWIFT_NAME(init(name:array:));
+ (LPVar *)define:(NSString *)name withColor:(nullable UIColor *)defaultValue
NS_SWIFT_NAME(init(name:color:));
/**@}*/

/**
 * Returns the name of the variable.
 */
- (NSString *)name;

/**
 * Returns the components of the variable's name.
 */
- (NSArray<NSString *> *)nameComponents;

/**
 * Returns the default value of a variable.
 */
- (nullable id)defaultValue;

/**
 * Returns the kind of the variable.
 */
- (NSString *)kind;

/**
 * Returns whether the variable has changed since the last time the app was run.
 */
- (BOOL)hasChanged;

/**
 * For file variables, called when the file is ready.
 */
- (void)onFileReady:(LeanplumVariablesChangedBlock)block;

/**
 * Called when the value of the variable changes.
 */
- (void)onValueChanged:(LeanplumVariablesChangedBlock)block;

/**
 * Sets the delegate of the variable in order to use
 * {@link LPVarDelegate::fileIsReady:} and {@link LPVarDelegate::valueDidChange:}
 */
- (void)setDelegate:(nullable id <LPVarDelegate>)delegate;

/**
 * @{
 * Accessess the value(s) of the variable
 */
- (id)objectForKey:(nullable NSString *)key;
- (id)objectAtIndex:(NSUInteger )index;
- (id)objectForKeyPath:(nullable id)firstComponent, ... NS_REQUIRES_NIL_TERMINATION;
- (id)objectForKeyPathComponents:(nullable NSArray<NSString *> *)pathComponents;
- (NSUInteger)count;

- (nullable NSNumber *)numberValue;
- (nullable NSString *)stringValue;
- (nullable NSString *)fileValue;
- (nullable UIImage *)imageValue;
- (int)intValue;
- (double)doubleValue;
- (CGFloat)cgFloatValue;
- (float)floatValue;
- (short)shortValue;
- (BOOL)boolValue;
- (char)charValue;
- (long)longValue;
- (long long)longLongValue;
- (NSInteger)integerValue;
- (unsigned char)unsignedCharValue;
- (unsigned short)unsignedShortValue;
- (unsigned int)unsignedIntValue;
- (NSUInteger)unsignedIntegerValue;
- (unsigned long)unsignedLongValue;
- (unsigned long long)unsignedLongLongValue;
- (nullable UIColor *)colorValue;
/**@}*/
@end

NS_ASSUME_NONNULL_END
