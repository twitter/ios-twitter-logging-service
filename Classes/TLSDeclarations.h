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

#import "TLSLog.h"

/** Domain for errors stemming from TwitterLoggingService APIs */
FOUNDATION_EXTERN NSString * __nonnull const TLSErrorDomain;

/** Pull out an name for the current thread or `nil` if no name was identified */
FOUNDATION_EXTERN NSString * __nullable TLSCurrentThreadName();

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
@property (nonatomic, readonly) unsigned int line;
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
 @return A log message string in the format `@"[TIMESTAMP][THREAD][CHANNEL][LEVEL](__FILE__:__LINE__ __PRETTY_FUNCTION___) : MESSAGE"`
 where the _TIMESTAMP_ is the time *HHH:mm:ss.MMM* (hours, minutes, seconds, milliseconds) since the `TLSLoggingService` was initialized, and
 the `(__FILE__:__LINE__ __PRETTY_FUNCTION___)` part is only in log messages with a *level* of `TLSLogLevelWarning` or higher.
 */
- (nonnull NSString *)composeFormattedMessage;

/**
 Composes a string that combines the _file_, _function_ and _line_ information.
 @return a string in the format `@"(__FILE__:__LINE__ __FUNCTION)"`
 */
- (nonnull NSString *)composeFileFunctionLineString;

/**
 Designated initializer
 */
- (nonnull instancetype)initWithLevel:(TLSLogLevel)level file:(nonnull NSString *)file function:(nonnull NSString *)function line:(unsigned int)line channel:(nonnull NSString *)channel timestamp:(nonnull NSDate *)timestamp logLifespan:(NSTimeInterval)logLifespan threadId:(unsigned int)threadId threadName:(nullable NSString *)threadName contextObject:(nullable id)contextObject message:(nonnull NSString *)message NS_DESIGNATED_INITIALIZER;

/**
 `NS_UNAVAILABLE`
 */
- (nullable instancetype)init NS_UNAVAILABLE;
/**
 `NS_UNAVAILABLE`
 */
+ (nullable instancetype)new NS_UNAVAILABLE;

@end

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
