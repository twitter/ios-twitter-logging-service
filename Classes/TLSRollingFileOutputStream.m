//
//  TLSRollingFileOutputStream.m
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

#import "TLS_Project.h"
#import "TLSLoggingService+Advanced.h"
#import "TLSRollingFileOutputStream.h"

NSString * const TLSRollingFileOutputStreamDefaultLogFilePrefix = @"log.";
const NSUInteger TLSRollingFileOutputStreamDefaultMaxBytesPerLogFile = (1024 * 256);
const NSUInteger TLSRollingFileOutputStreamDefaultMaxLogFiles = 10;

static NSString * const TLSRollingFileOutputStreamDefaultLogFileExtension = @"log";

static NSString * const TLSRollingFileOutputEventKeyNewLogFilePath = @"newLogFilePath";
static NSString * const TLSRollingFileOutputEventKeyOldLogFilePath = @"oldLogFilePath";
static NSString * const TLSRollingFileOutputEventKeyLogData = @"logData";

// Mar 21, 2006 @ 12:50PM - aka. "just setting up my twttr"
static const time_t kTLSReferenceTime = 164667000;

static const NSUInteger kMinLogFiles = 1;
static const NSUInteger kMaxLogFiles = 1024;

static const NSUInteger kMinBytesPerFile = 1024; // 1 KB
static const NSUInteger kMaxBytesPerFile = 1 * 1024 * 1024 * 1024; // 1 GB
static const unsigned long long kMaxBytesTotal = 4ULL * 1024ULL * 1024ULL * 1024ULL; // 4 GB

#define LOG_EVENT_PREFIX @"[LOG EVENT] : "

typedef long long TLSLogFileId;

static TLSLogFileId _GenerateLogFileId(void);
static TLSLogFileId _GenerateLogFileId()
{
    static NSDate *sReferenceDate;
    static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
        sReferenceDate = [NSDate dateWithTimeIntervalSinceReferenceDate:kTLSReferenceTime];
    });
    NSTimeInterval ti = [[NSDate date] timeIntervalSinceDate:sReferenceDate];
    ti *= 100.0f;
    return (TLSLogFileId)ti;
}

static NSString *_GenerateLogFileName(NSString* __nonnull prefix, TLSLogFileId fileId);
static NSString *_GenerateLogFileName(NSString* prefix, TLSLogFileId fileId)
{
    return [NSString stringWithFormat:@"%@%qu.%@", prefix, fileId, TLSRollingFileOutputStreamDefaultLogFileExtension];
}

TLS_OBJC_DIRECT_MEMBERS
@interface TLSRollingFileOutputStream (Private)
- (BOOL)_rolloverIfNeeded;
- (BOOL)_purgeOldLogsIfNeeded;
- (nullable NSArray<NSString *> *)_getLogFiles;
- (void)_writeStartupTimestampInfo;
@end

@implementation TLSRollingFileOutputStream
{
    BOOL _hasRunPrune;
}

- (instancetype)initWithOutError:(NSError **)errorOut
{
    return [self initAndReturnError:errorOut];
}

- (instancetype)initAndReturnError:(NSError **)errorOut
{
    return [self initWithLogFileDirectoryPath:nil error:errorOut];
}

- (instancetype)initWithLogFileDirectoryPath:(NSString *)logFileDirectoryPath
{
    return [self initWithLogFileDirectoryPath:logFileDirectoryPath error:NULL];
}

- (instancetype)initWithLogFileDirectoryPath:(NSString *)logFileDirectoryPath
                                       error:(out NSError **)errorOut
{
    return [self initWithLogFileDirectoryPath:logFileDirectoryPath
                                logFilePrefix:TLSRollingFileOutputStreamDefaultLogFileExtension
                                  maxLogFiles:TLSRollingFileOutputStreamDefaultMaxLogFiles
                           maxBytesPerLogFile:TLSRollingFileOutputStreamDefaultMaxBytesPerLogFile
                                        error:errorOut];
}

