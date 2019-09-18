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
    case blocks(NSRange, anchor: Int)

    static func blocks(_ range: NSRange) -> BlockListSelection {
        return .blocks(range, anchor: range.location)
    }
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

    public static func merge(ranges: [NSRange]) -> NSRange {
        if ranges.isEmpty { fatalError("Cannot merge 0 ranges") }

        let location = ranges.map { $0.location }.min()!
        let length = ranges.map { $0.upperBound }.max()! - location

        return .init(location: location, length: length)
    }

    func removing(range: NSRange) -> NSRange {
        return .init(location: lowerBound, length: max(0, range.lowerBound - lowerBound))
    }
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

    open func handleChangeBlocks(_ blocks: [BlockEditor.Block]) -> Bool {
        return onChangeBlocks?(blocks) ?? false
    }

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

    private func handlePressMore(line: Int) {
        TooltipManager.shared.hideTooltip()

        selection = .blocks(NSRange(location: line, length: 1))
    }

    private func handlePressPlus(line: Int) {
        TooltipManager.shared.hideTooltip()

        if blocks[line].content == .text(.init(), .paragraph) {
            focus(line: line)
            return
        }

        let id = UUID()
        let ok = handleAddBlock(line: line, block: .init(id: id, content: .text(.init(), .paragraph)))

        if ok, let addedLine = self.line(forBlock: id) {
            guard let window = window else { return }
            let rect = window.convertToScreen(tableView.convert(tableView.rect(ofRow: addedLine), to: nil))

            commandPaletteAnchor = (addedLine, 0, rect)
            showCommandPalette(line: addedLine, query: "", rect: rect)
        }
    }

    private func handleAddBlock(line: Int, block: EditableBlock) -> Bool {
        var clone = blocks

        clone.insert(block, at: line + 1)

        let ok = handleChangeBlocks(clone)

        if ok {
            focus(id: block.id)
        }

        return ok
    }

    private func handleDelete(line: Int) {
        if blocks.count <= 1 { return }

        var clone = self.blocks
        clone.remove(at: line)

        let id = clone[line > 0 ? line - 1 : line].id

        if handleChangeBlocks(clone) {
            focus(id: id)
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
//                        Swift.print("update", index)
                        let view = tableView.view(atColumn: 0, row: index, makeIfNecessary: false)

                        if let view = view as? InlineBlockEditor, case .text(let attributedString, let sizeLevel) = new.content {
                            view.textValue = attributedString
                            view.sizeLevel = sizeLevel
                            view.needsLayout = true
                            view.needsDisplay = true
                        } else if let view = view as? LogicEditor, case .tokens(let rootNode) = new.content {
                            view.rootNode = rootNode
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

            needsDisplay = true
        }
    }

    public var onChangeBlocks: (([BlockEditor.Block]) -> Bool)?

    // MARK: Private

    private var selection: BlockListSelection = .none {
        didSet {
            switch oldValue {
            case .none:
                break
            case .item(let row, _):
                if row >= blocks.count { return }

                let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true)

                if let view = view as? InlineBlockEditor {
                    view.setSelectedRangesWithoutNotification([NSValue(range: .empty)])
                    view.needsDisplay = true
                    view.setPlaceholder(string: " ")
                }
            case .blocks(let range, _):
                for index in range.lowerBound..<range.upperBound {
                    let rowView = tableView.rowView(atRow: index, makeIfNecessary: false) as? BlockListRowView
                    rowView?.isBlockSelected = false
                }
            }

            switch selection {
            case .none:
                break
            case .item(let row, let range):
                if row >= blocks.count { return }

                let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true)

                if let view = view as? InlineBlockEditor {
                    view.setSelectedRangesWithoutNotification([NSValue(range: range)])
//                    view.needsDisplay = true
                    view.setPlaceholder(string: "Type '/' for commands")
                }
            case .blocks(let range, _):
                for index in range.lowerBound..<range.upperBound {
                    let rowView = tableView.rowView(atRow: index, makeIfNecessary: false) as? BlockListRowView
                    rowView?.isBlockSelected = true
                }
            }
        }
    }

    private var tableView = BlockListTableView()
    private let scrollView = NSScrollView()
    private let tableColumn = NSTableColumn(title: "Suggestions", minWidth: 100)

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

    private func line(forBlock id: UUID) -> Int? {
        return blocks.firstIndex(where: { $0.id == id })
    }

    private func focus(id: UUID) {
        guard let line = line(forBlock: id) else { return }

        focus(line: line)
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

        if let hoveredLine = hoveredLine, hoveredLine < blocks.count {
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

        if let hoveredLine = hoveredLine, hoveredLine < blocks.count {
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

        let alignmentHeight = blocks[line].lineButtonAlignmentHeight

        let rect = NSRect(
            x: 60 - lineButtonSize.width - lineButtonMargin,
            y: floor(rowRect.maxY - alignmentHeight + (alignmentHeight - lineButtonSize.height) / 2 - 4),
            width: lineButtonSize.width,
            height: lineButtonSize.height)

        return rect
    }

    private func moreButtonRect(for line: Int) -> CGRect {
        let rowRect = convert(tableView.rect(ofRow: line), from: tableView)

        let alignmentHeight = blocks[line].lineButtonAlignmentHeight

        let rect = NSRect(
            x: 60 - lineButtonSize.width * 2 - lineButtonMargin * 2,
            y: floor(rowRect.maxY - alignmentHeight + (alignmentHeight - lineButtonSize.height) / 2 - 4),
            width: lineButtonSize.width,
            height: lineButtonSize.height)

        return rect
    }

    private var commandPaletteAnchor: (line: Int, character: Int, rect: NSRect)?

    public static var commandPaletteVisible: Bool = false

    public static var commandPalette: SuggestionWindow = {
        let suggestionWindow = SuggestionWindow()

        suggestionWindow.showsSearchBar = false
        suggestionWindow.showsSuggestionDetails = false

        return suggestionWindow
    }()

    // MARK: Event handling

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override func keyDown(with event: NSEvent) {
        let isShiftEnabled = event.modifierFlags.contains(NSEvent.ModifierFlags.shift)
//        let isCommandEnabled = event.modifierFlags.contains(NSEvent.ModifierFlags.command)

//        switch (event.characters) {
//        case "d" where isShiftEnabled && isCommandEnabled:
//            onDuplicateCommand?()
//        default:
//            break
//        }

        switch Int(event.keyCode) {
        case 36: // Enter
            break
        case 48: // Tab
            break
        case 51: // Delete
            switch selection {
            case .blocks(let range, _):
                let newBlocks: [BlockEditor.Block] = Array(blocks[0..<range.location] + blocks[range.location+range.length..<blocks.count])

                selection = .blocks(.init(location: range.location, length: 0), anchor: range.location)

                _ = handleChangeBlocks(newBlocks)
            default:
                break
            }
        case 123: // Left
            fallthrough
        case 126: // Up
            switch selection {
            case .blocks(let range, let anchor):
                let newRange = NSRange(location: max(0, range.location - 1), length: 1)

                if isShiftEnabled {
                    if anchor > range.lowerBound {
                        selection = .blocks(.init(location: range.location, length: range.length - 1), anchor: anchor - 1)
                    } else {
                        selection = .blocks(.merge(ranges: [range, newRange]), anchor: newRange.location)
                    }
                } else {
                    selection = .blocks(newRange)
                }
            default:
                break
            }
        case 124: // Right
            fallthrough
        case 125: // Down
            switch selection {
            case .blocks(let range, let anchor):
                let newRange = NSRange(location: min(blocks.count - 1, range.upperBound), length: 1)

                if isShiftEnabled {
                    if anchor < range.upperBound - 1 {
                        selection = .blocks(.init(location: range.location + 1, length: range.length - 1), anchor: anchor + 1)
                    } else {
                        selection = .blocks(.merge(ranges: [range, newRange]), anchor: newRange.location)
                    }
                } else {
                    selection = .blocks(newRange, anchor: newRange.location)
                }
            default:
                break
            }
        default:
            break
        }
    }

//    public override func keyDown(with event: NSEvent) {
//        let characters = event.charactersIgnoringModifiers!
//
//        if characters == String(Character(UnicodeScalar(NSEvent.SpecialKey.delete.rawValue)!)) {
//            switch selection {
//            case .blocks(let range):
//                Swift.print("delete selection", range)
//                Swift.print("keeping", 0..<range.location, range.location+range.length..<blocks.count)
//                let newBlocks: [BlockEditor.Block] = Array(blocks[0..<range.location] + blocks[range.location+range.length..<blocks.count])
//
//                selection = .none
//
//                _ = handleChangeBlocks(newBlocks)
//            default:
//                break
//            }
//        }
//    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        if let scroller = scrollView.verticalScroller, let view = scroller.hitTest(point) {
            return view
        }

        if bounds.contains(point) {
            return self
        }

        return nil
    }

    public override func mouseDown(with event: NSEvent) {
        hideCommandPalette()
        hideInlineToolbarWindow()

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
                        if initialRow < row {
                            selection = .blocks(NSRange(location: initialRow, length: row - initialRow + 1))
                        } else {
                            selection = .blocks(NSRange(location: row, length: initialRow - row + 1))
                        }
                    } else {
                        initialRow = row

                        if let view = view as? InlineBlockEditor {
                            let characterIndex = view.characterIndexForInsertion(at: convert(position, to: view))

//                            Swift.print(characterIndex, position, convert(position, to: view))

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

        hideCommandPalette()

        switch item(at: point) {
        case .plusButton(let line):
            handlePressPlus(line: line)
        case .moreButton(let line):
            handlePressMore(line: line)
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

            view.onChangeRootNode = { [unowned self] newRootNode in
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return false }

                let newBlock: BlockEditor.Block = .init(id: item.id, content: .tokens(newRootNode))

                _ = self.handleChangeBlocks(self.blocks.replacing(elementAt: row, with: newBlock))

                return true
            }

            return view
        case .text(let textValue, let sizeLevel):
            let view = item.view as! InlineBlockEditor

//            Swift.print("Row", row, view)

            view.textValue = textValue
            view.sizeLevel = sizeLevel
            view.onChangeTextValue = { [unowned self] newValue in
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                // Automatically create headings
                for heading in InlineBlockEditor.SizeLevel.headings {
                    if let prefix = heading.prefix, newValue.string.starts(with: prefix + " ") && !textValue.string.starts(with: prefix + " ") {
                        let prefixLength = prefix.count + 1
                        let remainder = newValue.attributedSubstring(from: .init(location: prefixLength, length: newValue.length - prefixLength))

                        var clone = self.blocks
                        clone[row] = .init(id: item.id, content: .text(heading.apply(to: remainder), heading))

                        _ = self.handleChangeBlocks(clone)

                        return
                    }
                }

                // If the string has changed, check if we want to open the command palette
                if newValue.string != view.textValue.string {
                    let range = view.selectedRange
                    let string = newValue.string
                    let location = range.location + 1
                    let prefix = string.prefix(location)
                    let rect = view.firstRect(forCharacterRange: NSRange(location: range.location, length: 1), actualRange: nil)

                    if prefix.last == "/" {
                        self.commandPaletteAnchor = (row, location, rect)
                        self.showCommandPalette(line: row, query: "", rect: rect)
                    } else if let anchor = self.commandPaletteAnchor, location > anchor.character, string.count >= location {
                        let query = (string as NSString).substring(with: NSRange(location: anchor.character, length: location - anchor.character))
                        self.showCommandPalette(line: row, query: query, rect: anchor.rect)
                    } else {
                        self.commandPaletteAnchor = nil
                        self.hideCommandPalette()
                    }
                }

                // Update the text
                var clone = self.blocks
                clone[row] = .init(id: item.id, content: .text(newValue, view.sizeLevel))

                _ = self.handleChangeBlocks(clone)
            }

            view.onChangeSelectedRange = { [unowned self] range in
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                self.selection = .item(row, range)

                if let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: true) as? InlineBlockEditor {
                    if range.length > 0 {
                        view.showInlineToolbar(for: range)
                    } else {
                        self.hideInlineToolbarWindow()
                    }
                }
            }

            view.onMoveUp = { [unowned self] rect in
                if BlockListView.commandPaletteVisible { return }

                switch self.selection {
                case .blocks:
                    fatalError("Invalid selection when inside text block")
                    break
                case .item(let line, _):
                    let nextLine = line - 1

                    if line == 0 {
                        self.selection = .item(0, .empty)
                    } else if let nextView = tableView.view(atColumn: 0, row: nextLine, makeIfNecessary: true) as? InlineBlockEditor {
                        let lineRect = nextView.lineRects.last!
                        let windowRect = self.window!.convertFromScreen(rect)
                        let convertedRect = nextView.convert(windowRect, from: nil)

                        let characterIndex = nextView.characterIndexForInsertion(at: NSPoint(x: convertedRect.origin.x, y: lineRect.midY))

                        self.selection = .item(nextLine, .init(location: characterIndex, length: 0))

                        if nextView.acceptsFirstResponder {
                            self.window?.makeFirstResponder(nextView)
                        }
                    } else {
                        self.focus(line: nextLine)
                    }
                case .none:
                    break
                }
            }

            view.onMoveDown = { [unowned self] rect in
                if BlockListView.commandPaletteVisible { return }

                switch self.selection {
                case .blocks:
                    fatalError("Invalid selection when inside text block")
                    break
                case .item(let line, _):
                    let nextLine = line + 1

                    if line >= self.blocks.count - 1 {
                        self.selection = .item(self.blocks.count - 1, self.blocks[line].lastSelectionRange)
                    } else if let nextView = tableView.view(atColumn: 0, row: nextLine, makeIfNecessary: true) as? InlineBlockEditor {
                        let lineRect = nextView.lineRects.first!
                        let windowRect = self.window!.convertFromScreen(rect)
                        let convertedRect = nextView.convert(windowRect, from: nil)

                        let characterIndex = nextView.characterIndexForInsertion(at: NSPoint(x: convertedRect.origin.x, y: lineRect.midY))

                        self.selection = .item(nextLine, .init(location: characterIndex, length: 0))

                        if nextView.acceptsFirstResponder {
                            self.window?.makeFirstResponder(nextView)
                        }
                    } else {
                        self.focus(line: nextLine)
                    }
                case .none:
                    break
                }
            }

            let handleSelect: () -> Void = { [unowned self] in
                switch self.selection {
                case .blocks:
                    fatalError("Invalid selection when inside text block")
                    break
                case .item(let line, _):
                    if self.acceptsFirstResponder {
                        self.window?.makeFirstResponder(self)
                    }

                    self.selection = .blocks(.init(location: line, length: 1), anchor: line)
                case .none:
                    break
                }
            }

            view.onSelectUp = handleSelect
            view.onSelectDown = handleSelect

            view.onPressDown = { [unowned self] in
                if !BlockListView.commandPaletteVisible { return }
                self.handleCommandPaletteDown()
            }

            view.onPressUp = { [unowned self] in
                if !BlockListView.commandPaletteVisible { return }
                self.handleCommandPaletteUp()
            }

            view.onSubmit = { [unowned self] in
                if BlockListView.commandPaletteVisible {
                    self.handleCommandPaletteSubmit()
                    return
                }

                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                let textValue = view.textValue
                let selectedRange = view.selectedRange
                let remainingRange = NSRange(location: selectedRange.upperBound, length: textValue.length - selectedRange.upperBound)
                let suffix = textValue.attributedSubstring(from: remainingRange)
                let prefix = textValue.attributedSubstring(from: NSRange(location: 0, length: selectedRange.upperBound))

                var clone = self.blocks
                clone[line] = .init(id: item.id, content: .text(prefix, view.sizeLevel))

                let nextBlock: EditableBlock = .init(id: UUID(), content: .text(suffix, .paragraph))
                clone.insert(nextBlock, at: line + 1)

                let ok = self.handleChangeBlocks(clone)

                if ok {
                    self.focus(id: nextBlock.id)
                }
            }

            view.onRequestDeleteEditor = { [unowned self] in
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                self.handleDelete(line: line)
            }

            return view
        }
    }

    func hideInlineToolbarWindow() {
        InlineToolbarWindow.shared.orderOut(nil)
    }

    func hideCommandPalette() {
        BlockListView.commandPalette.orderOut(nil)
        BlockListView.commandPaletteVisible = false
        commandPaletteAnchor = nil
    }

    func handleCommandPaletteDown() {
        let items = BlockListView.commandPalette.suggestionItems.enumerated().filter { $0.element.isSelectable }

        if let index = BlockListView.commandPalette.selectedIndex,
            let next = items.first(where: { $0.offset > index }) ?? items.last {
            BlockListView.commandPalette.selectedIndex = next.offset
        } else {
            BlockListView.commandPalette.selectedIndex = items.first?.offset
        }
    }

    func handleCommandPaletteUp() {
        let items = BlockListView.commandPalette.suggestionItems.enumerated().filter { $0.element.isSelectable }

        if let index = BlockListView.commandPalette.selectedIndex,
            let prev = items.last(where: { $0.offset < index }) ?? items.first {
            BlockListView.commandPalette.selectedIndex = prev.offset
        } else {
            BlockListView.commandPalette.selectedIndex = items.first?.offset
        }
    }

    func handleCommandPaletteSubmit() {
        if let index = BlockListView.commandPalette.selectedIndex {
            BlockListView.commandPalette.onSubmit?(index)
        }
    }

    func showCommandPalette(line: Int, query: String, rect: NSRect) {
        guard let window = self.window else { return }

        Swift.print("show cp")

        func image(named name: String) -> NSImage? {
            let bundle = BundleLocator.getBundle()
            guard let url = bundle.url(forResource: name, withExtension: "png") else { return nil }
            return NSImage(byReferencing: url)
        }

        BlockListView.commandPaletteVisible = true

        let menuItems: [(SuggestionListItem, EditableBlock)] = [
            (
                SuggestionListItem.sectionHeader("DOCUMENTATION"),
                EditableBlock.makeDefaultEmptyBlock()
            ),
            (
                SuggestionListItem.row("Text", "Write plain text", false, nil, image(named: "menu-thumbnail-paragraph")),
                EditableBlock(id: UUID(), content: .text(.init(), .paragraph))
            ),
            (
                SuggestionListItem.row("Heading 1", "Large section heading", false, nil, image(named: "menu-thumbnail-h1")),
                EditableBlock(id: UUID(), content: .text(.init(), .h1))
            ),
            (
                SuggestionListItem.row("Heading 2", "Medium section heading", false, nil, image(named: "menu-thumbnail-h2")),
                EditableBlock(id: UUID(), content: .text(.init(), .h2))
            ),
            (
                SuggestionListItem.row("Heading 3", "Small section heading", false, nil, image(named: "menu-thumbnail-h3")),
                EditableBlock(id: UUID(), content: .text(.init(), .h3))
            ),
            (
                SuggestionListItem.sectionHeader("TOKENS"),
                EditableBlock.makeDefaultEmptyBlock()
            ),
            (
                SuggestionListItem.row("Token", "Define a design token variable", false, nil, image(named: "menu-thumbnail-tokens")),
                EditableBlock(
                    id: UUID(),
                    content: .tokens(
                        LGCSyntaxNode.topLevelDeclarations(
                            .init(
                                id: UUID(),
                                declarations: .init(
                                    [
                                        .variable(
                                            id: UUID(),
                                            name: .init(id: UUID(), name: "token"),
                                            annotation: .typeIdentifier(id: UUID(), identifier: .init(id: UUID(), string: "Color"), genericArguments: .empty),
                                            initializer: .identifierExpression(id: UUID(), identifier: .init(id: UUID(), string: "placeholder", isPlaceholder: true)),
                                            comment: nil
                                        )
                                    ]
                                )
                            )
                        )
                    )
                )
            )
        ]

        let subwindow = BlockListView.commandPalette

        let suggestionItems: [SuggestionListItem] = menuItems.map { $0.0 }

        let suggestionListHeight = suggestionItems.map { $0.height }.reduce(0, +)

        subwindow.defaultWindowSize = .init(
            width: 260,
            height: min(suggestionListHeight + OverlayWindow.shadowViewMargin * 2, 400)
        )
        subwindow.anchorTo(rect: rect, verticalOffset: 4)

        func filteredSuggestionItems(query text: String) -> [(Int, SuggestionListItem)] {
            return suggestionItems.enumerated().filter { offset, item in
                if text.isEmpty { return true }

                switch item {
                case .sectionHeader:
                    return true
                case .row(let title, _, _, _, _),
                     .colorRow(name: let title, _, _, _),
                     .textStyleRow(let title, _, _):
                    return title.lowercased().contains(text.lowercased())
                }
            }
        }

        subwindow.suggestionText = query
        subwindow.suggestionItems = filteredSuggestionItems(query: query).map { offset, item in item }
        subwindow.selectedIndex = filteredSuggestionItems(query: query).firstIndex(where: { offset, item in item.isSelectable })

        subwindow.onSelectIndex = { [unowned subwindow] index in
            subwindow.selectedIndex = index
        }

        window.addChildWindow(subwindow, ordered: .above)
        window.makeMain()

        subwindow.onRequestHide = self.hideCommandPalette
        subwindow.onPressEscapeKey = self.hideCommandPalette

        subwindow.onSubmit = { [unowned self] index in
            let originalIndex = filteredSuggestionItems(query: subwindow.suggestionText).map { offset, item in offset }[index]
//            let item = menu[originalIndex]
//            item.action()

            Swift.print("choose item", originalIndex, "filtered: (\(index))")

            let newBlock = menuItems[originalIndex].1

            Swift.print("new block", newBlock)

            var replacementBlock: EditableBlock?

            switch self.blocks[line].content {
            case .text(let textValue, let sizeLevel):
                let mutable = NSMutableAttributedString()
                guard let anchorIndex = self.commandPaletteAnchor?.character else {
                    fatalError("No anchor index")
                }
                mutable.append(textValue.attributedSubstring(from: NSRange(location: 0, length: max(anchorIndex - 1, 0))))
                let queryEndIndex = anchorIndex + query.count
                mutable.append(textValue.attributedSubstring(from: NSRange(location: queryEndIndex, length: textValue.length - queryEndIndex)))

                if mutable.length > 1 {
                    replacementBlock = .init(id: self.blocks[line].id, content: .text(mutable, sizeLevel))
                }
            case .tokens:
                break
            }

            if let replacementBlock = replacementBlock {
                let clone = self.blocks
                    .replacing(elementAt: line, with: replacementBlock)
                    .inserting(newBlock, at: line + 1)

                let ok = self.handleChangeBlocks(clone)

                if ok {
                    self.focus(id: newBlock.id)
                }
            } else {
                let clone = self.blocks.replacing(elementAt: line, with: newBlock)

                let ok = self.handleChangeBlocks(clone)

                if ok {
                    self.focus(id: newBlock.id)
                }
            }

            self.hideCommandPalette()
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
