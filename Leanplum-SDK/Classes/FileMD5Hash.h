//
//  FileMD5Hash.h
//  Leanplum
//
//  Created by Andrew First on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef Leanplum_FileMD5Hash_h
#define Leanplum_FileMD5Hash_h

// In bytes
#define FileHashDefaultChunkSizeForReadingData 4096

// Core Foundation
#include <CoreFoundation/CoreFoundation.h>

CFStringRef Leanplum_FileMD5HashCreateWithPath(CFStringRef filePath,
                                               size_t chunkSizeForReadingData);

#endif
