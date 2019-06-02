//
//  LogicValue+Core.swift
//  Logic
//
//  Created by Devin Abbott on 6/2/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension LogicValue {
    public static let unit = LogicValue(.unit, .unit)

    public static func bool(_ value: Bool) -> LogicValue {
        return LogicValue(.bool, .bool(value))
    }

    public static func number(_ value: CGFloat) -> LogicValue {
        return LogicValue(.number, .number(value))
    }

    public static func string(_ value: String) -> LogicValue {
        return LogicValue(.string, .string(value))
    }

    public static func cssColor(_ value: String) -> LogicValue {
        return LogicValue(.cssColor, .record(values: ["value": .string(value)]))
    }

    public static func color(_ value: String) -> LogicValue {
        return LogicValue(.color, .enum(caseName: "custom", associatedValues: [cssColor(value)]))
    }
}
