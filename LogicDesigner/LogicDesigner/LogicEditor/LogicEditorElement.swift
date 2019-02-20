//
//  LogicEditorElement.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public typealias LogicTextID = String

public enum LogicEditorElement {
    case text(String)
    case coloredText(String, NSColor)
    case dropdown(LogicTextID, String, NSColor)

    var syntaxNodeID: String? {
        switch self {
        case .text:
            return nil
        case .coloredText:
            return nil
        case .dropdown(let id, _, _):
            return id
        }
    }

    var value: String {
        switch self {
        case .text(let value):
            return value
        case .coloredText(let value, _):
            return value
        case .dropdown(_, let value, _):
            return value
        }
    }

    var color: NSColor {
        switch self {
        case .text:
            return NSColor.black
        case .coloredText(_, let color):
            return color
        case .dropdown(_, _, let color):
            return color
        }
    }

    func measured(selected: Bool, offset: CGPoint) -> MeasuredEditorText {
        let attributedString = NSMutableAttributedString(string: self.value)
        let range = NSRange(location: 0, length: attributedString.length)

        switch self {
        case .text:
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.foregroundColor: NSColor.black,
                NSAttributedString.Key.font: LogicEditor.font
            ]
            attributedString.setAttributes(attributes, range: range)

            let attributedStringSize = attributedString.size()
            let rect = CGRect(origin: offset, size: attributedStringSize)
            let backgroundRect = rect.insetBy(dx: -LogicEditor.textPadding.width, dy: -LogicEditor.textPadding.height)

            return MeasuredEditorText(
                text: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        case .coloredText(_, let color):
            let color = selected ? NSColor.systemGreen : color

            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.font: LogicEditor.font
            ]
            attributedString.setAttributes(attributes, range: range)

            let attributedStringSize = attributedString.size()
            let rect = CGRect(origin: offset, size: attributedStringSize)
            let backgroundRect = rect.insetBy(dx: -LogicEditor.textPadding.width, dy: -LogicEditor.textPadding.height)

            return MeasuredEditorText(
                text: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        case .dropdown(_, _, let color):
            let color = selected ? NSColor.systemGreen : color

            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.font: LogicEditor.font
            ]
            attributedString.setAttributes(attributes, range: range)

            let attributedStringSize = attributedString.size()
            let rect = CGRect(origin: offset, size: attributedStringSize)
            var backgroundRect = rect.insetBy(dx: -LogicEditor.textPadding.width, dy: -LogicEditor.textPadding.height)
            backgroundRect.size.width += 14

            return MeasuredEditorText(
                text: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        }
    }
}

struct MeasuredEditorText {
    var text: LogicEditorElement
    var attributedString: NSAttributedString
    var attributedStringRect: CGRect
    var backgroundRect: CGRect
}