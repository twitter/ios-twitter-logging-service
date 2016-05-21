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
