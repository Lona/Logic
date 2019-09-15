//
//  BlockListView.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit
import Differ

private enum BlockListSelection: Equatable {
    case none
    case item(Int, NSRange)
    case blocks(NSRange)
}

private enum BlockListItem: Equatable {
    case background
    case moreButton(Int)
    case plusButton(Int)
    case item(Int, NSPoint)
}

extension NSRange {
    public init(between a: Int, and b: Int) {
        self = .init(location: min(a, b), length: abs(a - b))
    }

    public static var empty: NSRange = .init(location: 0, length: 0)
}

private extension NSPoint {
    func distance(to: NSPoint) -> CGFloat {
        return sqrt((x - to.x) * (x - to.x) + (y - to.y) * (y - to.y))
    }
}

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

public class BlockListRowView: NSTableRowView {
    public var isBlockSelected: Bool = false {
        didSet {
            if oldValue != isBlockSelected {
                needsDisplay = true
            }
        }
    }

    public override func drawBackground(in dirtyRect: NSRect) {
        if isBlockSelected {
            NSColor.selectedTextBackgroundColor.setFill()
            dirtyRect.fill()
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

    private func handlePressPlus(line: Int) {
        TooltipManager.shared.hideTooltip()

        if blocks[line].content == .text(.init()) {
            focus(line: line)
            return
        }

        handleAddBlock(line: line, text: .init())
    }

    private func handleAddBlock(line: Int, block: EditableBlock) {
        var clone = blocks

        clone.insert(block, at: line + 1)
        actions.append(.focus(id: block.id))

        onChangeBlocks?(clone)
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

        let id = blocks[line > 0 ? line - 1 : line].id

        actions.append(.focus(id: id))

        self.onChangeBlocks?(clone)
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
                            view.needsLayout = true
                            view.needsDisplay = true
                        }
                    }
                }
            } else {
                tableView.animateRowChanges(
                    oldData: oldValue,
                    newData: blocks
//                    deletionAnimation: .effectFade,
//                    insertionAnimation: .effectFade
                )

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

    private var selection: BlockListSelection = .none {
        didSet {
            switch oldValue {
            case .none:
                break
            case .item(let row, _):
                let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true)

                if let view = view as? InlineBlockEditor {
                    view.setSelectedRangesWithoutNotification([NSValue(range: .empty)])
                    view.needsDisplay = true
                    view.setPlaceholder(string: " ")
                }
            case .blocks(let range):
                for index in range.lowerBound...range.upperBound {
                    let rowView = tableView.rowView(atRow: index, makeIfNecessary: false) as? BlockListRowView
                    rowView?.isBlockSelected = false
                }
            }

            switch selection {
            case .none:
                break
            case .item(let row, let range):
                let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true)

                if let view = view as? InlineBlockEditor {
                    view.setSelectedRangesWithoutNotification([NSValue(range: range)])
//                    view.needsDisplay = true
                    view.setPlaceholder(string: "Type '/' for commands")
                }
            case .blocks(let range):
                for index in range.lowerBound...range.upperBound {
                    let rowView = tableView.rowView(atRow: index, makeIfNecessary: false) as? BlockListRowView
                    rowView?.isBlockSelected = true
                }
            }
        }
    }

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
        selection = .item(index, .empty)

        guard let window = window else { return }

        switch selection {
        case .item(let row, _):
            let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true)!

            if view.acceptsFirstResponder {
                window.makeFirstResponder(view)
            }
        default:
            break
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
        return true
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

    // MARK: Event handling

    public override func hitTest(_ point: NSPoint) -> NSView? {
        if bounds.contains(point) {
            return self
        }

        return nil
    }

    public override func mouseDown(with event: NSEvent) {
//        Swift.print("mouseDown")

        BlockListView.commandPalette.orderOut(nil)
        InlineToolbarWindow.shared.orderOut(nil)

        let point = convert(event.locationInWindow, from: nil)

        trackMouse(startingAt: point)
    }

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

