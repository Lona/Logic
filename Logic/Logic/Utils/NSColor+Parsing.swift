//
//  NSColor+Parsing.swift
//  Logic
//
//  Created by Devin Abbott on 8/7/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension NSColor {
    public static func parseAndNormalize(css: String) -> (css: String, color: NSColor)? {
        if let color = parse(css: css) {
            return (css, color)
        } else if let color = parse(css: "#" + css) {
            return ("#" + css, color)
        }
        return nil
    }
}
