//
//  TLSFileOutputStream.m
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

#import "TLS_Project.h"
#import "TLSFileOutputStream+Protected.h"

static NSString * const TLSFileOutputEventKeyNewLogFilePath = @"newLogFilePath";

@implementation TLSFileOutputStream

#pragma mark - initialization/cleanup

- (instancetype)initWithLogFileDirectoryPath:(NSString*)logFileDirectoryPath
                                 logFileName:(NSString*)logFileName
                                       error:(out NSError **)errorOut
{
    if (0 == [logFileDirectoryPath length]) {
        if (errorOut) {
            *errorOut = [NSError errorWithDomain:NSPOSIXErrorDomain
                                            code:EINVAL
                                        userInfo:@{ @"message" : @"unable to create directory without a name",
                                                    @"exceptionName" : NSInvalidArgumentException }];
        }
        return nil;
    }

    if (0 == [logFileName length]) {
        if (errorOut) {
            *errorOut = [NSError errorWithDomain:NSPOSIXErrorDomain
                                            code:EINVAL
                                        userInfo:@{ @"message" : @"unable to create file using empty name",
                                                    @"exceptionName" : NSInvalidArgumentException }];
        }
        return nil;
    }

    if (![[self class] createLogFileDirectoryAtPath:logFileDirectoryPath error:errorOut]) {
        return nil;
    }

    if (self = [super init]) {
        _composeLogMessageOptions = TLSComposeLogMessageInfoDefaultOptions;
        if (![self openLogFilePath:[logFileDirectoryPath stringByAppendingPathComponent:logFileName] error:errorOut]) {
            return nil;
        }
    }

    return self;
}

- (instancetype)initWithLogFileName:(NSString*)logFileName
                              error:(out NSError **)errorOut
{
    return [self initWithLogFileDirectoryPath:[TLSFileOutputStream defaultLogFileDirectoryPath]
                                  logFileName:logFileName
                                        error:errorOut];
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort(); // will never be reached, but prevents compiler warning
}

- (void)dealloc
{
    if (_logFile) {
        fflush(_logFile);
        fclose(_logFile);
    }
}

#pragma mark - public class method implementations

+ (NSString *)defaultLogFileDirectoryPath
{
    static NSString *_defaultLogFileDirectoryPath;
    static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
        @autoreleasepool {
            NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
#if !TARGET_OS_IPHONE || TARGET_OS_MACCATALYST
            // platform may be non-sandboxed, or "sandbox" may contain sym-links outside of expected sandbox
            // ensure unique path using bundle-id or process name for safety (if possible)
            NSString *extraPath = [[NSBundle mainBundle] bundleIdentifier] ?: TLSGetProcessBinaryName() ?: @"TLS";
            path = [path stringByResolvingSymlinksInPath];
            if (![path containsString:[NSString stringWithFormat:@"/%@/", extraPath]]) {
                path = [path stringByAppendingPathComponent:extraPath];
            }
#endif
            _defaultLogFileDirectoryPath = [path stringByAppendingPathComponent:@"logs"];
        }
    });
    return _defaultLogFileDirectoryPath;
}

- (NSStringEncoding)tls_loggedDataEncoding
{
    return NSUTF8StringEncoding;
}

- (BOOL)resetAndReturnError:(out NSError * __nullable * __nullable)error
{
    if (_logFile) {
        fclose(_logFile);
        _logFile = NULL;
        [[NSFileManager defaultManager] removeItemAtPath:_logFilePath error:NULL];
    }

    return [self openLogFilePath:_logFilePath error:error];
}

#pragma mark - TLSOutputStream protocol implementation

- (void)tls_flush
{
    if (_logFile) {
        fflush(_logFile);
    }
}

- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo
{
    NSString *message = [logInfo composeFormattedMessageWithOptions:self.composeLogMessageOptions];
    NSData *messageData = [message dataUsingEncoding:self.tls_loggedDataEncoding];
    [self outputLogData:messageData];
}

@end

@implementation TLSFileOutputStream(Protected)

#pragma mark - "protected" method implementations

