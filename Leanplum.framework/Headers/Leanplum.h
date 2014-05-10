//
//  Leanplum.h
//  Leanplum iOS SDK Version 1.3.0
//
//  Copyright (c) 2014 Leanplum. All rights reserved.
//

#define _LP_DEFINE_HELPER(name,val,type) LPVar* name; \
static void __attribute__((constructor)) initialize_##name() { \
@autoreleasepool { \
name = [LPVar define:[@#name stringByReplacingOccurrencesOfString:@"_" withString:@"."] with##type:val]; \
} \
}

// Use these macros to define variables inside your app.
// Underscores within variable names will create groups.
// To define variables in a more custom way, copy and modify
// the template above in your own code.

#define DEFINE_VAR_INT(name,val) _LP_DEFINE_HELPER(name, val, Int)
#define DEFINE_VAR_BOOL(name,val) _LP_DEFINE_HELPER(name, val, Bool)
#define DEFINE_VAR_STRING(name,val) _LP_DEFINE_HELPER(name, val, String)
#define DEFINE_VAR_NUMBER(name,val) _LP_DEFINE_HELPER(name, val, Number)
#define DEFINE_VAR_FLOAT(name,val) _LP_DEFINE_HELPER(name, val, Float)
#define DEFINE_VAR_CGFLOAT(name,val) _LP_DEFINE_HELPER(name, val, CGFloat)
#define DEFINE_VAR_DOUBLE(name,val) _LP_DEFINE_HELPER(name, val, Double)
#define DEFINE_VAR_SHORT(name,val) _LP_DEFINE_HELPER(name, val, Short)
#define DEFINE_VAR_LONG(name,val) _LP_DEFINE_HELPER(name, val, Long)
#define DEFINE_VAR_CHAR(name,val) _LP_DEFINE_HELPER(name, val, Char)
#define DEFINE_VAR_LONG_LONG(name,val) _LP_DEFINE_HELPER(name, val, LongLong)
#define DEFINE_VAR_INTEGER(name,val) _LP_DEFINE_HELPER(name, val, Integer)
#define DEFINE_VAR_UINT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInt)
#define DEFINE_VAR_UCHAR(name,val) _LP_DEFINE_HELPER(name, val, UnsignedChar)
#define DEFINE_VAR_ULONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLong)
#define DEFINE_VAR_UINTEGER(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInteger)
#define DEFINE_VAR_USHORT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedShort)
#define DEFINE_VAR_ULONGLONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLongLong)
#define DEFINE_VAR_UNSIGNED_INT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInt)
#define DEFINE_VAR_UNSIGNED_INTEGER(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInteger)
#define DEFINE_VAR_UNSIGNED_CHAR(name,val) _LP_DEFINE_HELPER(name, val, UnsignedChar)
#define DEFINE_VAR_UNSIGNED_LONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLong)
#define DEFINE_VAR_UNSIGNED_LONG_LONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLongLong)
#define DEFINE_VAR_UNSIGNED_SHORT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedShort)
#define DEFINE_VAR_FILE(name,filename) _LP_DEFINE_HELPER(name, filename, File)
#define DEFINE_VAR_DICTIONARY(name,dict) _LP_DEFINE_HELPER(name, dict, Dictionary)
#define DEFINE_VAR_ARRAY(name,array) _LP_DEFINE_HELPER(name, array, Array)
#define DEFINE_VAR_COLOR(name,val) _LP_DEFINE_HELPER(name, val, Color)

#define DEFINE_VAR_DICTIONARY_WITH_OBJECTS_AND_KEYS(name,...) LPVar* name; \
static void __attribute__((constructor)) initialize_##name() { \
@autoreleasepool { \
name = [LPVar define:[@#name stringByReplacingOccurrencesOfString:@"_" withString:@"."] withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__]]; \
} \
}

#define DEFINE_VAR_ARRAY_WITH_OBJECTS(name,...) LPVar* name; \
static void __attribute__((constructor)) initialize_##name() { \
@autoreleasepool { \
name = [LPVar define:[@#name stringByReplacingOccurrencesOfString:@"_" withString:@"."] withArray:[NSArray arrayWithObjects:__VA_ARGS__]]; \
} \
}

@class LPActionContext;

typedef void (^LeanplumStartBlock)(BOOL success);
typedef void (^LeanplumVariablesChangedBlock)();
typedef void (^LeanplumInterfaceChangedBlock)();
typedef void (^LeanplumEventsChangedBlock)();
// Returns whether the action was handled.
typedef BOOL (^LeanplumActionBlock)(LPActionContext* context);
typedef void (^LeanplumRegisterDeviceResponseBlock)(NSString *email);
typedef void (^LeanplumRegisterDeviceBlock)(LeanplumRegisterDeviceResponseBlock response);
typedef void (^LeanplumRegisterDeviceFinishedBlock)(BOOL success);
typedef void (^LeanplumHandleNotificationBlock)();
typedef void (^LeanplumShouldHandleNotificationBlock)(NSDictionary *userInfo, LeanplumHandleNotificationBlock response);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
typedef UIBackgroundFetchResult LeanplumUIBackgroundFetchResult;
#else
typedef int LeanplumUIBackgroundFetchResult;
#endif
typedef void (^LeanplumFetchCompletionBlock)(LeanplumUIBackgroundFetchResult result);

typedef enum {
    kLeanplumRegistrationModeOnlyWhenUnregistered = 1,
    kLeanplumRegistrationModeAlways = 2,
    kLeanplumRegistrationModeNever = 3,
} LeanplumRegistrationMode;

// This is a bit-field. To choose both kinds, use
// kLeanplumActionKindMessage | kLeanplumActionKindAction
typedef enum {
    kLeanplumActionKindMessage = 0b1,
    kLeanplumActionKindAction = 0b10,
} LeanplumActionKind;

// What type of device ID to use.
// By default, we use the identifier for vendor.
// However, if you need to link to some third-party attribution frameworks, switch to the
// identifier for advertisers.
typedef enum {
    kLeanplumDeviceIdModeAdvertisingIdentifier = 2,
    kLeanplumDeviceIdModeVendorIdentifier = 3,
    // Default. This is useful if you frequently uninstall the app on your test devices, as
    // the device ID doesn't change.
    kLeanplumDeviceIdModeVendorIdentifierInProdAndAdvertisingIdentifierInDev = 4
} LeanplumDeviceIdMode;

@interface Leanplum : NSObject

// Optional. Use these methods to configure Leanplum.
+ (void)setApiHostName:(NSString *)hostName withServletName:(NSString *)servletName usingSsl:(BOOL)ssl;
// The default timeout is 10 seconds for requests, and 15 seconds for file downloads.
+ (void)setNetworkTimeoutSeconds:(int)seconds;
+ (void)setNetworkTimeoutSeconds:(int)seconds forDownloads:(int)downloadSeconds;
// Advanced: Whether new variables can be downloaded mid-session. By default, this is disabled.
// Currently, if this is enabled, new variables can only be downloaded if a push notification is sent
// while the app is running, and the notification's metadata hasn't be downloaded yet.
+ (void)setCanDownloadContentMidSessionInProductionMode:(BOOL)value;

// Development mode options:
//
// By default, Leanplum will check for updates to the Leanplum SDK in development mode
// and notify you when your app starts if an update is available.
// Use this method to override this setting.
+ (void)setUpdateCheckingEnabledInDevelopmentMode:(BOOL)enabled;
// By default, Leanplum will hash file variables to determine if they're modified and need
// to be uploaded to the server if we're running in the simulator.
// Use this method to override this setting.
// Setting this to NO will reduce startup latency in development mode, but it's possible
// that Leanplum will not always have the most up-to-date versions of your resources.
+ (void)setFileHashingEnabledInDevelopmentMode:(BOOL)enabled;
// Choose when to show the registration prompt.
// Default: kLeanplumRegistrationModeOnlyWhenUnregistered.
+ (void)setRegistrationRequiredInDevelopmentMode:(LeanplumRegistrationMode)mode;

// Must call one of these before issuing any calls to the API, including start.
+ (void)setAppId:(NSString *)appId withDevelopmentKey:(NSString *)accessKey;
+ (void)setAppId:(NSString *)appId withProductionKey:(NSString *)accessKey;

// Call this before start if you want to update the UI on the fly with the WYSIWYG editor.
// This would update your UIViewController interfaces and events on viewWillAppear: automatically
// Alternatively, you can do it manually with the two update methods below.
+ (void)syncViews;
// Call this to manually update the UI of your ViewController
// Typically this would be inside the viewWillAppear method of your UIViewController,
// if you didn't call [Leanplum syncViews].
+ (void)updateViewControllerInterface:(UIViewController *)viewController;
// Call this to manually update the cells of your ViewController tables.
// Typically this would be inside the tableView:cellForRowAtIndexPath: method of your
// UITableViewDataSource, if you didn't call [Leanplum syncViews].
+ (void)updateInterfaceForViewController:(UIViewController *)viewController
                               tableView:(UITableView *)tableView
                                    cell:(UITableViewCell *)cell
                             atIndexPath:(NSIndexPath *)indexPath;
// Call this to manually update the events of your ViewController.
// Typically this would be inside the viewWillAppear method of your UIViewController,
// if you didn't call [Leanplum syncViews].
+ (void)updateViewControllerEvents:(UIViewController *)viewController;

// Call this to manually show a view controller interface preview.
// Use this only in a selector passed to [Leanplum addInterfaceChangedResponder:withSelector:]
// or in the block passed to [Leanplum onInterfaceChanged:]
+ (void)showViewControllerInterfacePreview:(UIViewController *)viewController;
// Call this to manually show a preview of updated cells of your ViewController tables.
// Typically this would be inside the tableView:cellForRowAtIndexPath: method of your
// UITableViewDataSource, if you didn't call [Leanplum syncViews].
+ (void)showInterfacePreviewForViewController:(UIViewController *)viewController
                                    tableView:(UITableView *)tableView
                                         cell:(UITableViewCell *)cell
                                  atIndexPath:(NSIndexPath *)indexPath;

// Sets what type of device ID to use.
// By default, we use kLeanplumDeviceIdModeVendorIdentifier.
+ (void)setDeviceIdMode:(LeanplumDeviceIdMode)mode;

// Syncs resources between Leanplum and the current app.
// You should only call one of these methods once, and before [Leanplum start].
+ (void)syncResources;
// Same as above except restricts paths to case-insensitive regex patterns matched in
// patternsToIncludeOrNil, excluding patterns matched in patternsToExcludeOrNil.
// For example, to sync only PNG and NIB files:
//   [Leanplum syncResourcePaths:@[@"\\.(png|nib)$"] excluding:nil];
// If you exclude files, you must use the standard methods within NSBundle to
// retrieve the files' locations.
+ (void)syncResourcePaths:(NSArray *)patternsToIncludeOrNil excluding:(NSArray *)patternsToExcludeOrNil;

// Call this when your application starts. The appId is assigned to you from
// our server. This will initiate a call to Leanplum's servers to get the values
// of the variables used in your app.
// Instead of providing a response block here, you can call onStart.
// User attributes get copied from session to session, so you only need to set them
// whenever they change. You may use up to 50 different user attributes for your app.
+ (void)start;
+ (void)startWithResponseHandler:(LeanplumStartBlock)response;
+ (void)startWithUserAttributes:(NSDictionary *)attributes;
+ (void)startWithUserId:(NSString *)userId;
+ (void)startWithUserId:(NSString *)userId responseHandler:(LeanplumStartBlock)response;
+ (void)startWithUserId:(NSString *)userId userAttributes:(NSDictionary *)attributes;
+ (void)startWithUserId:(NSString *)userId userAttributes:(NSDictionary *)attributes
        responseHandler:(LeanplumStartBlock)response;

// Whether or not Leanplum has finished starting.
+ (BOOL)hasStarted;
+ (BOOL)hasStartedAndRegisteredAsDeveloper;

// Block to call when the start call finishes, and variables are returned
// back from the server. Calling this multiple times will call each block
// in succession.
+ (void)onStartResponse:(LeanplumStartBlock)block;

// Block to call when the variables receive new values from the server.
// This will be called on start, and also later on if the user is in an experiment
// that can update in realtime.
+ (void)onVariablesChanged:(LeanplumVariablesChangedBlock)block;

// Block to call when the interface receive new values from the server.
// This will be called on start, and also later on if the user is in an experiment
// that can update in realtime.
+ (void)onInterfaceChanged:(LeanplumInterfaceChangedBlock)block;

// Block to call when the events receive new values from the server.
// This will be called on start, and also later on if the user is in an experiment
// that can update in realtime.
+ (void)onEventsChanged:(LeanplumEventsChangedBlock)block;

// Block to call when no more file downloads are pending (either when
// no files needed to be downloaded or all downloads have been completed).
+ (void)onVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block;

// Block to call ONCE when no more file downloads are pending (either when
// no files needed to be downloaded or all downloads have been completed).
+ (void)onceVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block;

// Defines new action and message types to be performed at points set up on the Leanplum dashboard.
+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args;
+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
         withOptions:(NSDictionary *)options;
+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
       withResponder:(LeanplumActionBlock)responder;
+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
         withOptions:(NSDictionary *)options
       withResponder:(LeanplumActionBlock)responder;

// Block to call when an action is received, such as to show a message to the user.
+ (void)onAction:(NSString *)actionName invoke:(LeanplumActionBlock)block;

// Call this to handle a push notification for apps that use Background Notifications.
// Without background notifications, Leanplum handles them automatically.
+ (void)handleNotification:(NSDictionary *)userInfo
    fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler;

// Block to call that decides whether a notification should be displayed when it is
// received while the app is running, and the notification is not muted.
// Overrides the default behavior of showing an alert view with the notification message.
+ (void)setShouldOpenNotificationHandler:(LeanplumShouldHandleNotificationBlock)block;

// Block to call when the device needs to be registered in development mode.
// This block will get called instead of the prompt showing up.
+ (void)onRegisterDevice:(LeanplumRegisterDeviceBlock)block;

+ (void)onRegisterDeviceDidFinish:(LeanplumRegisterDeviceFinishedBlock)block;

// Similar to the methods above but uses NSInvocations instead of blocks.
+ (void)addStartResponseResponder:(id)responder withSelector:(SEL)selector;
+ (void)addVariablesChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)addInterfaceChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)addEventsChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)addVariablesChangedAndNoDownloadsPendingResponder:(id)responder withSelector:(SEL)selector;
+ (void)addResponder:(id)responder withSelector:(SEL)selector forActionNamed:(NSString *)actionName;
+ (void)removeStartResponseResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeVariablesChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeInterfaceChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeEventsChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeVariablesChangedAndNoDownloadsPendingResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeResponder:(id)responder withSelector:(SEL)selector forActionNamed:(NSString *)actionName;

