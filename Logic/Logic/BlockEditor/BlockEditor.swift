//
//  BlockEditor.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

//private func makeView() -> NSView {
//    switch self.content {
//    case .text:
//        return InlineBlockEditor()
//    case .tokens(let syntaxNode):
//        let view = LogicEditor(rootNode: syntaxNode, formattingOptions: .visual)
//
//        var style = view.canvasStyle
//        style.textMargin = .zero
//        view.canvasStyle = style
//
//        view.scrollsVertically = false
//        view.showsMinimap = false
//        view.showsLineButtons = false
//        return view
//    }
//}

// MARK: - BlockEditor

public class BlockEditor: NSBox {

    public typealias Block = BlockType

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

    public var onChangeBlocks: (([Block]) -> Void)? {
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
