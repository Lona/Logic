//
//  EditableBlock.swift
//  Logic
//
//  Created by Devin Abbott on 9/27/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public class EditableBlock: Equatable {
    public let id: UUID
    public let content: EditableBlockContent

    public init(id: UUID, content: EditableBlockContent) {
        self.id = id
        self.content = content
    }

    public convenience init(_ content: EditableBlockContent) {
        self.init(id: UUID(), content: content)
    }

    public static func == (lhs: EditableBlock, rhs: EditableBlock) -> Bool {
        return lhs.id == rhs.id && lhs.content == rhs.content
    }

    private func makeView() -> NSView {
        switch self.content {
        case .text:
            return TextBlockView()
        case .tokens(let syntaxNode):
            let view = LogicEditor(rootNode: syntaxNode, formattingOptions: .visual)
            view.fillColor = Colors.blockBackground
            view.cornerRadius = 4
//            view.borderType = .lineBorder
//            view.borderWidth = 1
//            view.borderColor = Colors.divider

            var style = view.canvasStyle
            style.textMargin = .init(width: 5, height: 6)
            view.canvasStyle = style

            view.showsSearchBar = true
            view.scrollsVertically = false

            return view
        case .divider:
            return DividerBlock()
        case .image:
            let view = ImageBlock()

            view.image = NSImage()
            view.imageWidth = 100
            view.imageHeight = 100

            return view
        }
    }

    private func configure(view: NSView) {
        switch self.content {
        case .text(let attributedString, let sizeLevel):
            let view = view as! TextBlockView
            view.textValue = attributedString
            view.sizeLevel = sizeLevel
        case .tokens(let value):
            let view = view as! LogicEditor
            view.rootNode = value
        case .divider:
            break
        case .image(let url):
            let view = view as! ImageBlock

            if let url = url, let image = EditableBlock.fetchImage(url) {
                view.image = image
            } else {
                view.image = NSImage()
            }
        }
    }

    public var view: NSView {
        if let view = EditableBlock.viewCache[id] { return view }

        let view = makeView()
        configure(view: view)
        EditableBlock.viewCache[id] = view
        return view
    }

    public func updateView() {
        configure(view: view)
    }

    static var viewCache: [UUID: NSView] = [:]

    static var fetchImage: (URL) -> NSImage? = Memoize.all { url in
        guard let data = try? Data(contentsOf: url), let image = NSImage(data: data) else { return nil }
        return image
    }

//    deinit {
//        EditableBlock.viewCache.removeValue(forKey: id)
//    }

    public static func makeDefaultEmptyBlock() -> EditableBlock {
        return .init(.text(.init(), .paragraph))
    }

    public func updateViewWidth(_ width: CGFloat) {
        switch content {
        case .text:
            let view = self.view as! TextBlockView
            view.width = width
        case .image(let url):
            let view = self.view as! ImageBlock
            if let _ = url {
                let imageSize = view.image.size
                if imageSize.width > width {
                    view.imageWidth = width
                    view.imageHeight = imageSize.height * (width / imageSize.width )
                } else  {
                    view.imageWidth = imageSize.width
                    view.imageHeight = imageSize.height
                }
            } else {
                view.imageWidth = 100
                view.imageHeight = 100
            }
        default:
            break
        }
    }

    public var lineButtonAlignmentHeight: CGFloat {
        return content.lineButtonAlignmentHeight
    }

    public var lastSelectionRange: NSRange {
        switch content {
        case .tokens, .divider, .image:
            return .empty
        case .text(let text, _):
            return .init(location: text.length, length: 0)
        }
    }

    public var isEmpty: Bool {
        switch content {
        case .tokens:
            return false
        case .text(let text, _):
            let string = text.string
            return string.isEmpty || string == "/"
        case .divider:
            return true
        case .image(let url):
            return url == nil
        }
    }

    public var supportsInlineFocus: Bool {
        switch content {
        case .text:
            return true
        case .tokens, .divider, .image:
            return false
        }
    }

    public var supportsMergingText: Bool {
        switch content {
        case .text:
            return true
        case .tokens, .divider, .image:
            return false
        }
    }

    public var supportsDirectDragging: Bool {
        switch content {
        case .text, .tokens, .divider:
            return false
        case .image:
            return true
        }
    }

}

extension EditableBlock: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch content {
        case .text(let textValue, let sizeLevel):
            return "text:\(sizeLevel):\(textValue.string)"
        case .tokens(let syntaxNode):
            return "tokens:\(syntaxNode.nodeTypeDescription)"
        case .divider:
            return "divider"
        case .image(let url):
            return "image:\(String(describing: url))"
        }
    }
}

public enum EditableBlockContent: Equatable {
    case text(NSAttributedString, TextBlockView.SizeLevel)
    case tokens(LGCSyntaxNode)
    case divider
    case image(URL?)

    var lineButtonAlignmentHeight: CGFloat {
        switch self {
        case .text(_, let sizeLevel):
            return sizeLevel.fontSize * TextBlockView.lineHeightMultiple
        case .tokens, .image:
            return 18
        case .divider:
            return 21
        }
    }
}