// Sets additional user attributes after the session has started.
// Variables retrieved by start won't be targeted based on these attributes, but
// they will count for the current session for reporting purposes.
// Only those attributes given in the dictionary will be updated. All other
// attributes will be preserved.
+ (void)setUserAttributes:(NSDictionary *)attributes;

// Updates a user ID after session start.
+ (void)setUserId:(NSString *)userId;

// Updates a user ID after session start with a dictionary of user attributes.
+ (void)setUserId:(NSString *)userId withUserAttributes:(NSDictionary *)attributes;

// Advances to a particular state in your application. The string can be
// any value of your choosing, and will show up in the dashboard.
// A state is a section of your app that the user is currently in.
+ (void)advanceTo:(NSString *)state;

// Info is anything else you want to log with the state. For example, if the state
// is watchVideo, info could be the video ID.
+ (void)advanceTo:(NSString *)state withInfo:(NSString *)info;

// You can specify up to 50 types of parameters per app across all events and state.
// The parameter keys must be strings, and values either strings or numbers.
+ (void)advanceTo:(NSString *)state withParameters:(NSDictionary *)params;
+ (void)advanceTo:(NSString *)state withInfo:(NSString *)info andParameters:(NSDictionary *)params;

// Pauses the current state.
// You can use this if your game has a "pause" mode. You shouldn't call it
// when someone switches out of your app because that's done automatically.
+ (void)pauseState;

