//
//  TLSLoggingTests.m
//  TLSLoggingTests
//
//  Created on 12/11/13.
//  Copyright (c) 2016 Twitter, Inc.
//

#include <pthread.h>

#import <TwitterLoggingService/TwitterLoggingService.h>
#import <XCTest/XCTest.h>

static void LogStream(id<TLSOutputStream> stream, TLSLogLevel level, NSString *channel, NSString *file, NSString *function, unsigned int line, NSString *format, ...);
static NSTimeInterval NSTimeIntervalFromTLSFileOutputStreamTimestamp(NSString *timestamp);
static id GenerateLoggingArgument();
static void TurnConsoleChannelOn(NSString *channel, BOOL on);
static BOOL IsConsoleChannelOn(NSString *channel);

@interface TestLogger : NSObject <TLSOutputStream>
@property (nonatomic) TLSLogLevelMask permittedLoggingLevels;
@property (nonatomic) BOOL shouldFilterChannelsThatAreOff;
@property (nonatomic, readonly) NSUInteger loggedMessages;
- (void)setChannel:(NSString *)channel on:(BOOL)on;
@end

@interface TestStdErrLogger : TLSStdErrOutputStream
@end

@interface TestNSLogLogger : TLSNSLogOutputStream
@end

@interface TestFileLogger : TLSFileOutputStream
@end

@interface TLSLoggingTests : XCTestCase
@end

@interface TestRollingLogger : NSObject <TLSOutputStream>
@property (nonatomic) TLSLogLevelMask permittedLoggingLevels;
@property (nonatomic) BOOL shouldFilterChannelsThatAreOff;
@property (nonatomic, readonly) NSUInteger loggedMessages;
- (void)setChannel:(NSString *)channel on:(BOOL)on;
@end

@interface TestRollingFileLogger : TLSRollingFileOutputStream
@end

@interface TLSRollingFileTests : XCTestCase
@end

typedef void(^TestLoggingBlock)(NSString *channel);
typedef void(^TestStreamBlock)(id<TLSOutputStream> stream, NSString *channel);

static TLSLoggingService *sLoggingService;
static TLSStdErrOutputStream *sStdErrOut;
static TLSNSLogOutputStream *sNSLogOut;
static TLSFileOutputStream *sFileOut;
static TLSRollingFileOutputStream *sRollingFileOut;
static TestLoggingBlock sTestLoggingBlock;
static TestStreamBlock sTestStreamBlock;

static NSMutableSet *sOnConsoleChannels;
static NSMutableDictionary *sRuntimes;

#define TEST_MX_COUNT (3 * TEST_COUNT)

#define TEST_COUNT (250)

#define TEST_START NSDate *__start__ = [NSDate date];

#define TEST_STOP sRuntimes[NSStringFromSelector(_cmd)] = @([[NSDate date] timeIntervalSinceDate:__start__]);

#define TEST_UPDATE_CHANNEL(channel, on) do { [sLoggingService dispatchAsynchronousTransaction:^{ TurnConsoleChannelOn(channel, on); }]; [sLoggingService updateOutputStream:sStdErrOut]; [sLoggingService updateOutputStream:sNSLogOut]; } while (0)

#define TEST_CHANNEL_ON(channel)    TEST_UPDATE_CHANNEL(channel, YES)

#define TEST_CHANNEL_OFF(channel)   TEST_UPDATE_CHANNEL(channel, NO)

#define TEST_FILE_NAME @"TLSFileOutputStreamTest.log"

#define TEST_FLUSH_TRANSACTIONS() [sLoggingService dispatchSynchronousTransaction:^{}]

@implementation TLSLoggingTests

