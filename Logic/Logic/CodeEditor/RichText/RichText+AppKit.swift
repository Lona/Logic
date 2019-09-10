//
//  RichText+AppKit.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 3/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension RichText.HeadingSize {
    var textStyle: TextStyle {
        switch self {
        case .title:
            return TextStyle(size: 18)
        case .section:
            return TextStyle(weight: NSFont.Weight.medium, size: 12)
        }
    }
}

extension RichText.TextStyle {
    var textStyle: TextStyle {
        switch self {
        case .none:
            return TextStyle(size: 12, lineHeight: 18)
        case .bold:
            return TextStyle(weight: NSFont.Weight.bold, size: 12, lineHeight: 18)
        case .link:
            return TextStyle(weight: NSFont.Weight.bold, size: 12, lineHeight: 18, color: Colors.editableText)
        }
    }
}

extension RichText.AlertStyle {
    public var backgroundColor: NSColor {
        switch self {
        case .info:
            return NSColor.systemBlue.withAlphaComponent(0.5)
        case .warning:
            return NSColor.systemYellow.withAlphaComponent(0.5)
        case .error:
            return NSColor.systemRed.withAlphaComponent(0.5)
        }
    }

    public var icon: NSImage {
        switch self {
        case .info:
            return RichText.AlertStyle.iconInfo
        case .warning:
            return RichText.AlertStyle.iconWarning
        case .error:
            return RichText.AlertStyle.iconError
        }
    }

    public static var iconInfo = BundleLocator.getBundle().image(forResource: NSImage.Name("icon-info"))!
    public static var iconWarning = BundleLocator.getBundle().image(forResource: NSImage.Name("icon-warning"))!
    public static var iconError = BundleLocator.getBundle().image(forResource: NSImage.Name("icon-error"))!

    public static var iconMargin = NSEdgeInsets(top: 3, left: 4, bottom: 0, right: 4)
    public static var paragraphMargin = NSEdgeInsets(top: 0, left: 0, bottom: -1, right: 0)
}

extension RichText.BlockElement {
    var view: NSView {
        switch self {
        case .heading(let headingSize, let content):
            let attributedString = headingSize.textStyle.apply(to: content)
            return NSTextField(labelWithAttributedString: attributedString)
        case .alert(let alertStyle, let block):
            let container = NSBox()
            container.boxType = .custom
            container.borderType = .noBorder
            container.fillColor = alertStyle.backgroundColor
            container.contentViewMargins = .zero
            container.cornerRadius = 4

            let icon = alertStyle.icon
            let iconView = NSImageView(image: icon)

            let blockView = block.view

            container.addSubview(blockView)
            container.addSubview(iconView)

            container.translatesAutoresizingMaskIntoConstraints = false
            iconView.translatesAutoresizingMaskIntoConstraints = false
            blockView.translatesAutoresizingMaskIntoConstraints = false

            let iconMargin = RichText.AlertStyle.iconMargin
            let paragraphMargin = RichText.AlertStyle.paragraphMargin

            iconView.widthAnchor.constraint(equalToConstant: icon.size.width).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: icon.size.height).isActive = true
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: iconMargin.top).isActive = true
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: iconMargin.left).isActive = true

            blockView.leadingAnchor.constraint(
                equalTo: iconView.trailingAnchor,
                constant: iconMargin.right + paragraphMargin.left).isActive = true

            blockView.topAnchor.constraint(equalTo: container.topAnchor, constant: paragraphMargin.top).isActive = true
            blockView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: paragraphMargin.bottom).isActive = true
            blockView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -paragraphMargin.right).isActive = true

            return container
        case .paragraph(let elements):
            let paragraphString = NSMutableAttributedString()

            for element in elements {
                guard case .text(let style, let content) = element else { continue }

                let attributedString = style.textStyle.apply(to: content)
                paragraphString.append(attributedString)
            }

            return NSTextField(labelWithAttributedString: paragraphString)
        case .custom(let view):
            return view
        }
    }

    var marginTop: CGFloat {
        switch self {
        case .heading(let headingSize, _):
            switch headingSize {
            case .section:
                return 24
            case .title:
                return 18
            }
        case .paragraph:
            return 8
        case .custom:
            return 12
        case .alert:
            return 8
        }
    }
}

private class FlippedView: NSView {
    override var isFlipped: Bool {
        return true
    }
}

extension RichText {
    func makeContentView() -> NSView {
        let blockViews = blocks.map { $0.view }

        let contentView = FlippedView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        if blockViews.count > 0 {
            for (offset, view) in blockViews.enumerated() {
                contentView.addSubview(view)

                view.translatesAutoresizingMaskIntoConstraints = false
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24).isActive = true
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24).isActive = true

                if offset == 0 {
                    view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24).isActive = true
                } else {
                    let margin = max(blocks[offset].marginTop, 8)
                    view.topAnchor.constraint(equalTo: blockViews[offset - 1].bottomAnchor, constant: margin).isActive = true
                }

                if offset == blockViews.count - 1 {
                    view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24).isActive = true
                }
            }
        }

        return contentView
    }

    public func makeScrollView() -> NSScrollView {
        let contentView = self.makeContentView()

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
}