- (instancetype)initWithLogFileDirectoryPath:(NSString *)logFileDirectoryPath
                               logFilePrefix:(NSString *)logFilePrefix
                                 maxLogFiles:(NSUInteger)maxLogFiles
                          maxBytesPerLogFile:(NSUInteger)maxBytesPerLogFile
{
    return [self initWithLogFileDirectoryPath:logFileDirectoryPath
                                logFilePrefix:logFilePrefix
                                  maxLogFiles:maxLogFiles
                           maxBytesPerLogFile:maxBytesPerLogFile
                                        error:NULL];
}

- (instancetype)initWithLogFileDirectoryPath:(NSString *)logFileDirectoryPath
                               logFilePrefix:(NSString *)logFilePrefix
                                 maxLogFiles:(NSUInteger)maxLogFiles
                          maxBytesPerLogFile:(NSUInteger)maxBytesPerLogFile
                                       error:(out NSError **)errorOut // NS_DESIGNATED_INIIALIZER
{
    // allocation preconditions
    if (errorOut) {
        *errorOut = nil;
    }

    if (!logFileDirectoryPath) {
        logFileDirectoryPath = [TLSFileOutputStream defaultLogFileDirectoryPath];
    }

    if (!logFilePrefix) {
        logFilePrefix = @"";
    }

    // generate a log-file name, including edge-case of a duplicate file
    TLSLogFileId fileId = _GenerateLogFileId();
    NSString* generatedLogFileName;
    NSFileManager* fm = [NSFileManager defaultManager];
    while ([fm fileExistsAtPath:[logFileDirectoryPath stringByAppendingPathComponent:(generatedLogFileName = _GenerateLogFileName(logFilePrefix, fileId))]]) {
        ++fileId;
    }

    NSError *error = nil;
    self = [super initWithLogFileDirectoryPath:logFileDirectoryPath
                                   logFileName:generatedLogFileName
                                         error:&error];
    if (self) {

        [self tls_fileOutputEventBegan:TLSRollingFileOutputEventInitialize info:nil];

        maxBytesPerLogFile = MAX(MIN(maxBytesPerLogFile, kMaxBytesPerFile), kMinBytesPerFile);
        NSUInteger absoluteMaxLogFiles = (NSUInteger)MIN((kMaxBytesTotal / (unsigned long long)maxBytesPerLogFile), (unsigned long long)kMaxLogFiles);
        maxLogFiles = MAX(MIN(maxLogFiles, absoluteMaxLogFiles), kMinLogFiles);

        _maxBytesPerLogFile = maxBytesPerLogFile;
        _maxLogFiles = maxLogFiles;
        _logFilePrefix = [logFilePrefix copy];
        _hasRunPrune = NO;

        [self tls_fileOutputEventFinished:TLSRollingFileOutputEventInitialize
                                     info:@{ TLSRollingFileOutputEventKeyNewLogFilePath : _logFilePath }];

    } else if (!error) {
        NSString *exceptionName = NSDestinationInvalidException;
        NSString *message = [NSString stringWithFormat:@"'%@' could not be created in destination directory %@!", generatedLogFileName, logFileDirectoryPath];
        NSDictionary *info = @{ @"logFileDirectoryPath" : (logFileDirectoryPath) ?: [NSNull null],
                                @"generatedLogFileName" : generatedLogFileName,
                                @"message" : message,
                                @"exceptionName" : exceptionName };
        error = [NSError errorWithDomain:TLSErrorDomain code:EINVAL userInfo:info];
    }

    if (error) {
        [self tls_fileOutputEventFailed:TLSRollingFileOutputEventInitialize
                                   info:error.userInfo
                                  error:error];

        if (errorOut) {
            *errorOut = error;
        }
        return nil;
    }

    return self;
}

#pragma mark - TLSFileOutputStream override implementations

