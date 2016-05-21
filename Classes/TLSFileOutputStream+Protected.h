//
//  TLSFileOutputStream+Protected.h
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

#import "TLSFileOutputStream.h"

/**
 ## Protected category

 The Protected category contains methods of interested for any class subclassing `TLSFileOutputStream` and can be broken into 3 different sets of methods:

 # write methods

 Methods for writing data to the open log file.  Do not override these (except for `writeNewline`).

    - (void)writeBytes:(const char*)bytes length:(size_t)length;
    - (void)writeByte:(const char)byte;
    - (void)writeData:(NSData *)data;
    - (void)writeString:(NSString *)string;
    - (void)writeNewline; // writes '\n' character by default.  Can be overridden.

 # data output method

 Method that actual writes the log message data.  `tls_outputLogInfo:` just converts the log message into what should be written and then calls this.
 To customize log message output, override `tls_outputLogInfo:` and call `outputLogData:` with the custom data output.
 Don't override `outputLogData:`.

    - (void)outputLogData:(NSData *)data;
 */

@interface TLSFileOutputStream (Protected)

/**
 Convenience method to call createLogFileDirectoryAtPath:error: with the defaultLogFileDirectoryPath.
 It can be overridden to point to a different default log file directory for the given stream subclass.
 */
+ (BOOL)createDefaultLogFileDirectoryOrError:(out NSError * __nullable __autoreleasing * __nullable)errorOut;

/**
 Create a log file directory at the designated path and set the `logFileDirectoryPath` property.
 @return NO if there is an error and _errorOut_ will be set
 */
+ (BOOL)createLogFileDirectoryAtPath:(nonnull NSString*)logFileDirectoryPath error:(out NSError * __nullable __autoreleasing * __nullable)errorOut;

/**
 This is the method that actually writes the formatted log message data.
 The default implementation of  `tls_outputLogInfo:` just formats the log message into what should be written and then calls this.
 To customize log message output, override `tls_outputLogInfo:` and call this method with the custom data output.

 **DO NOT override this method **
 */
- (void)outputLogData:(nonnull NSData *)data;

/**
 This overrideable method performs the inner operation of opening a log at the given filepath.
 The directory containing the file designated by the new file to be created must already exist (generally achieved by separately calling createLogFileDirectoryAtPath:error:).
 This will set the `logFile`, `logFilePath` and `logFileDirectoryPath` properties and reset the `bytesWritten`.
 @param logFilePath must be non-nil
 @return YES if the file was opened, and NO if not.
 */
- (BOOL)openLogFilePath:(nonnull NSString*)logFilePath error:(out NSError * __nullable __autoreleasing * __nullable)errorOut;

#pragma mark Write Methods

/** do not override */
- (void)writeBytes:(const char* __nonnull)bytes length:(size_t)length;
/** do not override */
- (void)writeByte:(const char)byte;
/** do not override */
- (void)writeData:(nonnull NSData *)data;
/** do not override */
- (void)writeString:(nonnull NSString *)string;
/** override if you want newlines to be different than default of `'\n'` */
- (void)writeNewline;

@end
