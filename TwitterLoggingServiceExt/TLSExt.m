//
//  TLSExt.m
//  TwitterLoggingService
//
//  Created on 6/28/19.
//  Copyright © 2019 Twitter. All rights reserved.
//

#include <dlfcn.h>

#import <TwitterLoggingService/TLSDeclarations.h>
#import "TLSExt.h"

#pragma mark - Other definitions

NSString * const TLSExtErrorDomain = @"TLSExt.domain";
static NSString * const kFallbackChannel = @"OSLog";
static NSDate * sOSLogActivityStartTimestamp = nil;

NS_INLINE NSDate *_TLSExtGetOSLogActivityStartTimestampWithFallbackStartTimestamp(NSDate *fallback)
{
    if (!sOSLogActivityStartTimestamp) {
        sOSLogActivityStartTimestamp = fallback;
    }
    return sOSLogActivityStartTimestamp;
}

#pragma mark - OS Log Definitions

#include "TLSExtDefinitions.h"

#pragma mark - OS Log Dynamic Loading Statics

/// symbols

static uint8_t (*s_func_os_log_get_type)(void *log);
static tls_os_activity_stream_for_pid_t             s_func_os_activity_stream_for_pid;
static tls_os_activity_stream_resume_t              s_func_os_activity_stream_resume;
static tls_os_activity_stream_cancel_t              s_func_os_activity_stream_cancel;
static tls_os_activity_stream_set_event_handler_t   s_func_os_activity_stream_set_event_handler;
static tls_os_log_copy_formatted_message_t          s_func_os_log_copy_formatted_message;

/// handle

static void *sLoggingSupportFrameworkHandle = NULL;

#pragma mark - Activity Stream Code

static TLSLogMessageInfo * __nullable _LogMessageToLogMessageInfo(tls_os_activity_stream_entry_t entry,
                                                                  NSDate *timestamp,
                                                                  id<TLSExtOSLogActivityMonitor> monitor)
{
    tls_os_log_message_t log_message = &entry->log_message;
    if (entry->activity_id == 0 && entry->parent_id == 0 && log_message->subsystem == NULL && log_message->category == NULL) {
        // This is an NSLog message, which means it is not an os_log message and can be skipped
        return nil;
    }

    char *messageBuffer = s_func_os_log_copy_formatted_message(log_message);
    if (!messageBuffer) {
        return nil;
    }

    NSString *message = [[NSString alloc] initWithBytesNoCopy:messageBuffer
                                                       length:strlen(messageBuffer)
                                                     encoding:NSUTF8StringEncoding
                                                 freeWhenDone:YES];
    if (message.length == 0) {
        return nil;
    }

    TLSLogLevel level = TLSLogLevelWarning;
    switch (s_func_os_log_get_type(log_message)) {
        case 0x00:
            level = TLSLogLevelNotice;
            break;
        case 0x01:
            level = TLSLogLevelInformation;
            break;
        case 0x02:
            level = TLSLogLevelDebug;
            break;
        case 0x10:
            level = TLSLogLevelError;
            break;
        case 0x11:
            level = TLSLogLevelCritical;
            break;
        default:
            level = TLSLogLevelWarning;
            break;
    }

    NSString *channel = nil;
    if (log_message->subsystem) {
        NSString *subsystem = @(log_message->subsystem);
        if (subsystem.length) {
            channel = subsystem;
        }
    }
    if (log_message->category) {
        NSString *category = @(log_message->category);
        if (category.length) {
            if (channel) {
                channel = [channel stringByAppendingFormat:@":%@", category];
            } else {
                channel = category;
            }
        }
    }

    if (!channel) {
        channel = [monitor respondsToSelector:@selector(tlsext_defaultChannel)] ? monitor.tlsext_defaultChannel : kFallbackChannel;
    }

    NSDate *startTime = _TLSExtGetOSLogActivityStartTimestampWithFallbackStartTimestamp(timestamp);
    return [[TLSLogMessageInfo alloc] initWithLevel:level
                                               file:@""
                                           function:@""
                                               line:0
                                            channel:channel ?: kFallbackChannel
                                          timestamp:timestamp
                                        logLifespan:[timestamp timeIntervalSinceDate:startTime]
                                           threadId:0
                                         threadName:nil
                                      contextObject:nil
                                            message:message];
}

