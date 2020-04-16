//
//  LPOpenUrlMessageTemplate+Extenstion.h
//  Leanplum-SDK_Tests
//
//  Created by Dejan . Krstevski on 16.04.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPOpenUrlMessageTemplate.h"

#ifndef LPOpenUrlMessageTemplate_Extenstion_h
#define LPOpenUrlMessageTemplate_Extenstion_h

@interface LPOpenUrlMessageTemplate(UnitTest)

- (NSString *)urlEncodedStringFromString:(NSString *)urlString;

@end

#endif /* LPOpenUrlMessageTemplate_Extenstion_h */
