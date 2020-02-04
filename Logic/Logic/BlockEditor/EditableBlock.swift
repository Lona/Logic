//
//  EditableBlock.swift
//  Logic
//
//  Created by Devin Abbott on 9/27/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

// MARK: - EditableBlockView

public class EditableBlockView: NSView {

    public override var isFlipped: Bool {
        return true
    }

    // MARK: Lifecycle

    public init() {
        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUpViews()
        setUpConstraints()

        update()
    }

    // MARK: Public

    public var bottomMargin: CGFloat = 0 {
        didSet {
            bottomAnchorConstraint?.constant = -bottomMargin
        }
    }

    public var lineButtonAlignmentHeight: CGFloat = 0 {
        didSet {
            if lineButtonAlignmentHeight != oldValue {
                update()
            }
        }
    }

    public var listDepth: EditableBlockListDepth = .none {
        didSet {
            if listDepth != oldValue {
                update()
            }
        }
    }

    private var leadingMargin: CGFloat = 0 {
        didSet {
            leadingAnchorConstraint?.constant = leadingMargin
            invalidateIntrinsicContentSize()
        }
    }

    public var listItemView: NSView?

    public var contentView: NSView? {
        didSet {
            if contentView == oldValue { return }

            oldValue?.removeFromSuperview()

            if let contentView = contentView {
                addSubview(contentView)

                contentView.translatesAutoresizingMaskIntoConstraints = false
                contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
                contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

                bottomAnchorConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
                bottomAnchorConstraint?.isActive = true

                leadingAnchorConstraint = contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
                leadingAnchorConstraint?.isActive = true
            }
        }
    }

    // MARK: Private

    private var bottomAnchorConstraint: NSLayoutConstraint?

    private var leadingAnchorConstraint: NSLayoutConstraint?

    private func setUpViews() {}

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func update() {
        leadingMargin = listDepth.margin

        listItemView?.removeFromSuperview()

        switch listDepth {
        case .indented:
            break
        case .unordered:
            let bulletSize: CGFloat = 6
            let bulletRect: NSRect = .init(
                x: floor(listDepth.margin - EditableBlockListDepth.indentWidth + 6),
                y: floor((lineButtonAlignmentHeight - bulletSize) / 2) + 2,
                width: bulletSize,
                height: bulletSize
            )

            let bulletView = NSBox(frame: bulletRect)
            bulletView.boxType = .custom
            bulletView.fillColor = NSColor.textColor.withAlphaComponent(0.8)
            bulletView.borderType = .noBorder
            bulletView.cornerRadius = bulletSize / 2
            addSubview(bulletView)

            listItemView = bulletView
        case .ordered(_, let index):
            let bulletSize: CGFloat = 14
            let bulletRect: NSRect = .init(
                x: floor(listDepth.margin - EditableBlockListDepth.indentWidth + 3),
                y: floor((lineButtonAlignmentHeight - bulletSize) / 2) + 2,
                width: EditableBlockListDepth.indentWidth,
                height: bulletSize
            )
            let string = String(describing: index) + "."
            let attributedString = TextStyle(weight: .bold, color: NSColor.textColor.withAlphaComponent(0.8)).apply(to: string)
            let bulletView = NSTextField(labelWithAttributedString: attributedString)
            bulletView.frame.origin = bulletRect.origin
            addSubview(bulletView)

            listItemView = bulletView
        }
    }

    public override var intrinsicContentSize: NSSize {
        guard let contentView = contentView else { return super.intrinsicContentSize }

        let contentSize = contentView.intrinsicContentSize

        return .init(width: contentSize.width + leadingMargin, height: contentSize.height + bottomMargin)
    }

    public override func invalidateIntrinsicContentSize() {
        contentView?.invalidateIntrinsicContentSize()

        super.invalidateIntrinsicContentSize()
    }
}


// MARK: - EditableBlock

