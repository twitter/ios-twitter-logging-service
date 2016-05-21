//
//  TLSLoggingSwiftTests.swift
//  TwitterLoggingService
//
//  Created on 2/4/16.
//  Copyright (c) 2016 Twitter, Inc.
//

import TwitterLoggingService
import XCTest

let TLSLoggingSwiftTestOutputStreamNotification = "TLSLoggingSwiftTestOutputStreamNotification"

class TLSLoggingSwiftTestOutputStream : NSObject, TLSOutputStream
{
    func tls_outputLogInfo(logInfo: TLSLogMessageInfo)
    {
        dispatch_async(dispatch_get_main_queue(), {
            print(logInfo.composeFormattedMessage())
            NSNotificationCenter.defaultCenter().postNotificationName(TLSLoggingSwiftTestOutputStreamNotification, object: logInfo)
        })
    }
}

class TLSLoggingSwiftTestMessageInfo : TLSLogMessageInfo
{
    var didGetLevel: Bool = false
    override var level: TLSLogLevel {
        get {
            didGetLevel = true
            return super.level
        }
    }
    var didGetFile: Bool = false
    override var file: String {
        get {
            didGetFile = true
            return super.file
        }
    }
    var didGetFunction: Bool = false
    override var function: String {
        get {
            didGetFunction = true
            return super.function
        }
    }
    var didGetLine: Bool = false
    override var line: UInt32 {
        get {
            didGetLine = true
            return super.line
        }
    }
    var didGetChannel: Bool = false
    override var channel: String {
        get {
            didGetChannel = true
            return super.channel
        }
    }
    var didGetContextObject: Bool = false
    override var contextObject: AnyObject? {
        get {
            didGetContextObject = true
            return super.contextObject
        }
    }
    var didGetTimestamp: Bool = false
    override var timestamp: NSDate {
        get {
            didGetTimestamp = true
            return super.timestamp
        }
    }
    var didGetLogLifespan: Bool = false
    override var logLifespan: NSTimeInterval {
        get {
            didGetLogLifespan = true
            return super.logLifespan
        }
    }
    var didGetThreadId: Bool = false
    override var threadId: UInt32 {
        get {
            didGetThreadId = true
            return super.threadId
        }
    }
    var didGetMessage: Bool = false
    override var message: String {
        get {
            didGetMessage = true
            return super.message
        }
    }

    var didComposeFormattedMessage: Bool = false
    override func composeFormattedMessage() -> String
    {
        didComposeFormattedMessage = true
        return super.composeFormattedMessage()
    }

    var didComposeFileFunctionLineString: Bool = false
    override func composeFileFunctionLineString() -> String
    {
        didComposeFileFunctionLineString = true
        return super.composeFileFunctionLineString()
    }

    internal func reset()
    {
        didGetLevel = false
        didGetChannel = false
        didGetMessage = false
        didGetThreadId = false
        didGetTimestamp = false
        didGetLogLifespan = false
        didGetContextObject = false
        didGetFile = false
        didGetFunction = false
        didGetLine = false
        didComposeFormattedMessage = false
        didComposeFileFunctionLineString = false
    }
}

class TLSLoggingSwiftTestCrashlyticsOutputStream : TLSCrashlyticsOutputStream
{
    var didOutputLogMessageToCrashlytics: Bool = false
    override func outputLogMessageToCrashlytics(message: String)
    {
        didOutputLogMessageToCrashlytics = true
    }

    private var _discardLargeLogMessagesOverride:Bool = false
    var discardLargeLogMessagesOverride: Bool
    {
        get {
            return _discardLargeLogMessagesOverride
        }
        set {
            _discardLargeLogMessagesOverride = newValue
        }
    }
    override func discardLargeLogMessages() -> Bool
    {
        return self.discardLargeLogMessagesOverride
    }

    func reset()
    {
        _discardLargeLogMessagesOverride = false
        didOutputLogMessageToCrashlytics = false
    }
}

class TLSLoggingSwiftTest: XCTestCase
{
    let testOutputStream = TLSLoggingSwiftTestOutputStream()

    override func setUp() {
        super.setUp()
        TLSLoggingService.sharedInstance().addOutputStream(testOutputStream)
    }

    override func tearDown() {
        TLSLoggingService.sharedInstance().removeOutputStream(testOutputStream)
        super.tearDown()
    }

    func expectationForLoggingLevel(level: TLSLogLevel) -> XCTestExpectation {
        return self.expectationForNotification(TLSLoggingSwiftTestOutputStreamNotification, object: nil, handler: { (note: NSNotification) in
            let messageInfo: TLSLogMessageInfo = note.object as! TLSLogMessageInfo
            return messageInfo.level == level
        })
    }