//    public override func hitTest(_ point: NSPoint) -> NSView? {
//        if bounds.contains(point) {
//            trackMouse(startingAt: point)
//            return self
//        }
//
//        return nil
//    }

    public func trackMouse(startingAt initialPosition: NSPoint) {
//        Swift.print("Start tracking")

        guard let window = window else { return }

        var isDragging: Bool = false
        var initialRow: Int? = nil
        var initialIndex: Int? = nil
        var didChangeInsertionColor = false

        trackingLoop: while true {
            let event = window.nextEvent(matching: [.leftMouseUp, .leftMouseDragged])!
            let position = convert(event.locationInWindow, from: nil)

            switch event.type {
            case .leftMouseDragged:
                let row = tableView.row(at: convert(position, to: tableView))

                if row >= 0 {
                    let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true)

                    if let initialRow = initialRow, initialRow != row {
                        selection = .blocks(NSRange(between: row, and: initialRow))
                    } else {
                        initialRow = row

                        if let view = view as? InlineBlockEditor {
                            let characterIndex = view.characterIndexForInsertion(at: convert(position, to: view))
                            
                            if let initialIndex = initialIndex {
                                selection = .item(row, NSRange(between: initialIndex, and: characterIndex))
                            } else {
                                initialIndex = characterIndex
                                selection = .item(row, NSRange(location: characterIndex, length: 0))
                            }

                            if view.acceptsFirstResponder {
                                window.makeFirstResponder(view)
                                view.insertionPointColor = .clear
                                didChangeInsertionColor = true
                            }
                        }
                    }
                }

                if initialPosition.distance(to: position) > 5 {
                    isDragging = true
                }
            case .leftMouseUp:
                if !isDragging {
                    handleMouseClick(point: position)
                }

                switch selection {
                case .item(let row, let range):
                    let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true)!

                    if view.acceptsFirstResponder {
                        window.makeFirstResponder(view)
                    }

                    if range.length > 0 {
                        (view as? InlineBlockEditor)?.showInlineToolbar(for: range)
                    }
                default:
                    window.makeFirstResponder(self)
                }

                break trackingLoop
            default:
                break
            }
        }

        if didChangeInsertionColor, let row = initialRow {
            let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true)

            if let view = view as? InlineBlockEditor {
                view.insertionPointColor = NSColor.textColor
            }
        }

//        Swift.print("Done tracking")
    }

    public func handleMouseClick(point: NSPoint) {
        selection = .none

        BlockListView.commandPalette.orderOut(nil)

        switch item(at: point) {
        case .plusButton(let line):
            handlePressPlus(line: line)
        case .moreButton(_):
            break
        case .item(let line, let point):
            let view = tableView.view(atColumn: 0, row: line, makeIfNecessary: false)

            if let view = view as? InlineBlockEditor {
                let characterIndex = view.characterIndexForInsertion(at: convert(point, to: view))
                selection = .item(line, NSRange(location: characterIndex, length: 0))

                if view.acceptsFirstResponder {
                    window?.makeFirstResponder(view)
                }
            } else if let view = view as? LogicEditor {
                view.canvasView.handlePress(locationInWindow: point)
            }
        case .background:
            break
        }
    }

    private func item(at point: NSPoint) -> BlockListItem {
        if let hoveredLine = hoveredLine {
            if plusButtonRect(for: hoveredLine).contains(point) {
                return .plusButton(hoveredLine)
            }

            if moreButtonRect(for: hoveredLine).contains(point) {
                return .moreButton(hoveredLine)
            }
        }

        let row = tableView.row(at: convert(point, to: tableView))

        if row >= 0 {
            return .item(row, point)
        } else {
            return .background
        }
    }
}

// MARK: - Delegate

extension BlockListView: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = BlockListRowView()