- (void)outputLogData:(NSData *)data
{
    NSDictionary *info = @{ TLSRollingFileOutputEventKeyLogData : (data) ?: [NSNull null] };
    [self tls_fileOutputEventBegan:TLSRollingFileOutputEventOutputLogData
                              info:info];

    // The only way `data` can be `nil` is if the caller coersed it to be a `nonnull` argument.
    // Since we are just wrapping the behavior of `outputLogData:` we MUST NOT change its behavior
    // and need to pass the `data` argument in the same coersed fashion so that the base
    // implementation can maintain ownership of acting upon `data`.
    [super outputLogData:(NSData * __nonnull)data];

    [self tls_fileOutputEventFinished:TLSRollingFileOutputEventOutputLogData
                                 info:info];
    if ([self _rolloverIfNeeded] || !_hasRunPrune) {
        [self _purgeOldLogsIfNeeded];
    }
}

#pragma mark - TLSDataRetrieval protocol implementations

- (NSData *)tls_retrieveLoggedData:(NSUInteger)maxBytes
{
    if (maxBytes <= self.maxBytesPerLogFile) {
        maxBytes = self.maxBytesPerLogFile;
    }

    [self tls_flush];
    NSArray<NSString *> *logs = [self _getLogFiles];
    NSString *logDirectoryPath = self.logFileDirectoryPath;
    NSMutableData *data = nil;
    NSFileManager *fm = [NSFileManager defaultManager];

    if (logs.count > 0) {
        // go through the logs, newest to oldest
        // prepend 1 log file at a time so long as it doesn't exceed our maximum size restrictions
        for (NSInteger i = (logs.count - 1); i >= 0; i--) {
            // keep this loop tight with an autorelease pool
            @autoreleasepool {
                NSString* logPath = [logs objectAtIndex:i];
                logPath = [logDirectoryPath stringByAppendingPathComponent:logPath];
                if (!data || ((data.length + [fm attributesOfItemAtPath:logPath error:NULL].fileSize) <= maxBytes)) {
                    NSMutableData* fileData = [NSMutableData dataWithContentsOfFile:logPath];
                    if (data) {
                        [fileData appendData:data];
                    }
                    data = fileData;
                }
            }
        }
    }

    return data; // don't copy the gobs of data we just created...
}

#pragma mark - TLSFileOutputStreamEvent protocol implementation

- (void)tls_fileOutputEventBegan:(TLSFileOutputEvent)event
                            info:(NSDictionary *)info
{
    if (TLSRollingFileOutputEventRolloverLogs == event) {
        NSString *newFile = info[TLSRollingFileOutputEventKeyNewLogFilePath];
        [self writeString:LOG_EVENT_PREFIX @"Single log limit reached. Moving to "];
        [self writeString:newFile];
        [self writeNewline];
    } else if (TLSRollingFileOutputEventPruneLogs == event) {
        [self writeString:[NSString stringWithFormat:LOG_EVENT_PREFIX @"At log file limit of %tu.  Pruning log files.", self.maxLogFiles]];
        [self writeNewline];
    }
}

- (void)tls_fileOutputEventFinished:(TLSFileOutputEvent)event
                               info:(NSDictionary *)info
{
    if (TLSRollingFileOutputEventInitialize == event) {
        [self _writeStartupTimestampInfo];
    } else if (TLSRollingFileOutputEventRolloverLogs == event) {
        NSString *oldFile = info[TLSRollingFileOutputEventKeyOldLogFilePath];
        [self writeString:LOG_EVENT_PREFIX @"... continuing log from "];
        [self writeString:oldFile];
        [self writeNewline];
        [self _writeStartupTimestampInfo];
    } else if (TLSRollingFileOutputEventPruneLogs == event) {
        [self writeString:LOG_EVENT_PREFIX @"logs successfully pruned."];
        [self writeNewline];
    } else if (TLSRollingFileOutputEventPurgeLog == event) {
        NSString *oldFile = info[TLSRollingFileOutputEventKeyOldLogFilePath];
        [self writeString:LOG_EVENT_PREFIX @"Purged old log file: "];
        [self writeString:oldFile];
        [self writeNewline];
    }
}

