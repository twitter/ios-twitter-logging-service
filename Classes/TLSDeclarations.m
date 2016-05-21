//
//  TLSDeclarations.m
//  TwitterLoggingService
//
//  Created on 12/11/13.
//  Copyright (c) 2016 Twitter, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//          http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#include <sys/sysctl.h>

#import "TLS_Project.h"
#import "TLSDeclarations.h"

NSString * const TLSErrorDomain = @"TLSErrorDomain";

@implementation TLSLogMessageInfo
{
    NSString *_formattedMessage;
    NSString *_fileFunctionLineString;
}

- (instancetype)initWithLevel:(TLSLogLevel)level file:(NSString *)file function:(NSString *)function line:(unsigned int)line channel:(NSString *)channel timestamp:(NSDate *)timestamp logLifespan:(NSTimeInterval)logLifespan threadId:(unsigned int)threadId threadName:(NSString *)threadName contextObject:(id)contextObject message:(NSString *)message
{
    if (self = [super init]) {
        _level = level;
        _file = [file copy];
        _function = [function copy];
        _line = line;
        _channel = [channel copy];
        _contextObject = contextObject;
        _timestamp = timestamp;
        _logLifespan = logLifespan;
        _threadId = threadId;
        _threadName = [threadName copy];
        _message = [message copy];
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (NSString *)composeFormattedMessage
{
    if (!_formattedMessage) {
        // wrap work in autorelease pool so that on exit memory impact
        // is not different than a property access
        @autoreleasepool {
            NSTimeInterval logLifespan = self.logLifespan;
            const TLSLogLevel level = self.level;

            NSString *fileFunctionInfo = nil;
            if (level <= TLSLogLevelWarning) {
                fileFunctionInfo = [self composeFileFunctionLineString];
            }

            const BOOL negative = logLifespan < 0.0;
            if (negative) {
                logLifespan *= -1.0;
            }

            unsigned long seconds = (unsigned long)logLifespan;
            unsigned long minutes = seconds / 60;

            const unsigned long msecs = (logLifespan - (NSTimeInterval)seconds) * 1000;
            const unsigned long hours = minutes / 60;

            seconds -= minutes * 60;
            minutes -= hours * 60;

            NSString *logTimestamp = [NSString stringWithFormat:((negative) ? @"-%02lu:%02lu:%02lu.%03lu" : @"%03lu:%02lu:%02lu.%03lu"), hours, minutes, seconds, msecs];

            _formattedMessage = [NSString stringWithFormat:@"[%@][0x%x][%@][%@]%@ : %@", logTimestamp, self.threadId, self.channel, TLSLogLevelToString(level), (fileFunctionInfo) ?: @"", self.message];
        }
    }
    return _formattedMessage;
}

- (NSString *)composeFileFunctionLineString
{
    if (!_fileFunctionLineString) {
        _fileFunctionLineString = [NSString stringWithFormat:@"(%@:%d %@)", self.file.lastPathComponent, self.line, self.function];
    }
    return _fileFunctionLineString;
}

@end

NSString *TLSLogLevelToString(TLSLogLevel level)
{
    static NSString *sLevelStrings[] = {
        @"OMG",
        @"ALR",
        @"CRI",
        @"ERR",
        @"WRN",
        @"not",
        @"inf",
        @"dbg"
    };

    TLS_COMPILER_ASSERT(((sizeof(sLevelStrings) / sizeof(NSString *)) == TLSLogLevelCount), sLevelStrings_NOT_EQUAL_TO_TLSLogLevelCount);

    if (level >= TLSLogLevelCount) {
#if DEBUG
        NSCAssert(false, @"Unknown logging level!");
#endif
        return [NSString stringWithFormat:@"???[%tu]", level];
    }

    return sLevelStrings[level];
}

NSString *TLSLogChannelApplicationDefault()
{
    static NSString *sAppChannel = nil;
    static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
        CFBundleRef bundle = CFBundleGetMainBundle();
        if (bundle) {
            sAppChannel = (__bridge NSString *)(CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleNameKey));
            if (!sAppChannel) {
                sAppChannel = (__bridge NSString *)(CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleExecutableKey));
            }
        }
        if (!sAppChannel) {
            sAppChannel = TLSGetProcessBinaryName();
        }
        if (!sAppChannel) {
            sAppChannel = @"Default";
        }
    });
    return sAppChannel;
}

NSString *TLSGetProcessBinaryName()
{
    NSString *name = nil;

    // This will retrieve the executing argument of the process,
    // which could be an absolute or relative path.
    // It (unfortunately) could also be a link.

    // Set up our sysctl variables
    int mib[3];
    size_t argMax = 0;
    size_t sizeArgMax = sizeof(argMax);
    char *args = NULL;

    mib[0] = CTL_KERN;
    mib[1] = KERN_ARGMAX;
    mib[2] = 0;

    // determine the max size we'd need to allocate
    if (sysctl(mib, 2, &argMax, &sizeArgMax, NULL, 0) != -1) {
        if (sizeArgMax > 0 && argMax > 0) {
            args = (char*)malloc(argMax);
        }
    }

    if (args) {
        mib[1] = KERN_PROCARGS2;
        mib[2] = getpid();

        // get the kernal process arguments
        if (sysctl(mib, 3, args, &argMax, NULL, 0) != -1) {
            // get to the second argument by finding the first NULL character
            char *strP;
            char *termP = &args[argMax];
            for (strP = args; strP < termP; strP++) {
                if ('\0' == *strP) {
                    break;
                }
            }

            // strip out the leading NULL characters so we get to the process launch path
            while (strP < termP && *strP == '\0') {
                strP++;
            }

            if (strP < termP) {
                // Ensure we don't go out of bounds in case there is malicious code
                // that doesn't NULL terminate it's arguments.
                int len = 0;
                for (char* strP2 = strP; *strP2 != '\0' && strP2 < termP; strP2++) {
                    len++;
                }

                char cPath[PATH_MAX+1] = { 0 };
                if (PATH_MAX < len) {
                    // strip leading characters if necessary to fit in our buffer
                    strP += len - PATH_MAX;
                }
                memcpy(cPath, strP, len);
                name = [@(cPath) lastPathComponent];
            }
        }

        free(args);
    }

    return name;
}
