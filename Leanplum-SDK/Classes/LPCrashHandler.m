//
//  LPCrashHandler.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 6/28/18.
//

#import "LPCrashHandler.h"

@interface LPCrashHandler()

@property (nonatomic, strong) id<LPCrashReporting> crashReporter;

@end

@implementation LPCrashHandler

+(instancetype)sharedCrashHandler
{
    static LPCrashHandler *sharedCrashHandler = nil;
    @synchronized(self) {
        if (!sharedCrashHandler)
            sharedCrashHandler = [[self alloc] init];
    }
    return sharedCrashHandler;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeRaygunReporter];
    }
    return self;
}

-(void)initializeRaygunReporter
{
    _crashReporter = [[NSClassFromString(@"LPRaygunCrashReporter") alloc] init];
    
}

-(void)reportException:(NSException *)exception
{
    if (self.crashReporter) {
        [self.crashReporter reportException:exception];
    }
}

@end