public class EditableBlock: Equatable {
    public let id: UUID
    public let content: EditableBlockContent
    public let listDepth: EditableBlockListDepth

    public var bottomMargin: CGFloat {
        get { return wrapperView.bottomMargin }
        set {
            if newValue != wrapperView.bottomMargin {
                wrapperView.bottomMargin = newValue
            }
        }
    }

    public init(id: UUID, content: EditableBlockContent, listDepth: EditableBlockListDepth) {
        self.id = id
        self.content = content
        self.listDepth = listDepth

        wrapperView.listDepth = listDepth
        wrapperView.lineButtonAlignmentHeight = lineButtonAlignmentHeight
    }

    public convenience init(_ content: EditableBlockContent, _ listDepth: EditableBlockListDepth) {
        self.init(id: UUID(), content: content, listDepth: listDepth)
    }

    public var indented: EditableBlock {
        return .init(id: UUID(), content: content, listDepth: listDepth.indented)
    }

    public var outdented: EditableBlock {
        return .init(id: UUID(), content: content, listDepth: listDepth.outdented)
    }

    public static func == (lhs: EditableBlock, rhs: EditableBlock) -> Bool {
        return lhs.id == rhs.id && lhs.content == rhs.content
    }

    private func makeView() -> NSView {
        switch self.content {
        case .text:
            return TextBlockContainerView()
        case .page(title: let title, target: let target):
            return PageBlock(titleText: title, linkTarget: target)
        case .tokens(let syntaxNode):
            let view = LogicEditor(rootNode: syntaxNode, formattingOptions: .visual)
            view.fillColor = Colors.blockBackground
            view.cornerRadius = 4

            var style = view.canvasStyle
            style.textMargin = .init(width: 5, height: 6)
            view.canvasStyle = style

            view.scrollsVertically = false

            return view
        case .divider:
            return DividerBlock()
        case .image:
            let view = ImageBlock()

            view.image = EditableBlock.placeholderImage
            view.imageWidth = 100
            view.imageHeight = 100

            return view
        }
    }

    static var placeholderImage: NSImage = {
        let image = NSImage()
        image.size = .init(width: 100, height: 100)
        return image
    }()