// Resumes the current state.
+ (void)resumeState;

// Logs a particular event in your application. The string can be
// any value of your choosing, and will show up in the dashboard.
+ (void)track:(NSString *)event;
+ (void)track:(NSString *)event withValue:(double)value;
+ (void)track:(NSString *)event withInfo:(NSString *)info;
+ (void)track:(NSString *)event withValue:(double)value andInfo:(NSString *)info;

// See above for the explanation of params.
+ (void)track:(NSString *)event withParameters:(NSDictionary *)params;
+ (void)track:(NSString *)event withValue:(double)value andParameters:(NSDictionary *)params;

// Gets the path for a particular resource. The resource can be overridden by the server.
+ (NSString *)pathForResource:(NSString *)name ofType:(NSString *)extension;
+ (id)objectForKeyPath:(id)firstComponent, ... NS_REQUIRES_NIL_TERMINATION;
+ (id)objectForKeyPathComponents:(NSArray *)pathComponents;

// Forces content to update from the server. If variables have changed, the
// appropriate callbacks will fire. Use sparingly as if the app is updated,
// you'll have to deal with potentially inconsistent state or user experience.
+ (void)forceContentUpdate;
// Similar to above except the provided callback will always fire regardless
// of whether the variables have changed.
+ (void)forceContentUpdate:(LeanplumVariablesChangedBlock)block;

