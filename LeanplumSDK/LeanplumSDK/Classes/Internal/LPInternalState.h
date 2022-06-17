//
//  LPInternalState.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import <Foundation/Foundation.h>
#import "LPRegisterDevice.h"
#import "LPActionTriggerManager.h"

@interface LPInternalState : NSObject

@property(strong, nonatomic) NSMutableArray *startBlocks;
@property(strong, nonatomic) NSMutableArray *variablesChangedBlocks;
@property(strong, nonatomic) NSMutableArray *noDownloadsBlocks;
@property(strong, nonatomic) NSMutableArray *onceNoDownloadsBlocks;
@property(strong, nonatomic) NSMutableArray *startIssuedBlocks;
@property(strong, nonatomic) NSMutableSet *startResponders, *variablesChangedResponders, *noDownloadsResponders;
@property(assign, nonatomic) NSUncaughtExceptionHandler *customExceptionHandler;
@property(strong, nonatomic) LPRegisterDevice *registration;
@property(assign, nonatomic) BOOL calledStart, hasStarted, hasStartedAndRegisteredAsDeveloper, startSuccessful, issuedStart;
@property(strong, nonatomic) LPActionTriggerManager *actionManager;
@property(strong, nonatomic) NSString *appVersion;
@property(strong, nonatomic) NSMutableArray *userAttributeChanges;
@property(assign, nonatomic) BOOL isVariantDebugInfoEnabled;
@property(assign, nonatomic) BOOL calledHandleNotification;

+ (LPInternalState *)sharedState;

@end