    private func configure(view: NSView) {
        switch self.content {
        case .text(let attributedString, let sizeLevel):
            let view = view as! TextBlockContainerView
            view.textValue = attributedString
            view.sizeLevel = sizeLevel
            view.onRequestInvalidateIntrinsicContentSize = { [weak self] in
                self?.wrapperView.invalidateIntrinsicContentSize()
            }
        case .page(title: let title, target: let target):
            let view = view as! PageBlock
            view.title = title
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
                view.image = EditableBlock.placeholderImage
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

    public var wrapperView: EditableBlockView {
        if let wrapperView = EditableBlock.wrapperViewCache[id] { return wrapperView }

        let wrapperView = EditableBlockView()
        wrapperView.contentView = self.view
        EditableBlock.wrapperViewCache[id] = wrapperView
        return wrapperView
    }

    public func updateView() {
        configure(view: view)
        enqueueLayoutUpdate()
    }

    static var viewCache: [UUID: NSView] = [:]

    static var wrapperViewCache: [UUID: EditableBlockView] = [:]

    static var fetchImage: (URL) -> NSImage? = Memoize.all { url in
        guard let data = try? Data(contentsOf: url), let image = NSImage(data: data) else { return nil }
        return image
    }

//    deinit {
//        EditableBlock.viewCache.removeValue(forKey: id)
//    }

    public static func makeDefaultEmptyBlock() -> EditableBlock {
        return .init(.text(.init(), .paragraph), .none)
    }

    public func enqueueLayoutUpdate() {
        switch content {
        case .text:
            wrapperView.invalidateIntrinsicContentSize()
            wrapperView.needsLayout = true
        default:
            wrapperView.needsLayout = true
        }
    }

    public func focus() {
        if let view = view as? TextBlockContainerView {
            view.focus()
        } else if view.acceptsFirstResponder {
            view.window?.makeFirstResponder(view)
        }
    }

    public func updateViewWidth(_ width: CGFloat) {
        let width = width - listDepth.margin

        switch content {
        case .text:
            let view = self.view as! TextBlockContainerView
            view.width = width
        case .image(let url):
            let view = self.view as! ImageBlock
            if let _ = url {
                let imageSize = view.image.size
                if imageSize.width > width {
                    view.imageWidth = width
                    view.imageHeight = ceil(imageSize.height * (width / imageSize.width))
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
        case .tokens, .divider, .image, .page:
            return .empty
        case .text(let text, _):
            return .init(location: text.length, length: 0)
        }
    }

    public var isEmpty: Bool {
        switch content {
        case .tokens, .page:
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
        case .tokens, .divider, .image, .page:
            return false
        }
    }

    public var supportsMergingText: Bool {
        switch content {
        case .text:
            return true
        case .tokens, .divider, .image, .page:
            return false
        }
    }

    public var supportsDirectDragging: Bool {
        switch content {
        case .text, .tokens, .divider, .page:
            return false
        case .image:
            return true
        }
    }

    static func margin(_ a: EditableBlock, _ b: EditableBlock) -> CGFloat {
        switch (a.content, b.content) {
        case (.text(_, .h1), .text(_, .h2)),
             (.text(_, .h1), .text(_, .h3)):
            return 24
        case (.text(_, .h2), .text(_, .h3)):
            return 16
        case (.text(_, .h1), .text(_, .paragraph)),
             (.text(_, .h2), .text(_, .paragraph)),
             (.text(_, .h3), .text(_, .paragraph)):
            return 4
        case (.text(_, .paragraph), .text(_, .h1)),
             (.text(_, .quote), .text(_, .h1)),
             (.tokens(_), .text(_, .h1)),
             (.page(_), .text(_, .h1)):
            return 32
        case (.text(_, .paragraph), .text(_, .h2)),
             (.text(_, .quote), .text(_, .h2)),
             (.page(_), .text(_, .h2)),
             (.tokens(_), .text(_, .h2)),
             (.tokens(_), .text(_, .h3)),
             (.tokens(_), .text(_, .paragraph)):
            return 20
        case (.text(_, .paragraph), .text(_, .h3)),
             (.text(_, .quote), .text(_, .h3)),
             (.page(_), .text(_, .h3)):
            return 8
        case (.text(_, .paragraph), .text(_, .paragraph)),
             (.text(_, .quote), .text(_, .paragraph)),
             (.text(_, .paragraph), .text(_, .quote)),
             (.text(_, .quote), .text(_, .quote)):
            return 8
        default:
            return 0
        }
    }
}

extension EditableBlock: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch content {
        case .page(let value):
            return "page:\(value.title):\(value.target)"
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
    case page(title: String, target: String)

    var lineButtonAlignmentHeight: CGFloat {
        switch self {
        case .text(_, let sizeLevel):
            return sizeLevel.fontSize * TextBlockView.lineHeightMultiple
        case .page:
            return 30
        case .tokens, .image:
            return 18
        case .divider:
            return 21
        }
    }
}

public enum EditableBlockListDepth: Equatable {
    case indented(depth: Int)
    case unordered(depth: Int)
    case ordered(depth: Int, index: Int)

    public var kind: String {
        switch self {
        case .indented: return "indented"
        case .unordered: return "unordered"
        case .ordered: return "ordered"
        }
    }

    public var isList: Bool {
        switch self {
        case .indented: return false
        case .unordered, .ordered: return true
        }
    }

    public static var indentWidth: CGFloat = 20

    public static var none: EditableBlockListDepth = .indented(depth: 0)

    public static var `default`: EditableBlockListDepth = .none

    public func with(depth: Int) -> EditableBlockListDepth {
        if depth == 0 { return .indented(depth: 0) }

        switch self {
        case .indented(_): return .indented(depth: depth)
        case .unordered(_): return .unordered(depth: depth)
        case .ordered(_, index: let index): return .ordered(depth: depth, index: index)
        }
    }

    public var depth: Int {
        switch self {
        case .indented(depth: let depth): return depth
        case .unordered(depth: let depth): return depth
        case .ordered(depth: let depth, index: _): return depth
        }
    }

    public var indented: EditableBlockListDepth {
        switch self {
        case .indented(depth: let depth):
            return .indented(depth: depth + 1)
        case .unordered(depth: let depth):
            return .unordered(depth: depth + 1)
        case .ordered(depth: let depth, index: let index):
            return .ordered(depth: depth + 1, index: index)
        }
    }

    public var outdented: EditableBlockListDepth {
        switch self {
        case .indented(depth: let depth):
            return depth > 1 ? .indented(depth: depth - 1) : .none
        case .unordered(depth: let depth):
            return depth > 1 ? .unordered(depth: depth - 1) : .none
        case .ordered(depth: let depth, index: let index):
            return depth > 1 ? .ordered(depth: depth - 1, index: index) : .none
        }
    }

    public var margin: CGFloat {
        return CGFloat(depth) * EditableBlockListDepth.indentWidth
    }
}

// MARK: - Sequence

extension Array where Element == EditableBlock {
    public var topLevelDeclarations: LGCTopLevelDeclarations {
        let nodes: [LGCSyntaxNode] = self.compactMap {
            switch $0.content {
            case .tokens(let rootNode):
                return rootNode
            default:
                return nil
            }
        }

        let declarations: [LGCDeclaration] = nodes.compactMap {
            switch $0 {
            case .declaration(let declaration):
                return declaration
            default:
                return nil
            }
        }

        return LGCTopLevelDeclarations(id: UUID(), declarations: .init(declarations))
    }

    public func updateMargins() {
        zip(dropLast(), dropFirst()).forEach { a, b in
            let margin = EditableBlock.margin(a, b)
            a.bottomMargin = margin
        }
    }

    public func normalizeLists() -> [EditableBlock] {
        let normalizedBlocks = self.enumerated().map { (offset, block) -> BlockEditor.Block in
            var block = block

            let previousListDepth = offset > 0 ? self[offset - 1].listDepth : .none

            var updatedListDepth = block.listDepth

            if previousListDepth.depth < block.listDepth.depth {
                switch block.listDepth {
                case .indented:
                    updatedListDepth = .indented(depth: previousListDepth.depth)
                case .unordered:
                    updatedListDepth = .unordered(depth: previousListDepth.depth + 1)
                case .ordered:
                    updatedListDepth = .ordered(depth: previousListDepth.depth + 1, index: 1)
                }
            } else {
                switch block.listDepth {
                case .indented, .unordered:
                    break
                case .ordered(let depth, _):
                    var index: Int = 1
                    loop: for previousBlock in self[0..<offset].reversed() {
                        if previousBlock.listDepth.depth < depth { break }
                        if previousBlock.listDepth.depth == depth {
                            switch previousBlock.listDepth {
                            case .indented:
                                continue loop
                            case .unordered:
                                break loop
                            case .ordered(_, index: let previousIndex):
                                index = previousIndex + 1
                                break loop
                            }
                        }
                    }
                    updatedListDepth = .ordered(depth: depth, index: index)
                }
            }

            if updatedListDepth != block.listDepth {
                block = EditableBlock(id: block.id, content: block.content, listDepth: updatedListDepth)
            }

            return block
        }

        // Repeat until stable
        return self.map { $0.listDepth } != normalizedBlocks.map { $0.listDepth }
            ? normalizedBlocks.normalizeLists()
            : normalizedBlocks
    }
}
