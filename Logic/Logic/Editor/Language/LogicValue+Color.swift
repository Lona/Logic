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

    public var textStyle: TextStyle? {
        guard type == .textStyle else { return nil }
        guard case .record(let members) = memory else { return nil }

        var textStyle = TextStyle()

        if let fontNameValue = members["fontName"], case .some(.string(let fontName)) = fontNameValue?.unwrapped?.memory {
            textStyle = textStyle.with(name: fontName)
        }
        if let fontFamilyValue = members["fontFamily"], case .some(.string(let fontFamily)) = fontFamilyValue?.unwrapped?.memory {
            textStyle = textStyle.with(family: fontFamily)
        }
        if let sizeValue = members["fontSize"], case .some(.number(let size)) = sizeValue?.unwrapped?.memory {
            textStyle = textStyle.with(size: size)
        }
        if let colorValue = members["color"], let colorString = colorValue?.unwrapped?.colorString {
            textStyle = textStyle.with(color: NSColor.parse(css: colorString) ?? .black)
        }

        return textStyle
    }

    public var unwrapped: LogicValue? {
        guard case .enum("value", let associatedValues) = memory else { return nil }
        return associatedValues[0]
    }
}
