//
//  TLSLoggingService.h
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
 Singleton object for a project to log messages in an efficient, thread safe and asynchronous way.

 TLSLoggingService functions as follows:

 1) ingests log messages (using `TLSLog` macros in `TLSLog.h`)

 2) enqueues the log messages to its owned background queue

 3) distributes the log messages to the available `TLSOutputStream` objects

 ## Less is more!

 Projects will seldom need to directly use `TLSLoggingService`.
 Nearly all functionality for *TwitterLoggingService* can be found in `TLSLog.h` (See `TLSLog`).

 */
@interface TLSLoggingService : NSObject

/**
 Access to the shared `TLSLoggingService` singleton instance.
 */
+ (nonnull instancetype)sharedInstance __attribute__((const));

/**
 Initializer is available for any case where a distinct `TLSLoggingService` would be desired.
 All most all use cases will want to use the `sharedInstance` though.
 */
- (nonnull instancetype)init;

/**
 Add an output stream to the `TLSLoggingService`.
 Streams are added in a thread safe manner and in charge of their own log message filtering by how they implement the `TLSFiltering` protocol.
 Subclass an existing `TLSOutputStream` to change its filtering behavior.
 @note It is recommended you only have 1 output stream that logs to the console and that it is either not added to the `TLSLoggingService` in `RELEASE` builds or filters out all log messages.
 */
- (void)addOutputStream:(nonnull id<TLSOutputStream>)stream;

/**
 Start logging the message (asynchronously).
 The best option is almost always to use the `TLSLog` macros in `TLSLog.h`.
 See `TLSLogError`, `TLSLogWarning`, `TLSLogInformation`, `TLSLogDebug`
 @param level the logging level to log at.
 @param channel the logging channel to log at.  If `nil`, won't log.
 @param file the `@__FILE__`
 @param function the `@__FUNCTION__`
 @param line the `__LINE__`
 @param contextObject any additional context to be used when logging (advanced, should often just be `nil`).
 @param message the `NSString` formatted message.
 */
- (void)logWithLevel:(TLSLogLevel)level channel:(nonnull NSString *)channel file:(nonnull NSString *)file function:(nonnull NSString *)function line:(unsigned int)line contextObject:(nullable id)contextObject message:(nonnull NSString *)message, ... NS_FORMAT_FUNCTION(7,8);

@end
