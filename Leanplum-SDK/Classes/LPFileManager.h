//
//  LPFileManager.h
//  LeanplumTest
//
//  Created by Andrew First on 1/9/13.
//
//

#import "Leanplum.h"
#import <Foundation/Foundation.h>

@interface NSBundle (LeanplumExtension)

+ (NSBundle *__nullable)leanplum_mainBundle;

@end

@interface LPBundle : NSBundle

- (__nullable instancetype)initWithPath:(NSString *__nonnull)path NS_DESIGNATED_INITIALIZER;

@end

@interface LPFileManager : NSObject

+ (NSString *__nullable)appBundlePath;
+ (NSString *__nullable)documentsDirectory;
+ (NSString *__nullable)cachesDirectory;
+ (NSString *__nullable)documentsPathRelativeToFolder:(NSString *__nonnull)folder;
+ (NSString *__nullable)documentsPath;
+ (NSString *__nullable)bundlePathRelativeToFolder:(NSString *__nonnull)folder;
+ (NSString *__nullable)bundlePath;

+ (NSString *__nullable)fileRelativeToAppBundle:(NSString *__nonnull)path;
+ (NSString *__nullable)fileRelativeToDocuments:(NSString *__nonnull)path
                       createMissingDirectories:(BOOL)createMissingDirectories;
+ (NSString *__nullable)fileRelativeToLPBundle:(NSString *__nonnull)path;
+ (BOOL)isNewerLocally:(NSDictionary *__nonnull)localAttributes
            orRemotely:(NSDictionary *__nonnull)serverAttributes;

+ (BOOL)fileExists:(NSString *__nonnull)name;
+ (BOOL)shouldDownloadFile:(NSString *__nullable)value
              defaultValue:(NSString *__nullable)defaultValue;
+ (BOOL)maybeDownloadFile:(NSString *__nullable)value
             defaultValue:(NSString *__nullable)defaultValue
               onComplete:(void (^__nullable)())complete;
+ (NSString *__nullable)fileValue:(NSString *__nonnull)stringValue
                 withDefaultValue:(NSString *__nullable)defaultValue;

+ (void)initAsync:(BOOL)async;
+ (void)initWithInclusions:(NSArray *__nullable)inclusions
             andExclusions:(NSArray *__nullable)exclusions
                     async:(BOOL)async;

+ (BOOL)hasInited;
+ (BOOL)initializing;
+ (void)setResourceSyncingReady:(__nonnull LeanplumVariablesChangedBlock)block;

// Finds all files in absDir and adds them to the files array.
+ (void)traverse:(NSString *__nonnull)absoluteDir
         current:(NSString *__nonnull)relativeDir
           files:(NSMutableArray *__nonnull)files;

@end
