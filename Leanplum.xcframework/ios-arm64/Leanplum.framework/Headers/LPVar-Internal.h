//
//  LPVar.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LeanplumInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPVar ()

- (instancetype)initWithName:(NSString *)name
              withComponents:(NSArray *)components
            withDefaultValue:(NSObject *)defaultValue
                    withKind:(NSString *)kind;

@property (readonly) BOOL isInternal;
@property (readonly, strong) NSString *name;
@property (readonly, strong) NSArray *nameComponents;
@property (readonly) BOOL hadStarted;
@property (readonly, strong) NSString *kind;
@property (readonly, strong) NSMutableArray *fileReadyBlocks;
@property (readonly, strong) NSMutableArray *valueChangedBlocks;
@property (readonly) BOOL fileIsPending;
@property (nonatomic, unsafe_unretained, nullable) id <LPVarDelegate> delegate;
@property (readonly) BOOL hasChanged;

- (void) update;
- (void) cacheComputedValues;
- (void) triggerFileIsReady;
- (void) triggerValueChanged;

+(BOOL)printedCallbackWarning;
+(void)setPrintedCallbackWarning:(BOOL)newPrintedCallbackWarning;

@end

NS_ASSUME_NONNULL_END
