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

extension RichText.BlockElement {
    var view: NSView {
        switch self {
        case .heading(let headingSize, let content):
            let attributedString = headingSize.textStyle.apply(to: content())
            return NSTextField(labelWithAttributedString: attributedString)
        case .paragraph(let elements):
            let paragraphString = NSMutableAttributedString()

            for element in elements {
                guard case .text(let style, let content) = element else { continue }

                let attributedString = style.textStyle.apply(to: content())
                paragraphString.append(attributedString)
            }

            return NSTextField(labelWithAttributedString: paragraphString)
        case .code(let node):
            let container = NSBox()
            container.boxType = .custom
            container.borderType = .lineBorder
            container.borderWidth = 1
            container.borderColor = NSColor(red: 0.59, green: 0.59, blue: 0.59, alpha: 0.26)
            container.fillColor = .white
            container.cornerRadius = 4

            let editor = LogicEditor()
            editor.formattedContent = node.formatted

            container.addSubview(editor)

            editor.translatesAutoresizingMaskIntoConstraints = false
            editor.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
            editor.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
            editor.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            editor.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true

            return container
        }
    }

    var marginTop: CGFloat {
        switch self {
        case .heading(let headingSize, _):
            switch headingSize {
            case .section:
                return 24
            case .title:
                return 0
            }
        case .paragraph:
            return 8
        case .code:
            return 12
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

    func makeScrollView() -> NSScrollView {
        let contentView = self.makeContentView()

        let scrollView = NSScrollView()

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.documentView = contentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true

        return scrollView
    }
}

