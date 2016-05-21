//
//  TLSLog.swift
//  TwitterLoggingService
//
//  Created on 2/3/16.
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

import Foundation

/**
 Static class for logging with *Twitter Logging Service*
 */
public class TLSLog {

    /**
     Usage:

     TLSLog.log(TLSLogLevel.Error, "ChannelToLog", myContextObject, "This is my log message with info: \(info)")

     See also: `TLSLogError`, `TLSLogWarning`, `TLSLogInformation` and `TLSLogDebug`
     */
    public class func log(level: TLSLogLevel, _ channel: String, _ context: AnyObject?, @autoclosure _ message: () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line)
    {
        if (!TLSCanLog(nil, level, channel, context)) {
            return;
        }

        TLSLogString(nil, level, channel, file.stringValue, function.stringValue, UInt32(line), context, message())
    }

    /**
     Usage:

     TLSLog.error("ChannelToLog", "This is my log message with info: \(info)")
     */
    public class func error(channel: String, @autoclosure _ message: () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line)
    {
        log(TLSLogLevel.Error, channel, nil /*context*/, message, file: file, function: function, line: line)
    }

    /**
     Usage:

     TLSLog.warning("ChannelToLog", "This is my log message with info: \(info)")
     */
    public class func warning(channel: String, @autoclosure _ message: () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line)
    {
        log(TLSLogLevel.Warning, channel, nil /*context*/, message, file: file, function: function, line: line)
    }

    /**
     Usage:

     TLSLog.information("ChannelToLog", "This is my log message with info: \(info)")
     */
    public class func information(channel: String, @autoclosure _ message: () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line)
    {
        log(TLSLogLevel.Information, channel, nil /*context*/, message, file: file, function: function, line: line)
    }

    /**
     Usage:

     TLSLog.debug("ChannelToLog", "This is my log message with info: \(info)")

     *Note*: Only logs on `DEBUG` builds
     */
    public class func debug(channel: String, @autoclosure _ message: () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line)
    {
        log(TLSLogLevel.Debug, channel, nil /*context*/, message, file: file, function: function, line: line)
    }
}