- (void)tls_fileOutputEventFailed:(TLSFileOutputEvent)event
                             info:(NSDictionary *)info
                            error:(NSError *)error
{
    NSString *message = error.userInfo[@"message"];
    [self writeString:LOG_EVENT_PREFIX @"ERROR - "];
    [self writeString:message];
    [self writeNewline];

    if (TLSRollingFileOutputEventRolloverLogs == event) {
        NSString *newFile = info[TLSRollingFileOutputEventKeyNewLogFilePath];
        [self writeString:LOG_EVENT_PREFIX @"ERROR - could not open "];
        [self writeString:newFile];
        [self writeNewline];
    } else if (TLSRollingFileOutputEventPurgeLog == event) {
        NSString *oldFile = info[TLSRollingFileOutputEventKeyOldLogFilePath];
        [self writeString:LOG_EVENT_PREFIX @"ERROR - failed to purge old log file: "];
        [self writeString:oldFile];
        [self writeNewline];
    }
}

@end

#pragma mark - private method implementations

@implementation TLSRollingFileOutputStream (Private)

- (BOOL)_rolloverIfNeeded
{
    BOOL didRollover = NO;

    if (_maxBytesPerLogFile < self.bytesWritten) {
#if DEBUG
        NSCAssert(_maxBytesPerLogFile > 0, @"Max bytes per file must not be 0");
#endif

        NSFileManager* fm = [NSFileManager defaultManager];
        NSString *oldFilePath = self.logFilePath;
        NSString *oldFileDir = self.logFileDirectoryPath;
        TLSLogFileId fileId = _GenerateLogFileId();
        NSString *newFilePath = [oldFileDir stringByAppendingPathComponent:_GenerateLogFileName(self.logFilePrefix, fileId)];

        // fileId is based on the current second, here's code to handle super edge case of resusing the same file id.
        while ([fm fileExistsAtPath:newFilePath]) {
            fileId++;
            newFilePath = [oldFileDir stringByAppendingPathComponent:_GenerateLogFileName(self.logFilePrefix, fileId)];
        }

#if DEBUG
        NSCAssert([oldFileDir isEqualToString:[oldFilePath stringByDeletingLastPathComponent]], @"Path missmatch!");
        NSCAssert(![newFilePath isEqualToString:oldFilePath], @"Old path cannot match new path!");
#endif

        NSDictionary *eventInfo = @{ TLSRollingFileOutputEventKeyOldLogFilePath : oldFilePath,
                                     TLSRollingFileOutputEventKeyNewLogFilePath : newFilePath };
        [self tls_fileOutputEventBegan:TLSRollingFileOutputEventRolloverLogs
                                  info:eventInfo];

        NSError *openError;
        if (!(didRollover = [self openLogFilePath:newFilePath error:&openError])) {
            [self tls_fileOutputEventFailed:TLSRollingFileOutputEventRolloverLogs
                                       info:eventInfo
                                      error:[NSError errorWithDomain:NSDestinationInvalidException
                                                                code:errno
                                                            userInfo:@{ @"message" : @"Log could not be rolled over" }]];
        } else {
            [self tls_fileOutputEventFinished:TLSRollingFileOutputEventRolloverLogs
                                         info:eventInfo];
        }
    }

    return didRollover;
}

