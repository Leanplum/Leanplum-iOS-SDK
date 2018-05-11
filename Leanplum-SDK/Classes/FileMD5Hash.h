//
//  FileMD5Hash.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
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
