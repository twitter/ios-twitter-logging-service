//
//  TLSDeclarations.h
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

#import <Foundation/Foundation.h>

#pragma mark - Constants

/** Domain for errors stemming from TwitterLoggingService APIs */
FOUNDATION_EXTERN NSErrorDomain __nonnull const TLSErrorDomain;

/** Pull out an name for the current thread or `nil` if no name was identified */
FOUNDATION_EXTERN NSString * __nullable TLSCurrentThreadName(void);

/**
 These are syslog compatible log levels for use with *TwitterLoggingService*.
 `TLSLog.h` only exposes easy macros for Error, Warning, Information and Debug.

 # Number of levels

 static const NSUInteger TLSLogLevelCount = TLSLogLevelDebug + 1;

 ## Levels to strings

 FOUNDATION_EXTERN NSString *TLSLogLevelToString(TLSLogLevel level);

 */
typedef NS_ENUM(NSInteger, TLSLogLevel)
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
static const NSInteger TLSLogLevelCount = TLSLogLevelDebug + 1;

/**
 A set of flags that can be used to identify specific log levels in one mask.
 Used by `TLSOutputStream` conforming objects for filtering log levels.
 */
typedef NS_OPTIONS(NSInteger, TLSLogLevelMask)
{
    /** Emergency */
    TLSLogLevelMaskEmergency   = (1 << TLSLogLevelEmergency),
    /** Alert */
    TLSLogLevelMaskAlert       = (1 << TLSLogLevelAlert),
    /** Critical */
    TLSLogLevelMaskCritical    = (1 << TLSLogLevelCritical),
    /** Error */
    TLSLogLevelMaskError       = (1 << TLSLogLevelError),
    /** Warning */
    TLSLogLevelMaskWarning     = (1 << TLSLogLevelWarning),
    /** Notice */
    TLSLogLevelMaskNotice      = (1 << TLSLogLevelNotice),
    /** Information */
    TLSLogLevelMaskInformation = (1 << TLSLogLevelInformation),
    /** Debug */
    TLSLogLevelMaskDebug       = (1 << TLSLogLevelDebug),

    /** All Levels */
    TLSLogLevelMaskAll         = 0xFF,
    /** No Levels */
    TLSLogLevelMaskNone        = 0,

    /** Emergency and above */
    TLSLogLevelMaskEmergencyAndAbove   = TLSLogLevelMaskEmergency,
    /** Alert and above */
    TLSLogLevelMaskAlertAndAbove       = TLSLogLevelMaskEmergencyAndAbove   | TLSLogLevelMaskAlert,
    /** Critical and above */
    TLSLogLevelMaskCriticalAndAbove    = TLSLogLevelMaskAlertAndAbove       | TLSLogLevelMaskCritical,
    /** Error and above */
    TLSLogLevelMaskErrorAndAbove       = TLSLogLevelMaskCriticalAndAbove    | TLSLogLevelMaskError,
    /** Warning and above */
    TLSLogLevelMaskWarningAndAbove     = TLSLogLevelMaskErrorAndAbove       | TLSLogLevelMaskWarning,
    /** Notice and above */
    TLSLogLevelMaskNoticeAndAbove      = TLSLogLevelMaskWarningAndAbove     | TLSLogLevelMaskNotice,
    /** Information and above */
    TLSLogLevelMaskInformationAndAbove = TLSLogLevelMaskNoticeAndAbove      | TLSLogLevelMaskInformation,
    /** Debug and above (effectively everything except out of bounds values) */
    TLSLogLevelMaskDebugAndAbove       = TLSLogLevelMaskInformationAndAbove | TLSLogLevelMaskDebug
};

/** Advanced options for logging a message */
typedef NS_OPTIONS(NSInteger, TLSLogMessageOptions) {
    /** no options (default behavior) */
    TLSLogMessageOptionsNone = 0,
    /** ignore the `[TLSLoggingService maximumSafeMessageLength]` capping of the message */
    TLSLogMessageOptionsIgnoringMaximumSafeMessageLength = 1 << 0,
};

/**
 Options for how to compose a `TLSLogMessageInfo` into a message string
 Selects which components of the message will be in the composed string.
 All components will format as `@"[TIMESTAMP][THREAD][CHANNEL][LEVEL](__FILE__:__LINE__ __PRETTY_FUNCTION___) : MESSAGE"`
 */
