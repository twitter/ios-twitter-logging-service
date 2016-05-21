//
//  TLS_Project.h
//  TwitterLoggingService
//
//  Created on 3/24/16.
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

/* This header is private to Twitter Logging Service */

@import Foundation;

/*
 Static Asserts (asserts that trigger at compile time)

 Call `TLS_COMPILER_ASSERT` with the condition and the message.
 The message MUST be variable name compliant (no whitespace, alpha, numeric and '_')

 Example:

     TLS_COMPILER_ASSERT((sizeof(sArray) / sizeof(sArray[0])) == kExpectedArrayItemCount,
                         array_count_didnt_match_expected_count);
 */
#define __TLS_COMPILER_ASSERT(line, msg) \
    TLS_COMPILER_ASSERT_##line##_##msg
#define _TLS_COMPILER_ASSERT(line, msg) \
    __TLS_COMPILER_ASSERT(line, msg)
#define TLS_COMPILER_ASSERT(cond, msg) \
    typedef char _TLS_COMPILER_ASSERT(__LINE__, msg) [ (cond) ? 1 : -1 ]

//! Best effort attempt to get the binary name of the current process
FOUNDATION_EXTERN NSString *TLSGetProcessBinaryName();
