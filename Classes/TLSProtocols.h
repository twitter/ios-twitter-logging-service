//
//  TLSProtocols.h
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

#import <TwitterLoggingService/TLSDeclarations.h>

/**
 The reasons that a log message was filtered
 */
typedef NS_OPTIONS(NSInteger, TLSFilterStatus)
{
    /** OK means no filtering */
    TLSFilterStatusOK = 0,
    /** The log level prevented logging the message */
    TLSFilterStatusCannotLogLevel = (1 << 0),
    /** The log channel prevented logging the message */
    TLSFilterStatusCannotLogChannel = (1 << 1),
    /** The log context prevented logging the message */
    TLSFilterStatusCannotLogContextObject = (1 << 2),

    /**
     Provide this as the reason if the reason for filtering is not due to the log level,
     log channel or log context object nor due to an exclusive combination of those 3.
     */
    TLSFilterStatusCannotLogExternal = (1 << 7)
};

/**
 Defines filtering methods used for logging.  Used by `TLSOutputStream` implementations.
 If the behavior of any of the implemented methods in a `TLSOutputStream` change, that stream must be provided to `TLSLoggingService`'s `updateOutputStream:` method.
 @warning All methods of `TLSFiltering` must never call a `TLSLoggingService` method nor a `TLSLog` function.  Doing so could result in unintended deadlocks.
 */
@protocol TLSFiltering <NSObject>

@optional

/**
 Indicate whether the known filterable attributes (level, channel and contextObject) should result in the log message being filtered.

 Consider it a last chance for custom filtering to provide valuable filtering.
 If not implemented, defaults to `TLSFilterStatusOK`.

 @note None of the predefined `TLSOutputStream` concrete classes define `tls_shouldFilterLevel:channel:contextObject:`.  Subclass or create new `TLSOutputStream` classes to utilize this advanced filtering method.

 @warning The implementation of this method must never call a `TLSLoggingService` method nor a `TLSLog` function.  Doing so could result in unintended deadlocks.
 */
- (TLSFilterStatus)tls_shouldFilterLevel:(TLSLogLevel)level channel:(nonnull NSString *)channel contextObject:(nullable id)contextObject;

@end

/**
 The necessary protocol for implementing a logging output stream that can be added to `TLSLoggingService`
 */
@protocol TLSOutputStream <TLSFiltering>

@required

/**
 Called by `TLSLoggingService` on a serial dispatch queue to log a message.

 If this output stream can be used outside of the `TLSLoggingService`, thread safety is up to the implemented
 (no `TLSOutputStream` objects in `TLSLogging` are thread safe outside of the `TLSLoggingService`).
 The implementation details on how to output the log info is up to the output stream.
 It is acceptable to log synchronously, though be aware that synchronous logging can back up the queue of log messages.
 @note It is recommended that any slow logging by a `TLSOutputStream` that occurs be done asynchronously (such as over a network connection or across processes).
 */
- (void)tls_outputLogInfo:(nonnull TLSLogMessageInfo *)logInfo;

@optional

/**
 Flush anything buffered in the output stream out to it's destination.

 It is possible for logs to be stuck in an I/O buffer so when it is important for logs to be completely output, this method enables that.
 @note Example: `TLSFileOutputStream` implements the `tls_flush` method to flush the I/O buffer of the file to disk.
 */
- (void)tls_flush;

@end

/**
 Data retrieval protocol for `TLSOutputStream` objects.

 Implement this protocol on `TLSOutputStream` objects that can have their past logged data retrieved.
 */
@protocol TLSDataRetrieval <NSObject>

@required

/** Get the past log data given a maximum number of bytes. */
- (nullable NSData *)tls_retrieveLoggedData:(NSUInteger)maxBytes;

/** The format that the log data is retrievable as (`NSUTF8StringEncoding` is very common). */
@property (nonatomic, readonly) NSStringEncoding tls_loggedDataEncoding;

@end

/**
 Base event type for use in the protocol `TLSFileOutputStreamEvent`
 */
typedef NSInteger TLSFileOutputEvent;

/**
 File stream event protocol for use by `TLSFileOutputStream` subclasses

 Implement this protocol in the subclass of `TLSFileOutputStream` to (1) notify the subclass of the event; and (2) have the base implementation log contextual log info based on the event

 E.g. for a rolling log to output JSON instead of log lines when events occur.
 The JSON log can implement/override the items in the following protocol in order to change the event log output to be into a format that complies with the JSON,
 or just disable the event logging altogether.
 */
@protocol TLSFileOutputStreamEvent <NSObject>

/**
  Signal that the event has started, with information about the event
 */
- (void)tls_fileOutputEventBegan:(TLSFileOutputEvent)event info:(nullable NSDictionary *)info;

/**
 Signal that the event has completed successfully, with information about the event
 */
- (void)tls_fileOutputEventFinished:(TLSFileOutputEvent)event info:(nullable NSDictionary *)info;

/**
 Signal that the event has failed to complete successfully, with information about the event failure
 */
- (void)tls_fileOutputEventFailed:(TLSFileOutputEvent)event info:(nullable NSDictionary *)info error:(nonnull NSError *)error;

@end
