/*******************************************************************************

 University of Illinois/NCSA
 Open Source License

 Copyright (c) 2010 Apple Inc.
 All rights reserved.

 Developed by:

 LLDB Team

 http://lldb.llvm.org/ - https://github.com/limneos/oslog

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal with
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:

 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimers.

 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimers in the
 documentation and/or other materials provided with the distribution.

 * Neither the names of the LLDB Team, copyright holders, nor the names of
 its contributors may be used to endorse or promote products derived from
 this Software without specific prior written permission.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH THE
 SOFTWARE.

 *******************************************************************************/

#ifndef TLSExtDefinitions_h
#define TLSExtDefinitions_h

#include <sys/time.h>

#define TLS_OS_ACTIVITY_MAX_CALLSTACK 32

// Enums

typedef NS_OPTIONS(uint32_t, tls_os_activity_stream_flags_t) {
    TLS_OS_ACTIVITY_STREAM_PROCESS_ONLY = 0x00000001,
    TLS_OS_ACTIVITY_STREAM_SKIP_DECODE = 0x00000002,
    TLS_OS_ACTIVITY_STREAM_PAYLOAD = 0x00000004,
    TLS_OS_ACTIVITY_STREAM_HISTORICAL = 0x00000008,
    TLS_OS_ACTIVITY_STREAM_CALLSTACK = 0x00000010,
    TLS_OS_ACTIVITY_STREAM_DEBUG = 0x00000020,
    TLS_OS_ACTIVITY_STREAM_BUFFERED = 0x00000040,
    TLS_OS_ACTIVITY_STREAM_NO_SENSITIVE = 0x00000080,
    TLS_OS_ACTIVITY_STREAM_INFO = 0x00000100,
    TLS_OS_ACTIVITY_STREAM_PROMISCUOUS = 0x00000200,
    TLS_OS_ACTIVITY_STREAM_PRECISE_TIMESTAMPS = 0x00000200
};

typedef NS_ENUM(uint32_t, tls_os_activity_stream_type_t) {
    TLS_OS_ACTIVITY_STREAM_TYPE_ACTIVITY_CREATE = 0x0201,
    TLS_OS_ACTIVITY_STREAM_TYPE_ACTIVITY_TRANSITION = 0x0202,
    TLS_OS_ACTIVITY_STREAM_TYPE_ACTIVITY_USERACTION = 0x0203,

    TLS_OS_ACTIVITY_STREAM_TYPE_TRACE_MESSAGE = 0x0300,

    TLS_OS_ACTIVITY_STREAM_TYPE_LOG_MESSAGE = 0x0400,
    TLS_OS_ACTIVITY_STREAM_TYPE_LEGACY_LOG_MESSAGE = 0x0480,

    TLS_OS_ACTIVITY_STREAM_TYPE_SIGNPOST_BEGIN = 0x0601,
    TLS_OS_ACTIVITY_STREAM_TYPE_SIGNPOST_END = 0x0602,
    TLS_OS_ACTIVITY_STREAM_TYPE_SIGNPOST_EVENT = 0x0603,

    TLS_OS_ACTIVITY_STREAM_TYPE_STATEDUMP_EVENT = 0x0A00,
};

typedef NS_ENUM(uint32_t, tls_os_activity_stream_event_t) {
    TLS_OS_ACTIVITY_STREAM_EVENT_STARTED = 1,
    TLS_OS_ACTIVITY_STREAM_EVENT_STOPPED = 2,
    TLS_OS_ACTIVITY_STREAM_EVENT_FAILED = 3,
    TLS_OS_ACTIVITY_STREAM_EVENT_CHUNK_STARTED = 4,
    TLS_OS_ACTIVITY_STREAM_EVENT_CHUNK_FINISHED = 5,
};

// Types

typedef uint64_t tls_os_activity_id_t;
typedef struct tls_os_activity_stream_s *tls_os_activity_stream_t;
typedef struct tls_os_activity_stream_entry_s *tls_os_activity_stream_entry_t;

#define TLS_OS_ACTIVITY_STREAM_COMMON() \
uint64_t trace_id;                      \
uint64_t timestamp;                     \
uint64_t thread;                        \
const uint8_t *image_uuid;              \
const char *image_path;                 \
struct timeval tv_gmt;                  \
struct timezone tz;                     \
uint32_t offset

