//
//  LightMark+AppKit.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 3/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

// https://stackoverflow.com/a/48583402
extension Sequence where Iterator.Element: NSAttributedString {
    /// Returns a new attributed string by concatenating the elements of the sequence, adding the given separator between each element.
    /// - parameters:
    ///     - separator: A string to insert between each of the elements in this sequence. The default separator is an empty string.
    public func joined(separator: NSAttributedString = NSAttributedString(string: "")) -> NSAttributedString {
        var isFirst = true
        return self.reduce(NSMutableAttributedString()) {
            (r, e) in
            if isFirst {
                isFirst = false
            } else {
                r.append(separator)
            }
            r.append(e)
            return r
        }
    }
}

extension LightMark.HeadingLevel {
    var weight: NSFont.Weight {
        switch self {
        case .level1:
            return .regular
        case .level2:
            return .medium
        case .level3:
            return .heavy
        case .level4, .level5, .level6:
            fatalError("Unhandled heading level")
        }
    }

    var size: CGFloat {
        switch self {
        case .level1:
            return 18
        case .level2:
            return 15
        case .level3:
            return 13
        case .level4, .level5, .level6:
            fatalError("Unhandled heading level")
        }
    }
}

extension LightMark.TextStyle {
    var weight: NSFont.Weight? {
        switch self {
        case .strong:
            return .bold
        case .emphasis, .strikethrough:
            return nil
        }
    }
}

extension LightMark.QuoteKind {
    public var backgroundColor: NSColor {
        switch self {
        case .none:
            return Colors.dividerBackground
        case .info:
            return NSColor.systemBlue.withAlphaComponent(0.3)
        case .warning:
            return NSColor.systemYellow.withAlphaComponent(0.5)
        case .error:
            return NSColor.systemRed.withAlphaComponent(0.5)
        }
    }

    public var icon: NSImage? {
        switch self {
        case .none:
            return nil
        case .info:
            return LightMark.QuoteKind.iconInfo
        case .warning:
            return LightMark.QuoteKind.iconWarning
        case .error:
            return LightMark.QuoteKind.iconError
        }
    }

    public static var iconInfo = BundleLocator.getBundle().image(forResource: NSImage.Name("icon-info"))!
    public static var iconWarning = BundleLocator.getBundle().image(forResource: NSImage.Name("icon-warning"))!
    public static var iconError = BundleLocator.getBundle().image(forResource: NSImage.Name("icon-error"))!

    public static var iconMargin = NSEdgeInsets(top: 3, left: 4, bottom: 0, right: 4)
    public static var paragraphMargin = NSEdgeInsets(top: 0, left: 0, bottom: 1, right: 0)
}

typealias LogicTextStyle = TextStyle

extension LightMark {
    static func makeTextStyle(headingLevel: HeadingLevel? = nil, textStyle: TextStyle? = nil, isCode: Bool = false) -> LogicTextStyle {
        return makeTextStyleMemoized(headingLevel, textStyle, isCode)
    }

    private static var makeTextStyleMemoized: (HeadingLevel?, TextStyle?, Bool) -> LogicTextStyle = Memoize.all({
        headingLevel, textStyle, isCode in

        let weight: NSFont.Weight = textStyle?.weight ?? headingLevel?.weight ?? .regular
        let size: CGFloat = headingLevel?.size ?? 12

        return LogicTextStyle(weight: weight, size: size, lineHeight: 18, color: isCode ? Colors.editableText : nil)
    })
}

extension LightMark.InlineElement {
    func attributedString() -> NSAttributedString {
        switch self {
        case .text(content: let content):
            return LightMark.makeTextStyle().apply(to: content)
        case .styledText(style: let style, content: let content):
            return LightMark.makeTextStyle(textStyle: style)
                .apply(to: content.map { $0.attributedString() }.joined())
        case .code(content: let content):
            return LightMark.makeTextStyle(isCode: true).apply(to: content)
        case .link(source: let source, content: let content):
            let attributedString = LightMark.makeTextStyle()
                .apply(to: content.map { $0.attributedString() }.joined())
            let string = attributedString.string
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            let range = NSRange(string.startIndex..<string.endIndex, in: string)
            mutableAttributedString.addAttribute(.link, value: NSURL(string: source) as Any, range: range)
            return mutableAttributedString
        case .image:
            return NSAttributedString()
        }
    }
}

extension LightMark {
    public class RenderingOptions {
        var formattingOptions: LogicFormattingOptions

        public init(formattingOptions: LogicFormattingOptions) {
            self.formattingOptions = formattingOptions
        }
    }
}

