//
//  Log.swift
//  popguide
//
//  Created by Pierluigi Galdi on 19/03/2018.
//  Copyright © 2018 Populi Ltd. All rights reserved.
//

import Foundation

public class Log {

    // MARK: Enum for message event
    public enum LogEvent: String {
        case info           = "[ℹ️]"
        case warning        = "[⚠️]"
        case error          = "[🛑]"
        case success        = "[✅]"
        case nullPointer    = "[❓]"
        case emptyArray     = "[📭]"
    }

    /// Hide initialiser
    @available(*, unavailable)
    init() {}

    /// Class function to print our log message in DEBUG mode only
    /// - parameter message: [Required]: The custom message to be printed
    /// - parameter event: [Required]: The event of the message (default is `.info`)
    /// - parameter fileName: [Optional]: The name of the file (default is last component of `#file` path)
    /// - parameter line: [Optional]: The number of the line where the log is placed (default is `#line`)
    /// - parameter funcName: [Optional]: The name of the function where the log is placed in (default is `#function`)
    public class func debug(message: String,
                            event: LogEvent,
                            fileName: String      = #file,
                            line: Int         = #line,
                            funcName: String      = #function) {
        /// Print message
        #if DEBUG
            print("\(event.rawValue)")
            print("[\(Log.dateAsString())]")
            print("[\(Log.fileName(path: fileName)):\(line)]")
            print("[\(funcName)] → \"\(message)\"")
        #endif
    }

    /// Class function to print our log message both in DEBUG and PRODUCTION mode
    /// - parameter message: [Required]: The custom message to be printed
    /// - parameter event: [Required]: The event of the message (default is `.info`)
    /// - parameter fileName: [Optional]: The name of the file (default is last component of `#file` path)
    /// - parameter line: [Optional]: The number of the line where the log is placed (default is `#line`)
    /// - parameter funcName: [Optional]: The name of the function where the log is placed in (default is `#function`)
    public class func prod(message: String,
                           event: LogEvent,
                           fileName: String      = #file,
                           line: Int         = #line,
                           funcName: String      = #function) {
        /// Print message
        print("\(event.rawValue)")
        print("[\(Log.dateAsString())]")
        print("[\(Log.fileName(path: fileName)):\(line)]")
        print("[\(funcName)] → \"\(message)\"")
    }

    /// Class function to print a `fatalError` with custom message and event
    /// - parameter message: [Required]: The custom message to be printed
    /// - parameter event: [Required]: The event of the message (default is `.info`)
    /// - parameter fileName: [Optional]: The name of the file (default is last component of `#file` path)
    /// - parameter line: [Optional]: The number of the line where the log is placed (default is `#line`)
    /// - parameter funcName: [Optional]: The name of the function where the log is placed in (default is `#function`)
    public class func fatalError(message: String,
                                 event: LogEvent,
                                 fileName: String = #file,
                                 line: Int = #line,
                                 funcName: String = #function) -> Never {
        /// Print message
        Swift.fatalError("""
                        \(event.rawValue)
                        [\(Log.dateAsString())]
                        [\(Log.fileName(path: fileName)):\(line)]
                        [\(funcName)] → \"\(message)\"
                        """)
    }

    // MARK: Private vars
    // Create date formatter
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }

    // MARK: Private functions
    ///
    /// Get `Date()` formatted as `String`
    private class func dateAsString() -> String {
        return Log.dateFormatter.string(from: Date())
    }

    /// Get filename
    private class func fileName(path: String?) -> String {
        let components = (path ?? #file).components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}
