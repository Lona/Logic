//
//  BlockEditor.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

// MARK: - BlockEditor

open class BlockEditor: NSBox {

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

    public var onClickLink: ((String) -> Bool)? {
        get { return blockListView.onClickLink }
        set { blockListView.onClickLink = newValue }
    }

    public var onClickPageLink: ((String) -> Bool)? {
        get { return blockListView.onClickPageLink }
        set { blockListView.onClickPageLink = newValue }
    }

    /**
     Transform an image URL before fetching it.

     Use this to transform a local file path into a `file://` URL.
     */
    public var transformImageURL: ((URL) -> URL)? {
        get { return blockListView.transformImageURL }
        set { blockListView.transformImageURL = newValue }
    }

    public var onRequestCreatePage: ((Int, Bool) -> Void)? {
        get { return blockListView.onRequestCreatePage }
        set { blockListView.onRequestCreatePage = newValue }
    }

    public var parameters: Parameters {
        didSet {
            if parameters != oldValue {
                update()
            }
        }
    }

    public var onChangeSelection: ((BlockListSelection) -> Void)? {
        get { blockListView.onChangeSelection }
        set { blockListView.onChangeSelection = newValue }
    }

    public var onChangeVisibleRows: ((Range<Int>) -> Void)? {
        get { blockListView.onChangeVisibleBlocks }
        set { blockListView.onChangeVisibleBlocks = newValue }
    }

    public var showsMinimap: Bool {
        get { blockListView.showsMinimap }
        set { blockListView.showsMinimap = newValue }
    }

    public var floatingMinimap: Bool {
        get { blockListView.floatingMinimap }
        set { blockListView.floatingMinimap = newValue }
    }

    public func select(id: UUID) {
        blockListView.select(id: id)
    }

    public func view(for block: EditableBlock) -> NSView {
        return blockListView.getView(block)
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

extension BlockEditor {

    // The block editor supports drag and drop, so we don't allow dragging the window.
    // We could potentially handle this more granularly if needed.
    open override var mouseDownCanMoveWindow: Bool {
        return false
    }
}
