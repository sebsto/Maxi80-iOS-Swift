//
//  Logger.swift
//  Maxi80
//
//  Created by Stormacq, Sebastien on 07/11/2018.
//  Copyright © 2018 stormacq.com. All rights reserved.
//

import Foundation
import os.log

// Wrapper class for os_log function
public class Logger: NSObject {
    
    // Creates OSLog object which describes log subsystem and category
    //
    // - Parameter category: Category, provided predefined log category
    // - Returns: OSLog
    class func createOSLog(module: String) -> OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier ?? "-", category: module)
    }
    
}

// Prints provided debug log message with help of os_log function
//
// - Parameters:
//   - logger: a logger object created by createOSLog()
//   - message: String, provided log message
//   - args : one arg per placeholder in the message
func os_log_debug(_ log : OSLog, _ message: String) {
    os.os_log("%{private}@", log: log, type: OSLogType.debug, message)
}

// Prints provided info log message with help of os_log function
//
// - Parameters:
//   - logger: a logger object created by createOSLog()
//   - message: String, provided log message
//   - args : one arg per placeholder in the message
func os_log_info(_ log : OSLog, _ message: String) {
    os.os_log("%{private}@", log: log, type: OSLogType.info, message)
}

// Prints provided error log message with help of os_log function
//
// - Parameters:
//   - logger: a logger object created by createOSLog()
//   - message: String, provided log message
//   - args : one arg per placeholder in the message
func os_log_error(_ log : OSLog, _ message: String) {
    os.os_log("%{private}@", log: log, type: OSLogType.error, message)
}

// Prints provided default log message with help of os_log function
//
// - Parameters:
//   - logger: a logger object created by createOSLog()
//   - message: String, provided log message
//   - args : one arg per placeholder in the message
func os_log(_ log : OSLog, _ message: String) {
    os.os_log("%{private}@", log: log, type: OSLogType.default, message)
}