+ (void)setUp
{
    [super setUp];
    sLoggingService = [TLSLoggingService sharedInstance];
    sStdErrOut = [[TestStdErrLogger alloc] init];
    sNSLogOut = [[TestNSLogLogger alloc] init];
    NSString *defaultLogFileDirectoryPath = [TLSFileOutputStream defaultLogFileDirectoryPath];
    [[NSFileManager defaultManager] removeItemAtPath:defaultLogFileDirectoryPath error:NULL];
    sFileOut = [[TestFileLogger alloc] initWithLogFileName:TEST_FILE_NAME error:NULL];
    sRollingFileOut = [[TestRollingFileLogger alloc] initWithLogFileDirectoryPath:defaultLogFileDirectoryPath logFilePrefix:TLSRollingFileOutputStreamDefaultLogFilePrefix maxLogFiles:5 maxBytesPerLogFile:(1024 * 64)];
    sTestLoggingBlock = ^(NSString *theChannel) {
        TLSLogDebug(theChannel, @"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil);
        TLSLogInformation(theChannel, @"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil);
        TLSLogWarning(theChannel, @"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil);
        TLSLogError(theChannel, @"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil);
    };
    sTestStreamBlock = ^(id<TLSOutputStream> stream, NSString *channel) {
        LogStream(stream, TLSLogLevelDebug, channel, @(__FILE__), @(__PRETTY_FUNCTION__), __LINE__, @"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil);
        LogStream(stream, TLSLogLevelInformation, channel, @(__FILE__), @(__PRETTY_FUNCTION__), __LINE__, @"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil);
        LogStream(stream, TLSLogLevelWarning, channel, @(__FILE__), @(__PRETTY_FUNCTION__), __LINE__, @"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil);
        LogStream(stream, TLSLogLevelError, channel, @(__FILE__), @(__PRETTY_FUNCTION__), __LINE__, @"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil);
    };
    sRuntimes = [[NSMutableDictionary alloc] init];
    sOnConsoleChannels = [[NSMutableSet alloc] init];
}

- (void)testLoggingStdErr1
{
    TEST_START
    [sLoggingService addOutputStream:sStdErrOut];

    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-StdErr"];

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_OFF(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_STOP
}

- (void)testLoggingStdErr2
{
    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-StdErr"];
    [sLoggingService removeOutputStream:sStdErrOut];
    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_OFF(channel);

    [sLoggingService flush];
}

- (void)testLoggingStdErr3
{
    TEST_START
    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-StdErrMx"];
    TEST_CHANNEL_ON(channel);
    [sLoggingService addOutputStream:sStdErrOut];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_queue_create("mxQ", DISPATCH_QUEUE_CONCURRENT);

    for (int i = 0; i < TEST_MX_COUNT; i++) {
        dispatch_group_async(group, q, ^() {
            sTestLoggingBlock(channel);
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    TEST_CHANNEL_OFF(channel);
    TEST_STOP

    [sLoggingService flush];
    [sLoggingService removeOutputStream:sStdErrOut];
}

- (void)testLoggingNSLog1
{
    TEST_START
    [sLoggingService addOutputStream:sNSLogOut];

    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-NSLog"];

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_OFF(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_STOP
}

- (void)testLoggingNSLog2
{
    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-NSLog"];
    [sLoggingService removeOutputStream:sNSLogOut];
    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    };

    TEST_CHANNEL_OFF(channel);

    [sLoggingService flush];
}

- (void)testLoggingNSLog3
{
    TEST_START
    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-NSLogMx"];
    TEST_CHANNEL_ON(channel);
    [sLoggingService addOutputStream:sNSLogOut];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_queue_create("mxQ", DISPATCH_QUEUE_CONCURRENT);

    for (int i = 0; i < TEST_MX_COUNT; i++) {
        dispatch_group_async(group, q, ^() {
            sTestLoggingBlock(channel);
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    TEST_CHANNEL_OFF(channel);
    TEST_STOP

    [sLoggingService flush];
    [sLoggingService removeOutputStream:sNSLogOut];
}

- (void)testStdErr1
{
    TEST_START
    (void)TLSLogChannelDefault;
    NSString *channel = @"StdErr";

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestStreamBlock(sStdErrOut, channel);
    }

    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestStreamBlock(sStdErrOut, channel);
    }

    TEST_CHANNEL_OFF(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestStreamBlock(sStdErrOut, channel);
    }

    TEST_STOP

    [sStdErrOut tls_flush];
}

- (void)testStdErr2
{
    TEST_START
    NSString *channel = @"StdErrMx";

    TEST_CHANNEL_ON(channel);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_queue_create("mxQ", DISPATCH_QUEUE_CONCURRENT);

    for (int i = 0; i < TEST_MX_COUNT; i++) {
        dispatch_group_async(group, q, ^() {
            sTestStreamBlock(sStdErrOut, channel);
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    TEST_CHANNEL_OFF(channel);
    TEST_STOP
}

- (void)testNSLog1
{
    TEST_START
    (void)TLSLogChannelDefault;
    NSString *channel = @"NSLog";

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestStreamBlock(sNSLogOut, channel);
    }

    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestStreamBlock(sNSLogOut, channel);
    }

    TEST_CHANNEL_OFF(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestStreamBlock(sNSLogOut, channel);
    }

    TEST_STOP
}

- (void)testNSLog2
{
    TEST_START
    NSString *channel = @"NSLogMx";

    TEST_CHANNEL_ON(channel);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_queue_create("mxQ", DISPATCH_QUEUE_CONCURRENT);

    for (int i = 0; i < TEST_MX_COUNT; i++) {
        dispatch_group_async(group, q, ^() {
            sTestStreamBlock(sNSLogOut, channel);
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    TEST_CHANNEL_OFF(channel);
    TEST_STOP
}

- (void)testLoggingFile1
{
    TEST_START
    [sLoggingService addOutputStream:sFileOut];

    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-File"];

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_OFF(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_STOP
}

- (void)testLoggingFile2
{
    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-File"];
    [sLoggingService removeOutputStream:sFileOut];
    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_OFF(channel);

    [sLoggingService flush];
}

- (void)testLoggingFile3
{
    TEST_START
    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-FileMx"];
    TEST_CHANNEL_ON(channel);
    [sLoggingService addOutputStream:sFileOut];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_queue_create("mxQ", DISPATCH_QUEUE_CONCURRENT);

    for (int i = 0; i < TEST_MX_COUNT; i++) {
        dispatch_group_async(group, q, ^() {
            sTestLoggingBlock(channel);
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    TEST_CHANNEL_OFF(channel);
    TEST_STOP

    [sLoggingService flush];
    [sLoggingService removeOutputStream:sFileOut];
}

- (void)testLoggingFile4
{
    // Test Logging File Creation
#if TARGET_IPHONE_SIMULATOR
    NSString *restrictedDir = @"/bin";
#else
    NSString *restrictedDir = @"/";
#endif

    NSError *error = nil;
    TLSFileOutputStream *stream = [[TLSFileOutputStream alloc] initWithLogFileDirectoryPath:restrictedDir logFileName:@"restricted.log" error:&error];
    XCTAssertNil(stream, @"'%@' directory should always result in an empty stream representing the failure to create a %@ stream! Your machine might have write permissions on '%@', which it shouldn't.", restrictedDir, NSStringFromClass([stream class]), restrictedDir);
    XCTAssertNotNil(error, @"'%@' directory should always result in an error describing the failure to create a %@ stream! Your machine might have write permissions on '%@', which it shouldn't.", restrictedDir, NSStringFromClass([stream class]), restrictedDir);
    error = nil;

    stream = [[TLSFileOutputStream alloc] initWithLogFileName:TEST_FILE_NAME error:&error];
    XCTAssertNil(error, @"TLSFileOutputStream should have succeeded");
    XCTAssertNotEqual(NULL, stream.logFile, @"TLSLoggingFileOuptutStream.logFile should not be NULL");
    XCTAssert([[[TLSFileOutputStream defaultLogFileDirectoryPath] stringByAppendingPathComponent:TEST_FILE_NAME] isEqualToString:stream.logFilePath], @"TLSFileOutputStream.tls_loggedDataEncoding should have been NSUTF8StringEncoding");
    XCTAssertEqual(NSUTF8StringEncoding, stream.tls_loggedDataEncoding, @"TLSFileOutputStream.tls_loggedDataEncoding should have been NSUTF8StringEncoding");

    NSString *data = @"TLSFileOutputStream data";
    [stream outputLogData:[data dataUsingEncoding:stream.tls_loggedDataEncoding]];
    XCTAssertEqual(data.length+1, stream.bytesWritten, @"TLSFileOutputStream bytes written should equal %tu", data.length);
}

- (void)testLoggingFile5
{
    NSArray *levels = @[ TLSLogLevelToString(TLSLogLevelError), TLSLogLevelToString(TLSLogLevelWarning), TLSLogLevelToString(TLSLogLevelInformation), TLSLogLevelToString(TLSLogLevelDebug) ];

    XCTAssertFalse([sFileOut conformsToProtocol:@protocol(TLSDataRetrieval)], @"baseline FileOutputStream should not conform to TLSDataRetrieval");

    // Validate on disk logs
    @autoreleasepool {
        NSString *string = [[NSString alloc] initWithContentsOfFile:sFileOut.logFilePath encoding:sFileOut.tls_loggedDataEncoding error:NULL];
        XCTAssertNotNil(string, @"reading log file must result in non-nil string");
        NSArray *lines = [string componentsSeparatedByString:@"\n"];
        XCTAssertTrue(lines.count > 0, @"each log file must have at least 1 line");
        for (NSString *line in lines) {
            NSMutableArray *tokens = [[line componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] mutableCopy];
            [tokens removeObjectsAtIndexes:[tokens indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [(NSString *)obj length] == 0;
            }]];
            if (tokens.count >= 5) {
                NSTimeInterval ti = NSTimeIntervalFromTLSFileOutputStreamTimestamp(tokens[0]);
                if (ti > 0.0f) {
                    XCTAssertTrue([levels containsObject:tokens[3]], @"Log level must be Error, Warning, Information or Debug");
                    XCTAssertTrue([tokens[2] hasPrefix:TLSLogChannelDefault], @"Logging channel is wrong");
                }
            }
        }
    }
}

- (void)testLoggingFile6
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *logFileDirectoryPath = [TLSFileOutputStream defaultLogFileDirectoryPath];
    NSArray *logFiles = [fm contentsOfDirectoryAtPath:logFileDirectoryPath error:NULL];
    NSString *logFileOfInterest = logFiles[[logFiles indexOfObject:TEST_FILE_NAME]];

    unsigned long long bytes = [fm attributesOfItemAtPath:[logFileDirectoryPath stringByAppendingPathComponent:logFileOfInterest] error:NULL].fileSize;
    unsigned long long expectedBytes = [NSString stringWithFormat:@"%@ data\n", NSStringFromClass([TLSFileOutputStream class])].length;
    XCTAssertEqual(bytes, expectedBytes, @"file size doesn't match expectations");
}

- (void)testLoggingFileNSLogCombo
{
    TEST_START
    [sLoggingService addOutputStream:sNSLogOut];
    [sLoggingService addOutputStream:sFileOut];

    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-ComboMx"];
    TEST_CHANNEL_ON(channel);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_queue_create("mxQ", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < TEST_MX_COUNT; i++) {
        dispatch_group_async(group, q, ^() {
            sTestLoggingBlock(channel);
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    TEST_CHANNEL_OFF(channel);
    TEST_STOP

    [sLoggingService flush];
    for (id<TLSOutputStream> stream in sLoggingService.outputStreams) {
        [sLoggingService removeOutputStream:stream];
    }
}

- (void)testLoggingRollingFile1
{
    TEST_START
    [sLoggingService addOutputStream:sFileOut];

    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-File"];

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_OFF(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_STOP
}

- (void)testLoggingRollingFile2
{
    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-File"];
    [sLoggingService removeOutputStream:sRollingFileOut];
    TEST_CHANNEL_ON(channel);

    for (int i = 0; i < TEST_COUNT; i++) {
        sTestLoggingBlock(channel);
    }

    TEST_CHANNEL_OFF(channel);

    [sLoggingService flush];
}

- (void)testLoggingRollingFile3
{
    TEST_START
    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-FileMx"];
    TEST_CHANNEL_ON(channel);
    [sLoggingService addOutputStream:sRollingFileOut];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_queue_create("mxQ", DISPATCH_QUEUE_CONCURRENT);

    for (int i = 0; i < TEST_MX_COUNT; i++) {
        dispatch_group_async(group, q, ^() {
            sTestLoggingBlock(channel);
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    TEST_CHANNEL_OFF(channel);
    TEST_STOP

    [sLoggingService flush];
}

- (void)testLoggingRollingFile4
{
    // Test Logging File Creation
#if TARGET_IPHONE_SIMULATOR
    NSString *restrictedDir = @"/bin";
#else
    NSString *restrictedDir = @"/";
#endif

    NSError *error = nil;
    TLSRollingFileOutputStream *stream = [[TLSRollingFileOutputStream alloc] initWithLogFileDirectoryPath:restrictedDir logFilePrefix:@"log." maxLogFiles:5 maxBytesPerLogFile:1024 error:&error];
    XCTAssertNil(stream, @"'%@' directory should always result in a failure to create a %@ stream! Your machine might have write permissions on '%@', which it shouldn't.", restrictedDir, NSStringFromClass([stream class]), restrictedDir);
    XCTAssertNotNil(error, @"'%@' directory should always result in a failure to create a %@ stream! Your machine might have write permissions on '%@', which it shouldn't.", restrictedDir, NSStringFromClass([stream class]), restrictedDir);
    error = nil;

    NSString *path = [[TLSRollingFileOutputStream defaultLogFileDirectoryPath] stringByAppendingPathComponent:@"TLSLogging"];
    NSString *prefix = @"twp.";
    NSUInteger maxBytesPerLogFile = 256 * 1024;
    NSUInteger maxLogFiles = 10;

    stream = [[TLSRollingFileOutputStream alloc] initWithLogFileDirectoryPath:path logFilePrefix:prefix maxLogFiles:maxLogFiles maxBytesPerLogFile:maxBytesPerLogFile error:&error];
    XCTAssertNil(error, @"TLSRollingFileOutputStream should have succeeded");
    XCTAssertEqual(maxBytesPerLogFile, stream.maxBytesPerLogFile, @"maxBytesPerLogFile differs!");
    XCTAssertEqual(maxLogFiles, stream.maxLogFiles, @"maxLogFiles differs!");
    XCTAssertEqualObjects(path, stream.logFileDirectoryPath, @"logFileDirectoryPath differs!");
    XCTAssertEqualObjects(prefix, stream.logFilePrefix, @"logFilePrefix differs!");

    NSUInteger maxBytesPerLogFileModified = (NSUInteger)(1024ULL * 1024ULL * 1024ULL); // capped value (1GB)
    maxBytesPerLogFile = (NSUInteger)((unsigned long long)maxBytesPerLogFileModified * 2ULL);
    maxLogFiles = 100;
    NSUInteger maxLogFilesModified = (NSUInteger)((4ULL * 1024ULL * 1024ULL * 1024ULL) / (unsigned long long)maxBytesPerLogFileModified); // capped value
    stream = [[TLSRollingFileOutputStream alloc] initWithLogFileDirectoryPath:path logFilePrefix:prefix maxLogFiles:maxLogFiles maxBytesPerLogFile:maxBytesPerLogFile error:&error];
    XCTAssertNil(error, @"TLSRollingFileOutputStream should have succeeded");
    XCTAssertNotEqual(maxBytesPerLogFile, stream.maxBytesPerLogFile, @"maxBytesPerLogFile should have been capped!");
    XCTAssertEqual(maxBytesPerLogFileModified, stream.maxBytesPerLogFile, @"maxBytesPerLogFile differs!");
    XCTAssertNotEqual(maxLogFiles, stream.maxLogFiles, @"maxLogFiles should have been capped!");
    XCTAssertEqual(maxLogFilesModified, stream.maxLogFiles, @"maxLogFiles differ!");

    maxBytesPerLogFile = 0; // 256MB
    maxBytesPerLogFileModified = 1024; // min value
    maxLogFiles = 0;
    maxLogFilesModified = 1; // min value
    stream = [[TLSRollingFileOutputStream alloc] initWithLogFileDirectoryPath:path logFilePrefix:prefix maxLogFiles:maxLogFiles maxBytesPerLogFile:maxBytesPerLogFile error:&error];
    XCTAssertNil(error, @"TLSRollingFileOutputStream should have succeeded");
    XCTAssertNotEqual(maxBytesPerLogFile, stream.maxBytesPerLogFile, @"maxBytesPerLogFile should have been capped!");
    XCTAssertEqual(maxBytesPerLogFileModified, stream.maxBytesPerLogFile, @"maxBytesPerLogFile differs!");
    XCTAssertNotEqual(maxLogFiles, stream.maxLogFiles, @"maxLogFiles should have been capped!");
    XCTAssertEqual(maxLogFilesModified, stream.maxLogFiles, @"maxLogFiles differ!");
}

- (void)testLoggingRollingFile5
{
    NSArray *levels = @[ TLSLogLevelToString(TLSLogLevelError), TLSLogLevelToString(TLSLogLevelWarning), TLSLogLevelToString(TLSLogLevelInformation), TLSLogLevelToString(TLSLogLevelDebug) ];

    @autoreleasepool {
        // Validate received data
        NSData *newlineData = [NSData dataWithBytes:"\n" length:1];
        NSData *data = [sLoggingService retrieveLoggedDataFromOutputStream:sRollingFileOut maxBytes:0];
        NSUInteger dataLength1 = data.length;
        XCTAssertTrue(data.length <= (sRollingFileOut.maxBytesPerLogFile * 2), @"Logs were not rolled over at the right time!");
        NSRange r;
        r.length = [data rangeOfData:newlineData options:NSDataSearchBackwards range:NSMakeRange(0, dataLength1 / 2)].location;
        r.location = [data rangeOfData:newlineData options:NSDataSearchBackwards range:NSMakeRange(0, r.length - 2)].location + 1;
        r.length -= r.location;
        NSString *exampleNewer = [[NSString alloc] initWithData:[data subdataWithRange:r] encoding:sRollingFileOut.tls_loggedDataEncoding];
        data = [sLoggingService retrieveLoggedDataFromOutputStream:sRollingFileOut maxBytes:sRollingFileOut.maxBytesPerLogFile + (2 * dataLength1)];
        NSUInteger dataLength2 = data.length;
        XCTAssertTrue(data.length <= (sRollingFileOut.maxBytesPerLogFile * 3), @"Logs were not rolled over at the right time!");
        r.location = 0;
        r.length = dataLength2 - dataLength1;
        data = [data subdataWithRange:r];
        XCTAssertTrue(data.length == dataLength2 - dataLength1, @"Didn't create subset of data correctly");
        XCTAssertTrue(data.length <= (sRollingFileOut.maxBytesPerLogFile * 2), @"Logs were not rolled over at the right time!");
        r.length = [data rangeOfData:newlineData options:NSDataSearchBackwards range:NSMakeRange(0, dataLength1 / 2)].location;
        r.location = [data rangeOfData:newlineData options:NSDataSearchBackwards range:NSMakeRange(0, r.length - 2)].location + 1;
        r.length -= r.location;
        NSString *exampleOlder = [[NSString alloc] initWithData:[data subdataWithRange:r] encoding:sRollingFileOut.tls_loggedDataEncoding];
        XCTAssertNotEqualObjects(exampleNewer, exampleOlder, @"Log lines should differ between files");
        NSMutableArray *tokensOlder = [[exampleOlder componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] mutableCopy];
        NSMutableArray *tokensNewer = [[exampleNewer componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] mutableCopy];
        [tokensOlder removeObjectsAtIndexes:[tokensOlder indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [(NSString *)obj length] == 0;
        }]];
        [tokensNewer removeObjectsAtIndexes:[tokensNewer indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [(NSString *)obj length] == 0;
        }]];
        XCTAssertNotEqualObjects(tokensOlder, tokensNewer, @"Log lines should differ between files");
        XCTAssertTrue(tokensOlder.count >= 5, @"Must have at minimum: timestamp, threadId, channel, level and message in log entries");
        XCTAssertTrue(tokensNewer.count >= 5, @"Must have at minimum: timestamp, threadId, channel, level and message in log entries");
        XCTAssertTrue([levels containsObject:tokensNewer[3]], @"Log level must be Error, Warning, Information or Debug");
        XCTAssertTrue([levels containsObject:tokensOlder[3]], @"Log level must be Error, Warning, Information or Debug");
        XCTAssertTrue([tokensNewer[2] hasPrefix:TLSLogChannelDefault], @"Logging channel is wrong");
        XCTAssertTrue([tokensOlder[2] hasPrefix:TLSLogChannelDefault], @"Logging channel is wrong");
        NSTimeInterval tiOlder = NSTimeIntervalFromTLSFileOutputStreamTimestamp(tokensOlder[0]);
        NSTimeInterval tiNewer = NSTimeIntervalFromTLSFileOutputStreamTimestamp(tokensNewer[0]);
        XCTAssertTrue(tiOlder > 0.0f, @"Invalid timestamp");
        XCTAssertTrue(tiNewer > 0.0f, @"Invalid timestamp");
        if ([tokensNewer[1] isEqualToString:tokensOlder[1]]) {
            XCTAssertTrue(tiNewer >= tiOlder, @"Newer timestamp must be greater than older timestamp");
        } else if (tiOlder > tiNewer) {
            XCTAssertTrue(tiNewer >= tiOlder + 0.1, @"Newer timestamp must be greater than older timestamp: %@ then %@", tokensOlder[0], tokensNewer[0]);
        }
    }

    // Validate on disk logs
    NSMutableArray *logs = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:sRollingFileOut.logFileDirectoryPath error:NULL] mutableCopy];
    [logs removeObjectsAtIndexes:[logs indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ![[(NSString *)obj lastPathComponent] hasPrefix:sRollingFileOut.logFilePrefix];
    }]];
    XCTAssertTrue(logs.count == sRollingFileOut.maxLogFiles, @"Logs must have rolled over and been pruned!");
    [logs sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *path1 = obj1;
        NSString *path2 = obj2;
        return [path1 compare:path2];
    }];

    NSTimeInterval lastTimestamp = 0;
    __strong NSString *lastLog = nil;
    for (__strong NSString *path in logs) {
        @autoreleasepool {
            path = [sRollingFileOut.logFileDirectoryPath stringByAppendingPathComponent:path];
            NSString *string = [[NSString alloc] initWithContentsOfFile:path encoding:sRollingFileOut.tls_loggedDataEncoding error:NULL];
            XCTAssertNotNil(string, @"reading log file must result in nil string");
            NSArray *lines = [string componentsSeparatedByString:@"\n"];
            string = nil;
            XCTAssertTrue(lines.count > 0, @"each log file must have at least 1 line");
            for (NSString *line in lines) {
                NSMutableArray *tokens = [[line componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] mutableCopy];
                [tokens removeObjectsAtIndexes:[tokens indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    return [(NSString *)obj length] == 0;
                }]];
                if (tokens.count >= 5) {
                    NSTimeInterval ti = NSTimeIntervalFromTLSFileOutputStreamTimestamp(tokens[0]);
                    if (ti > 0.0) {
                        XCTAssertTrue([levels containsObject:tokens[3]], @"Log level must be Error, Warning, Information or Debug");
                        XCTAssertTrue([tokens[2] hasPrefix:TLSLogChannelDefault], @"Logging channel is wrong");
                        if (ti < lastTimestamp) {
                            static unsigned long inversion = 0;
                            inversion++;
                            NSLog(@"Timestamps out of order %lu times", inversion);
                        }
                        lastTimestamp = ti;
                        lastLog = line;
                    }
                }
            }
        }
    }
}

- (void)testLoggingRollingFile6
{
    unsigned long long bytes = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *logFiles = [fm contentsOfDirectoryAtPath:sRollingFileOut.logFileDirectoryPath error:NULL];
    XCTAssert(logFiles, @"directory containing log files should exist");
    for (NSString *item in logFiles) {
        if ([item hasPrefix:sRollingFileOut.logFilePrefix]) {
            bytes += [fm attributesOfItemAtPath:[sRollingFileOut.logFileDirectoryPath stringByAppendingPathComponent:item] error:NULL].fileSize;
        }
    }
    NSData *logs = [sLoggingService retrieveLoggedDataFromOutputStream:sRollingFileOut maxBytes:NSUIntegerMax];
    XCTAssertTrue(bytes <= logs.length + 128 && bytes >= logs.length - 128, @"retrieved logged data doesn't match expectations");
    logs = nil;
    logs = [sLoggingService retrieveLoggedDataFromOutputStream:sRollingFileOut maxBytes:0];
    XCTAssertTrue(logs.length > 0, @"the minimum bytes you can cap is the maximum bytes per files, not 0");
}

- (void)testLoggingRollingNSLogCombo
{
    TEST_START
    [sLoggingService addOutputStream:sNSLogOut];
    [sLoggingService addOutputStream:sRollingFileOut];

    NSString *channel = [TLSLogChannelDefault stringByAppendingString:@"-ComboMx"];
    TEST_CHANNEL_ON(channel);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_queue_create("mxQ", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < TEST_MX_COUNT; i++) {
        dispatch_group_async(group, q, ^() {
            sTestLoggingBlock(channel);
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    TEST_CHANNEL_OFF(channel);
    TEST_STOP

    [sLoggingService flush];
    for (id<TLSOutputStream> stream in sLoggingService.outputStreams) {
        [sLoggingService removeOutputStream:stream];
    }
}

- (void)testZZLoggingSpeedVerification
{
    XCTAssertTrue(sFileOut != nil, @"TLSFileOutputStream must have successfully been created!");
    XCTAssertTrue(sRollingFileOut != nil, @"TLSRollingFileOutputStream must have successfully been created!");
    NSString *loggingPrefix = @"testLogging";
    NSString *nonLoggingPrefix = @"test";
    for (NSString *key in sRuntimes.allKeys) {
        if ([key hasPrefix:loggingPrefix]) {
            NSString *otherKey = [key stringByReplacingOccurrencesOfString:loggingPrefix withString:nonLoggingPrefix];
            if (sRuntimes[otherKey]) {
                double loggingTime = [sRuntimes[key] doubleValue];
                double nonLoggingTime = [sRuntimes[otherKey] doubleValue];

                double improvement = ((loggingTime < nonLoggingTime) ? ((nonLoggingTime - loggingTime) / loggingTime) : (((loggingTime - nonLoggingTime) / nonLoggingTime) * -1.0f)) * 100;
                NSLog(@"%f%% speed boost going from %@ (%f s) to %@ (%f s)", improvement, otherKey, nonLoggingTime, key, loggingTime);

// TODO: re-enable the following line when a the infrastructure has been added to disable occasionally flaky tests in CI
//                XCTAssertTrue(loggingTime < (nonLoggingTime * 2.0), @"%@ must perform as well as %@", key, otherKey);
            }
        }
    }
    XCTAssertTrue([[NSFileManager defaultManager] contentsOfDirectoryAtPath:[TLSFileOutputStream defaultLogFileDirectoryPath] error:NULL].count > 0, @"Must have logged something to log file directory");
    NSLog(@"Logs files: %@", [TLSFileOutputStream defaultLogFileDirectoryPath]);

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:[TLSFileOutputStream defaultLogFileDirectoryPath] error:NULL];
}

- (void)testZZZCustomLogger
{
#if DEBUG
    const NSUInteger kNumberOfLevelsSupported = 4;
#else
    const NSUInteger kNumberOfLevelsSupported = 3;
#endif

#define TEST_CUSTOM \
    do { \
        XCTAssertTrue(testLogger.loggedMessages == expectedLoggedMessages, @"Should have logged %tu messages not %tu", expectedLoggedMessages, testLogger.loggedMessages); \
        XCTAssertTrue(dispatchedLogMessages == expectedDispatchedMessages, @"Should have dispatched %tu messages not %tu", expectedDispatchedMessages, dispatchedLogMessages); \
        expectedLoggedMessages = testLogger.loggedMessages; \
        expectedDispatchedMessages = dispatchedLogMessages; \
    } while (0)

    __block NSUInteger dispatchedLogMessages = 0;
    TestLoggingBlock block = ^(NSString *theChannel) {
        if (TLSCanLog(nil, TLSLogLevelDebug, theChannel, NULL)) {
            dispatchedLogMessages++;
            [sLoggingService logWithLevel:TLSLogLevelDebug channel:theChannel file:@(__FILE__) function:@(__PRETTY_FUNCTION__) line:__LINE__ contextObject:NULL options:0 message:@"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil];
            [sLoggingService flush];
        }
        if (TLSCanLog(nil, TLSLogLevelInformation, theChannel, NULL)) {
            dispatchedLogMessages++;
            [sLoggingService logWithLevel:TLSLogLevelInformation channel:theChannel file:@(__FILE__) function:@(__PRETTY_FUNCTION__) line:__LINE__ contextObject:NULL options:0 message:@"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil];
            [sLoggingService flush];
        }
        if (TLSCanLog(nil, TLSLogLevelWarning, theChannel, NULL)) {
            dispatchedLogMessages++;
            [sLoggingService logWithLevel:TLSLogLevelWarning channel:theChannel file:@(__FILE__) function:@(__PRETTY_FUNCTION__) line:__LINE__ contextObject:NULL options:0 message:@"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil];
            [sLoggingService flush];
        }
        if (TLSCanLog(nil, TLSLogLevelError, theChannel, NULL)) {
            dispatchedLogMessages++;
            [sLoggingService logWithLevel:TLSLogLevelError channel:theChannel file:@(__FILE__) function:@(__PRETTY_FUNCTION__) line:__LINE__ contextObject:NULL options:0 message:@"%d %@ %f %@ %@", 1, @2, 3.0f, GenerateLoggingArgument(), nil];
            [sLoggingService flush];
        }
    };
#define TEST_FILTER(channel) block(channel)

    NSUInteger expectedLoggedMessages = 0;
    NSUInteger expectedDispatchedMessages = 0;
    NSString *defaultChannel = [TLSLogChannelDefault stringByAppendingString:@"-Custom"];
    TestLogger *testLogger = [[TestLogger alloc] init];

    [sLoggingService addOutputStream:testLogger];
    TEST_FLUSH_TRANSACTIONS();
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 1; // first log message would have been dispatched to cache the channel as off
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 0; // channel is cached as off
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    TEST_CHANNEL_ON(defaultChannel);
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 0;
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    [sLoggingService updateOutputStream:testLogger];
    TEST_FLUSH_TRANSACTIONS();
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += kNumberOfLevelsSupported;
    expectedLoggedMessages += kNumberOfLevelsSupported;
    TEST_CUSTOM;
    [sLoggingService removeOutputStream:testLogger];
    TEST_FLUSH_TRANSACTIONS();
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 0;
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    [sLoggingService addOutputStream:[[TLSNSLogOutputStream alloc] init]];
    TEST_FLUSH_TRANSACTIONS();
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += kNumberOfLevelsSupported;
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    [sLoggingService removeOutputStream:sLoggingService.outputStreams.anyObject];
    TEST_FLUSH_TRANSACTIONS();
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 0;
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    [sLoggingService addOutputStream:testLogger];
    TEST_FLUSH_TRANSACTIONS();
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += kNumberOfLevelsSupported;
    expectedLoggedMessages += kNumberOfLevelsSupported;
    TEST_CUSTOM;

    // updated log level changes
    testLogger.permittedLoggingLevels = TLSLogLevelMaskInformation;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += kNumberOfLevelsSupported;
    expectedLoggedMessages += 1;
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 1;
    expectedLoggedMessages += 1;
    TEST_CUSTOM;
    [sLoggingService updateOutputStream:testLogger];
    TEST_FLUSH_TRANSACTIONS();
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += kNumberOfLevelsSupported;
    expectedLoggedMessages += 1;
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 1;
    expectedLoggedMessages += 1;
    TEST_CUSTOM;
    testLogger.permittedLoggingLevels = TLSLogLevelMaskAll;
    [sLoggingService updateOutputStream:testLogger];
    TEST_FLUSH_TRANSACTIONS();
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += kNumberOfLevelsSupported;
    expectedLoggedMessages += kNumberOfLevelsSupported;
    TEST_CUSTOM;

    // update channel filtering
    TEST_CHANNEL_OFF(defaultChannel); // resets cache
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 1; // first log message would have been dispatched to cache the channel as off
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 0; // cached as off
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    testLogger.shouldFilterChannelsThatAreOff = NO; // cache not updated
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 0;
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    [sLoggingService updateOutputStream:testLogger]; // cache reset
    TEST_FLUSH_TRANSACTIONS();
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += kNumberOfLevelsSupported;
    expectedLoggedMessages += kNumberOfLevelsSupported;
    TEST_CUSTOM;
    TEST_CHANNEL_ON(defaultChannel);
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += kNumberOfLevelsSupported;
    expectedLoggedMessages += kNumberOfLevelsSupported;
    TEST_CUSTOM;

    // update stream specific channel filter
    [testLogger setChannel:defaultChannel on:NO]; // doesn't update cache
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 1; // first log message will cache
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 0;
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    [testLogger setChannel:defaultChannel on:YES]; // doesn't update cache
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += 0;
    expectedLoggedMessages += 0;
    TEST_CUSTOM;
    [sLoggingService updateOutputStream:testLogger]; // resets cache
    TEST_FLUSH_TRANSACTIONS();
    TEST_FILTER(defaultChannel);
    expectedDispatchedMessages += kNumberOfLevelsSupported;
    expectedLoggedMessages += kNumberOfLevelsSupported;
    TEST_CUSTOM;

    [sLoggingService removeOutputStream:testLogger];
}

@end

@implementation TestLogger
{
    NSMutableSet *_channelsToFilter;
}

- (void)setPermittedLoggingLevels:(TLSLogLevelMask)permittedLoggingLevels
{
    if (_permittedLoggingLevels != permittedLoggingLevels) {
        _permittedLoggingLevels = permittedLoggingLevels;
    }
}

- (void)setShouldFilterChannelsThatAreOff:(BOOL)filterChannels
{
    if (_shouldFilterChannelsThatAreOff != filterChannels) {
        _shouldFilterChannelsThatAreOff = filterChannels;
    }
}

- (TLSFilterStatus)tls_shouldFilterLevel:(TLSLogLevel)level channel:(NSString *)channel contextObject:(id)contextObject
{
    if (0 == (_permittedLoggingLevels & (1 << level))) {
        return TLSFilterStatusCannotLogLevel;
    }

    if (_shouldFilterChannelsThatAreOff && !IsConsoleChannelOn(channel)) {
        return TLSFilterStatusCannotLogChannel;
    }

    if ([_channelsToFilter containsObject:channel]) {
        return TLSFilterStatusCannotLogChannel;
    }

    return TLSFilterStatusOK;
}

- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo
{
    _loggedMessages++;
}

- (void)setChannel:(NSString *)channel on:(BOOL)on
{
    if (on) {
        [_channelsToFilter removeObject:channel];
    } else {
        [_channelsToFilter addObject:channel];
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        _shouldFilterChannelsThatAreOff = YES;
        _permittedLoggingLevels = TLSLogLevelMaskAll;
        _channelsToFilter = [NSMutableSet set];
    }
    return self;
}

@end

@implementation TestStdErrLogger

- (TLSFilterStatus)tls_shouldFilterLevel:(TLSLogLevel)level channel:(NSString *)channel contextObject:(id)contextObject
{
    if (!IsConsoleChannelOn(channel)) {
        return TLSFilterStatusCannotLogChannel;
    }
    return TLSFilterStatusOK;
}

@end

@implementation TestNSLogLogger

- (TLSFilterStatus)tls_shouldFilterLevel:(TLSLogLevel)level channel:(NSString *)channel contextObject:(id)contextObject
{
    if (!IsConsoleChannelOn(channel)) {
        return TLSFilterStatusCannotLogChannel;
    }
    return TLSFilterStatusOK;
}

@end

@implementation TestFileLogger
@end

@implementation TestRollingFileLogger
@end

static void LogStream(id<TLSOutputStream> stream, TLSLogLevel level, NSString *channel, NSString *file, NSString *function, unsigned int line, NSString *format, ...)
{
    NSDate *timestamp = [NSDate date];
    va_list list;
    va_start(list, format);
    TLSLogMessageInfo *info = [[TLSLogMessageInfo alloc] initWithLevel:level
                                                                  file:file
                                                              function:function
                                                                  line:line
                                                               channel:channel
                                                             timestamp:timestamp
                                                           logLifespan:[timestamp timeIntervalSinceDate:[[TLSLoggingService sharedInstance] startupTimestamp]]
                                                              threadId:pthread_mach_thread_np(pthread_self())
                                                            threadName:TLSCurrentThreadName()
                                                         contextObject:nil
                                                               message:[[NSString alloc] initWithFormat:format arguments:list]];
    va_end(list);
    __block BOOL isChannelOn = NO;
    [[TLSLoggingService sharedInstance] dispatchSynchronousTransaction:^{
        isChannelOn = IsConsoleChannelOn(channel);
    }];
    if (isChannelOn) {
        [stream tls_outputLogInfo:info];
    }
}

static NSTimeInterval NSTimeIntervalFromTLSFileOutputStreamTimestamp(NSString *timestamp)
{
    NSMutableArray *timestampElements = [[timestamp componentsSeparatedByString:@":"] mutableCopy];
    if (!timestampElements) {
        timestampElements = [NSMutableArray array];
    }
    while (timestampElements.count < 4) {
        [timestampElements insertObject:@"0" atIndex:0];
    }
    NSTimeInterval ti = 0;
    ti += [timestampElements[0] integerValue] * 60 * 60;
    ti += [timestampElements[1] integerValue] * 60;
    ti += [timestampElements[2] integerValue];
    ti += ((double)[timestampElements[3] integerValue]) / 1000.0f;
    return ti;
}

static id GenerateLoggingArgument()
{
    // [NSThread sleepForTimeInterval:0.004]; // <- uncomment this to enable slow arguments in the test
    return [NSDate date];
}

static void TurnConsoleChannelOn(NSString *channel, BOOL on)
{
    if (on) {
        [sOnConsoleChannels addObject:channel];
    } else {
        [sOnConsoleChannels removeObject:channel];
    }
}

static BOOL IsConsoleChannelOn(NSString *channel)
{
    return [sOnConsoleChannels containsObject:channel];
}
