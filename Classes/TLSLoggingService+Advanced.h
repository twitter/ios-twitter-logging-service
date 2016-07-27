//
//  TLSLoggingService+Advanced.h
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

#import "TLSLoggingService.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const TLSLogMessageExceededMaximumMessageLengthNotification;
FOUNDATION_EXTERN NSString * const TLSLogMessageExceededMaximumMessageLengthNotificationMessageLengthKey;

@interface TLSLoggingService (Advanced)

/**
 The time that the `TLSLoggingService` was initialized for convenience.
 */
@property (nonatomic, readonly) NSDate *startupTimestamp;
/**
 the set of `id<TLSOutputStream>` objects
 */
@property (atomic, nonnull, readonly) NSSet<id<TLSOutputStream>> *outputStreams;
/**
 the maximum length of a log message.  Anything larger will be discarded and `TLSLogMessageExceededMaximumMessageLengthNotification` will be posted.  `0` means no maximum.

 Default == `0`
 */
@property (nonatomic, readwrite) NSUInteger maximumMessageLength;

/**
 Call this when any of the results of a `TLSOutputStream`'s `TLSFiltering` methods change.
 If `TLSCANLOGMODE` is not `1` this is a no-op.
 */
- (void)updateOutputStream:(id<TLSOutputStream>)stream;
/**
 Remove the provided _stream_
 */
- (void)removeOutputStream:(id<TLSOutputStream>)stream;

/**
 synchronously flushes all internal queues and calls flush on all `TLSOutputStream`s that implement `flush`
 */
- (void)flush;

/**
 synchronously execute the given block on the `TLSLoggingService` instance's transaction queue.
 Don't muck with `TLSLoggingService` or other queues/threads from within the _block_.
 */
- (void)dispatchSynchronousTransaction:(dispatch_block_t)block;
/**
 asynchronously execute the given block on the `TLSLoggingService` intances's transaction queue.
 Don't muck with `TLSLoggingService` or other queues/threads from within the _block_.
 */
- (void)dispatchAsynchronousTransaction:(dispatch_block_t)block;

/**
 @return a set of output streams that support getting the past logged message data (i.e. conform to `TLSDataRetrieval`)
 */
- (NSSet<id<TLSOutputStream, TLSDataRetrieval>> *)outputStreamsThatSupportLoggedDataRetrieval;

/**
 @return past log message data from a given stream
 */
- (nullable NSData *)retrieveLoggedDataFromOutputStream:(id<TLSOutputStream, TLSDataRetrieval>)stream maxBytes:(NSUInteger)maxBytes;

@end

NS_ASSUME_NONNULL_END