static bool _ActivityStreamReceivedEntry(id<TLSExtOSLogActivityMonitor> monitor,
                                         tls_os_activity_stream_t activityStream,
                                         tls_os_activity_stream_entry_t entry,
                                         int error)
{
    if (error != 0 || NULL == entry) {
        return true;
    }

    TLSLogMessageInfo *info = nil;
    const long long currentTimeInMS = (entry->common.tv_gmt.tv_sec * 1000) + (entry->common.tv_gmt.tv_usec / 1000);
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:(double)currentTimeInMS / 1000.];
    switch (entry->type) {
        case TLS_OS_ACTIVITY_STREAM_TYPE_ACTIVITY_CREATE:
        case TLS_OS_ACTIVITY_STREAM_TYPE_ACTIVITY_TRANSITION:
        case TLS_OS_ACTIVITY_STREAM_TYPE_ACTIVITY_USERACTION:
            break;

        case TLS_OS_ACTIVITY_STREAM_TYPE_TRACE_MESSAGE:
            // TODO: might want to support trace messages
            break;
        case TLS_OS_ACTIVITY_STREAM_TYPE_LEGACY_LOG_MESSAGE:
            break;
        case TLS_OS_ACTIVITY_STREAM_TYPE_LOG_MESSAGE:
            info = _LogMessageToLogMessageInfo(entry, timestamp, monitor);
            break;

        // TODO: support sign posts
        case TLS_OS_ACTIVITY_STREAM_TYPE_SIGNPOST_BEGIN:
        case TLS_OS_ACTIVITY_STREAM_TYPE_SIGNPOST_END:
        case TLS_OS_ACTIVITY_STREAM_TYPE_SIGNPOST_EVENT:
            break;

        case TLS_OS_ACTIVITY_STREAM_TYPE_STATEDUMP_EVENT:
            // TODO: can we support a state dump?
            break;
    }

    if (info) {
        [monitor tlsext_logMessage:info];
    }

    return true;
}

static void _ActivityStreamReceivedEvent(id<TLSExtOSLogActivityMonitor> monitor,
                                         tls_os_activity_stream_t activityStream,
                                         tls_os_activity_stream_event_t event)
{
    if (![monitor respondsToSelector:@selector(tlsext_activityStreamEvent:)]) {
        return;
    }

    TLSLogLevel level = TLSLogLevelNotice;
    NSDate *timestamp = [NSDate date];
    NSString *message = nil;
    switch (event) {
        case TLS_OS_ACTIVITY_STREAM_EVENT_STARTED:
            message = @"***** activity stream started *****";
            break;
        case TLS_OS_ACTIVITY_STREAM_EVENT_STOPPED:
            message = @"***** activity stream stopped *****";
            break;
        case TLS_OS_ACTIVITY_STREAM_EVENT_FAILED:
            message = @"***** activity stream failed *****";
            break;
        case TLS_OS_ACTIVITY_STREAM_EVENT_CHUNK_STARTED:
            message = @"***** activity stream chunk started *****";
            level = TLSLogLevelDebug;
            break;
        case TLS_OS_ACTIVITY_STREAM_EVENT_CHUNK_FINISHED:
            message = @"***** activity stream chunk finished *****";
            level = TLSLogLevelDebug;
            break;
    }

    if (message) {
        NSString *channel = [monitor respondsToSelector:@selector(tlsext_defaultChannel)] ? monitor.tlsext_defaultChannel : kFallbackChannel;
        NSDate *startTime = _TLSExtGetOSLogActivityStartTimestampWithFallbackStartTimestamp(timestamp);
        TLSLogMessageInfo *info = [[TLSLogMessageInfo alloc] initWithLevel:level
                                                                      file:@""
                                                                  function:@""
                                                                      line:0
                                                                   channel:channel
                                                                 timestamp:timestamp
                                                               logLifespan:[timestamp timeIntervalSinceDate:startTime]
                                                                  threadId:0
                                                                threadName:nil
                                                             contextObject:nil
                                                                   message:message];
        [monitor tlsext_activityStreamEvent:info];
    }
}

#pragma mark - Load LoggingSupport.framework Code

static BOOL _LoadLoggingSupportFramework(NSError * __nullable * __nullable outError)
{
    if (sLoggingSupportFrameworkHandle) {
        return YES;
    }

    sLoggingSupportFrameworkHandle = dlopen("/System/Library/PrivateFrameworks/LoggingSupport.framework/LoggingSupport", RTLD_NOW);
    if (!sLoggingSupportFrameworkHandle) {
        if (outError) {
            NSString *dlerrorStr = @(dlerror());
            *outError = [NSError errorWithDomain:TLSExtErrorDomain
                                            code:-1
                                        userInfo:(dlerrorStr ? @{ NSDebugDescriptionErrorKey : dlerrorStr } : nil)];
        }
        return NO;
    }

    (void)dlerror(); // flush past dlerrors

    NSString *dlsymErrorString = nil;
#define GET_DLSYM_ERR() ({ \
        if (!dlsymErrorString) { \
            char *dlsymError = dlerror(); \
            if (dlsymError) { \
                dlsymErrorString = @(dlsymError); \
            } \
        } \
    })
    s_func_os_activity_stream_for_pid = (tls_os_activity_stream_for_pid_t)dlsym(sLoggingSupportFrameworkHandle, "os_activity_stream_for_pid");
    GET_DLSYM_ERR();
    s_func_os_activity_stream_resume = (tls_os_activity_stream_resume_t)dlsym(sLoggingSupportFrameworkHandle, "os_activity_stream_resume");
    GET_DLSYM_ERR();
    s_func_os_activity_stream_cancel = (tls_os_activity_stream_cancel_t)dlsym(sLoggingSupportFrameworkHandle, "os_activity_stream_cancel");
    GET_DLSYM_ERR();
    s_func_os_log_copy_formatted_message = (tls_os_log_copy_formatted_message_t)dlsym(sLoggingSupportFrameworkHandle, "os_log_copy_formatted_message");
    GET_DLSYM_ERR();
    s_func_os_activity_stream_set_event_handler = (tls_os_activity_stream_set_event_handler_t)dlsym(sLoggingSupportFrameworkHandle, "os_activity_stream_set_event_handler");
    GET_DLSYM_ERR();
    s_func_os_log_get_type = (uint8_t(*)(void *))dlsym(sLoggingSupportFrameworkHandle, "os_log_get_type");
    GET_DLSYM_ERR();

    const BOOL didLoadAllSymbols =  s_func_os_activity_stream_set_event_handler != nil &&
                                    s_func_os_activity_stream_for_pid != nil &&
                                    s_func_os_activity_stream_cancel != nil &&
                                    s_func_os_activity_stream_resume != nil &&
                                    s_func_os_log_copy_formatted_message != nil &&
                                    s_func_os_log_get_type != nil;
    if (!didLoadAllSymbols) {
        if (outError) {
            *outError = [NSError errorWithDomain:TLSExtErrorDomain
                                            code:-2
                                        userInfo:(dlsymErrorString ? @{ NSDebugDescriptionErrorKey : dlsymErrorString } : nil)];
        }
        dlclose(sLoggingSupportFrameworkHandle);
        sLoggingSupportFrameworkHandle = NULL;
        return NO;
    }

    return YES;
}

