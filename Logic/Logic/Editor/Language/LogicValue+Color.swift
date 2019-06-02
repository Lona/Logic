//
//  Color.swift
//  Logic
//
//  Created by Devin Abbott on 6/2/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension LogicValue {
    public var colorString: String? {
        func getColorStringFromCSSColor(value: LogicValue) -> String? {
            guard value.type == .cssColor else { return nil }
            guard case .record(let members) = value.memory else { return nil }
            guard let colorValue = members["value"] else { return nil }
            guard case .string(let stringValue)? = colorValue?.memory else { return nil }
            return stringValue
        }

        if let colorString = getColorStringFromCSSColor(value: self) {
            return colorString
        }

        if self.type == .color, case .enum(let caseName, let values) = self.memory {
            if caseName == "custom", let value = values.first {
                if let colorString = getColorStringFromCSSColor(value: value) {
                    return colorString
                }
            } else if caseName == "system", let value = values.dropFirst().first {
                if let colorString = getColorStringFromCSSColor(value: value) {
                    return colorString
                }
            }
        }

        return nil
    }
}
