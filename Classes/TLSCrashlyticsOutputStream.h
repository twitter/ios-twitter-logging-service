//
//  TLSCrashlyticsOutputStream.h
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

#import "TLSProtocols.h"

/**
 Abstract base class of `TLSOutputStream` to output logs to `Crashlytics`.

 This class does not directly deliver the logging message to _Crashlytics_,
 but rather delegates that responsibility to subclasses overriding `outputLogMessageToCrashlytics:`.

 Due to a limitation in _Crashlytics_, dynamic frameworks cannot call into the _Crashlytics_
 interfaces and instead the responsibility must be delegated to the main executable itself.

 Keep in mind that if `CrashlyticsCollectCustomLogs` is set to `NO` in the application's
 `Info.plist`, all of `Crashlytics` logging will no-op (including this stream).

 @note Crashlytics doesn't work in the simulator so it doesn't make sense to use a `TLSCrashlyticsOutputStream` while in the simulator.
 */
@interface TLSCrashlyticsOutputStream : NSObject <TLSOutputStream>

/**
 Subclass MUST override this method to output the message to crashlytics.

 `TLS_OUTPUTLOGMESSAGETOCRASHLYTICS_DEFAULT_IMPL` can be used by
 subclasses to implement the default behavior of just calling `CLSLog`.
 */
- (void)outputLogMessageToCrashlytics:(nonnull NSString *)message;

/**
 Crashlytics has a cap for a log message before it effectively disables logging.

 This output stream will cap the log message at 16,384 characters
 (which can be between 16KB and 64KB, depending on encoding).

 By default `discardLargeLogMessages` is NO and therefore the message will be truncated.
 Override and return `YES` to discard large log messages instead of truncating them.

 Default == NO.
 */
- (BOOL)discardLargeLogMessages;

@end

//! convenience macro to easily implement the required method for Crashlytics support
#define TLS_OUTPUTLOGMESSAGETOCRASHLYTICS_DEFAULT_IMPL \
- (void)outputLogMessageToCrashlytics:(NSString *)message \
{ \
    CLSLog(@"%@", message); \
}
