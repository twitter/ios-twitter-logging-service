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

#import "TLSProtocols.h"

NS_ASSUME_NONNULL_BEGIN

/**
 This is the base class for other file output stream classes to extend.
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
 Initialize the `TLSFileOutputStream` with the provided settings
 @param logFilePath the directory where the log files will live. cannot be nil
 @param logFileName the short file name to append as a path component to create the full logFilePath
 @param errorOut an output reference to get any errors that occur while creating the output stream.  If there is an error, the return value will be `non-nil`.
 */
- (nullable instancetype)initWithLogFileDirectoryPath:(NSString*)logFilePath logFileName:(NSString*)logFileName error:(out NSError * __nullable __autoreleasing * __nullable)errorOut NS_DESIGNATED_INITIALIZER;

/**
 Convenience initializer - calls the designated initializer with the `defaultLogFileDirectoryPath`

 @param logFileName - short name (without path). cannot be nil
 @param errorOut - address of an NSError* to contain any initialization errors
 */
- (nullable instancetype)initWithLogFileName:(NSString*)logFileName error:(out NSError * __nullable __autoreleasing * __nullable)errorOut;

/**
 NS_UNAVAILABLE: callers are not allowed to instantiate this class without a logFile name or path
 */
- (nullable instancetype)init NS_UNAVAILABLE;
/**
 NS_UNAVAILABLE: callers are not allowed to instantiate this class without a logFile name or path
 */
+ (nullable instancetype)new NS_UNAVAILABLE;

/**
 @return the User's Caches directory under a directory named "logs"
 */
+ (NSString *)defaultLogFileDirectoryPath;

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
