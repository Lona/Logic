//
//  BundleLocator.swift
//  Logic
//
//  Created by Devin Abbott on 4/4/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

@objc class BundleLocator: NSObject {
    @objc static func getBundle() -> Bundle {
        return Bundle(for: self)
    }
}
