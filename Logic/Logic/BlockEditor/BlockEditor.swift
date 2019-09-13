//
//  BlockEditor.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

private class BlockListView: NSView {

    override var isFlipped: Bool { return true }

    public init() {
        super.init(frame: .zero)
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var blocks: [BlockEditor.Block] = [] {
        didSet {
            if blocks != oldValue {
                update()
            }
        }
    }

    private var padding: NSEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)

    private func update() {
        subviews.forEach { $0.removeFromSuperview() }

        let blockViews: [NSView] = blocks.map { block in
            switch block {
            case .text(let value):
                let view = InlineBlockEditor(frame: .zero)
                view.textValue = value
                view.onChangeTextValue = { [unowned self] newValue in
                    view.textValue = newValue
//                    view.needsLayout = true
//                    view.invalidateIntrinsicContentSize()
                }

//                view

//                if let view = view as? NSTextView {
//                    view.textContainer?.widthTracksTextView = false
//                }

                return view
            }
        }

        let contentView = self

        if blockViews.count > 0 {
            for (offset, view) in blockViews.enumerated() {
                contentView.addSubview(view)

                view.translatesAutoresizingMaskIntoConstraints = false
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding.left).isActive = true
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding.right).isActive = true

                if offset == 0 {
                    view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding.top).isActive = true
                } else {
                    let margin: CGFloat = 8
                    view.topAnchor.constraint(equalTo: blockViews[offset - 1].bottomAnchor, constant: margin).isActive = true
                }

                if offset == blockViews.count - 1 {
                    view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding.bottom).isActive = true
                }
            }
        }
    }
}


// MARK: - BlockEditor

public class BlockEditor: NSBox {

    public enum Block: Equatable {
        case text(String)
    }

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

    public var parameters: Parameters {
        didSet {
            if parameters != oldValue {
                update()
            }
        }
    }

    // MARK: Private

    private let scrollView = NSScrollView()
    private let canvasView = BlockListView()

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero

        addSubview(scrollView)

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = canvasView
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        canvasView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor).isActive = true
        canvasView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor).isActive = true
        canvasView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor).isActive = true
    }

    private func update() {
        canvasView.blocks = blocks
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
