# Twitter Logging Service

## Background

Twitter created a framework for logging in order to fulfill the following requirements:

- fast (no blocking the main thread)
- thread safe
- as easy as `NSLog` in most situations
- support pluggable "output streams" to which messages will be delivered
- "output streams" filter messages rather than global filtering for all "output streams"
- able to categorize log messages (log channels)
- able to designate importance to log messages (log levels)
- require messages to opt-in for persisted logs (a security requirement, fulfilled by using the _context_ feature of *TLS*)

Twitter has been using *Twitter Logging Service* since January 2014 with minimal changes.  We've decided to share it with the developer community.

## List of good alternative logging frameworks

If *Twitter Logging Service* doesn't meet your needs, there are many great logging frameworks available, including the following high quality and well maintained projects:

- CocoaLumberjack
- SwiftyBeaver
- Apache Logging Services

## Architecture

There are 3 components to consider:
  1. the log message and its context
  2. the logging service instance or singleton
  3. the output stream(s)

The log message is sent to the logging service which provides the message to each output stream.

The logging service is configured by adding discrete output streams.  Output streams encapsulate their own behavior and decisions, including filtering and logging messages.  For instance, logging can mean printing to console with NSLog, writing to a file on disk, or sending the message to a remote server.

Message arguments don't need to be evaluated if the message is going to be filtered out.  This avoids expensive, synchronous execution of argument evaluation.  The message is then packaged with context before it is sent to the logging service.  Context includes information such as the log level, log channel, file name, function name, line number and timestamp.

The logging service marshals the message and its context to a background queue for processing by all available output streams.  Streams can then filter or output the message.

## Installation
### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it using the following command:
```bash
    $ gem install cocoapods
```

To integrate TwitterLoggingService into your Xcode project using CocoaPods, specify it in your `Podfile`:
```ruby
    platform :ios, '8.0'
    use_frameworks!

    target "MyApp" do
        pod 'TwitterLoggingService', '~> 2.5.0'
    end
```

## Usage

`TLSLog.h` is the principal header for using *TwitterLoggingService*.  Just include `TLSLog.h` or `@import TwitterLoggingService`.

```c
    // The primary macros for *TwitterLoggingService*

    TLSLogError(channel, ...)          // Log at the TLSLogLevelError level
    TLSLogWarning(channel, ...)        // Log at the TLSLogLevelWarning level
    TLSLogInformation(channel, ...)    // Log at the TLSLogLevelInformation level
    TLSLogDebug(channel, ...)          // Log at the TLSLogLevelDebug level
```

For each macro in the `TLSLog` family of macros, `TLSCanLog` is called first to gate whether the actual
logging should occur.  This saves us from having to evaluate the arguments to the log message and can provide a win in performance when calling a `TLSLog` macro that will never end up being logged.  For more on `TLSCanLog` see `Gating TLSLog messages` below.

## TLSLog Core Macro

```c
    #define TLSLog(level, channel, ...)
```

`TLSLog` is the core macro and takes 3 parameters: a `TLSLogLevel` level, an `NSString` channel and then an `NSString` format with variable formatting arguments.
The level and channel parameters are used to filter the log message per `TLSOutputStream` in the `TLSLoggingService` singleton.  Providing `nil` as the channel argument to any logging macro, function or method will result in the message not being logged.

## Logging Channels, Levels and Context Objects

# Channels

The logging channel of a log message is an arbitrary string and acts as a tag to that message to further help identify what the message relates to.
Channels can help to quickly identify what a log message relates to in a large code base, as well as provide a mechanism for filtering.
A `TLSOutputStream` can filter based on the logging channel in its implementation of `tls_shouldFilterLevel:channel:contextObject:`.
Providing a `nil` channel to a log statement has the effect of not logging that message.

Examples of potential logging channels: @"Networking" for the networking stack, @"SignUp" for an app’s signup flow,  `TLSLogChannelDefault` as a catch all default logging channel, and @"Verbose" for anything you just want to log for the helluvit.

# Levels

The enum `TLSLogLevel` specifies 8 logging levels in accordance with the *syslog* specification for logging.
For practical use, however, only 4 log levels are used: `TLSLogLevelError`, `TLSLogLevelWarning`, `TLSLogLevelInformation` and `TLSLogLevelDebug`.
Each log message has a specified logging level which helps quickly identify its level, `TLSLogLevelEmergency` (or `TLSLogLevelError` in practice) is the most important while `TLSLogLevelDebug` is the least.
`TLSOutputStream` instances can filter a log message by its log level (in combination with its logging channel and context object) by implementing `tls_shouldFilterLevel:channel:contextObject:`.

An implementation detail to keep in mind w.r.t. logging levels is that `TLSLogLevelDebug` is ALWAYS filtered out in non-`DEBUG` builds.

# Context Objects

Though the `TLSLog` macros do not have a *context object* parameter, one can provide a *context object* to the `TLSLogging` APIs in order to provide additional context to custom `TLSOutputStream`s.
The *context object* will carry through the `TLSLoggingService` so that it is available to all `TLSOutputStream` instances.  The *context object* can be used to filter in the `tls_shouldFilterLevel:channel:contextObject:` method.  The *context object* can also be used for additional information in the logging of a message since it carries to the `TLSLogMessageInfo` object that's passed to `tls_outputLogInfo:`.

This *context object* provides near limitless extensibility to the `TLSLogging` framework beyond the basics of filtering and logging based on a logging level and logging channel.  Twitter uses the *context object* as a way to secure log messages from leaking to output streams that should not log messages unless explicitely told to do so, thus protecting Personally Identifiable Information from being logged as a default behavior.

