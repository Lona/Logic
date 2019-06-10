//
//  LogicElement.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public enum LogicElement {

    public enum Decoration {
        case color(NSColor)
        case character(NSAttributedString, NSColor)
        case label(NSFont, String)
    }

    public enum DropdownStyle {
        case source, variable, placeholder, boldVariable

        var color: NSColor {
            switch self {
            case .source:
                return Colors.text
            case .variable, .boldVariable:
                return Colors.editableText
            case .placeholder:
                return NSColor.systemYellow
            }
        }
    }

    case text(String)
    case coloredText(String, NSColor)
    case dropdown(UUID, String, DropdownStyle)
    case title(UUID, String)
    case colorSwatch(String, NSColor)

    public var isActivatable: Bool {
        switch self {
        case .text,
             .coloredText,
             .colorSwatch:
            return false
        case .title,
             .dropdown:
            return true
        }
    }

    public var syntaxNodeID: UUID? {
        switch self {
        case .text,
             .coloredText,
             .colorSwatch:
            return nil
        case .title(let id, _),
             .dropdown(let id, _, _):
            return id
        }
    }

    public var value: String {
        switch self {
        case .text(let value),
             .coloredText(let value, _),
             .title(_, let value),
             .dropdown(_, let value, _),
             .colorSwatch(let value, _):
            return value
        }
    }

    public var color: NSColor {
        switch self {
        case .text, .title:
            return Colors.text
        case .coloredText(_, let color), .colorSwatch(_, let color):
            return color
        case .dropdown(_, _, let dropdownStyle):
            return dropdownStyle.color
        }
    }
}

let titleTextStyle = TextStyle(size: 22, color: Colors.text)

extension LogicElement {
    func measured(
        selected: Bool,
        origin: CGPoint,
        font: NSFont,
        boldFont: NSFont,
        padding: NSSize,
        decoration: Decoration?) -> LogicMeasuredElement {

        func textComponents(color: NSColor, font: NSFont) -> (string: NSAttributedString, rect: CGRect, backgroundRect: CGRect) {
            let attributedString = NSMutableAttributedString(string: self.value)
            let range = NSRange(location: 0, length: attributedString.length)

            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.font: font,
            ]
            attributedString.setAttributes(attributes, range: range)

            let attributedStringSize = attributedString.size()
            let offset = CGPoint(x: origin.x + padding.width, y: origin.y + padding.height)
            let rect = CGRect(origin: offset, size: attributedStringSize)
            let backgroundRect = rect.insetBy(dx: -padding.width, dy: -padding.height)

            return (attributedString, rect, backgroundRect)
        }

        func textElement(color: NSColor, font: NSFont) -> LogicMeasuredElement {
            let (attributedString, rect, backgroundRect) = textComponents(color: color, font: font)

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        }

        switch self {
        case .text:
            return textElement(color: Colors.textNoneditable, font: font)
        case .title:
            var (attributedString, rect, backgroundRect) = textComponents(color: self.color, font: titleTextStyle.nsFont)

            if LogicCanvasView.dropdownCarets || value.isEmpty {
                backgroundRect.size.width += value.isEmpty ? 5 : 11
            }

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        case .colorSwatch(_, _):
            let rect: CGRect = .init(origin: origin, size: .init(width: 68, height: 68))

            return LogicMeasuredElement(
                element: self,
                attributedString: .init(),
                attributedStringRect: rect,
                backgroundRect: rect)
        case .coloredText:
            fatalError("Unused")
//            return textElement(color: selected ? NSColor.systemGreen : color, font: titleTextStyle.nsFont)
        case .dropdown(_, _, let dropdownStyle):
            var (attributedString, rect, backgroundRect) = textComponents(
                color: dropdownStyle.color,
                font: dropdownStyle == .boldVariable ? boldFont : font
            )

            if LogicCanvasView.dropdownCarets || value.isEmpty {
                backgroundRect.size.width += value.isEmpty ? 5 : 11
            }

            switch decoration {
            case .some(.label(let font, let text)):
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.foregroundColor: NSColor.white,
                    NSAttributedString.Key.font: font,
                ]
                let labelString = NSAttributedString(string: text, attributes: attributes)
                let labelWidth = labelString.size().width + 5 + 6
                
                backgroundRect.size.width += labelWidth
            case .some(.color), .some(.character):
                rect.origin.x += 18
                backgroundRect.size.width += 18
            case .none:
                break
            }

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        }
    }
}