// This should be your first statement in a unit test. This prevents
// Leanplum from communicating with the server.
+ (void)enableTestMode;

@end

@interface LeanplumCompatibility : NSObject

// Used only for compatibility with Google Analytics.
+ (void)gaTrack:(NSObject *)trackingObject;

@end

@class LPVar;

@protocol LPVarDelegate <NSObject>
@optional
- (void)fileIsReady:(LPVar *)var;
- (void)valueDidChange:(LPVar *)var;
@end

// A variable is any part of your application that can change from an experiment.
// Check out the macros at the top of the file for defining variables more easily.
@interface LPVar : NSObject

+ (LPVar *)define:(NSString *)name;
+ (LPVar *)define:(NSString *)name withInt:(int)defaultValue;
+ (LPVar *)define:(NSString *)name withFloat:(float)defaultValue;
+ (LPVar *)define:(NSString *)name withDouble:(double)defaultValue;
+ (LPVar *)define:(NSString *)name withCGFloat:(CGFloat)cgFloatValue;
+ (LPVar *)define:(NSString *)name withShort:(short)defaultValue;
+ (LPVar *)define:(NSString *)name withChar:(char)defaultValue;
+ (LPVar *)define:(NSString *)name withBool:(BOOL)defaultValue;
+ (LPVar *)define:(NSString *)name withString:(NSString *)defaultValue;
+ (LPVar *)define:(NSString *)name withNumber:(NSNumber *)defaultValue;
+ (LPVar *)define:(NSString *)name withInteger:(NSInteger)defaultValue;
+ (LPVar *)define:(NSString *)name withLong:(long)defaultValue;
+ (LPVar *)define:(NSString *)name withLongLong:(long long)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedChar:(unsigned char)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedInt:(unsigned int)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedInteger:(NSUInteger)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedLong:(unsigned long)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedLongLong:(unsigned long long)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedShort:(unsigned short)defaultValue;
+ (LPVar *)define:(NSString *)name withFile:(NSString *)defaultFilename;
+ (LPVar *)define:(NSString *)name withDictionary:(NSDictionary *)defaultValue;
+ (LPVar *)define:(NSString *)name withArray:(NSArray *)defaultValue;
+ (LPVar *)define:(NSString *)name withColor:(UIColor *)defaultValue;

