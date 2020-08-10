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

#import <Foundation/Foundation.h>

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
FOUNDATION_EXTERN NSString *TLSGetProcessBinaryName(void);

/** Does the `mask` have at least 1 of the bits in `flags` set */
#define TLS_BITMASK_INTERSECTS_FLAGS(mask, flags)   (((mask) & (flags)) != 0)
/** Does the `mask` have all of the bits in `flags` set */
#define TLS_BITMASK_HAS_SUBSET_FLAGS(mask, flags)   (((mask) & (flags)) == (flags))
/** Does the `mask` have none of the bits in `flags` set */
#define TLS_BITMASK_EXCLUDES_FLAGS(mask, flags)     (((mask) & (flags)) == 0)

#pragma mark - Objective-C attribute support

#if defined(__has_attribute) && (defined(__IPHONE_14_0) || defined(__MAC_10_16) || defined(__MAC_11_0) || defined(__TVOS_14_0) || defined(__WATCHOS_7_0))
# define TLS_SUPPORTS_OBJC_DIRECT __has_attribute(objc_direct)
#else
# define TLS_SUPPORTS_OBJC_DIRECT 0
#endif

#if defined(__has_attribute)
# define TLS_SUPPORTS_OBJC_FINAL  __has_attribute(objc_subclassing_restricted)
#else
# define TLS_SUPPORTS_OBJC_FINAL  0
#endif

#pragma mark - Objective-C Direct Support

#if TLS_SUPPORTS_OBJC_DIRECT
# define tls_nonatomic_direct     nonatomic,direct
# define tls_atomic_direct        atomic,direct
# define TLS_OBJC_DIRECT          __attribute__((objc_direct))
# define TLS_OBJC_DIRECT_MEMBERS  __attribute__((objc_direct_members))
#else
# define tls_nonatomic_direct     nonatomic
# define tls_atomic_direct        atomic
# define TLS_OBJC_DIRECT
# define TLS_OBJC_DIRECT_MEMBERS
#endif // #if TLS_SUPPORTS_OBJC_DIRECT

#pragma mark - Objective-C Final Support

#if TLS_SUPPORTS_OBJC_FINAL
# define TLS_OBJC_FINAL   __attribute__((objc_subclassing_restricted))
#else
# define TLS_OBJC_FINAL
#endif // #if TLS_SUPPORTS_OBJC_FINAL

