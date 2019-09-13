//
//  BlockListView.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit
import Differ

private extension NSTableColumn {
    convenience init(
        title: String,
        resizingMask: ResizingOptions = .autoresizingMask,
        width: CGFloat? = nil,
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil) {
        self.init(identifier: NSUserInterfaceItemIdentifier(rawValue: title))
        self.title = title
        self.resizingMask = resizingMask

        if let width = width {
            self.width = width
        }

        if let minWidth = minWidth {
            self.minWidth = minWidth
        }

        if let maxWidth = maxWidth {
            self.maxWidth = maxWidth
        }
    }
}

// MARK: - BlockListView

public class BlockListView: NSBox {

    enum Action {
        case focus(id: UUID)
    }

    // MARK: Lifecycle

    public init() {
        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()

        addTrackingArea(trackingArea)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUpViews()
        setUpConstraints()

        update()

        addTrackingArea(trackingArea)
    }

    private lazy var trackingArea = NSTrackingArea(
        rect: self.frame,
        options: [.mouseEnteredAndExited, .activeInActiveApp, .mouseMoved, .inVisibleRect],
        owner: self)

    deinit {
        removeTrackingArea(trackingArea)
    }

    // MARK: Public

    private func showToolTip(string: String, at point: NSPoint) {
        guard let window = window else { return }
        let windowPoint = convert(point, to: nil)
        let screenPoint = window.convertPoint(toScreen: windowPoint)

        if window.isKeyWindow {
            TooltipManager.shared.showTooltip(string: string, point: screenPoint, delay: .milliseconds(120))
        }
    }

    public var plusButtonTooltip: String = "**Click** _to add below_"
    public var moreButtonTooltip: String = "**Drag** _to move_\n**Click** _to open menu_"

    public override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let row = tableView.row(at: .init(x: 60, y: convert(point, from: tableView).y))

        if row >= 0 {
            hoveredLine = row
        } else {
            hoveredLine = nil
        }

        if let hoveredLine = hoveredLine {
            let plusRect = plusButtonRect(for: hoveredLine)
            hoveredPlusButton = plusRect.contains(point)

            if hoveredPlusButton {
                showToolTip(
                    string: plusButtonTooltip,
                    at: NSPoint(x: plusRect.midX, y: plusRect.minY - 4)
                )
            }

            let moreRect = moreButtonRect(for: hoveredLine)
            hoveredMoreButton = moreRect.contains(point)

            if hoveredMoreButton {
                showToolTip(
                    string: moreButtonTooltip,
                    at: NSPoint(x: moreRect.midX, y: moreRect.minY - 4)
                )
            }
        } else {
            hoveredPlusButton = false
            hoveredMoreButton = false
        }

