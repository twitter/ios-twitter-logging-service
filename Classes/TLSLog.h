//
//  TLSLog.h
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

#ifndef __TLSLOG_H__
#define __TLSLOG_H__

#import <Foundation/Foundation.h>
#import <TwitterLoggingService/TLSDeclarations.h>

@class TLSLoggingService;

NS_ASSUME_NONNULL_BEGIN

#pragma mark Helper Macros

/**
 Helper macro for the file name macro.

 `__FILE__` is the historical C macro that is replaced with the full file path of the current file being compiled (e.g. `/Users/username/workspace/project/source/subfolder/anotherfolder/implementation/file.c`)
 `__FILE_NAME__` is the new C macro in clang that is replaced with the file name of the current file being compiled (e.g. `file.c`)

 By default, if `__FILE_NAME__` is availble with the current compiler, it will be used.
 This behavior can be overridden by providing a value for `TLS_FILE_NAME` to the compiler, like `-DTLS_FILE_NAME=__FILE__` or `-DTLS_FILE_NAME=\"redacted\"`
 */
#if !defined(TLS_FILE_NAME)
#ifdef __FILE_NAME__
#define TLS_FILE_NAME __FILE_NAME__
#else
#define TLS_FILE_NAME __FILE__
#endif
#endif

#pragma mark Essential Macros

//! Root Macro.  Provide the _level_, _channel_ and format string.
#define TLSLog(level, channel, ...) \
    if (TLSCanLog(nil, level, channel, nil)) { \
        TLSLogEx(nil, level, channel, @(__FILE__), @(__PRETTY_FUNCTION__), __LINE__, nil, TLSLogMessageOptionsNone, __VA_ARGS__); \
    }

//! Log to Error level
#define TLSLogError(channel, ...)        TLSLog(TLSLogLevelError, channel, __VA_ARGS__)
//! Log to Warning level
#define TLSLogWarning(channel, ...)      TLSLog(TLSLogLevelWarning, channel, __VA_ARGS__)
//! Log to Information level
#define TLSLogInformation(channel, ...)  TLSLog(TLSLogLevelInformation, channel, __VA_ARGS__)
//! Log to Debug level
#define TLSLogDebug(channel, ...)        TLSLog(TLSLogLevelDebug, channel, __VA_ARGS__)

#pragma mark Convenience Functions

//! Convert the log level to a short parsable string
FOUNDATION_EXTERN NSString *TLSLogLevelToString(TLSLogLevel level);

//! A default application log channel if no custom channel is desired
FOUNDATION_EXTERN NSString *TLSLogChannelApplicationDefault(void) __attribute__((const));

//! Macro to a default application log channel
#define TLSLogChannelDefault TLSLogChannelApplicationDefault()

#pragma mark TLSLog Helper Functions

//! Log a message using formatted message
FOUNDATION_EXTERN void TLSLogEx(TLSLoggingService * __nullable service,
                                TLSLogLevel level,
                                NSString *channel,
                                NSString *file,
                                NSString *function,
                                NSInteger line,
                                id __nullable contextObject,
                                TLSLogMessageOptions options,
                                NSString *format, ...) NS_FORMAT_FUNCTION(9,10);

//! Log a message using a fully constructed string
FOUNDATION_EXTERN void TLSLogString(TLSLoggingService * __nullable service,
                                    TLSLogLevel level,
                                    NSString *channel,
                                    NSString *file,
                                    NSString *function,
                                    NSInteger line,
                                    id __nullable contextObject,
                                    TLSLogMessageOptions options,
                                    NSString *message);

//! Log a message using a variable arguments list
FOUNDATION_EXTERN void TLSvaLog(TLSLoggingService * __nullable service,
                                TLSLogLevel level,
                                NSString *channel,
                                NSString *file,
                                NSString *function,
                                NSInteger line,
                                id __nullable contextObject,
                                TLSLogMessageOptions options,
                                NSString *format,
                                va_list arguments);

//! Determine if the given _level_, _channel_ and _contextObject_ can be logged
FOUNDATION_EXTERN BOOL TLSCanLog(TLSLoggingService * __nullable service,
                                 TLSLogLevel level,
                                 NSString *channel,
                                 id __nullable contextObject);

NS_ASSUME_NONNULL_END

#endif // __TLSLOG_H__
