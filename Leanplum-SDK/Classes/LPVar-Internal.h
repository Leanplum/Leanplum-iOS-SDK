//
//  LPVar.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "Leanplum-Internal.h"

@interface LPVar ()

- (instancetype)initWithName:(NSString *)name withComponents:(NSArray *)components
            withDefaultValue:(NSObject *)defaultValue withKind:(NSString *)kind;

@property (readonly) BOOL private_IsInternal;
@property (readonly, strong) NSString *private_Name;
@property (readonly, strong) NSArray *private_NameComponents;
@property (readonly, strong) NSString *private_StringValue;
@property (readonly, strong) NSNumber *private_NumberValue;
@property (readonly) BOOL private_HadStarted;
@property (readonly, strong) id private_Value;
@property (readonly, strong) id private_DefaultValue;
@property (readonly, strong) NSString *private_Kind;
@property (readonly, strong) NSMutableArray *private_FileReadyBlocks;
@property (readonly, strong) NSMutableArray *private_valueChangedBlocks;
@property (readonly) BOOL private_FileIsPending;
@property (nonatomic, unsafe_unretained) id <LPVarDelegate> private_Delegate;
@property (readonly) BOOL private_HasChanged;

- (void) update;
- (void) cacheComputedValues;
- (void) triggerFileIsReady;
- (void) triggerValueChanged;

+(BOOL)printedCallbackWarning;
+(void)setPrintedCallbackWarning:(BOOL)newPrintedCallbackWarning;

@end
