//
//  TLSConsoleOutputStreams.m
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

#import "TLSConsoleOutputStreams.h"

#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
#define OS_LOG_AVAILABLE 1
#elif TARGET_OS_TV && __TV_OS_VERSION_MAX_ALLOWED >= 100000
#define OS_LOG_AVAILABLE 1
#elif TARGET_OS_WATCH && __WATCH_OS_VERSION_MAX_ALLOWED >= 30000
#define OS_LOG_AVAILABLE 0 // not on watch
#elif TARGET_OS_MAC && __MAC_OS_X_VERSION_MAX_ALLOWED >= 101200
#define OS_LOG_AVAILABLE 1
#else
#define OS_LOG_AVAILABLE 0
#endif

#if OS_LOG_AVAILABLE
#include <os/log.h>
#endif

@implementation TLSStdErrOutputStream

- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo
{
    fprintf(stderr, "%s\n", [[logInfo composeFormattedMessage] UTF8String]);
}

- (void)tls_flush
{
    fflush(stderr);
}

@end

@implementation TLSNSLogOutputStream

- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo
{
    NSString *fileFunctionInfo = nil;
    if (logInfo.level <= TLSLogLevelWarning) {
        fileFunctionInfo = [logInfo composeFileFunctionLineString];
    }

    NSLog(@"[%@][%@]%@ : %@", logInfo.channel, TLSLogLevelToString(logInfo.level), (fileFunctionInfo) ?: @"", logInfo.message);
}

@end

@implementation TLSOSLogOutputStream

+ (BOOL)supported
{
#if OS_LOG_AVAILABLE

    NSProcessInfo *procInfo = [NSProcessInfo processInfo];
    if (![procInfo respondsToSelector:@selector(operatingSystemVersion)]) {
        return NO;
    }
    NSOperatingSystemVersion osVersion = procInfo.operatingSystemVersion;

#if TARGET_OS_IPHONE || TARGET_OS_TV

    return osVersion.majorVersion >= 10;

#elif TARGET_OS_MAC && !TARGET_OS_WATCH

    if (osVersion.majorVersion < 10) {
        // Mac OS 9
        return NO;
    } else if (osVersion.majorVersion > 10) {
        // macOS 11, presumably
        return YES;
    }

    return osVersion.minorVersion >= 12; // 10.12+

#else

    (void)osVersion;
    return NO;

#endif // TARGET_OS

#else // !OS_LOG_AVAILABLE
    return NO;
#endif // OS_LOG_AVAILABLE
}

- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo
{
#if OS_LOG_AVAILABLE
    /**
     Start off simple and just support os_log, but in the future
     we could start using the os_log_create to have a specific
     output "log" based on the channel for more advanced filtering support.
     */

    os_log_type_t type = OS_LOG_TYPE_DEFAULT;
    TLSLogLevel level = logInfo.level;
    if (TLSLogLevelDebug == level) {
        type = OS_LOG_TYPE_DEBUG;
    } else if (level > TLSLogLevelWarning) {
        type = OS_LOG_TYPE_INFO;
    } else {
        type = OS_LOG_TYPE_ERROR;
    }

    const BOOL isSensitive = [self logInfoIsSensitive:logInfo];
    if (isSensitive) {
        os_log_with_type(OS_LOG_DEFAULT, type, "%s", logInfo.composeFormattedMessage.UTF8String);
    } else {
        os_log_with_type(OS_LOG_DEFAULT, type, "%{public}s", logInfo.composeFormattedMessage.UTF8String);
    }
#endif // OS_LOG_AVAILABLE
}

- (BOOL)logInfoIsSensitive:(TLSLogMessageInfo *)logInfo
{
    return NO;
}

@end
