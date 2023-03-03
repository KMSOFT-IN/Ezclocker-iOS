//
//  ErrorLogging.swift
//  ezClocker
//
//  Created by Mehrooz Khan on 01/08/2022.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

import Foundation

import Firebase

@objc class ErrorLogging: NSObject {
    
    @objc static func logError(_ error: NSError? = nil) {
        guard let error = error else { return }
        Crashlytics.crashlytics().record(error: error)
    }
    
    @objc static func logError( domain: String, code: NSInteger, description: String, error: NSError?) {
        if let error = error {
            logError(error)
            return
        }
        let detail = [NSLocalizedDescriptionKey: description]
        let error = NSError(domain: domain, code: code, userInfo: detail)
        Crashlytics.crashlytics().record(error: error)
    }
    
}