#pragma mark - Register Code

void TLSExtSetOSLogActivityStartTimestamp(NSDate *timestamp)
{
    if (timestamp) {
        sOSLogActivityStartTimestamp = timestamp;
    }
}

BOOL TLSExtRegisterOSLogActivityMonitor(id<TLSExtOSLogActivityMonitor> monitor, NSError * __nullable * __nullable outError)
{
    if (!_LoadLoggingSupportFramework(outError)) {
        return NO;
    }

    const tls_os_activity_stream_flags_t flags =  TLS_OS_ACTIVITY_STREAM_PROCESS_ONLY |
                                               /* TLS_OS_ACTIVITY_STREAM_DEBUG | Debug is too much */
                                                  TLS_OS_ACTIVITY_STREAM_INFO;
    const pid_t pid = [NSProcessInfo processInfo].processIdentifier;

    __block tls_os_activity_stream_t activityStream = NULL;
    activityStream = s_func_os_activity_stream_for_pid(pid, flags, ^bool(tls_os_activity_stream_entry_t entry, int error) {
        return _ActivityStreamReceivedEntry(monitor, activityStream, entry, error);
    });
    s_func_os_activity_stream_set_event_handler(activityStream, ^void(tls_os_activity_stream_t stream, tls_os_activity_stream_event_t event) {
        _ActivityStreamReceivedEvent(monitor, stream, event);
    });

    s_func_os_activity_stream_resume(activityStream);
    return YES;
}

#pragma mark - Convenience Code

@interface TLSExtGenericOSLogActivityMonitor : NSObject <TLSExtOSLogActivityMonitor>
- (instancetype)initWithDefaultChannel:(nullable NSString *)defaultChannel
                       logMessageBlock:(nullable TLSExtOSLogActivityLogMessageBlock)logMessageBlock
              activityStreamEventBlock:(nullable TLSExtOSLogActivityLogMessageBlock)activityStreamEventBlock;
@end

@implementation TLSExtGenericOSLogActivityMonitor
{
    TLSExtOSLogActivityLogMessageBlock _logMessageBlock;
    TLSExtOSLogActivityLogMessageBlock _activityStreamEventBlock;
    NSString *_defaultChannel;
}

- (instancetype)initWithDefaultChannel:(nullable NSString *)defaultChannel
                       logMessageBlock:(nullable TLSExtOSLogActivityLogMessageBlock)logMessageBlock
              activityStreamEventBlock:(nullable TLSExtOSLogActivityLogMessageBlock)activityStreamEventBlock
{
    if (self = [super init]) {
        _logMessageBlock = [logMessageBlock copy];
        _activityStreamEventBlock = [activityStreamEventBlock copy];
        _defaultChannel = [defaultChannel copy];
    }
    return self;
}

- (nullable NSString *)tlsext_defaultChannel
{
    return _defaultChannel;
}

- (void)tlsext_logMessage:(TLSLogMessageInfo *)info
{
    _logMessageBlock(info);
}

- (void)tlsext_activityStreamEvent:(TLSLogMessageInfo *)info
{
    _activityStreamEventBlock(info);
}

@end

id<TLSExtOSLogActivityMonitor> TLSExtOLSLogActivityMonitorCreate(NSString * __nullable defaultChannel,
                                                                 TLSExtOSLogActivityLogMessageBlock __nullable logMessageBlock,
                                                                 TLSExtOSLogActivityLogMessageBlock __nullable activityStreamEventBlock) NS_RETURNS_RETAINED
{
    return [[TLSExtGenericOSLogActivityMonitor alloc] initWithDefaultChannel:defaultChannel
                                                             logMessageBlock:logMessageBlock
                                                    activityStreamEventBlock:activityStreamEventBlock];
}

