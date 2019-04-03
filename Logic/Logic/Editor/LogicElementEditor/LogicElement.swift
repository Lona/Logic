//
//  LogicElement.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public enum LogicElement {

    public enum DropdownStyle {
        case source, variable, placeholder

        var color: NSColor {
            switch self {
            case .source:
                return Colors.text
            case .variable:
                return Colors.editableText
            case .placeholder:
                return NSColor.systemYellow
            }
        }
    }

    case text(String)
    case coloredText(String, NSColor)
    case dropdown(UUID, String, DropdownStyle)

    public var isActivatable: Bool {
        switch self {
        case .text, .coloredText:
            return false
        case .dropdown:
            return true
        }
    }

    public var syntaxNodeID: UUID? {
        switch self {
        case .text:
            return nil
        case .coloredText:
            return nil
        case .dropdown(let id, _, _):
            return id
        }
    }

    public var value: String {
        switch self {
        case .text(let value):
            return value
        case .coloredText(let value, _):
            return value
        case .dropdown(_, let value, _):
            return value
        }
    }

    public var color: NSColor {
        switch self {
        case .text:
            return Colors.text
        case .coloredText(_, let color):
            return color
        case .dropdown(_, _, let dropdownStyle):
            return dropdownStyle.color
        }
    }
}

extension LogicElement {
    func measured(selected: Bool, offset: CGPoint) -> LogicMeasuredElement {
        let attributedString = NSMutableAttributedString(string: self.value)
        let range = NSRange(location: 0, length: attributedString.length)

        switch self {
        case .text:
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.foregroundColor: Colors.textNoneditable,
                NSAttributedString.Key.font: LogicCanvasView.font
            ]
            attributedString.setAttributes(attributes, range: range)

            let attributedStringSize = attributedString.size()
            let rect = CGRect(origin: offset, size: attributedStringSize)
            let backgroundRect = rect.insetBy(dx: -LogicCanvasView.textPadding.width, dy: -LogicCanvasView.textPadding.height)

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        case .coloredText(_, let color):
            let color = selected ? NSColor.systemGreen : color

            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.font: LogicCanvasView.font
            ]
            attributedString.setAttributes(attributes, range: range)

            let attributedStringSize = attributedString.size()
            let rect = CGRect(origin: offset, size: attributedStringSize)
            let backgroundRect = rect.insetBy(dx: -LogicCanvasView.textPadding.width, dy: -LogicCanvasView.textPadding.height)

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        case .dropdown(_, _, let dropdownStyle):
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.foregroundColor: dropdownStyle.color,
                NSAttributedString.Key.font: LogicCanvasView.font,
            ]
            attributedString.setAttributes(attributes, range: range)

            let attributedStringSize = attributedString.size()
            let rect = CGRect(origin: offset, size: attributedStringSize)
            var backgroundRect = rect.insetBy(dx: -LogicCanvasView.textPadding.width, dy: -LogicCanvasView.textPadding.height)

            if LogicCanvasView.dropdownCarets || value.isEmpty {
                backgroundRect.size.width += value.isEmpty ? 5 : 11
            }

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        }
    }
}