- (BOOL)_purgeOldLogsIfNeeded
{
    _hasRunPrune = YES;
    NSArray<NSString *>* logs = [self _getLogFiles];
    BOOL purgeMade = NO;

    NSUInteger logFileCount = logs.count;
    NSUInteger maxLogFiles = self.maxLogFiles;
    if (logFileCount > maxLogFiles) {
#if DEBUG
        NSCAssert(maxLogFiles > 0, @"Must have maximum number of log files be at least 1");
#endif

        NSString *root = self.logFileDirectoryPath;
        NSString *currentFile = self.logFilePath;

        [self tls_fileOutputEventBegan:TLSRollingFileOutputEventPruneLogs
                                  info:nil];

        NSFileManager *fm = [NSFileManager defaultManager];
        NSUInteger filesToDelete = logFileCount - maxLogFiles;
        for (NSUInteger i = 0; i < logFileCount && 0 != filesToDelete; i++) {
            NSString* nextLog = [root stringByAppendingPathComponent:[logs objectAtIndex:i]];
            if ([nextLog isEqualToString:currentFile]) {
                // Ran out of logs to purge
                break;
            }

            NSError *err = nil;
            NSDictionary *eventInfo = @{ TLSRollingFileOutputEventKeyOldLogFilePath : nextLog };
            [self tls_fileOutputEventBegan:TLSRollingFileOutputEventPurgeLog
                                      info:eventInfo];
            if ([fm removeItemAtPath:nextLog error:&err]) {
                [self tls_fileOutputEventFinished:TLSRollingFileOutputEventPurgeLog
                                             info:eventInfo];
                filesToDelete--;
                purgeMade = YES;
            } else {
                NSString *domain = NSDestinationInvalidException;
                NSDictionary *errInfo = @{ @"message" : @"File could not be purged" };
                NSInteger code = EPERM;
                if (err) {
                    domain = err.domain;
                    code = err.code;
                    NSMutableDictionary *errInfoM = [err.userInfo mutableCopy];
                    if (!errInfoM) {
                        errInfoM = [[NSMutableDictionary alloc] init];
                    }
                    if (!errInfoM[@"message"]) {
                        errInfoM[@"message"] = errInfo[@"message"];
                    }
                    errInfo = errInfoM;
                }
                [self tls_fileOutputEventFailed:TLSRollingFileOutputEventPurgeLog
                                           info:eventInfo
                                          error:[NSError errorWithDomain:domain
                                                                    code:code
                                                                userInfo:errInfo]];
            }
        }

        if (filesToDelete > 0) {
            [self tls_fileOutputEventFailed:TLSRollingFileOutputEventPruneLogs
                                       info:nil
                                      error:[NSError errorWithDomain:NSGenericException
                                                                code:EIO
                                                            userInfo:@{ @"message" : @"Could not prune enough logs to reach out log file limit" }]];
        } else {
            [self tls_fileOutputEventFinished:TLSRollingFileOutputEventPruneLogs
                                         info:nil];
        }
    }

    return purgeMade;
}

- (nullable NSArray<NSString *> *)_getLogFiles
{
    NSError *err = nil;
    NSMutableArray<NSString *> *logs = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.logFileDirectoryPath
                                                                                            error:&err] mutableCopy];

    if (err) {
        // should this be a TLSFileOutputEvent so we can log it?
        return nil;
    }

    @autoreleasepool {
        NSIndexSet *indexSet = [logs indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return ![(NSString *)obj hasPrefix:self->_logFilePrefix] || ![[(NSString *)obj pathExtension] isEqualToString:TLSRollingFileOutputStreamDefaultLogFileExtension];
        }];
        [logs removeObjectsAtIndexes:indexSet];

        NSUInteger prefixLength = _logFilePrefix.length;
        [logs sortUsingComparator:^NSComparisonResult (id obj1, id obj2) {
            NSString* logFile1 = [obj1 stringByDeletingPathExtension];
            NSString* logFile2 = [obj2 stringByDeletingPathExtension];

            if (logFile1.length <= prefixLength || logFile2.length <= prefixLength) {
                return [logFile1 compare:logFile2];
            }

            logFile1 = [logFile1 substringFromIndex:prefixLength];
            logFile2 = [logFile2 substringFromIndex:prefixLength];

            long long stamp1 = logFile1.longLongValue;
            long long stamp2 = logFile2.longLongValue;

            if (stamp1 < stamp2) {
                return NSOrderedAscending;
            } else if (stamp1 > stamp2) {
                return NSOrderedDescending;
            }

            return NSOrderedSame;
        }];
    }

    return [logs copy];
}

- (void)_writeStartupTimestampInfo
{
    static NSDateFormatter *sFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sFormatter = [[NSDateFormatter alloc] init];
        sFormatter.dateFormat = @"YYYY'-'MM'-'dd HH':'mm':'ss zZ";
        sFormatter.timeZone = [NSTimeZone localTimeZone];
    });

    NSString *startupTimestamp = [sFormatter stringFromDate:[TLSLoggingService sharedInstance].startupTimestamp];

    [self writeString:LOG_EVENT_PREFIX];
    [self writeString:NSStringFromClass([TLSLoggingService class])];
    [self writeString:@" startup = '"];
    [self writeString:startupTimestamp];
    [self writeString:@"'"];
    [self writeNewline];
}

@end
