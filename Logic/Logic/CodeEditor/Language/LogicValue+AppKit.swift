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

    public var nsShadow: NSShadow? {
        guard type == .shadow else { return nil }
        guard case .record(let members) = memory else { return nil }

        let shadow = NSShadow()

        if let xValue = members["x"], case .some(.number(let x)) = xValue?.memory {
            shadow.shadowOffset.width = x
        }
        if let yValue = members["y"], case .some(.number(let y)) = yValue?.memory {
            shadow.shadowOffset.height = -y
        }
        if let blurValue = members["blur"], case .some(.number(let blur)) = blurValue?.memory {
            shadow.shadowBlurRadius = blur
        }
        if let colorValue = members["color"], let colorString = colorValue?.colorString {
            shadow.shadowColor = NSColor.parse(css: colorString) ?? .black
        }

        return shadow
    }

    public var fontWeight: NSFont.Weight? {
        guard case .enum(let caseName, _) = memory else { return nil }

        switch caseName {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return nil
        }
    }

    public var textStyle: TextStyle? {
        guard type == .textStyle else { return nil }
        guard case .record(let members) = memory else { return nil }

        var textStyle = TextStyle()

        if let logicValue = members["fontName"], case .some(.string(let value)) = logicValue?.unwrapped?.memory {
            textStyle = textStyle.with(name: value)
        }
        if let logicValue = members["fontFamily"], case .some(.string(let value)) = logicValue?.unwrapped?.memory {
            textStyle = textStyle.with(family: value)
        }
        if let logicValue = members["fontSize"], case .some(.number(let value)) = logicValue?.unwrapped?.memory {
            textStyle = textStyle.with(size: value)
        }
        if let logicValue = members["fontWeight"], case .some(let value) = logicValue {
            textStyle = textStyle.with(weight: value.fontWeight)
        }
        if let logicValue = members["lineHeight"], case .some(.number(let value)) = logicValue?.unwrapped?.memory {
            textStyle = textStyle.with(lineHeight: value)
        }
        if let logicValue = members["letterSpacing"], case .some(.number(let value)) = logicValue?.unwrapped?.memory {
            textStyle = textStyle.with(kerning: Double(value))
        }
        if let logicValue = members["color"], let value = logicValue?.unwrapped?.colorString {
            textStyle = textStyle.with(color: NSColor.parse(css: value) ?? .black)
        }

        return textStyle
    }

    public var unwrapped: LogicValue? {
        guard case .enum("value", let associatedValues) = memory else { return nil }
        return associatedValues[0]
    }
}