typedef struct tls_os_activity_stream_common_s {
    TLS_OS_ACTIVITY_STREAM_COMMON();
} * tls_os_activity_stream_common_t;

struct tls_os_activity_create_s {
    TLS_OS_ACTIVITY_STREAM_COMMON();
    const char *name;
    tls_os_activity_id_t creator_aid;
    uint64_t unique_pid;
};

struct tls_os_activity_transition_s {
    TLS_OS_ACTIVITY_STREAM_COMMON();
    tls_os_activity_id_t transition_id;
};

typedef struct tls_os_log_message_s {
    TLS_OS_ACTIVITY_STREAM_COMMON();
    const char *format;
    const uint8_t *buffer;
    size_t buffer_sz;
    const uint8_t *privdata;
    size_t privdata_sz;
    const char *subsystem;
    const char *category;
    uint32_t oversize_id;
    uint8_t ttl;
    bool persisted;
} * tls_os_log_message_t;

typedef struct tls_os_trace_message_v2_s {
    TLS_OS_ACTIVITY_STREAM_COMMON();
    const char *format;
    const void *buffer;
    size_t bufferLen;
    void *payload;
} * tls_os_trace_message_v2_t;

typedef struct tls_os_activity_useraction_s {
    TLS_OS_ACTIVITY_STREAM_COMMON();
    const char *action;
    bool persisted;
} * tls_os_activity_useraction_t;

typedef struct tls_os_signpost_s {
    TLS_OS_ACTIVITY_STREAM_COMMON();
    const char *format;
    const uint8_t *buffer;
    size_t buffer_sz;
    const uint8_t *privdata;
    size_t privdata_sz;
    const char *subsystem;
    const char *category;
    uint64_t duration_nsec;
    uint32_t callstack_depth;
    uint64_t callstack[TLS_OS_ACTIVITY_MAX_CALLSTACK];
} * tls_os_signpost_t;

typedef struct tls_os_activity_statedump_s {
    TLS_OS_ACTIVITY_STREAM_COMMON();
    char *message;
    size_t message_size;
    char image_path_buffer[PATH_MAX];
} * tls_os_activity_statedump_t;

struct tls_os_activity_stream_entry_s {
    tls_os_activity_stream_type_t type;

    // information about the process streaming the data
    pid_t pid;
    uint64_t proc_id;
    const uint8_t *proc_imageuuid;
    const char *proc_imagepath;

    // the activity associated with this streamed event
    tls_os_activity_id_t activity_id;
    tls_os_activity_id_t parent_id;

    union {
        struct tls_os_activity_stream_common_s common;
        struct tls_os_activity_create_s activity_create;
        struct tls_os_activity_transition_s activity_transition;
        struct tls_os_log_message_s log_message;
        struct tls_os_trace_message_v2_s trace_message;
        struct tls_os_activity_useraction_s useraction;
        struct tls_os_signpost_s signpost;
        struct tls_os_activity_statedump_s statedump;
    };

};

// Blocks

typedef bool (^tls_os_activity_stream_block_t)(tls_os_activity_stream_entry_t entry,
                                               int error);

typedef void (^tls_os_activity_stream_event_block_t)(tls_os_activity_stream_t stream,
                                                     tls_os_activity_stream_event_t event);

// Functions

typedef tls_os_activity_stream_t (*tls_os_activity_stream_for_pid_t)(pid_t pid,
                                                                     tls_os_activity_stream_flags_t flags,
                                                                     tls_os_activity_stream_block_t stream_block);

typedef void (*tls_os_activity_stream_resume_t)(tls_os_activity_stream_t stream);

typedef void (*tls_os_activity_stream_cancel_t)(tls_os_activity_stream_t stream);

typedef char *(*tls_os_log_copy_formatted_message_t)(tls_os_log_message_t log_message);

typedef void (*tls_os_activity_stream_set_event_handler_t)(tls_os_activity_stream_t stream,
                                                           tls_os_activity_stream_event_block_t block);

#endif /* TLSExtDefinitions_h */
