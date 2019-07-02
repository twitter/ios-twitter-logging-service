//
//  TLSCrashlyticsOutputStream.m
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

#import "TLSCrashlyticsOutputStream.h"
#import "TLSLog.h"

static const NSUInteger kMaxLogMessageLength = 16 * 1024;

@implementation TLSCrashlyticsOutputStream

- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo
{
    // [CHANNEL][LEVEL]CALLSITE_INFO : MESSAGE
    NSString *message = [logInfo composeFormattedMessageWithOptions:TLSComposeLogMessageInfoLogChannel |
                                                                    TLSComposeLogMessageInfoLogLevel |
                                                                    TLSComposeLogMessageInfoLogCallsiteInfoForWarnings];

    // Message too large?
    if (message.length > kMaxLogMessageLength) {
        if (self.discardLargeLogMessages) {
            // discard
            return;
        }

        // Truncate our message
        message = [message substringToIndex:kMaxLogMessageLength];
    }

    // Delegate to the subclass
    [self outputLogMessageToCrashlytics:message];
}

- (void)outputLogMessageToCrashlytics:(NSString *)message
{
    NSLog(@"Crashlytics integration with TwitterLoggingService is incomplete!  You must override %@ in your %@ subclass %@.", NSStringFromSelector(_cmd), NSStringFromClass([TLSCrashlyticsOutputStream class]), NSStringFromClass([self class]));
    NSLog(@"%@", message);
}

- (BOOL)discardLargeLogMessages
{
    return NO;
}

@end
