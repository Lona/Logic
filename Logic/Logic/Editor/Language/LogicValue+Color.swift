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
            guard value.type == .color else { return nil }
            guard case .record(let members) = value.memory else { return nil }
            guard let colorValue = members["value"] else { return nil }
            guard case .string(let stringValue)? = colorValue?.memory else { return nil }
            return stringValue
        }

        if let colorString = getColorStringFromCSSColor(value: self) {
            return colorString
        }

        return nil
    }
}
