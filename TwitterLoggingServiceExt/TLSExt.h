//
//  TLSExt.h
//  TwitterLoggingService
//
//  Created on 6/28/19.
//  Copyright © 2020 Twitter. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TLSExtOSLogActivityMonitor;
@class TLSLogMessageInfo;

//! Domain for `TLSExt` errors
FOUNDATION_EXTERN NSErrorDomain const TLSExtErrorDomain;

//! block for providing a log message info to log
typedef void(^TLSExtOSLogActivityLogMessageBlock)(TLSLogMessageInfo *info);

//! Set the start time of `os_log` entries (can be rough estimate). For computing the relative time elapsed of any given entry. Leaving unset will use the first encountered `os_log` entry's timestamp (until this function is called).
FOUNDATION_EXTERN void TLSExtSetOSLogActivityStartTimestamp(NSDate *timestamp);

/**
 Register a `TLSExtOSLogActivityMonitor` for monitoring `os_log` messages.
 The registration process will also load the private __LoggingSupport.framework__.
 @param monitor the `TLSExtOSLogActivityMonitor` to observe events with
 @param outError an `NSError` if registration failed
 @return returns `YES` if the _monitor_ could register successfully.  `NO` if registration failed.
 @warning Since this function requires using a private Apple framework, this should ONLY ever be used by non-production apps. Running this code (and potentially even just compiling it!) will result in the app being rejected by Apple.  For development purposes ONLY!  See `TLSLogExt`.
 */
FOUNDATION_EXTERN BOOL TLSExtRegisterOSLogActivityMonitor(id<TLSExtOSLogActivityMonitor> monitor, NSError * __nullable * __nullable outError);

//! Convenience function to create a `TLSExtOSLogActivityMonitor` instance.  See `TLSExtOSLogActivityMonitor`.
FOUNDATION_EXTERN id<TLSExtOSLogActivityMonitor> TLSExtOLSLogActivityMonitorCreate(NSString * __nullable defaultChannel,
                                                                                   TLSExtOSLogActivityLogMessageBlock __nullable logMessageBlock,
                                                                                   TLSExtOSLogActivityLogMessageBlock __nullable activityStreamEventBlock) NS_RETURNS_RETAINED;

/**
 A protocol for monitoring `os_log` entries.

 Currenly supports _log message_ and _activity stream event_ entries.

 @note log message entries that are _debug_ level will not be passed to the monitor (just too verbose).
 @note log message entries that come from `NSLog` will not be passed to the monitor.

 @warning all source messages are from `os_log` so it is critical that no output messages go to
 `os_log` or you will hit an infinite loop!  Take care you do not log these messages to
 `TLSOSLogOutputStream`.  `TLSNSLogOutputStream` will be fine since `NSLog` messages are filtered
 out by the __TLSExt__ system that captures `os_log` messages.
 */
@protocol TLSExtOSLogActivityMonitor <NSObject>

@optional

/**
 default channel for the `TLSLogMessageInfo` if a channel cannot be surmised.
 If not implemented or `nil`, will fall back to `@"OSLog"`.
 */
- (nullable NSString *)tlsext_defaultChannel;

/** callback when a _log message_ entry is encountered */
- (void)tlsext_logMessage:(TLSLogMessageInfo *)info;

/** callback when an _activity stream event_ occurs */
- (void)tlsext_activityStreamEvent:(TLSLogMessageInfo *)info;

// TODO: add support for additional entries like trace messages

@end

#if APPLEDOC
/**
 # __Twitter Logging Service Extensions__ (aka __TLSExt__)

 __TLSExt__ provides extra functionality outside of __TLS__ itself and can be compiled and linked by
 any app consuming __TLS__.

 The features of __TLSExt__ are tied to Private frameworks from Apple and are therefore deemed
 _unsafe_ for shipping with production code.

 @warning Only compile / link __TLSExt__ into non-production builds!  Compiling/linking __TLSExt__ into production builds __will__ result in app store rejection!

 @note __TLSExt__ depends on __TLS__, but it would be fairly simple to change the `TLSLogMessageInfo` uses into something that doesn't depend on __TLS__ if you want to capture `os_log` activity without depending on __TLS__.

 ## TLSExt Errors

     FOUNDATION_EXTERN NSString * const TLSExtErrorDomain;

 ## os_log activity monitoring

 __TLSExt__ provides APIs to observe `os_log` activity.  This is a great feature when capturing logs
 to debug issues that might only be seen in the logs from Apple frameworks, or if `os_log` ends up
 being a logging mechanism for an app.

 At Twitter, we elect to capture the `os_log` activity and write it to disk in a rolling log.  When
 an employee encounters an issue and they file a bug report from our dogfood app, these logs (among
 others) are zipped up and sent to our bug reporting system.  We do not link __TLSExt__ at all in
 production -- it is strictly a tool for non-production builds.

 ### Set the start time for activity monitoring

 Call `TLSExtSetOSLogActivityStartTimestamp` with and `NSDate` timestamp to set the starting time
 when `os_log` activity started (can be rough estimate). Leaving unset will use the first encountered `os_log` entry's timestamp (until this function is called).

    FOUNDATION_EXTERN void TLSExtSetOSLogActivityStartTimestamp(NSDate *timestamp);

 ### Create an os_log activity monitor instance

 Use `TLSExtOLSLogActivityMonitorCreate` convenience function to create a `TLSExtOSLogActivityMonitor`
 instance.  See `TLSExtOSLogActivityMonitor`.

     FOUNDATION_EXTERN id \<TLSExtOSLogActivityMonitor\> TLSExtOLSLogActivityMonitorCreate(
                                                                NSString * __nullable defaultChannel,
                                                                TLSExtOSLogActivityLogMessageBlock __nullable logMessageBlock,
                                                                TLSExtOSLogActivityLogMessageBlock __nullable activityStreamEventBlock
                                                                            ) NS_RETURNS_RETAINED;

 Or instantiate a custom implementation of `TLSExtOSLogActivityMonitor` protocol

 ### Registering an os_log activity monitor

 Register a `TLSExtOSLogActivityMonitor` for monitoring `os_log` messages with `TLSExtRegisterOSLogActivityMonitor`

    FOUNDATION_EXTERN BOOL TLSExtRegisterOSLogActivityMonitor(id \<TLSExtOSLogActivityMonitor\> monitor,
                                                              NSError * __nullable * __nullable outError);

 Returns `YES` if the _monitor_ could register successfully.  `NO` if registration failed.

 ### CFNETWORK_DIAGNOSTICS monitoring

 With __TLSExt__ support of `os_log` monitoring, it is now possible to easily capture `CFNetwork`
 logs to help debug while developing.  What used to require a special profile installed on a specific
 device followed by a sysdiagnose (takes 10 minutes to gather!), now can just be captured in whatever
 logs you prefer.

 To enable `CFNetwork` logs, you must set the `"CFNETWORK_DIAGNOSTICS"` environment variable to a
 desired logging level (`"1"`, `"2"` or `"3"`), and it must be done _before_ any `NSURLSession`
 instances are instantiated.

    setenv("CFNETWORK_DIAGNOSTICS", "1", 1);

 3 ways to do it:

   1. Set the environment variable before running the given app (edit target app's scheme: under Run > Arguments > Environment Variables).
   2. Set the environment variable early during execution, such as during the `main` function starting.
   3. Set the environment variable with a C constructor (so it runs before `main`).

 */
NS_ROOT_CLASS @interface TLSExt
@end
#endif

NS_ASSUME_NONNULL_END
