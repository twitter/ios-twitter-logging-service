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

#ifdef __cplusplus
#import <Foundation/Foundation.h>
#else
@import Foundation;
#endif

NS_ASSUME_NONNULL_BEGIN

#pragma mark Declarations

/**
 These are syslog compatible log levels for use with *TwitterLoggingService*.
 `TLSLog.h` only exposes easy macros for Error, Warning, Information and Debug.

 # Number of levels

 static const NSUInteger TLSLogLevelCount = TLSLogLevelDebug + 1;

 ## Levels to strings

 FOUNDATION_EXTERN NSString *TLSLogLevelToString(TLSLogLevel level) __attribute__((const));

 */
typedef NS_ENUM(NSUInteger, TLSLogLevel)
{
    /** Present for syslog compatability */
    TLSLogLevelEmergency = 0,
    /** Present for syslog compatability */
    TLSLogLevelAlert,
    /** Present for syslog compatability */
    TLSLogLevelCritical,
    /** Use `TLSLogError` (See TLSLog) */
    TLSLogLevelError,
    /** Use `TLSLogWarning` (See TLSLog) */
    TLSLogLevelWarning,
    /** Present for syslog compatability */
    TLSLogLevelNotice,
    /** Use `TLSLogInformation` (See TLSLog) */
    TLSLogLevelInformation,
    /** Use `TLSLogDebug` (See TLSLog) */
    TLSLogLevelDebug
};

//! Number of log levels
static const NSUInteger TLSLogLevelCount = TLSLogLevelDebug + 1;

#pragma mark Essential Macros

//! Root Macro.  Provide the _level_, _channel_ and format string.
#define TLSLog(level, channel, ...) \
    if (TLSCanLog(nil, level, channel, nil)) { \
        TLSLogEx(nil, level, channel, @(__FILE__), @(__PRETTY_FUNCTION__), __LINE__, nil, __VA_ARGS__); \
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
FOUNDATION_EXTERN NSString *TLSLogLevelToString(TLSLogLevel level) __attribute__((const));

//! A default application log channel if no custom channel is desired
FOUNDATION_EXTERN NSString *TLSLogChannelApplicationDefault() __attribute__((const));

//! Macro to a default application log channel
#define TLSLogChannelDefault TLSLogChannelApplicationDefault()

#pragma mark TLSLog Helper Functions

@class TLSLoggingService;

//! Log a message using formatted message
FOUNDATION_EXTERN void TLSLogEx(TLSLoggingService * __nullable service,
                                TLSLogLevel level,
                                NSString *channel,
                                NSString *file,
                                NSString *function,
                                unsigned int line,
                                id __nullable contextObject,
                                NSString *format, ...) NS_FORMAT_FUNCTION(8,9);

//! Log a message using a fully constructed string
FOUNDATION_EXTERN void TLSLogString(TLSLoggingService * __nullable service,
                                    TLSLogLevel level,
                                    NSString *channel,
                                    NSString *file,
                                    NSString *function,
                                    unsigned int line,
                                    id __nullable contextObject,
                                    NSString *message);

//! Log a message using a variable arguments list
FOUNDATION_EXTERN void TLSvaLog(TLSLoggingService * __nullable service,
                                TLSLogLevel level,
                                NSString *channel,
                                NSString *file,
                                NSString *function,
                                unsigned int line,
                                id __nullable contextObject,
                                NSString *format,
                                va_list arguments);

//! Determine if the given _level_, _channel_ and _contextObject_ can be logged
FOUNDATION_EXTERN BOOL TLSCanLog(TLSLoggingService * __nullable service,
                                 TLSLogLevel level,
                                 NSString *channel,
                                 id __nullable contextObject);

NS_ASSUME_NONNULL_END

#endif // __TLSLOG_H__
