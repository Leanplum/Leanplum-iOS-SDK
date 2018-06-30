//
//  LPVar.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LeanplumInternal.h"

@interface LPVar ()

- (instancetype)initWithName:(NSString *)name withComponents:(NSArray *)components
            withDefaultValue:(NSObject *)defaultValue withKind:(NSString *)kind;

@property (nonatomic, assign) BOOL isInternal;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *nameComponents;
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic, assign) BOOL hadStarted;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) id defaultValue;
@property (nonatomic, strong) NSString *kind;
@property (nonatomic, strong) NSMutableArray *fileReadyBlocks;
@property (nonatomic, strong) NSMutableArray *valueChangedBlocks;
@property (nonatomic, assign) BOOL fileIsPending;
@property (nonatomic, weak) id <LPVarDelegate> delegate;
@property (nonatomic, assign) BOOL hasChanged;

- (void) update;
- (void) cacheComputedValues;
- (void) triggerFileIsReady;
- (void) triggerValueChanged;

+(BOOL)printedCallbackWarning;
+(void)setPrintedCallbackWarning:(BOOL)newPrintedCallbackWarning;

@end
