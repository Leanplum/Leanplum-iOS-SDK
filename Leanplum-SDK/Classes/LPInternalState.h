//
//  LPInternalState.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import <Foundation/Foundation.h>
#import "LPRegisterDevice.h"
#import "LPActionManager.h"

@interface LPInternalState : NSObject
{
    NSMutableArray *_startBlocks, *_variablesChangedBlocks, *_interfaceChangedBlocks,
    *_eventsChangedBlocks, *_noDownloadsBlocks, *_onceNoDownloadsBlocks;
    NSMutableDictionary *_actionBlocks, *_actionResponders;
    NSMutableSet *_startResponders, *_variablesChangedResponders, *_interfaceChangedResponders,
    *_eventsChangedResponders, *_noDownloadsResponders;
    NSUncaughtExceptionHandler *_customExceptionHandler;
    LPRegisterDevice *_registration;
    BOOL _calledStart, _hasStarted, _hasStartedAndRegisteredAsDeveloper, _startSuccessful,
    _issuedStart;
    BOOL _initializedMessageTemplates;
    BOOL _stripViewControllerFromState;
    BOOL _isScreenTrackingEnabled;
    BOOL _isInterfaceEditingEnabled;
    LPActionManager *_actionManager;
    NSString *_deviceId;
    NSString *_appVersion;
    NSMutableArray *_userAttributeChanges;
    BOOL _calledHandleNotification;
}

@property(strong, nonatomic) NSMutableArray *startBlocks, *variablesChangedBlocks,
*interfaceChangedBlocks, *eventsChangedBlocks, *noDownloadsBlocks, *onceNoDownloadsBlocks,
*startIssuedBlocks;
@property(strong, nonatomic) NSMutableDictionary *actionBlocks, *actionResponders;
@property(strong, nonatomic) NSMutableSet *startResponders, *variablesChangedResponders,
*interfaceChangedResponders, *eventsChangedResponders, *noDownloadsResponders;
@property(assign, nonatomic) NSUncaughtExceptionHandler *customExceptionHandler;
@property(strong, nonatomic) LPRegisterDevice *registration;
@property(assign, nonatomic) BOOL calledStart, hasStarted, hasStartedAndRegisteredAsDeveloper,
startSuccessful, issuedStart, initializedMessageTemplates, stripViewControllerFromState;
@property(strong, nonatomic) LPActionManager *actionManager;
@property(strong, nonatomic) NSString *deviceId;
@property(strong, nonatomic) NSString *appVersion;
@property(strong, nonatomic) NSMutableArray *userAttributeChanges;
@property(assign, nonatomic) BOOL isScreenTrackingEnabled;
@property(assign, nonatomic) BOOL isVariantDebugInfoEnabled;
@property(assign, nonatomic) BOOL isInterfaceEditingEnabled;
@property(assign, nonatomic) BOOL calledHandleNotification;

+ (LPInternalState *)sharedState;

@end
