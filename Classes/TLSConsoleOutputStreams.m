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
#import "TLSLog.h"

#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_MAC
#define OS_LOG_AVAILABLE 1
#elif TARGET_OS_WATCH
#define OS_LOG_AVAILABLE 0 // not on watch
#else
#define OS_LOG_AVAILABLE 0
#endif

#if OS_LOG_AVAILABLE
#include <os/log.h>
#endif

@implementation TLSStdErrOutputStream

- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo
{
    NSString *message = [logInfo composeFormattedMessageWithOptions:
                         TLSComposeLogMessageInfoLogTimestampAsLocalTime |
                         TLSComposeLogMessageInfoLogThreadId |
                         TLSComposeLogMessageInfoLogChannel |
                         TLSComposeLogMessageInfoLogLevel |
                         TLSComposeLogMessageInfoLogCallsiteInfoForWarnings];
    fprintf(stderr, "%s\n", [message UTF8String]);
}

- (void)tls_flush
{
    fflush(stderr);
}

@end

@implementation TLSNSLogOutputStream

- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo
{
    NSString *message = [logInfo composeFormattedMessageWithOptions:
                         TLSComposeLogMessageInfoLogChannel |
                         TLSComposeLogMessageInfoLogLevel |
                         TLSComposeLogMessageInfoLogCallsiteInfoForWarnings |
                         TLSComposeLogMessageInfoDoNotCache];
    NSLog(@"%@", message);
}

@end

@implementation TLSOSLogOutputStream

+ (BOOL)supported
{
#if OS_LOG_AVAILABLE

#if !TARGET_OS_WATCH
    return YES;
#endif

#endif // OS_LOG_AVAILABLE

    return NO;
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

    NSString *message = [logInfo composeFormattedMessageWithOptions:
                         TLSComposeLogMessageInfoLogTimestampAsLocalTime |
                         TLSComposeLogMessageInfoLogThreadId |
                         TLSComposeLogMessageInfoLogChannel |
                         TLSComposeLogMessageInfoLogLevel |
                         TLSComposeLogMessageInfoLogCallsiteInfoForWarnings];
    const BOOL isSensitive = [self logInfoIsSensitive:logInfo];
    if (isSensitive) {
        os_log_with_type(OS_LOG_DEFAULT, type, "%s", message.UTF8String);
    } else {
        os_log_with_type(OS_LOG_DEFAULT, type, "%{public}s", message.UTF8String);
    }
#endif // OS_LOG_AVAILABLE
}

- (BOOL)logInfoIsSensitive:(TLSLogMessageInfo *)logInfo
{
    return NO;
}

@end
