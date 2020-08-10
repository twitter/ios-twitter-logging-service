//
//  TLSFileOutputStream.h
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

#import <TwitterLoggingService/TLSProtocols.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This is the base class for other file output stream classes to extend.

 ### Buffered I/O with File Output Streams

 Something important to consider is I/O buffering.
 The file output stream will output to a file descriptor but for system performance an I/O write
 doesn't happen synchronously, it gets buffered until one of the following is encountered:

    1. enough output is buffered
    2. the file descriptor is closed
    3. the file descriptor is explicitly flushed

 For debugging, you can use the exposed property on the file output stream to explicitly flush on
 every write, but it is recommended to only do so when trying to debug something specific and never
 be enabled in production builds.   See `flushAfterEveryWriteEnabled`

 To offer increased control over output streams buffering, `TLSLoggingService` exposes a `flush`
 method.  It is recommended that you `flush` whenever you encounter an explicit need to have the
 buffered I/O be output to disk, such as:

    1. When the app backgrounds
    2. When the app is terminated
    3. When a crash is detected (call it JIT flushing)
    4. When the logs need to be read (like when you zip them up for a bug report)

 */
@interface TLSFileOutputStream : NSObject <TLSOutputStream>
{
@protected
    FILE *_logFile;
    NSUInteger _bytesWritten;
    NSString *_logFilePath;
    BOOL _flushAfterEveryWriteEnabled;
}

/**
 The `FILE *` being written to
 established during initialization
 */
@property (nonatomic, readonly) FILE *logFile;
/**
 Number of bytes written to the `logFile`
 established during initialization
 */
@property (nonatomic, readonly) NSUInteger bytesWritten;
/**
 The path to the `logFile`
 established during initialization
 */
@property (nonatomic, copy, readonly) NSString *logFilePath;
/**
 The director containing the `logFile`
 established during initialization
 */
@property (nonatomic, copy, readonly) NSString *logFileDirectoryPath;

/**
 Enable flushing after every write.  Expensive with I/O, should only be used for debugging.
 Default is `NO`.
 */
@property (nonatomic, getter=isFlushAfterEveryWriteEnabled) BOOL flushAfterEveryWriteEnabled;

/**
 The encoding of the logged data.
 Default is `NSUTF8StringEncoding`.
 */
@property (nonatomic, readonly) NSStringEncoding tls_loggedDataEncoding;

/**
 The format to log the message with.
 Default is `TLSComposeLogMessageInfoDefaultOptions`
 */
@property (nonatomic) TLSComposeLogMessageInfoOptions composeLogMessageOptions;

/**
 Initialize the `TLSFileOutputStream` with the provided settings
 @param logFilePath the directory where the log files will live. cannot be nil
 @param logFileName the short file name to append as a path component to create the full logFilePath
 @param errorOut an output reference to get any errors that occur while creating the output stream.  If there is an error, the return value will be `non-nil`.
 */
- (nullable instancetype)initWithLogFileDirectoryPath:(NSString*)logFilePath
                                          logFileName:(NSString*)logFileName
                                                error:(out NSError * __nullable __autoreleasing * __nullable)errorOut NS_DESIGNATED_INITIALIZER;

/**
 Convenience initializer - calls the designated initializer with the `defaultLogFileDirectoryPath`

 @param logFileName - short name (without path). cannot be nil
 @param errorOut - address of an NSError* to contain any initialization errors
 */
- (nullable instancetype)initWithLogFileName:(NSString*)logFileName
                                       error:(out NSError * __nullable __autoreleasing * __nullable)errorOut;

/**
 NS_UNAVAILABLE: callers are not allowed to instantiate this class without a logFile name or path
 */
- (nonnull instancetype)init NS_UNAVAILABLE;
/**
 NS_UNAVAILABLE: callers are not allowed to instantiate this class without a logFile name or path
 */
+ (nonnull instancetype)new NS_UNAVAILABLE;

/**
 @return the User's Caches directory under a directory named "logs"
 */
+ (NSString *)defaultLogFileDirectoryPath;

/**
 Reset the log and clear it
 */
- (BOOL)resetAndReturnError:(out NSError * __nullable __autoreleasing * __nullable)error;

#pragma mark TLSOutputStream

/**
 flush the file I/O buffer
 */
- (void)tls_flush;

/**
 write the _logInfo_ provided to the open log file
 */
- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo;

@end

NS_ASSUME_NONNULL_END
