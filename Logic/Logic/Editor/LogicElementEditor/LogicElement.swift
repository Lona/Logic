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
        case source, variable, placeholder, boldVariable, comment, empty

        var color: NSColor {
            switch self {
            case .source, .empty:
                return Colors.text
            case .variable, .boldVariable:
                return Colors.editableText
            case .placeholder:
                return NSColor.systemYellow
            case .comment:
                return Colors.textComment
            }
        }
    }

    case text(String)
    case coloredText(String, NSColor)
    case dropdown(UUID, String, DropdownStyle)
    case title(UUID, String)
    case colorPreview(String, NSColor, UUID)
    case shadowPreview(NSShadow, UUID)
    case textStylePreview(TextStyle, String, UUID)
    case indentGuide(UUID)
    case errorSummary(String, UUID)

    public var isActivatable: Bool {
        switch self {
        case .text,
             .coloredText,
             .colorPreview,
             .shadowPreview,
             .textStylePreview,
             .indentGuide,
             .errorSummary:
            return false
        case .title,
             .dropdown:
            return true
        }
    }

    public var allowsLineSelection: Bool {
        switch self {
        case .colorPreview,
             .shadowPreview,
             .textStylePreview,
             .indentGuide,
             .errorSummary:
            return false
        case .title,
             .dropdown,
             .coloredText,
             .text:
            return true
        }
    }

    public var syntaxNodeID: UUID? {
        switch self {
        case .text,
             .coloredText,
             .colorPreview,
             .shadowPreview,
             .textStylePreview,
             .indentGuide,
             .errorSummary:
            return nil
        case .title(let id, _),
             .dropdown(let id, _, _):
            return id
        }
    }

    public var ownerNodeId: UUID? {
        switch self {
        case .text,
             .coloredText,
             .indentGuide,
             .errorSummary:
            return nil
        case .title(let id, _),
             .dropdown(let id, _, _),
             .colorPreview(_, _, let id),
             .shadowPreview(_, let id),
             .textStylePreview(_, _, let id):
            return id
        }
    }

    public var isLogicalNode: Bool {
        switch self {
        case .indentGuide,
             .errorSummary:
            return false
        case .text,
             .coloredText,
             .title,
             .dropdown,
             .colorPreview,
             .shadowPreview,
             .textStylePreview:
            return true
        }
    }

    public var value: String {
        switch self {
        case .indentGuide,
             .shadowPreview,
             .colorPreview,
             .textStylePreview:
            // This value has no meaning
            return ""
        case .text(let value),
             .coloredText(let value, _),
             .title(_, let value),
             .dropdown(_, let value, _),
             .errorSummary(let value, _):
            return value
        }
    }

    public var color: NSColor {
        switch self {
        case .text, .title, .errorSummary:
            return Colors.text
        case .coloredText(_, let color), .colorPreview(_, let color, _):
            return color
        case .dropdown(_, _, let dropdownStyle):
            return dropdownStyle.color
        case .indentGuide:
            return Colors.indentGuide
        case .shadowPreview, .textStylePreview:
            // This value has no meaning
            return .white
        }
    }

    public var backgroundColor: NSColor? {
        switch self {
        case .dropdown(_, _, .comment):
            return Colors.commentBackground
        case .errorSummary:
            return Colors.errorSummaryBackground
        default:
            return nil
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
        case .errorSummary:
            var (attributedString, rect, backgroundRect) = textComponents(color: self.color, font: font)

            let offset: CGFloat = 16

            backgroundRect.size.width += offset
            backgroundRect.origin.x += 6
            rect.origin.x += 6 + offset

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        case .title:
            var (attributedString, rect, backgroundRect) = textComponents(color: self.color, font: titleTextStyle.nsFont)

            if value.isEmpty {
                backgroundRect.size.width += value.isEmpty ? 5 : 11
            }

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect)
        case .colorPreview, .shadowPreview:
            let rect: CGRect = .init(origin: origin, size: .init(width: 68, height: 68))

            return LogicMeasuredElement(
                element: self,
                attributedString: .init(),
                attributedStringRect: rect,
                backgroundRect: rect)
        case .textStylePreview:
            let rect: CGRect = .init(origin: origin, size: .init(width: 68 * 2, height: 68))

            return LogicMeasuredElement(
                element: self,
                attributedString: .init(),
                attributedStringRect: rect,
                backgroundRect: rect)
        case .indentGuide:
            let rect: CGRect = .init(origin: origin, size: .init(width: 1, height: 0))

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

            if value.isEmpty {
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
