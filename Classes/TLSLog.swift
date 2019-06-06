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
    public final class func log(_ level: TLSLogLevel,
                                _ channel: String,
                                _ context: Any?,
                                _ message: @autoclosure () -> String,
                                options: TLSLogMessageOptions = TLSLogMessageOptions(),
                                file: StaticString = #file,
                                function: StaticString = #function,
                                line: Int = #line)
    {
        if (!TLSCanLog(nil, level, channel, context)) {
            return;
        }

        TLSLogString(nil,
                     level,
                     channel,
                     String(describing: file),
                     String(describing: function),
                     Int(line),
                     context,
                     options,
                     message())
    }

    /**
     Usage:

     TLSLog.error("ChannelToLog", "This is my log message with info: \(info)")
     */
    public final class func error(_ channel: String,
                                  _ message: @autoclosure () -> String,
                                  options: TLSLogMessageOptions = TLSLogMessageOptions(),
                                  file: StaticString = #file,
                                  function: StaticString = #function,
                                  line: Int = #line)
    {
        log(.error,
            channel,
            nil /*context*/,
            message(),
            options: options,
            file: file,
            function: function,
            line: line)
    }

    /**
     Usage:

     TLSLog.warning("ChannelToLog", "This is my log message with info: \(info)")
     */
    public final class func warning(_ channel: String,
                                    _ message: @autoclosure () -> String,
                                    options: TLSLogMessageOptions = TLSLogMessageOptions(),
                                    file: StaticString = #file,
                                    function: StaticString = #function,
                                    line: Int = #line)
    {
        log(.warning,
            channel,
            nil /*context*/,
            message(),
            options: options,
            file: file,
            function: function,
            line: line)
    }

    /**
     Usage:

     TLSLog.information("ChannelToLog", "This is my log message with info: \(info)")
     */
    public final class func information(_ channel: String,
                                        _ message: @autoclosure () -> String,
                                        options: TLSLogMessageOptions = TLSLogMessageOptions(),
                                        file: StaticString = #file,
                                        function: StaticString = #function,
                                        line: Int = #line)
    {
        log(.information,
            channel,
            nil /*context*/,
            message(),
            options: options,
            file: file,
            function: function,
            line: line)
    }

    /**
     Usage:

     TLSLog.debug("ChannelToLog", "This is my log message with info: \(info)")

     *Note*: Only logs on `DEBUG` builds
     */
    public final class func debug(_ channel: String,
                                  _ message: @autoclosure () -> String,
                                  options: TLSLogMessageOptions = TLSLogMessageOptions(),
                                  file: StaticString = #file,
                                  function: StaticString = #function,
                                  line: Int = #line)
    {
        log(.debug,
            channel,
            nil /*context*/,
            message(),
            options: options,
            file: file,
            function: function,
            line: line)
    }
}
