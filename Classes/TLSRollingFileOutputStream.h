//
//  TLSRollingFileOutputStream.h
//  TwitterLoggingService
//
//  Created by Kirk Beitz on 06/07/13.
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

#import <TwitterLoggingService/TLSFileOutputStream+Protected.h>
#import <TwitterLoggingService/TLSProtocols.h>

/**
 Enumeration of events the `TLSRollingFileOutputStream` will go through

 ## Constants for use with TLSRollingFileOutputEvent events

 // for RolloverLogs: new log file. for Initialize: new log file (only on finished or some failed).
 FOUNDATION_EXTERN NSString * const TLSRollingFileOutputEventKeyNewLogFilePath;
 // for RolloverLogs: previous log file. for PurgeLog: purge file.
 FOUNDATION_EXTERN NSString * const TLSRollingFileOutputEventKeyOldLogFilePath;
 */
typedef NS_ENUM(TLSFileOutputEvent, TLSRollingFileOutputEvent) {
    /** when the `TLSFileOutputStream` is initialized */
    TLSRollingFileOutputEventInitialize,
    /** when `tls_outputLogInfo:` is called on the `TLSFileOutputStream` */
    TLSRollingFileOutputEventOutputLogData,
    /** when the `TLSRollingFileOutputStream`'s single log file size limit has been reached and it is rolling over the log */
    TLSRollingFileOutputEventRolloverLogs,
    /** when the `TLSRollingFileOutputStream` has reached its log limit and needs to prune its old logs */
    TLSRollingFileOutputEventPruneLogs,
    /** occurs during `TLSRollingFileOutputEventPruneLogs` */
    TLSRollingFileOutputEventPurgeLog
};

/**
 A concrete extension of `TLSOutputStream` for logging logs to file(s) on disk, using a rolling log approach.

 That is to say it gets things to disk and out of memory as fast as possible and once the log file limit is reached, it rolls over to the next log file - pruning old files along the way.

 ## Constants

    FOUNDATION_EXTERN const NSUInteger TLSRollingFileOutputStreamDefaultMaxBytesPerLogFile;    // 256KB (aka 1024 * 256)
    FOUNDATION_EXTERN const NSUInteger TLSRollingFileOutputStreamDefaultMaxLogFiles;           // 10 files
    FOUNDATION_EXTERN NSString * const TLSRollingFileOutputStreamDefaultLogFilePrefix;         // @"log." as a prefix

 */
@interface TLSRollingFileOutputStream : TLSFileOutputStream <TLSDataRetrieval, TLSFileOutputStreamEvent>

/**
 Max bytes per log file.
 Default is `256KB`.
 Minimum value is `1KB`, maximum value is `1GB`.
 This is a soft upper bound: when a log file exceeds the max, it will rollover.
 */
@property (nonatomic, readonly) NSUInteger maxBytesPerLogFile;
/**
 Max number of log files.
 Default is `10`.
 Min is `1`, max is the lesser of `(4GB / maxBytesPerLogFile)` and `1024`.
 */
@property (nonatomic, readonly) NSUInteger maxLogFiles;
/**
 The prefix for each log file.
 Default is `@"log."`
 */
@property (nonatomic, nonnull, copy, readonly) NSString *logFilePrefix;

/**
 Initialize the `TLSRollingFileOutputStream` with the provided settings
 @param logFileDirectoryPath the directory where the log files will live. By default uses `defaultLogFileDirectoryPath`.
 @param logFilePrefix the string to prefix all created log files with. Default is `TLSFileOutputStreamDefaultLogFilePrefix`.
 @param maxLogFiles the maximum number of log files to maintain before old files are deleted.  Defaults is `TLSFileOutputStreamDefaultMaxLogFiles`.  Min is 1.  Max is the lesser of (4GB / *maxBytesPerLogFile*) and 1024.
 @param maxBytesPerLogFile the max bytes per log file before the log is rolled over.  Default `TLSFileOutputStreamDefaultMaxBytesPerLogFile`. Min is 1KB. Max is 1GB.
 @param errorOut an output reference to get any errors that occur while creating the output stream.  If there is an error, the return value will be `nil`.
 @note *maxBytesPerLogFile* is a soft maximum.  Once that cap is exceeded, the log rolls over to the next log file.  That doesn't mean it won't exceed the max number of bytes per log file though.
 */
