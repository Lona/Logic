//
//  BlockEditor.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
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
        }
    }

    public var view: NSView {
        if let view = EditableBlock.viewCache[id] {
            configure(view: view)
            return view
        }

        let view = makeView()
        configure(view: view)
        EditableBlock.viewCache[id] = view
        return view
    }

    public func updateView() {
        configure(view: view)
    }

    static var viewCache: [UUID: NSView] = [:]

//    deinit {
//        EditableBlock.viewCache.removeValue(forKey: id)
//    }

    public static func makeDefaultEmptyBlock() -> EditableBlock {
        return .init(.text(.init(), .paragraph))
    }

    public var lineButtonAlignmentHeight: CGFloat {
        return content.lineButtonAlignmentHeight
    }

    public var lastSelectionRange: NSRange {
        switch content {
        case .tokens:
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
        }
    }

    public var markdownString: String {
        switch content {
        case .text(let textValue, let sizeLevel):
            if let prefix = sizeLevel.prefix {
                return prefix + " " + textValue.markdownString() + "\n"
            } else {
                return textValue.markdownString() + "\n"
            }
        case .tokens(let rootNode):
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(rootNode) else { return "FAILED TO SERIALIZE TOKENS" }
            guard let xml = LogicFile.convert(data, kind: .logic, to: .xml) else { return "FAILED TO CONVERT TOKENS TO XML" }
            let code = String(data: xml, encoding: .utf8)!

            return "```tokens\n\(code)\n```"
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
        }
    }
}

public enum EditableBlockContent: Equatable {
    case text(NSAttributedString, TextBlockView.SizeLevel)
    case tokens(LGCSyntaxNode)

    var lineButtonAlignmentHeight: CGFloat {
        switch self {
        case .text(_, let sizeLevel):
            return sizeLevel.fontSize * TextBlockView.lineHeightMultiple
        case .tokens:
            return 18
        }
    }
}

// MARK: - BlockEditor

public class BlockEditor: NSBox {

    public typealias Block = EditableBlock

    // MARK: Lifecycle

    public init(_ parameters: Parameters) {
        self.parameters = parameters

        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()
    }

    public convenience init() {
        self.init(Parameters())
    }

    public required init?(coder aDecoder: NSCoder) {
        self.parameters = Parameters()

        super.init(coder: aDecoder)

        setUpViews()
        setUpConstraints()

        update()
    }

    // MARK: Public

    public var blocks: [Block] = [] {
        didSet {
            if blocks != oldValue {
                update()
            }
        }
    }

    public var onChangeBlocks: (([Block]) -> Bool)? {
        get { return blockListView.onChangeBlocks }
        set { blockListView.onChangeBlocks = newValue }
    }

    public var parameters: Parameters {
        didSet {
            if parameters != oldValue {
                update()
            }
        }
    }

    // MARK: Private

    private let blockListView = BlockListView()

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero

        addSubview(blockListView)
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        blockListView.translatesAutoresizingMaskIntoConstraints = false

        blockListView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        blockListView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        blockListView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        blockListView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    private func update() {
        blockListView.blocks = blocks
    }
}

// MARK: - Parameters

extension BlockEditor {
    public struct Parameters: Equatable {
        public init() {}
    }
}

// MARK: - Model

extension BlockEditor {
    public struct Model: LonaViewModel, Equatable {
        public var id: String?
        public var parameters: Parameters
        public var type: String {
            return "BlockEditor"
        }

        public init(id: String? = nil, parameters: Parameters) {
            self.id = id
            self.parameters = parameters
        }

        public init(_ parameters: Parameters) {
            self.parameters = parameters
        }

        public init() {
            self.init(Parameters())
        }
    }
}

extension Sequence where Iterator.Element: EditableBlock {
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
}
