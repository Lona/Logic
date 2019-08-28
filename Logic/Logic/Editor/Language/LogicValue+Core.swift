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

    public static func color(_ value: String) -> LogicValue {
        return LogicValue(.color, .record(values: ["value": .string(value)]))
    }

    public static func optional(_ value: LogicValue) -> LogicValue {
        return LogicValue(.optional(value.type), .enum(caseName: "value", associatedValues: [value]))
    }

    public static func unwrapOptional(_ value: LogicValue) -> LogicValue? {
        switch (value.type, value.memory) {
        case (.cons(name: "Optional", parameters: _), .enum(caseName: "value", associatedValues: let values)):
            return values.first
        default:
            return nil
        }
    }

    public var array: [LogicValue]? {
        switch memory {
        case .array(let values):
            return values
        default:
            return nil
        }
    }
}