- (nullable instancetype)initWithLogFileDirectoryPath:(nullable NSString *)logFileDirectoryPath
                                        logFilePrefix:(nullable NSString *)logFilePrefix
                                          maxLogFiles:(NSUInteger)maxLogFiles
                                   maxBytesPerLogFile:(NSUInteger)maxBytesPerLogFile
                                                error:(out NSError * __nullable __autoreleasing * __nullable)errorOut NS_DESIGNATED_INITIALIZER;

/** See initWithLogFileDirectoryPath:logFilePrefix:maxLogFiles:maxBytesPerLogFile:error: */
- (nullable instancetype)initWithLogFileDirectoryPath:(nullable NSString *)logFileDirectoryPath
                                        logFilePrefix:(nullable NSString *)logFilePrefix
                                          maxLogFiles:(NSUInteger)maxLogFiles
                                   maxBytesPerLogFile:(NSUInteger)maxBytesPerLogFile;

/** See initWithLogFileDirectoryPath:logFilePrefix:maxLogFiles:maxBytesPerLogFile:error: */
- (nullable instancetype)initWithLogFileDirectoryPath:(nullable NSString *)logFileDirectoryPath
                                                error:(out NSError * __nullable __autoreleasing * __nullable)errorOut;

/** See initWithLogFileDirectoryPath:logFilePrefix:maxLogFiles:maxBytesPerLogFile:error: */
- (nullable instancetype)initWithLogFileDirectoryPath:(nullable NSString *)logFileDirectoryPath;

/** See initWithLogFileDirectoryPath:logFilePrefix:maxLogFiles:maxBytesPerLogFile:error: */
- (nullable instancetype)initWithOutError:(__autoreleasing NSError * __nullable * __nullable)errorOut;

/** NS_UNAVAILABLE */
- (nullable instancetype)initWithLogFileDirectoryPath:(nullable NSString*)logFilePath
                                          logFileName:(nullable NSString*)logFileName
                                                error:(out NSError * __nullable __autoreleasing * __nullable)errorOut NS_UNAVAILABLE;
/** NS_UNAVAILABLE */
- (nullable instancetype)initWithLogFileName:(nullable NSString*)logFileName
                                       error:(out NSError * __nullable __autoreleasing * __nullable)errorOut NS_UNAVAILABLE;

/** Unavailable because super init is NS_UNAVAILABLE */
- (nonnull instancetype)init NS_UNAVAILABLE;
/** Unavailable because super init is NS_UNAVAILABLE */
+ (nonnull instancetype)new NS_UNAVAILABLE;

#pragma mark - protocol TLSDataRetrieval
/**
 Get the past logged data
 @param maxBytes The maximum number of bytes to get from the log file(s). `2` to `4` times *maxBytesPerLogFile* is a suggestion.  Min is *maxBytesPerLogFile*.
 @return NSData object with up to *maxBytes* of log data.
 @note *maxBytes* is a hard limit.  Will retrieve the past log files so long as it doesn't surpass *maxBytes*.  That is to say, the log data is loaded `1` entire log file at a time - no partial files will be loaded.
 */
- (nullable NSData *)tls_retrieveLoggedData:(NSUInteger)maxBytes;

@end

FOUNDATION_EXTERN NSString * __nonnull const TLSRollingFileOutputStreamDefaultLogFilePrefix;         // @"log." as a prefix

FOUNDATION_EXTERN const NSUInteger TLSRollingFileOutputStreamDefaultMaxBytesPerLogFile;    // 256KB (aka 1024 * 256)
FOUNDATION_EXTERN const NSUInteger TLSRollingFileOutputStreamDefaultMaxLogFiles;           // 10 files