extension LightMark.BlockElement {
    func view(renderingOptions: LightMark.RenderingOptions) -> NSView {
        switch self {
        case .heading(let headingLevel, let content):
            let attributedString = LightMark.makeTextStyle(headingLevel: headingLevel)
                .apply(to: content.map { $0.attributedString() }.joined())

            return LightMark.makeTextField(attributedString: attributedString)
        case .quote(kind: let kind, content: let blocks):
            let container = NSBox()
            container.boxType = .custom
            container.borderType = .noBorder
            container.fillColor = kind.backgroundColor
            container.contentViewMargins = .zero
            container.cornerRadius = 4

            let icon = kind.icon ?? NSImage()
            let iconView = NSImageView(image: icon)

            let blockView = LightMark.makeContentView(blocks, padding: .init(top: 0, left: 0, bottom: 0, right: 0), renderingOptions: renderingOptions)

            container.addSubview(blockView)
            container.addSubview(iconView)

            container.translatesAutoresizingMaskIntoConstraints = false
            iconView.translatesAutoresizingMaskIntoConstraints = false
            blockView.translatesAutoresizingMaskIntoConstraints = false

            let iconMargin = LightMark.QuoteKind.iconMargin
            let paragraphMargin = LightMark.QuoteKind.paragraphMargin

            iconView.widthAnchor.constraint(equalToConstant: icon.size.width).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: icon.size.height).isActive = true
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: iconMargin.top).isActive = true
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: iconMargin.left).isActive = true

            blockView.leadingAnchor.constraint(
                equalTo: iconView.trailingAnchor,
                constant: iconMargin.right + paragraphMargin.left).isActive = true

            blockView.topAnchor.constraint(equalTo: container.topAnchor, constant: paragraphMargin.top).isActive = true
            blockView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -paragraphMargin.bottom).isActive = true
            blockView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -paragraphMargin.right).isActive = true

            return container
        case .paragraph(let elements):
            let attributedString = elements.map { $0.attributedString() }.joined()

            return LightMark.makeTextField(attributedString: attributedString)
        case .block(language: "logic", content: let content),
             .block(language: "tokens", content: let content):
            let xml = #"<?xml version="1.0"?>"# + content

            guard let data = xml.data(using: .utf8) else { fatalError("Invalid utf8 data in markdown code block") }

            guard let node = LGCSyntaxNode(data: data) else {
                Swift.print("Failed to create documentation code block from", content)
                return NSView()
            }

            return node.makeCodeView(using: renderingOptions.formattingOptions)
        case .block(language: _, content: let content):
            let container = NSBox()
            container.boxType = .custom
            container.borderType = .noBorder
            container.fillColor = Colors.blockBackground
            container.contentViewMargins = .zero
            container.cornerRadius = 4

            let paragraphMargin = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

            let textStyle = TextStyle(family: "Menlo", size: 12)

            let textField = LightMark.makeTextField(attributedString: textStyle.apply(to: content))
            textField.translatesAutoresizingMaskIntoConstraints = false

            container.addSubview(textField)

            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: paragraphMargin.left).isActive = true
            textField.topAnchor.constraint(equalTo: container.topAnchor, constant: paragraphMargin.top).isActive = true
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -paragraphMargin.bottom).isActive = true
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -paragraphMargin.right).isActive = true

            return container
        case .horizontalRule:
            let container = NSBox()

            container.boxType = .custom
            container.borderType = .noBorder
            container.fillColor = Colors.divider

            container.translatesAutoresizingMaskIntoConstraints = false
            container.heightAnchor.constraint(equalToConstant: 1).isActive = true

            return container
        case .lineBreak:
            return NSView()
        default:
            fatalError("Unhandled type")
        }
    }

    var marginTop: CGFloat {
        switch self {
        case .heading(let headingSize, _):
            switch headingSize {
            case .level1:
                return 24
            case .level2:
                return 18
            case .level3:
                return 16
            case .level4, .level5, .level6:
                fatalError("Unhandled heading level")
            }
        case .paragraph, .block, .quote:
            return 0
//        case .custom:
//            return 12
//        case .alert:
//            return 8
        case .lineBreak:
            return 8
        case .horizontalRule:
            return 18
        default:
            fatalError("Unhandled type")
        }
    }
}

private class FlippedView: NSView {
    override var isFlipped: Bool {
        return true
    }
}

extension LightMark {
    public static func makeInlineElements(attributedString: NSAttributedString) -> [InlineElement] {
        let markdownString = attributedString.markdownString()

        Swift.print("md string", markdownString)

        let parsed = LightMark.parse(markdownString)
        for blockElement in parsed {
            switch blockElement {
            case .paragraph(content: let inlineElements):
                return inlineElements
            default:
                break
            }
        }

        return []
//        fatalError("Can't create inline elements")
    }

    public static func makeTextField(attributedString: NSAttributedString) -> NSTextField {
        let textField = NSTextField(labelWithAttributedString: attributedString)
        textField.isEnabled = true
        textField.isSelectable = true
        textField.allowsEditingTextAttributes = true

        return textField
    }

    public static func makeContentView(_ blocks: [LightMark.BlockElement], padding: NSEdgeInsets, renderingOptions: RenderingOptions) -> NSView {
        let blockViews = blocks.map { $0.view(renderingOptions: renderingOptions) }

        let contentView = FlippedView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        if blockViews.count > 0 {
            for (offset, view) in blockViews.enumerated() {
                contentView.addSubview(view)

                view.translatesAutoresizingMaskIntoConstraints = false
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding.left).isActive = true
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding.right).isActive = true

                if offset == 0 {
                    view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding.top).isActive = true
                } else {
                    let margin = max(blocks[offset].marginTop, 8)
                    view.topAnchor.constraint(equalTo: blockViews[offset - 1].bottomAnchor, constant: margin).isActive = true
                }

                if offset == blockViews.count - 1 {
                    view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding.bottom).isActive = true
                }
            }
        }

        return contentView
    }

    public static func makeScrollView(_ blocks: [LightMark.BlockElement], renderingOptions: RenderingOptions) -> NSScrollView {
        let contentView = self.makeContentView(blocks, padding: .init(top: 24, left: 24, bottom: 24, right: 24), renderingOptions: renderingOptions)

        let scrollView = NSScrollView()

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = contentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor).isActive = true

        return scrollView
    }

    public static func makeScrollView(markdown: String, renderingOptions: RenderingOptions) -> NSScrollView {
        return LightMark.makeScrollView(LightMark.parse(markdown), renderingOptions: renderingOptions)
    }
}