typedef NS_OPTIONS(NSInteger, TLSComposeLogMessageInfoOptions) {
    /**
     No options
     `@" : MESSAGE"`
     */
    TLSComposeLogMessageInfoNoOptions = 0,

    //! TIMESTAMP

    //! Log the `TIMESTAMP` as the time since logging started as *HHH:mm:ss.MMM* (hours, minutes, seconds, milliseconds)
    TLSComposeLogMessageInfoLogTimestampAsTimeSinceLoggingStarted = 1 << 0,
    //! Log the `TIMESTAMP` as the local time as *HHH:mm:ss.MMM* (hours, minutes, seconds, milliseconds)
    TLSComposeLogMessageInfoLogTimestampAsLocalTime = 1 << 1,
    //! Log the `TIMESTAMP` as the UTC time as *HHH:mm:ss.MMM* (hours, minutes, seconds, milliseconds)
    TLSComposeLogMessageInfoLogTimestampAsUTCTime = 1 << 2,

    //! THREAD [THREADNAME] | [THREADID] | [THREADNAME(THREADID)]
    //! Log the `THREAD` identifier
    TLSComposeLogMessageInfoLogThreadId = 1 << 4,
    //! Log the `THREAD` name. @note Take care since thread names can be long and might not be ideal for all logs.
    TLSComposeLogMessageInfoLogThreadName = 1 << 5,

    //! CHANNEL
    //! Log the `CHANNEL`
    TLSComposeLogMessageInfoLogChannel = 1 << 8,

    //! LEVEL
    //! Log the `LEVEL`
    TLSComposeLogMessageInfoLogLevel = 1 << 12,

    //! Callsite Info: (__FILE__:__LINE__ __PRETTY_FUNCTION___)
    //! Log the callsite info always: `(__FILE__:__LINE__ __PRETTY_FUNCTION___)`
    TLSComposeLogMessageInfoLogCallsiteInfoAlways = 1 << 16,
    //! Log the callsite info when message's *level* is `TLSLogLevelWarning` or higher: `(__FILE__:__LINE__ __PRETTY_FUNCTION___)`
    TLSComposeLogMessageInfoLogCallsiteInfoForWarnings = 1 << 17,

    //! Caching
    //! Do not cache the composed log message
    TLSComposeLogMessageInfoDoNotCache = 1 << 31,

    /**
     Default options
     `@"[TIMESTAMP][THREADID][CHANNEL][LEVEL](__FILE__:__LINE__ __PRETTY_FUNCTION___) : MESSAGE"`
     Where `TIMESTAMP` is the time since logging started.
     Where `(__FILE__:__LINE__ __PRETTY_FUNCTION__)` is only present for Warning and above.
     */
    TLSComposeLogMessageInfoDefaultOptions = TLSComposeLogMessageInfoLogTimestampAsTimeSinceLoggingStarted |
                                             TLSComposeLogMessageInfoLogThreadId |
                                             TLSComposeLogMessageInfoLogChannel |
                                             TLSComposeLogMessageInfoLogLevel |
                                             TLSComposeLogMessageInfoLogCallsiteInfoForWarnings,
};

#pragma mark - Declarations

/**
 Encapsulation of log message information.

 All properties of `TLSLogMessageInfo` are readonly and populated at initialization time with the exception of `composeFormattedMessage`.
 */
@interface TLSLogMessageInfo : NSObject

/** The `TLSLogLevel` */
@property (nonatomic, readonly) TLSLogLevel level;
/** The `@__FILE__` of the log message */
@property (nonatomic, nonnull, copy, readonly) NSString *file;
/** The `@__FUNCTION__` of the log message */
@property (nonatomic, nonnull, copy, readonly) NSString *function;
/** The `__LINE__` of the log message */
@property (nonatomic, readonly) NSInteger line;
/** The `NSString*` channel */
@property (nonatomic, nonnull, copy, readonly) NSString *channel;
/** The context object */
@property (nonatomic, nullable, readonly) id contextObject;
/** The log message's timestamp */
@property (nonatomic, nonnull, readonly) NSDate *timestamp;
/** how long the `TLSLoggingService` instance had been alive when this log message was made */
@property (nonatomic, readonly) NSTimeInterval logLifespan;
/** The thread identifier (mach_port_t) that the message was logged from */
@property (nonatomic, readonly) unsigned int threadId;
/** The thread name of the thread that was logged from */
@property (nonatomic, nullable, copy, readonly) NSString *threadName;
/** The log message */
@property (nonatomic, nonnull, copy, readonly) NSString *message;

/**
 Composes a log message in predefined format which is cached for the lifetime of this object.
 @return A log message string using `TLSComposeLogMessageInfoDefaultOptions`
 */
- (nonnull NSString *)composeFormattedMessage;

/**
 Composes a log message in predefined format which is cached for the lifetime of this object.
 @return A log message string using the given `TLSComposeLogMessageInfoOptions` _options_
 */
- (nonnull NSString *)composeFormattedMessageWithOptions:(TLSComposeLogMessageInfoOptions)options;

/**
 Composes a string that combines the _file_, _function_ and _line_ information.
 @return a string in the format `@"(__FILE__:__LINE__ __FUNCTION)"`
 */
- (nonnull NSString *)composeFileFunctionLineString;

/**
 Designated initializer
 */
- (nonnull instancetype)initWithLevel:(TLSLogLevel)level
                                 file:(nonnull NSString *)file
                             function:(nonnull NSString *)function
                                 line:(NSInteger)line
                              channel:(nonnull NSString *)channel
                            timestamp:(nonnull NSDate *)timestamp
                          logLifespan:(NSTimeInterval)logLifespan
                             threadId:(unsigned int)threadId
                           threadName:(nullable NSString *)threadName
                        contextObject:(nullable id)contextObject
                              message:(nonnull NSString *)message NS_DESIGNATED_INITIALIZER;

/**
 `NS_UNAVAILABLE`
 */
- (nonnull instancetype)init NS_UNAVAILABLE;
/**
 `NS_UNAVAILABLE`
 */
+ (nonnull instancetype)new NS_UNAVAILABLE;

@end
