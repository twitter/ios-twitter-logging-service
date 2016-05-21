//
//  TLSConsoleOutputStreams.h
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
 concrete implementation of a `TLSOutputStream` that writes to `stderr`.
 @note If this stream is used, do not use `TLSNSLogOutputStream`.
 */
@interface TLSStdErrOutputStream : NSObject <TLSOutputStream>

/** uses `fprintf` to write the *logInfo* to `stderr` */
- (void)tls_outputLogInfo:(nonnull TLSLogMessageInfo *)logInfo;

/** flush `stderr` */
- (void)tls_flush;

@end


/**
 concrete implementation of a `TLSOutputStream` that uses `NSLog`.
 @note If this stream is used, do not use `TLSStdErrOutputStream`.
 */
@interface TLSNSLogOutputStream : NSObject <TLSOutputStream>

/** writes the *logInfo* to `NSLog` */
- (void)tls_outputLogInfo:(nonnull TLSLogMessageInfo *)logInfo;

@end
