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
    case colorPreview(String, NSColor, UUID, targetId: UUID)
    case shadowPreview(NSShadow, UUID, targetId: UUID)
    case textStylePreview(TextStyle, String, UUID, targetId: UUID)
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
             .colorPreview(_, _, let id, _),
             .shadowPreview(_, let id, _),
             .textStylePreview(_, _, let id, _):
            return id
        }
    }

    public var targetNodeId: UUID? {
        switch self {
        case .text,
             .coloredText,
             .indentGuide,
             .errorSummary,
             .title,
             .dropdown:
            return nil
        case .colorPreview(_, _, _, let id),
             .shadowPreview(_, _, let id),
             .textStylePreview(_, _, _, let id):
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
        case .coloredText(_, let color), .colorPreview(_, let color, _, _):
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

extension Memoize {
    static let emptyAttributedString = NSAttributedString()

    static let attributedString: (NSFont, NSColor, String) -> NSAttributedString = Memoize.all { font, color, string in
        return NSAttributedString(string: string, attributes: [
            NSAttributedString.Key.foregroundColor: color,
            NSAttributedString.Key.font: font,
        ])
    }

    static let attributedStringSize: (NSAttributedString) -> NSSize = Memoize.all { attributedString in
        return attributedString.size()
    }
}

extension LogicElement {
    func measured(
        selected: Bool,
        origin: CGPoint,
        font: NSFont,
        boldFont: NSFont,
        padding: NSSize,
        decoration: Decoration?) -> LogicMeasuredElement {

        func textComponents(color: NSColor, font: NSFont) -> (string: NSAttributedString, rect: CGRect, backgroundRect: CGRect) {
            let attributedString = Memoize.attributedString(font, color, self.value)
            let attributedStringSize = Memoize.attributedStringSize(attributedString)

            let offset = CGPoint(x: origin.x + padding.width, y: origin.y + padding.height)
            let rect = CGRect(origin: offset, size: attributedStringSize)
            let backgroundRect = rect.insetBy(dx: -padding.width, dy: -padding.height)

            return (attributedString, rect, backgroundRect)
        }

        switch self {
        case .text:
            let (attributedString, rect, backgroundRect) = textComponents(color: color, font: font)

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect
            )
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
                backgroundRect: backgroundRect
            )
        case .title:
            var (attributedString, rect, backgroundRect) = textComponents(color: self.color, font: titleTextStyle.nsFont)

            if value.isEmpty {
                backgroundRect.size.width += value.isEmpty ? 5 : 11
            }

            return LogicMeasuredElement(
                element: self,
                attributedString: attributedString,
                attributedStringRect: rect,
                backgroundRect: backgroundRect
            )
        case .colorPreview, .shadowPreview:
            let rect: CGRect = .init(origin: origin, size: .init(width: 68, height: 68))

            return LogicMeasuredElement(
                element: self,
                attributedString: Memoize.emptyAttributedString,
                attributedStringRect: rect,
                backgroundRect: rect
            )
        case .textStylePreview:
            let rect: CGRect = .init(origin: origin, size: .init(width: 68 * 2, height: 68))

            return LogicMeasuredElement(
                element: self,
                attributedString: Memoize.emptyAttributedString,
                attributedStringRect: rect,
                backgroundRect: rect
            )
        case .indentGuide:
            let rect: CGRect = .init(origin: origin, size: .init(width: 1, height: 0))

            return LogicMeasuredElement(
                element: self,
                attributedString: Memoize.emptyAttributedString,
                attributedStringRect: rect,
                backgroundRect: rect
            )
        case .coloredText:
            fatalError("Unused")
        case .dropdown(_, _, let dropdownStyle):
            var (attributedString, rect, backgroundRect) = textComponents(
                color: dropdownStyle.color,
                font: dropdownStyle == .boldVariable ? boldFont : font
            )

            if value.isEmpty {
                backgroundRect.size.width += 11
            }

            switch decoration {
            case .some(.label(let font, let text)):
                let labelString = Memoize.attributedString(font, NSColor.white, text)
                let labelWidth = Memoize.attributedStringSize(labelString).width + 5 + 6
                
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
                backgroundRect: backgroundRect
            )
        }
    }
}
