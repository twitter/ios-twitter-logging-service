# Twitter Logging Service Change Log

## Info

**Document version:** 2.7.0

**Last updated:** 06/28/2019

**Author:** Nolan O'Brien

## History

### 2.7.0 (06/28/2019)

- Add support for capturing `os_log` logs executed within a running app.
  - __TLSExt__ is provided as the interface and is not a part of __TLS__ proper.  This is because __TLSExt__ makes use of private Apple frameworks and would lead to app store rejection.
  - So, the consumer is responsible to compiling and linking the `TLSExt*.h|m` files themselves and must only do so with non-production builds.
  - This can be of immense help when dogfooding with developers and teammates with an Enterprise distribution (not Test Flight and not production).

### 2.6.0 (06/11/2019)

- Add options to composing a log message string from `TLSLogMessageInfo`
  - `TLSComposeLogMessageInfoOptions` provides options for what components to put in the output `composeFormattedMessageWithOptions:` string

### 2.5.0 (09/13/2016)

- Add options to _TLS_ with `TLSLogMessageOptions`
  - Provides support to explicitely ignore the maximum message length cap
  - Change `maximumSafeMessageLength` to truncate by default instead of discard when message length is too long and there is not delegate

### 2.4.0 (07/28/2016)

- Create `TLSLoggingServiceDelegate` protocol.  Currently delegates the decision of what to do when a log message with an unsafe length is encountered.

### 2.3.0 (06/30/2016)

- Add `os_log` support (iOS 10+ and macOS 10.12+) with `TLSOSLogOutputStream`

### 2.2.1 (05/31/2016)

- Add cap to log message sizes.  Will also fire a notification that can be observed to identify where the message that was too large was logged from.

### 2.2.0   (05/19/2016)

- Remove `TLSFileFunctionLine` struct since it is too easy to make mistakes such as constructing the struct on the stack with stack C-string values then accessing copies of the struct from other threads that should not have references to the stack C-string values. 

### 2.1.1   (05/04/2016)

- Add `threadName` to `TLSLogMessageInfo` for additional context

### 2.1.0   (03/23/2016)

- Refactor coding style/conventions to be better aligned with open source best practices
- Absolute minimal executable code changes

### 2.0.0   (02/25/2016)

- Rename `TFNLogging` to `TwitterLoggingService`

### 1.2.5   (02/03/2016)

- Add Swift support
- Simplify _Crashlytics_ support by delegating responsibility of calling `CLSLog` to the subclass of `TLSCrashlyticsOutputStream`

### 1.2.1   (09/11/2015)

- Optimize log message filtering by moving quick filter checks to a concurrent queue

### 1.2.0   (06/12/2014) - Kirk Beitz

- Made class `TLSFileOutputStream` more abstract as a base + protected implementation
- no longer implements @protocol `TLSDataRetrieval`
- keeps the generic readonly @property 'constants', but makes them @protected
- implements one default initializer taking a logging directory and a file name
- implements one convenience initializer taking a file name and making use of the default logging directory
- makes 'init' NS_UNAVAILABLE
- keeps the public `defaultLogFileDirectory` class method & the `tls_outputLogInfo:` and `tls_flush` methods
- keep the several protected `(void)write` methods
- refactor some portions of `(instancetype)initWithLogFileDirectoryPath:logFilePrefix:maxLogFiles:maxBytesPerLogFile:error:` to new protected `createLogFileDirectoryPath:error:` & `openLogFile:error:`

- Made new protocol `TLSFileOutputStreamEvent` based on methods that had been "abstract" and "overrideable" in the old TLSFileOutputStream
- makes use of the new typedef `TLSFileOutputEvent` for the first argument of all functions

- Made new class `TLSRollingFileOutputStream` as a concrete implementation of `TLSFileOutputStream`
- copied over all of the old initializers from `TLSFileOutputStream`
- copied over from `TLSFileOutputStream` the @property items that were specific to rolling file output stream
- interface creates new NS_ENUM `TLSRollingFileOutputEvent` (based upon `TLSFileOutputEvent` and override-able `fileStreamEvent` methods
- takes over implementation of protocol `TLSDataRetrieval`
- takes over implementation of `fileOutputEventBegan/Finished/Failed` methods via implementation of the @protocol `TLSFileOutputStreamEvent`

### 1.1.0   (04/09/2014)

- Remove `permittedLoggingLevels` and `shouldFilterChannelsThatAreOff` to completely decouple the filtering from the `TLSLoggingService`.  All output streams control their own destiny now.

### 1.0.1   (01/16/2014)

- Expand maximum bytes per log file from 128MB to 1GB.
- Add `flushAfterEveryWriteEnabled` property to `TLSLoggingService`.

### 1.0.0  (01/01/2014)

- Initial production release
