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

#pragma mark - Private Method C Functions Support

/**
 Macro to help with implementing static C-functions instead of private methods

    static NSString *_extendedDescription(PRIVATE_SELF(type))
    {
        if (!self) { // ALWAYS perform the `self` nil-check first
            return nil;
        }
        return [[self description] stringByAppendingFormat:@" %@", self->_extendedInfo];
    }

 Can be helpful to define a macro at the top of a .m file for the primary class' `PRIVATE_SELF`.
 Then, that macro can be used in all private function declarations/implementations
 For example:

    // in TLSLoggingService.m
    #define SELF_ARG PRIVATE_SELF(TLSLoggingService)

    static NSString *_extendedDescription(SELF_ARG)
    {
        if (!self) { // ALWAYS perform the `self` nil-check first
            return nil;
        }
        return [[self description] stringByAppendingFormat:@" %@", self->_extendedInfo];
    }

 Calling:

     // private method
     NSString *description = [self _tip_extendedDescription];

     // static function
     NSString *description = _extendedDescription(self);

 Provide context:

    // Don't just pass ambiguous values to arguments, provide context

    UIImage *nilOverlayImage = nil;
    UIImage *image = _renderImage(self,
                                  nilOverlayImage,
                                  self.textOverlayString,
                                  [UIColor yellow], // tintColor
                                  UIImageOrientationUp,
                                  CGSizeZero, // zero size to render without scaling
                                  0, // options
                                  NO); // opaque

 Note the context is clear for each:

     1. self is self, of course
     2. nilOverlayImage: we set up a local variable so we can provide context instead of passing `nil` without context
     3. self.textOverlayString: variable is descriptive of what it is, enough context on its own
     4. [UIColor yellow]: it's a color, sure, but what for?  Provide a comment that it is for the `tintColor`
     5. UIImageOrientationUp: clear that this is the orientation to provide to the render function
     6. CGSizeZero: it's a size, but what does it mean for a special case value of zero and what's the size for?  Extra context with a descriptive comment.
     7. 0: provides no insight, commenting that it is for `options` is sufficient at specifying that no options were selected.
     8. NO: provides no insight, commenting that it is for `opaque` indicates the image render will be non-opaque (and probably have an alpha channel).
 */

#ifndef PRIVATE_SELF
#define PRIVATE_SELF(type) type * __nullable const self
#endif