## Setup

Setting up your project to use *TwitterLoggingService*:

1) Add the *TwitterLoggingService* XCode project as a subproject of your XCode project.

2) Add the *libTwitterLoggingService.a* library or *TwitterLoggingService.framework* framework as a dependency in your XCode project.

3) Set up your project to build the *TwitterLoggingService* project with `DEBUG=1` in debug builds and `RELEASE=1` in release builds.

4) Set up the `TLSLoggingService` singleton on application startup (often in `application:didFinishLaunchingWithOptions:` of your `UIApplication`'s delegate for iOS).

```
    @import TLSLoggingKit;

    // ...

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options
    {
        // ...

        // Set up the Twitter Logging Service!
        TLSLoggingService *logger = [TLSLoggingService sharedInstance];
    #if DEBUG
        if ([TLSOSLogOutputStream supported]) {
            [logger addOutputStream:[[TLSOSLogOutputStream alloc] init]];
        } else {
            [logger addOutputStream:[[TLSNSLogOutputStream alloc] init]];
        }
    #endif
        [logger addOutputStream:[[TLSFileOutputStream alloc] initWithLogFileName:@"appname-info.log"]];

        // ...
    }

    // ...

    // Someplace else in your project
    - (void)foo
    {
        //  ...

        if (error) {
            TLSLogError(TLSLogChannelDefault, @"Encountered an error while performing foo: %@", error);
        } else {
            TLSLogInformation(@"Verbose", @"foo executed flawlessly!");
        }

        // ...
    }
```

## Best Practices

As a best practice follow these simple guidelines:

1) Any user sensitive information should not be logged to output streams that persist messages (including being sent over the network to be saved). You can configure your output stream to filter out logs to these sensitive channels.  Or do the inverse, and only permit certain "safe" channels to be logged.  Twitter has elected to use the pattern where only explicitely "safe" messages (designated via a custom context object) are logged to output streams that will persist. If in doubt, you can log to the `TLSLogLevelDebug` log level, which is only ever logged in `DEBUG` builds.

2) Configure `DEBUG` builds to have a console output like `TLSNSLogOutputStream` or `TLSStdErrOutputStream` - but add only 1 or you'll spam the debug console.

3) Configure `RELEASE` builds to not use the console output stream.

4) Add `Crashlytics` to your project and add a subclass of the `TLSCrashlyticsOutputStream` to `TLSLoggingService` instead of using `CLSLog`, `CLSNSLog` or `CLS_LOG`. You MUST subclass `TLSCrashlyticsOutputStream`.

## TLSLogChannelApplicationDefault function

```
    FOUNDATION_EXTERN NSString *TLSLogChannelApplicationDefault() __attribute__((const));
    #define TLSLogChannelDefault TLSLogChannelApplicationDefault()
```

Retrieve a channel based on the application.  You can use this as a default channel.

Loads and caches the channel name in the following order of descending priority:

1) `kCFBundleNameKey` of main bundle

2) `kCFBundleExecutableKey` of main bundle

3) Binary executable name

4) `@"Default"`

The default channel is available as a convenience for quick logging.  However, it is recommended to always have concrete, well-defined logging channels to which output is logged (e.g. "Networking", "UI", "Model", "Cache", et al).

## TLSLog Helper Functions

There are a number of **TLSLog Helper Functions** and they all accept as a first parameter a `TLSLoggingService`.
If `nil` is provided for the *service* parameter, the shared `[TLSLoggingService sharedInstance]` will be used.
All `TLSLog` macros use `nil` for the *service* parameter, but if there is different instance to be used, these helper functions support that.
As an example, Twitter extends *TwitterLoggingService* with its own set of macros so that a context is provided that defines the duration for which a message can be safely retained (e.g. to avoid retaining sensitive information), and uses custom macros that call these helper functions.

## Gating TLSLog messages

```
    BOOL TLSCanLog(TLSLoggingService *service, TLSLogLevel level, NSString *channel, id contextObject); // gate for logging TLSLog messages
```

At the moment, `TLSCanLog` evaluates two things (*contextObject* is currently ignored): the cached permitted log levels and the cached not permitted log channels.
A log message can log given the desired *level* is permitted by the internal cache of known permitted `TLSLogLevel`s based on the `outputStreams` of `TLSLoggingService`
AND the given log *channel* has not been cached as a known to be an *always off* channel (for `TLSLOGMODE=1` that is, see below for different behaviors).

## TLSCANLOGMODE build setting

*TwitterLoggingService* supports being compiled in one of 3 different modes:

* `TLSCANLOGMODE=0`
* `TLSCanLog` will always return `YES`
* Log arguments always evaluate, which can be inefficient for args that won't log
* `TLSCANLOGMODE=1`
* `TLSCanLog` will base its return value on cached insight into what can and cannot be logged
* This will save on argument evalution at the minimal cost of a quick lookup of cached information
* This is the default if `TLSCANLOGMODE` is not defined
* `TLSCANLOGMODE=2`
* `TLSCanLog` will base its return value on the filtering behavior of all the registered output streams
* This will save on argument evalution but requires an expensive examination of all output streams

# License

Copyright 2013-2018 Twitter, Inc.

Licensed under the Apache License, Version 2.0: https://www.apache.org/licenses/LICENSE-2.0

# Security Issues?

Please report sensitive security issues via Twitter's bug-bounty program (https://hackerone.com/twitter) rather than GitHub.
