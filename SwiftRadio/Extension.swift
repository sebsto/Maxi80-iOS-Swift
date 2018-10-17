//
//  BundleExtension.swift
//  SwiftRadio
//
//  Created by Stormacq, Sebastien on 3/11/17.
//  Copyright © 2017 matthewfecher.com. All rights reserved.
//

import Foundation

extension Bundle {
    
    var appName: String? {
        return infoDictionary?["CFBundleName"] as? String
    }
    
    var bundleId: String? {
        return bundleIdentifier!
    }
    
    var versionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
}