- (void)writeBytes:(const char*)bytes length:(size_t)length
{
    if (_logFile && bytes != NULL && length > 0) {
        _bytesWritten += fwrite(bytes, 1, length, _logFile);
        if (_flushAfterEveryWriteEnabled) {
            fflush(_logFile);
        }
    }
}

- (void)writeByte:(const char)byte
{
    [self writeBytes:&byte length:1];
}

- (void)writeNewline
{
    [self writeBytes:"\n" length:1];
}

- (void)writeData:(NSData *)data
{
    [self writeBytes:(const char*)data.bytes length:data.length];
}

- (void)writeString:(NSString *)string
{
    [self writeData:[string dataUsingEncoding:self.tls_loggedDataEncoding]];
}

+ (BOOL)createDefaultLogFileDirectoryOrError:(out NSError **)errorOut
{
    return [self createLogFileDirectoryAtPath:[TLSFileOutputStream defaultLogFileDirectoryPath]
                                        error:errorOut];
}

+ (BOOL)createLogFileDirectoryAtPath:(NSString*)logFileDirectoryPath
                               error:(out NSError **)errorOut
{
    if (0 == [logFileDirectoryPath length]) {
        if (errorOut) {
            *errorOut = [NSError errorWithDomain:NSPOSIXErrorDomain
                                            code:EINVAL
                                        userInfo:@{ @"message" : @"unable to create directory without a name",
                                                    @"exceptionName" : NSInvalidArgumentException }];
        }
        return NO;
    }

    NSFileManager* fm = [NSFileManager defaultManager];
    NSError* error;
    [fm createDirectoryAtPath:logFileDirectoryPath
  withIntermediateDirectories:YES
                   attributes:nil
                        error:&error];

    if (!error) {
        BOOL isDir = NO;
        if (![fm fileExistsAtPath:logFileDirectoryPath isDirectory:&isDir]) {
            if (errorOut) {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                            code:ENOENT
                                        userInfo:@{ @"message" : [NSString stringWithFormat:@"'%@' not created", logFileDirectoryPath],
                                                    @"exceptionName" : NSObjectInaccessibleException }];
            }
        } else if (!isDir) {
            if (errorOut) {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                            code:EEXIST
                                        userInfo:@{ @"message" : [NSString stringWithFormat:@"'%@' already exists, but is not a directory", logFileDirectoryPath],
                                                    @"exceptionName" : NSObjectInaccessibleException }];
            }
        }
    }

    if (error) {
        if (errorOut) {
            *errorOut = error;
        }
        return NO;
    }

    return YES;
}

- (BOOL)openLogFilePath:(NSString*)logFilePath
                  error:(NSError **)errorOut
{
    if (0 == [logFilePath length]) {
        if (errorOut) {
            *errorOut = [NSError errorWithDomain:NSPOSIXErrorDomain
                                            code:EINVAL
                                        userInfo:@{ @"message" : @"unable to create file using empty name",
                                                    @"exceptionName" : NSInvalidArgumentException }];
        }
        return NO;
    }

    FILE *newLogFile = fopen(logFilePath.UTF8String, "w");
    if (!newLogFile) {
        if (errorOut) {
            int errCode = errno;
            NSDictionary *info = @{ TLSFileOutputEventKeyNewLogFilePath : (logFilePath) ?: [NSNull null],
                                    @"message" : @"Could not create file for logging to!",
                                    @"exceptionName" : NSObjectInaccessibleException };
            *errorOut = [NSError errorWithDomain:NSPOSIXErrorDomain
                                            code:errCode
                                        userInfo:info];
        }
        return NO;
    }

    if (_logFile) {
        [self tls_flush];
        fclose(_logFile);
    }

    _logFilePath = [logFilePath copy];
    _logFileDirectoryPath = [_logFilePath stringByDeletingLastPathComponent];
    _logFile = newLogFile;
    _bytesWritten = 0;

    return YES;
}

- (void)outputLogData:(NSData *)data
{
    [self writeData:data];
    [self writeNewline];
}

@end
