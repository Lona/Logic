//
//  Focusable.swift
//  Logic
//
//  Created by Devin Abbott on 10/2/20.
//  Copyright © 2020 BitDisco, Inc. All rights reserved.
//

import Foundation

@objc public protocol Focusable {
    @objc func focus()
}

extension NSView: Focusable {
    public func focus() {
        if acceptsFirstResponder {
            window?.makeFirstResponder(self)
        }
    }
}
