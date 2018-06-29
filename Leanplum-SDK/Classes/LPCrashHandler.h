//
//  LPCrashHandler.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 6/28/18.
//

#import <Foundation/Foundation.h>

@protocol LPCrashReporting
-(void)reportException:(NSException *)exception;
@end

@interface LPCrashHandler : NSObject

+(instancetype)sharedCrashHandler;
-(void)reportException:(NSException *)exception;

@end