    func dummyLogMessageInfo(message: String = "Some Message") -> TLSLoggingSwiftTestMessageInfo
    {
        return TLSLoggingSwiftTestMessageInfo(level: TLSLogLevel.Error, file:#file, function:#function ,line:#line, channel: "SomeChannel", timestamp: NSDate(), logLifespan: 0.1, threadId: 1, threadName: TLSCurrentThreadName(), contextObject: nil, message: message)
    }

    func testSwiftLogging() {
        let context = NSDate()

        var expectation = self.expectationForLoggingLevel(TLSLogLevel.Error)
        TLSLog.error("TestChannel", "Message with context: \(context)")
        self.waitForExpectationsWithTimeout(10, handler: nil)

        expectation = self.expectationForLoggingLevel(TLSLogLevel.Warning)
        TLSLog.warning("TestChannel", "Message with context: \(context)")
        self.waitForExpectationsWithTimeout(10, handler: nil)

        expectation = self.expectationForLoggingLevel(TLSLogLevel.Information)
        TLSLog.information("TestChannel", "Message with context: \(context)")
        self.waitForExpectationsWithTimeout(10, handler: nil)

        expectation = self.expectationForLoggingLevel(TLSLogLevel.Alert)
        TLSLog.log(TLSLogLevel.Alert, "TestChanne", context, "Message with context: \(context)")
        self.waitForExpectationsWithTimeout(10, handler: nil)

#if DEBUG
        expectation = self.expectationForLoggingLevel(TLSLogLevel.Debug)
        TLSLog.debug("TestChannel", "Message with context: \(context)")
        self.waitForExpectationsWithTimeout(10, handler: nil)
#endif
    }

    func testConsoleOutputStreams()
    {
        let messageInfo = self.dummyLogMessageInfo()

        let NSLogOutputStream = TLSNSLogOutputStream()
        NSLogOutputStream.tls_outputLogInfo(messageInfo)
        XCTAssertTrue(messageInfo.didGetFile)
        XCTAssertTrue(messageInfo.didGetFunction)
        XCTAssertTrue(messageInfo.didGetLine)
        XCTAssertTrue(messageInfo.didGetLevel)
        XCTAssertTrue(messageInfo.didGetChannel)
        XCTAssertTrue(messageInfo.didGetMessage)
        XCTAssertTrue(messageInfo.didComposeFileFunctionLineString)
        XCTAssertFalse(messageInfo.didComposeFormattedMessage) // doesn't use "composeFormattedMessage"
        messageInfo.reset()

        let stdOutOutputStream = TLSStdErrOutputStream()
        stdOutOutputStream.tls_outputLogInfo(messageInfo)
        XCTAssertFalse(messageInfo.didGetFile) // caching prevents access
        XCTAssertFalse(messageInfo.didGetFunction) // caching prevents access
        XCTAssertFalse(messageInfo.didGetLine) // caching prevents access
        XCTAssertTrue(messageInfo.didGetLevel)
        XCTAssertTrue(messageInfo.didGetChannel)
        XCTAssertTrue(messageInfo.didGetMessage)
        XCTAssertTrue(messageInfo.didComposeFileFunctionLineString) // cached value, access will not reconstruct string
        XCTAssertTrue(messageInfo.didComposeFormattedMessage) // does use "composeFormattedMessage"
        messageInfo.reset()
    }

    func testCrashlyticsOutputStream()
    {
        var longMessage = "This is a long message that will exceed 16KB so that we can test that it will be discarded."
        while (longMessage.characters.count < 16 * 1024) {
            longMessage += longMessage
        }
        let crashlyticsOutputStream = TLSLoggingSwiftTestCrashlyticsOutputStream()
        let messageInfo = self.dummyLogMessageInfo()
        let longMessageInfo = self.dummyLogMessageInfo(longMessage)

        crashlyticsOutputStream.tls_outputLogInfo(messageInfo)
        XCTAssertTrue(messageInfo.didGetMessage)
        XCTAssertTrue(crashlyticsOutputStream.didOutputLogMessageToCrashlytics)
        crashlyticsOutputStream.reset()
        messageInfo.reset()

        crashlyticsOutputStream.discardLargeLogMessagesOverride = true
        crashlyticsOutputStream.tls_outputLogInfo(messageInfo)
        XCTAssertTrue(messageInfo.didGetMessage)
        XCTAssertTrue(crashlyticsOutputStream.didOutputLogMessageToCrashlytics)
        crashlyticsOutputStream.reset()
        messageInfo.reset()

        crashlyticsOutputStream.tls_outputLogInfo(longMessageInfo)
        XCTAssertTrue(longMessageInfo.didGetMessage)
        XCTAssertTrue(crashlyticsOutputStream.didOutputLogMessageToCrashlytics)
        crashlyticsOutputStream.reset()
        longMessageInfo.reset()

        crashlyticsOutputStream.discardLargeLogMessagesOverride = true
        crashlyticsOutputStream.tls_outputLogInfo(longMessageInfo)
        XCTAssertTrue(longMessageInfo.didGetMessage)
        XCTAssertFalse(crashlyticsOutputStream.didOutputLogMessageToCrashlytics)
        crashlyticsOutputStream.reset()
        longMessageInfo.reset()
    }
}