        if !hoveredPlusButton && !hoveredMoreButton {
            TooltipManager.shared.hideTooltip()
        }
    }

    private func handlePressPlus(line: Int) {
        TooltipManager.shared.hideTooltip()

        if blocks[line].content == .text(.init()) {
            focus(line: line)
            return
        }

        handleAddBlock(line: line, text: .init())
    }

    private func handleAddBlock(line: Int, text: NSAttributedString) {
        var clone = blocks

        let id = UUID()
        let emptyBlock: EditableBlock = .init(id: id, content: .text(text))
        clone.insert(emptyBlock, at: line + 1)
        actions.append(.focus(id: id))

        onChangeBlocks?(clone)
    }

    private func handleDelete(line: Int) {
        var clone = self.blocks
        clone.remove(at: line)

        self.onChangeBlocks?(clone)

        let id = blocks[line > 0 ? line - 1 : line].id
        actions.append(.focus(id: id))
    }

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if let hoveredLine = hoveredLine {
            if plusButtonRect(for: hoveredLine).contains(point) {
                handlePressPlus(line: hoveredLine)
            }

            if moreButtonRect(for: hoveredLine).contains(point) {
                Swift.print("Clicked more")
            }
        }
    }

    public var blocks: [BlockEditor.Block] = [] {
        didSet {
            let diff = oldValue.extendedDiff(blocks, isEqual: { a, b in a.id == b.id })

            if diff.isEmpty {
                for index in 0..<blocks.count {
                    let old = oldValue[index]
                    let new = blocks[index]

                    if old !== new {
                        Swift.print("update", index)
                        if let view = tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? InlineBlockEditor,
                            case .text(let value) = new.content {
                            view.textValue = value
                        }
                    }
                }
            } else {
                tableView.animateRowChanges(oldData: oldValue, newData: blocks)

//                if diff.count == 1, let firstInserted = diff.elements.first(where: { element in
//                    switch element {
//                    case .insert:
//                        return true
//                    default:
//                        return false
//                    }
//                }), case .insert(let index) = firstInserted {
////                    Swift.print("index", index)
//                    let view = tableView.view(atColumn: 0, row: index, makeIfNecessary: true)
//                    window?.makeFirstResponder(view)
//                }
            }

            actions.forEach { action in
                switch action {
                case .focus(id: let id):
                    guard let index = blocks.firstIndex(where: { $0.id == id }) else { return }

                    Swift.print("Focus", index)

                    focus(line: index)
                }
            }

            actions = []
        }
    }

    var actions: [Action] = []

    public var onChangeBlocks: (([BlockEditor.Block]) -> Void)?

    // MARK: Private

    private var tableView = BlockListTableView()
    private let scrollView = NSScrollView()
    private let tableColumn = NSTableColumn(title: "Suggestions", minWidth: 100)

    private var focusedLine: Int?

    private var hoveredLine: Int? {
        didSet {
            if oldValue != hoveredLine {
                needsDisplay = true
//                if let row = hoveredLine {
//                    toolbarView.isHidden = false
//
//                    let rect = convert(tableView.rect(ofRow: row), from: tableView)
//                    toolbarView.frame.origin = .init(x: 20, y: rect.minY)
//                } else {
//                    toolbarView.isHidden = true
//                }
            }
        }
    }

    private func focus(line index: Int) {
        let view = tableView.view(atColumn: 0, row: index, makeIfNecessary: true)

        guard let window = window else { return }

        if let editable = view as? FieldEditable {
            if window.firstResponder != view && !editable.isFieldEditorFirstResponder {
                window.makeFirstResponder(view)
            }
        }
    }

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero
        fillColor = Colors.suggestionListBackground

        tableView.usesAutomaticRowHeights = true
        tableView.addTableColumn(tableColumn)
        tableView.intercellSpacing = NSSize.zero
        tableView.headerView = nil
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .none

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = tableView

        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = .init(top: 20, left: 60, bottom: 20, right: 60)
        scrollView.scrollerInsets = .init(top: -20, left: -60, bottom: -20, right: -60)

        addSubview(scrollView)

        tableView.reloadData()
        tableView.sizeToFit()

        tableView.intercellSpacing = .init(width: 0, height: 6)
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    private func update() {


//        blocks.forEach { block in
//            block.updateView()
//        }

//        tableView.reloadData()
//        tableView.sizeToFit()
    }

    override public var acceptsFirstResponder: Bool {
        return false
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let hoveredLine = hoveredLine {
            let rect = plusButtonRect(for: hoveredLine)
            let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

            if hoveredPlusButton {
                Colors.divider.set()
                backgroundPath.fill()
            }

            let path = NSBezierPath(plusWithin: rect, lineWidth: 1, margin: .init(width: 3, height: 3))
            Colors.textComment.setStroke()
            path.stroke()
        }

        if let hoveredLine = hoveredLine {
            let rect = moreButtonRect(for: hoveredLine)
            let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

            if hoveredMoreButton {
                Colors.divider.set()
                backgroundPath.fill()
            }

            let path = NSBezierPath(hamburgerWithin: rect, thickness: 1, margin: .init(width: 4, height: 5))
            Colors.textComment.setStroke()
            path.stroke()
        }
    }

    public let lineButtonSize = NSSize(width: 19, height: 19)
    public let lineButtonMargin: CGFloat = 2

    private var hoveredPlusButton: Bool = false {
        didSet {
            if oldValue != hoveredPlusButton {
                needsDisplay = true
//                update()
            }
        }
    }

    private var hoveredMoreButton: Bool = false {
        didSet {
            if oldValue != hoveredMoreButton {
                needsDisplay = true
//                update()
            }
        }
    }

    private func plusButtonRect(for line: Int) -> CGRect {
        let rowRect = convert(tableView.rect(ofRow: line), from: tableView)

        let rect = NSRect(
            x: 60 - lineButtonSize.width - lineButtonMargin,
            y: rowRect.maxY - lineButtonSize.height - 4,
            width: lineButtonSize.width,
            height: lineButtonSize.height)

        return rect
    }

    private func moreButtonRect(for line: Int) -> CGRect {
        let rowRect = convert(tableView.rect(ofRow: line), from: tableView)

        let rect = NSRect(
            x: 60 - lineButtonSize.width * 2 - lineButtonMargin * 2,
            y: rowRect.maxY - lineButtonSize.height - 4,
            width: lineButtonSize.width,
            height: lineButtonSize.height)

        return rect
    }

    public static var commandPalette: SuggestionWindow = {
        let suggestionWindow = SuggestionWindow()

        suggestionWindow.onRequestHide = {
            suggestionWindow.orderOut(nil)
        }

        return suggestionWindow
    }()
}

// MARK: - Delegate

extension BlockListView: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = blocks[row]

        switch item.content {
        case .text(let value):
            let view = item.view as! InlineBlockEditor

            Swift.print("Row", row, view)

            view.textValue = value
            view.onChangeTextValue = { [unowned self] newValue in
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                var clone = self.blocks
                clone[row] = .init(id: item.id, content: .text(newValue))

                self.onChangeBlocks?(clone)

////                self.actions.append(.focus(id: item.id))
//
//                view.textValue = newValue
//                self.tableView.noteHeightOfRows(withIndexesChanged: .init(integer: row))
            }

            view.onRequestCreateEditor = { [unowned self] newText in
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                self.handleAddBlock(line: line, text: newText)
            }

            view.onRequestDeleteEditor = { [unowned self] in
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                self.handleDelete(line: line)
            }

            view.onSearchCommandPalette = { [unowned self] query, rect in
                guard let window = self.window else { return }

                window.addChildWindow(BlockListView.commandPalette, ordered: .above)

                BlockListView.commandPalette.anchorTo(rect: rect)
            }

            view.onHideCommandPalette = {
                BlockListView.commandPalette.orderOut(nil)
            }

//            view.onFocus = { [unowned self] in
//                let row = self.tableView.row(for: view)
//                self.focusedLine = row
//            }

            return view
        }
    }
}

// MARK: - Data source

extension BlockListView: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return blocks.count
    }

//    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//        let item = blocks[row]
//
//        switch item.content {
//        case .text(let value):
//            return value.measure(width: tableView.bounds.width).height
//        }
//    }
}

// MARK: - BlockListTableView

class BlockListTableView: NSTableView {
    override var acceptsFirstResponder: Bool {
        return false
    }

    // Allows clicking into NSTextFields directly (otherwise the NSTableView captures the first click)
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return true
    }
}
