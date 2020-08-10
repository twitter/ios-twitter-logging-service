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

#import <TwitterLoggingService/TLS_Project.h>
#import <TwitterLoggingService/TLSDeclarations.h>
#import <TwitterLoggingService/TLSLog.h>

NSErrorDomain const TLSErrorDomain = @"TLSErrorDomain";

@implementation TLSLogMessageInfo
{
    NSDictionary<NSNumber *, NSString *> *_formattedMessages;
    NSString *_fileFunctionLineString;
}

- (instancetype)initWithLevel:(TLSLogLevel)level
                         file:(NSString *)file
                     function:(NSString *)function
                         line:(NSInteger)line
                      channel:(NSString *)channel
                    timestamp:(NSDate *)timestamp
                  logLifespan:(NSTimeInterval)logLifespan
                     threadId:(unsigned int)threadId
                   threadName:(NSString *)threadName
                contextObject:(id)contextObject
                      message:(NSString *)message
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
    return [self composeFormattedMessageWithOptions:TLSComposeLogMessageInfoDefaultOptions];
}

- (NSString *)composeFormattedMessageWithOptions:(TLSComposeLogMessageInfoOptions)options
{
    NSNumber *optionsKey = @(options);
    NSString *composedMessage = _formattedMessages[optionsKey];
    if (!composedMessage) {

        // wrap work in autorelease pool so that on exit memory impact
        // is not different than a property access

        @autoreleasepool {

            const TLSLogLevel level = self.level;
            NSMutableString *mComposedMessage = [[NSMutableString alloc] init];

            // TIMESTAMP
            {
                NSString *logTimestamp = nil;
                if (TLS_BITMASK_INTERSECTS_FLAGS(options, TLSComposeLogMessageInfoLogTimestampAsTimeSinceLoggingStarted)) {
                    NSTimeInterval logLifespan = self.logLifespan;
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

                    logTimestamp = [NSString stringWithFormat:((negative) ? @"-%02lu:%02lu:%02lu.%03lu" : @"%03lu:%02lu:%02lu.%03lu"),
                                    hours,
                                    minutes,
                                    seconds,
                                    msecs];
                } else if (TLS_BITMASK_INTERSECTS_FLAGS(options, TLSComposeLogMessageInfoLogTimestampAsLocalTime)) {
                    static NSDateFormatter *sFormatter = nil;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        sFormatter = [[NSDateFormatter alloc] init];
                        sFormatter.dateFormat = @"HH':'mm':'ss'.'SSS";
                        sFormatter.timeZone = [NSTimeZone localTimeZone];
                    });
                    logTimestamp = [sFormatter stringFromDate:self.timestamp];
                } else if (TLS_BITMASK_INTERSECTS_FLAGS(options, TLSComposeLogMessageInfoLogTimestampAsUTCTime)) {
                    static NSDateFormatter *sFormatter = nil;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        sFormatter = [[NSDateFormatter alloc] init];
                        sFormatter.dateFormat = @"HH':'mm':'ss'.'SSS";
                        sFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0]; // UTC == GMT
                    });
                    logTimestamp = [sFormatter stringFromDate:self.timestamp];
                }

                if (logTimestamp) {
                    [mComposedMessage appendFormat:@"[%@]", logTimestamp];
                }
            }

            // THREAD
            if (TLS_BITMASK_INTERSECTS_FLAGS(options, TLSComposeLogMessageInfoLogThreadId | TLSComposeLogMessageInfoLogThreadName)) {
                [mComposedMessage appendString:@"["];
                NSString *threadName = self.threadName;
                const BOOL hasName = TLS_BITMASK_INTERSECTS_FLAGS(options, TLSComposeLogMessageInfoLogThreadName)
                                     && (threadName != nil);
                if (hasName) {
                    [mComposedMessage appendString:threadName];
                }
                if (TLS_BITMASK_INTERSECTS_FLAGS(options, TLSComposeLogMessageInfoLogThreadId)) {
                    [mComposedMessage appendFormat:(hasName) ? @"(0x%x)" : @"0x%x", self.threadId];
                }
                [mComposedMessage appendString:@"]"];
            }

            // CHANNEL
            if (TLS_BITMASK_INTERSECTS_FLAGS(options, TLSComposeLogMessageInfoLogChannel)) {
                [mComposedMessage appendFormat:@"[%@]", self.channel];
            }

            // LEVEL
            if (TLS_BITMASK_INTERSECTS_FLAGS(options, TLSComposeLogMessageInfoLogLevel)) {
                [mComposedMessage appendFormat:@"[%@]", TLSLogLevelToString(level)];
            }

            // Call Site Info
            if (TLS_BITMASK_INTERSECTS_FLAGS(options, TLSComposeLogMessageInfoLogCallsiteInfoAlways | TLSComposeLogMessageInfoLogCallsiteInfoForWarnings) && level <= TLSLogLevelWarning) {
                [mComposedMessage appendString:[self composeFileFunctionLineString]];
            }

            [mComposedMessage appendFormat:@" : %@", self.message];

            composedMessage = [mComposedMessage copy];
            if (TLS_BITMASK_EXCLUDES_FLAGS(options, TLSComposeLogMessageInfoDoNotCache)) {
                if (!_formattedMessages) {
                    _formattedMessages = @{ optionsKey : composedMessage };
                } else {
                    NSMutableDictionary<NSNumber *, NSString *> *mMessages = [_formattedMessages mutableCopy];
                    mMessages[optionsKey] = composedMessage;
                    _formattedMessages = [mMessages copy];
                }
            }
        } // autoreleasepool
    }
    return composedMessage;
}

- (NSString *)composeFileFunctionLineString
{
    if (!_fileFunctionLineString) {
        _fileFunctionLineString = [NSString stringWithFormat:@"(%@:%li %@)", self.file.lastPathComponent, (long)self.line, self.function];
    }
    return _fileFunctionLineString;
}

@end

NSString *TLSLogLevelToString(TLSLogLevel level)
{
    static NSString * const sLevelStrings[] = {
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