//        rowView.isBlockSelected = row == 0

        return rowView
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = blocks[row]

        switch item.content {
        case .tokens(let syntaxNode):
            let view = item.view as! LogicEditor

            return view
        case .text(let value):
            let view = item.view as! InlineBlockEditor

//            Swift.print("Row", row, view)

            view.textValue = value
            view.onChangeTextValue = { [unowned self] newValue in
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                var clone = self.blocks
                clone[row] = .init(id: item.id, content: .text(newValue))

                self.onChangeBlocks?(clone)
            }

            view.onChangeSelectedRange = { [unowned self] range in
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                self.selection = .item(row, range)

                if let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true) as? InlineBlockEditor {
                    if range.length > 0 {
                        view.showInlineToolbar(for: range)
                    } else {
                        InlineToolbarWindow.shared.orderOut(nil)
                    }
                }
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
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                self.showCommandPalette(line: line, query: query, rect: rect)
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

    func showCommandPalette(line: Int, query: String, rect: NSRect) {
        guard let window = self.window else { return }

        let subwindow = BlockListView.commandPalette

        let suggestionItems: [SuggestionListItem] = [
            .sectionHeader("COMMANDS"),
            .row("Text", "Write plain text", false, nil),
            .row("Token", "Define a design token variable", false, nil)
        ]

        let suggestionListHeight = suggestionItems.map { $0.height }.reduce(0, +)

        subwindow.defaultWindowSize = .init(width: 200, height: min(suggestionListHeight + 32 + 25, 400))
        subwindow.suggestionView.showsSuggestionDetails = false
        subwindow.suggestionView.suggestionListWidth = 200
        subwindow.suggestionText = ""
        subwindow.placeholderText = "Filter actions"

        subwindow.anchorTo(rect: rect, verticalOffset: 4)
        subwindow.suggestionItems = suggestionItems

        func filteredSuggestionItems(query text: String) -> [(Int, SuggestionListItem)] {
            return suggestionItems.enumerated().filter { offset, item in
                if text.isEmpty { return true }

                switch item {
                case .sectionHeader:
                    return true
                case .row(let title, _, _, _),
                     .colorRow(name: let title, _, _, _),
                     .textStyleRow(let title, _, _):
                    return title.lowercased().contains(text.lowercased())
                }
            }
        }

        subwindow.onChangeSuggestionText = { [unowned subwindow] text in
            subwindow.suggestionText = text
            subwindow.suggestionItems = filteredSuggestionItems(query: text).map { offset, item in item }
            subwindow.selectedIndex = filteredSuggestionItems(query: text).firstIndex(where: { offset, item in item.isSelectable })
        }
        subwindow.onSelectIndex = { [unowned subwindow] index in
            subwindow.selectedIndex = index
        }

        window.addChildWindow(subwindow, ordered: .above)
        subwindow.focusSearchField()

        let hideWindow = { [unowned self] in
            subwindow.orderOut(nil)
        }

        subwindow.onPressEscapeKey = hideWindow
        subwindow.onRequestHide = hideWindow

        subwindow.onSubmit = { [unowned self] index in
            let originalIndex = filteredSuggestionItems(query: subwindow.suggestionText).map { offset, item in offset }[index]
//            let item = menu[originalIndex]
//            item.action()

            hideWindow()

            Swift.print("choose item", originalIndex)

            if originalIndex == 1 {
                self.handleAddBlock(line: line, text: .init())
            } else if originalIndex == 2 {
                let defaultTokens = LGCSyntaxNode.declaration(
                    .variable(
                        id: UUID(),
                        name: .init(id: UUID(), name: "token"),
                        annotation: .typeIdentifier(id: UUID(), identifier: .init(id: UUID(), string: "Color"), genericArguments: .empty),
                        initializer: .identifierExpression(id: UUID(), identifier: .init(id: UUID(), string: "placeholder", isPlaceholder: true)),
                        comment: nil
                    )
                )

                self.handleAddBlock(line: line, block: .init(.tokens(defaultTokens)))
            }

//            self.update()
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