- (NSString *)name;
- (NSArray *)nameComponents;

- (id)defaultValue;
- (NSString *)kind;

// Whether the variable has changed since the last time the app was run.
- (BOOL)hasChanged;

- (void)onFileReady:(LeanplumVariablesChangedBlock)block;
- (void)onValueChanged:(LeanplumVariablesChangedBlock)block;

// Sets the delegate in order to use the non-block versions of the above methods.
- (void)setDelegate:(id <LPVarDelegate>)delegate;

- (id)objectForKey:(NSString *)key;
- (id)objectAtIndex:(NSUInteger )index;
- (id)objectForKeyPath:(id)firstComponent, ... NS_REQUIRES_NIL_TERMINATION;
- (NSUInteger)count;

- (NSNumber *)numberValue;
- (NSString *)stringValue;
- (NSString *)fileValue;
- (UIImage *)imageValue;
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
- (UIColor *)colorValue;

@end

@interface LPActionArg : NSObject

+ (LPActionArg *)argNamed:(NSString *)name withNumber:(NSNumber *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withString:(NSString *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withBool:(BOOL)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withFile:(NSString *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withDict:(NSDictionary *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withArray:(NSArray *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withAction:(NSString *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withColor:(UIColor *)defaultValue;

- (NSString *)name;
- (NSString *)kind;
- (id)defaultValue;

@end

@interface LPActionContext : NSObject

- (NSString *)actionName;

- (NSString *)stringNamed:(NSString *)name;
- (NSString *)fileNamed:(NSString *)name;
- (NSNumber *)numberNamed:(NSString *)name;
- (BOOL)boolNamed:(NSString *)name;
- (NSDictionary *)dictionaryNamed:(NSString *)name;
- (NSArray *)arrayNamed:(NSString *)name;
- (UIColor *)colorNamed:(NSString *)name;

// Runs the action given by the "name" key.
- (void)runActionNamed:(NSString *)name;
// Runs and tracks an event for the action given by the "name" key.
// This will track an event if no action is set.
- (void)runTrackedActionNamed:(NSString *)name;

// Tracks an event in the context of the current message.
- (void)track:(NSString *)event withValue:(double)value andParameters:(NSDictionary *)params;

// Prevents the currently active message from appearing again in the future.
- (void)muteFutureMessagesOfSameKind;

@end
