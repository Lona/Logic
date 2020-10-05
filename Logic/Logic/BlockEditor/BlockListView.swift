//
//  BlockListView.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit
import Differ

extension NSPasteboard.PasteboardType {
    public static var blocks = NSPasteboard.PasteboardType.init("blocks")
}

extension NSPasteboard {
    public var blocks: [EditableBlock]? {
        guard let blockData = data(forType: .blocks),
            let pastedBlocks = MarkdownFile.makeBlocks(blockData) else { return nil }

        return pastedBlocks
    }
}

public enum BlockListSelection: Equatable {
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

        blocks.forEach({ block in
            viewFactory.invalidateCachedImage(for: block)
        })
    }

    // MARK: Public

    open func handleChangeBlocks(_ blocks: [BlockEditor.Block]) -> Bool {
        var blocks = blocks

        let emptyBlock = BlockEditor.Block.makeDefaultEmptyBlock()

        // Ensure there is an empty block at the end of the document at all times
        if blocks.last?.content != .some(emptyBlock.content) {
            blocks.append(emptyBlock)
        }

        return onChangeBlocks?(blocks.normalizeLists()) ?? false
    }

    private func showToolTip(string: String, at point: NSPoint) {
        guard let window = window else { return }
        let windowPoint = convert(point, to: nil)
        let screenPoint = window.convertPoint(toScreen: windowPoint)

        if window.isKeyWindow {
            TooltipManager.shared.showTooltip(string: string, point: screenPoint, delay: .milliseconds(120))
        }
    }

    private func handleMoveBlocks(range: NSRange, insertionIndex: Int) -> Bool {
        var normalizedIndex = min(insertionIndex + 1, blocks.count)

        if normalizedIndex > range.location {
            normalizedIndex -= range.length
        }

        let targetBlocks = blocks[range.lowerBound..<range.upperBound]

        var newBlocks: [BlockEditor.Block] = Array(blocks[0..<range.location] + blocks[range.location+range.length..<blocks.count])

        newBlocks.insert(contentsOf: targetBlocks, at: normalizedIndex)

        return handleChangeBlocks(newBlocks)
    }

    private func replaceBlocks(in range: NSRange, with otherBlocks: [EditableBlock]) -> Bool {
        var newBlocks: [BlockEditor.Block] = Array(blocks[0..<range.location] + blocks[range.location+range.length..<blocks.count])

        newBlocks.insert(contentsOf: otherBlocks, at: range.location)

        return self.handleChangeBlocks(newBlocks)
    }

    public var plusButtonTooltip: String = "**Click** _to add below_"
    public var moreButtonTooltip: String = "**Drag** _to move_\n**Click** _to open menu_"

    private func handlePressMore(line: Int) {
        TooltipManager.shared.hideTooltip()

        guard let window = window else { return }

        let windowRect = convert(moreButtonRect(for: line), to: nil)
        let screenRect = window.convertToScreen(windowRect)

        getWrapperView(line).showOverflowMenu(at: screenRect)
    }

    func getWrapperView(_ block: EditableBlock) -> EditableBlockView {
        return viewFactory.wrapperView(for: block)
    }

    func getWrapperView(_ line: Int) -> EditableBlockView {
        return getWrapperView(blocks[line])
    }

    func getView(_ block: EditableBlock) -> NSView {
        return viewFactory.view(for: block)
    }

    func getView(_ line: Int) -> NSView {
        return getView(blocks[line])
    }

    private func handlePressPlus(line: Int) {
        TooltipManager.shared.hideTooltip()

        func showCommandPalette(line: Int) {
            if let view = self.getView(line) as? TextBlockContainerView {
                let rect = view.firstRect(forCharacterRange: NSRange(location: 0, length: 0))

                commandPaletteAnchor = (line, 0, rect)
                self.showCommandPalette(line: line, query: "", rect: rect)
                view.setPlaceholder(string: "Type to filter commands")
            }
        }

        if blocks[line].content == .text(.init(), .paragraph) {
            focus(line: line)
            showCommandPalette(line: line)
        } else if line + 1 < blocks.count, blocks[line + 1].content == .text(.init(), .paragraph) {
            focus(line: line + 1)
            showCommandPalette(line: line + 1)
        } else {
            let id = UUID()
            let ok = handleAddBlock(line: line, block: .init(id: id, content: .text(.init(), .paragraph), listDepth: .none))

            if ok, let addedLine = self.line(forBlock: id) {
                showCommandPalette(line: addedLine)
            }
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

    public func updateBlockMargins(blocks: [EditableBlock]) {
        zip(blocks.dropLast(), blocks.dropFirst()).forEach { a, b in
            let margin = EditableBlock.margin(a, b)
            self.getWrapperView(a).bottomMargin = margin
        }
    }

    public var blocks: [BlockEditor.Block] = [] {
        didSet {
            tableView.blocks = blocks

            updateBlockMargins(blocks: blocks)

            let changedRows: [Int] = oldValue.extendedDiff(blocks).compactMap({ item in
                switch item {
                case .delete:
                    return nil
                case .insert(at: let row), .move(from: _, to: let row):
                    return row
                }
            })

            changedRows.forEach({ row in viewFactory.invalidateCachedImage(for: blocks[row]) })

            let deletedRows: [Int] = oldValue.extendedDiff(blocks).compactMap({ item in
                switch item {
                case .delete(let row):
                    return row
                case .insert, .move:
                    return nil
                }
            })

            // Clean up the image for the deleted row, so that we don't leak memory
            deletedRows.forEach({ row in viewFactory.invalidateCachedImage(for: oldValue[row]) })

            let identityDiff = oldValue.extendedDiff(blocks, isEqual: { a, b in a.id == b.id })

            if identityDiff.isEmpty {
                for index in 0..<blocks.count {
                    let old = oldValue[index]
                    let new = blocks[index]

                    // TODO: Is !== meaningful here? They're both structs
                    if old !== new {
                        viewFactory.updateView(block: new)
                    }
                }
            } else {
                var containsMoves = false

                outer: for element in identityDiff {
                    switch element {
                        case .move:
                            containsMoves = true
                            break outer
                        default:
                            break
                    }
                }

                // Calling animateRowChanges currently breaks row rendering.
                // Calling reloadData currently breaks item selection, but it works with block selection.
                // By calling reload only if we make a move, this solves the problem for now, since we
                // never move at the same time when doing an insert or delete
                if containsMoves {
                    tableView.reloadData()
                } else {
                    let firstResponder = window?.firstResponder as? NSView

                    tableView.animateRowChanges(oldData: oldValue, newData: blocks)

                    // Restore first responder if it hasn't been deleted
                    if firstResponder?.window == window {
                        window?.makeFirstResponder(firstResponder)
                    }
                }
            }

            if blocks.all(where: { $0.isEmpty }), !blocks.isEmpty {
                if let view = getView(0) as? TextBlockContainerView {
                    view.setPlaceholder(string: "Click here to start!")
                }
            }

            needsDisplay = true

            if showsMinimap {
                minimapScroller.needsDisplay = true
            }
        }
    }

    var viewFactory = EditableBlockFactory()

    public var transformImageURL: ((URL) -> URL)? {
        get { return viewFactory.transformImageURL }
        set { viewFactory.transformImageURL = newValue }
    }

    public var onChangeBlocks: (([BlockEditor.Block]) -> Bool)?

    public var onChangeSelection: ((BlockListSelection) -> Void)?

    public var onChangeVisibleBlocks: ((Range<Int>) -> Void)?

    public var onClickLink: ((String) -> Bool)?

    public var onClickPageLink: ((String) -> Bool)?

    public var onRequestCreatePage: ((Int, Bool) -> Void)?

    public func select(id: UUID) {
        guard let row = blocks.firstIndex(where: { $0.id == id }) else { return }

        self.selection = .item(row, .empty)

        let view = getView(row)
        let viewFrame = view.convert(view.frame, to: scrollView.contentView)

        scrollView.contentView.bounds.origin.y = viewFrame.origin.y
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    public var floatingMinimap: Bool = false {
        didSet {
            needsLayout = true

            if showsMinimap {
                minimapScroller.needsDisplay = true
            }
        }
    }

    public var showsMinimap: Bool = false {
        didSet {
            if showsMinimap {
                minimapScroller.drawKnobSlot = { rect, scaledDocumentSize, isHighlighted in
                    let minimapScale = MinimapScroller.renderingScale

                    let knobMinY = -rect.origin.y
                    let knobMaxY = knobMinY + rect.height

                    // Convert the top and bottom of the rect to a fraction of the whole document
                    let minFraction = knobMinY / scaledDocumentSize.height
                    let maxFraction = knobMaxY / scaledDocumentSize.height

                    let documentHeight = (self.scrollView.documentView?.frame.height ?? 0) + self.verticalPadding * 2
                    let documentMinY = documentHeight * minFraction
                    let documentMaxY = documentHeight * maxFraction

                    let tableViewBounds = self.tableView.bounds

                    // The visible portion of the table view
                    let visibleRect = NSRect(
                        x: 0,
                        y: documentMinY - self.verticalPadding,
                        width: tableViewBounds.width,
                        height: documentMaxY - documentMinY + self.verticalPadding
                    )

                    NSGraphicsContext.saveGraphicsState()
                    NSGraphicsContext.current?.cgContext.translateBy(x: rect.origin.x, y: 0)
                    NSGraphicsContext.current?.cgContext.scaleBy(x: minimapScale, y: minimapScale)
                    NSGraphicsContext.current?.cgContext.setAlpha(0.5)

                    let rowXOffset = max((rect.width / minimapScale - tableViewBounds.size.width) / 2, 10)
                    let rowYOffset = self.verticalPadding + rect.origin.y / minimapScale
                    let visibleRows = self.tableView.rows(in: visibleRect)

                    Range(visibleRows)?.forEach({ row in
                        guard let rowImage = self.viewFactory.image(for: self.blocks[row]) else { return }

                        var rowRect = self.tableView.rect(ofRow: row)
                        rowRect.origin.x += rowXOffset
                        rowRect.origin.y += rowYOffset
                        rowRect.size = rowImage.size

                        rowImage.draw(in: rowRect)
                    })

                    NSGraphicsContext.restoreGraphicsState()
                }

                scrollView.autohidesScrollers = false
                scrollView.verticalScroller = minimapScroller
                tableView.usesStaticContents = true
            } else {
                minimapScroller.drawKnobSlot = nil

                scrollView.autohidesScrollers = true
                scrollView.verticalScroller = NSScroller()
                tableView.usesStaticContents = false
            }
        }
    }

    // MARK: Private

    private var selection: BlockListSelection = .none {
        didSet {
            if oldValue == selection { return }

            updateSelection(from: oldValue, to: selection)
        }
    }

    private func updateSelection(from oldValue: BlockListSelection, to selection: BlockListSelection) {
        switch oldValue {
        case .none:
            break
        case .item(let row, _):
            if row >= blocks.count { return }

            let view = getView(row)

            if let view = view as? TextBlockContainerView {
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

        var scrollTargetView: NSView?

        switch selection {
        case .none:
            break
        case .item(let row, let range):
            if row >= blocks.count { return }

            let view = getView(row)

            if let view = view as? TextBlockContainerView {
                view.setSelectedRangesWithoutNotification([NSValue(range: range)])
//                    view.needsDisplay = true
                view.setPlaceholder(string: "Type '/' for commands")
            }

            scrollTargetView = view
        case .blocks(let range, let anchor):
            for index in range.lowerBound..<range.upperBound {
                let rowView = tableView.rowView(atRow: index, makeIfNecessary: false) as? BlockListRowView
                rowView?.isBlockSelected = true
            }

            if anchor < blocks.count {
                scrollTargetView = getView(anchor)
            }
        }

        if let view = scrollTargetView {
            let viewFrame = view.convert(view.frame, to: scrollView.documentView!)
            if scrollView.documentVisibleRect.maxY - 20 < viewFrame.minY {
                scrollView.documentView?.scrollToVisible(.init(x: 0, y: viewFrame.minY, width: 0, height: 0))
            } else if scrollView.documentVisibleRect.minY + 20 > viewFrame.maxY {
                scrollView.documentView?.scrollToVisible(.init(x: 0, y: viewFrame.maxY, width: 0, height: 0))
            }
        }

        onChangeSelection?(selection)
    }

    private var tableView = BlockListTableView()
    private let scrollView = NSScrollView()
    private let tableColumn = NSTableColumn(title: "Suggestions", minWidth: 100)
    private let minimapScroller = MinimapScroller(frame: .zero)

    private var dragTargetLine: Int? {
        didSet {
            if oldValue != dragTargetLine {
                needsDisplay = true
            }
        }
    }

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

        switch selection {
        case .item(let row, _):
            getView(row).focus()
        default:
            break
        }
    }

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero
        
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

        let leftInset = self.leftInset
        let rightInset = self.rightInset
        scrollView.contentInsets = .init(top: verticalPadding, left: leftInset, bottom: verticalPadding, right: rightInset)
        scrollView.scrollerInsets = .init(top: -verticalPadding, left: -leftInset, bottom: -verticalPadding, right: -rightInset)

        scrollView.contentView.postsBoundsChangedNotifications = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScroll),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        addSubview(scrollView)

        tableView.reloadData()
        tableView.sizeToFit()

        tableView.intercellSpacing = .init(width: 0, height: 6)
    }

    @objc private func handleScroll(_ sender: AnyObject) {
        let visibleRect = tableView.visibleRect
        let adjustedRect = visibleRect.insetBy(dx: 0, dy: 20)
        let visibleRows = tableView.rows(in: adjustedRect)

        onChangeVisibleBlocks?(visibleRows.lowerBound..<visibleRows.upperBound)
    }

    public override func viewWillMove(toWindow newWindow: NSWindow?) {
        if let window = newWindow {
            NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: nil, using: { [weak self] _ in
                guard let self = self else { return }

                self.tableView.enumerateAvailableRowViews { rowView, row in
                    self.viewFactory.updateViewWidth(block: self.blocks[row], self.tableView.bounds.width)
                }
            })
        }
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

    public var smallWidthBreakpointSize: CGFloat = 820
    public var largeWidthBreakpointSize: CGFloat = 1200
    public var minimumHorizontalPadding: CGFloat = 60
    public var verticalPadding: CGFloat = 80

    private var contentWidthSize: CGFloat {
        return smallWidthBreakpointSize - minimumHorizontalPadding * 2
    }

    public var horizontalPadding: CGFloat {
        let width = bounds.width
        let scrollerWidth = showsMinimap ? MinimapScroller.scrollerWidth(for: minimapControlSize(for: width), scrollerStyle: .overlay) : 0

        return (width - scrollerWidth) > smallWidthBreakpointSize
            ? (width - scrollerWidth - contentWidthSize) / 2
            : minimumHorizontalPadding
    }

    public var leftInset: CGFloat {
        let width = bounds.width
        let scrollerWidth = showsMinimap && floatingMinimap && width > 1000
            ? MinimapScroller.scrollerWidth(for: minimapControlSize(for: width), scrollerStyle: .overlay)
            : 0

        return horizontalPadding + scrollerWidth / 2
    }

    public var rightInset: CGFloat {
        let width = bounds.width
        let scrollerWidth = showsMinimap && floatingMinimap && width > 1000
            ? MinimapScroller.scrollerWidth(for: minimapControlSize(for: width), scrollerStyle: .overlay)
            : 0

        return horizontalPadding - scrollerWidth / 2
    }

    private func minimapControlSize(for width: CGFloat) -> NSControl.ControlSize {
        if bounds.width > largeWidthBreakpointSize {
            return .regular
        } else if bounds.width > smallWidthBreakpointSize {
            return .small
        } else {
            return .mini
        }
    }

    public override func layout() {
        super.layout()

        if showsMinimap {
            minimapScroller.controlSize = minimapControlSize(for: bounds.width)
        }

        if scrollView.contentInsets.left != leftInset {
            let leftInset = self.leftInset
            let rightInset = self.rightInset
            scrollView.contentInsets = .init(top: verticalPadding, left: leftInset, bottom: verticalPadding, right: rightInset)
            scrollView.scrollerInsets = .init(top: -verticalPadding, left: -leftInset, bottom: -verticalPadding, right: -rightInset)
        }
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let dragTargetLine = dragTargetLine {
            let rect: NSRect

            if dragTargetLine == -1 {
                let rowRect = convert(tableView.rect(ofRow: 0), from: tableView)
                rect = NSRect(x: rowRect.origin.x, y: rowRect.maxY, width: rowRect.width, height: 2)
            } else {
                let rowRect = convert(tableView.rect(ofRow: dragTargetLine), from: tableView)
                rect = NSRect(x: rowRect.origin.x, y: rowRect.minY, width: rowRect.width, height: 2)
            }

            NSColor.selectedMenuItemColor.setFill()

            rect.fill()
        }

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

        if line >= blocks.count {
            Swift.print("Bad state, plusButtonRect")
            return .zero
        }

        let alignmentHeight = blocks[line].lineButtonAlignmentHeight

        let rect = NSRect(
            x: floor(leftInset - lineButtonSize.width - lineButtonMargin),
            y: floor(rowRect.maxY - alignmentHeight + (alignmentHeight - lineButtonSize.height) / 2 - 4),
            width: lineButtonSize.width,
            height: lineButtonSize.height)

        return rect
    }

    private func moreButtonRect(for line: Int) -> CGRect {
        let rowRect = convert(tableView.rect(ofRow: line), from: tableView)

        if line >= blocks.count {
            Swift.print("Bad state, moreButtonRect")
            return .zero
        }

        let alignmentHeight = blocks[line].lineButtonAlignmentHeight

        let rect = NSRect(
            x: leftInset - lineButtonSize.width * 2 - lineButtonMargin * 2,
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
        suggestionWindow.acceptsKeyboardInputWithHiddenSearchBar = false
        suggestionWindow.showsSuggestionDetails = false

        return suggestionWindow
    }()

    func hideReplaceWithTextMenu() {
        let subwindow = BlockListView.replaceWithTextMenu

        subwindow.orderOut(nil)
    }

    func showReplaceWithTextMenu(rect: NSRect) {
        guard let window = window else { return }

        guard case let .item(line, _) = selection else { return }

        let subwindow = BlockListView.replaceWithTextMenu

        window.addChildWindow(subwindow, ordered: .above)
//        window.makeMain()

        subwindow.anchorTo(rect: rect, verticalOffset: 4)

        let hide: () -> Void = { [unowned self] in
            self.hideReplaceWithTextMenu()
            self.hideInlineToolbarWindow()
        }

        subwindow.onRequestHide = hide
        subwindow.onPressEscapeKey = hide

        subwindow.onSubmit = { [unowned self] index in
            let newBlock = BlockListView.replaceMenuSuggestionItems[index].1
            let oldBlock = self.blocks[line]

            switch (newBlock.content, oldBlock.content) {
            case (.text(_, let newSizeLevel), .text(let textValue, _)):

                // TODO: Why aren't inline attributes preserved?
                let replacementBlock: EditableBlock = .init(
                    id: oldBlock.id,
                    content: .text(newSizeLevel.apply(to: textValue), newSizeLevel),
                    listDepth: .none
                )

                let clone = self.blocks.replacing(elementAt: line, with: replacementBlock)

                let ok = self.handleChangeBlocks(clone)

                if ok {
                    self.focus(id: oldBlock.id)
                }
            default:
                return
            }

            hide()
        }
    }

    public static var replaceMenuSuggestionItems: [(SuggestionListItem, EditableBlock)] = [
        (Suggestion.text, EditableBlock(id: UUID(), content: .text(.init(), .paragraph), listDepth: .none)),
        (Suggestion.heading1, EditableBlock(id: UUID(), content: .text(.init(), .h1), listDepth: .none)),
        (Suggestion.heading2, EditableBlock(id: UUID(), content: .text(.init(), .h2), listDepth: .none)),
        (Suggestion.heading3, EditableBlock(id: UUID(), content: .text(.init(), .h3), listDepth: .none)),
        (Suggestion.quote, EditableBlock(id: UUID(), content: .text(.init(), .quote), listDepth: .none)),
    ]

    public static var replaceWithTextMenu: SuggestionWindow = {
        let subwindow = SuggestionWindow()

        subwindow.showsSearchBar = false
        subwindow.acceptsKeyboardInputWithHiddenSearchBar = false
        subwindow.showsSuggestionDetails = false

        let suggestionItems: [SuggestionListItem] = replaceMenuSuggestionItems.map { $0.0 }

        subwindow.defaultContentWidth = 236
        subwindow.suggestionItems = suggestionItems

        return subwindow
    }()

    public static var linkEditor: SuggestionWindow = {
        let subwindow = SuggestionWindow()

        subwindow.style = .textInput
        subwindow.placeholderText = "Paste a URL and press Enter"
        subwindow.onChangeSuggestionText = { value in
            subwindow.suggestionText = value
        }

        subwindow.onRequestHide = {
            subwindow.orderOut(nil)
        }

        return subwindow
    }()

    // MARK: Event handling

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override func keyDown(with event: NSEvent) {
        let isShiftEnabled = event.modifierFlags.contains(NSEvent.ModifierFlags.shift)
        let isCommandEnabled = event.modifierFlags.contains(NSEvent.ModifierFlags.command)

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
                        if isCommandEnabled {
                            selection = .blocks(.init(location: 0, length: range.location + 1), anchor: 0)
                        } else {
                            selection = .blocks(.init(location: range.location, length: range.length - 1), anchor: anchor - 1)
                        }
                    } else {
                        if isCommandEnabled {
                            selection = .blocks(.init(between: 0, and: range.upperBound), anchor: 0)
                        } else {
                            selection = .blocks(.merge(ranges: [range, newRange]), anchor: newRange.location)
                        }
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
                        if isCommandEnabled {
                            selection = .blocks(.init(between: range.upperBound - 1, and: blocks.count), anchor: blocks.count - 1)
                        } else {
                            selection = .blocks(.init(location: range.location + 1, length: range.length - 1), anchor: anchor + 1)
                        }
                    } else {
                        if isCommandEnabled {
                            selection = .blocks(.init(between: range.location, and: blocks.count), anchor: blocks.count - 1)
                        } else {
                            selection = .blocks(.merge(ranges: [range, newRange]), anchor: newRange.location)
                        }
                    }
                } else {
                    selection = .blocks(newRange, anchor: newRange.location)
                }
            default:
                break
            }
        default:
            super.keyDown(with: event)
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

    public func hideChildWindows() {
        hideCommandPalette()
        hideInlineToolbarWindow()
        hideReplaceWithTextMenu()
        hideLinkEditor()
        SuggestionWindow.contextMenu.orderOut(nil)
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        if let scroller = scrollView.verticalScroller, let view = scroller.hitTest(point) {
            return view
        }

        for (_, index) in tableView.availableRows {
            if let editableBlockView = tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? EditableBlockView {

                let view = editableBlockView.overflowMenuButton
                let converted = superview!.convert(point, to: view)

                if view.bounds.contains(converted) {
                    return view
                }
            }
        }

        if bounds.contains(point) {
            return self
        }

        return nil
    }

    public override func scrollWheel(with event: NSEvent) {
        scrollView.scrollWheel(with: event)
    }

    public override func mouseDown(with event: NSEvent) {
        hideChildWindows()

        trackMouse(startingWith: event)
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

    public func trackMouse(startingWith initialEvent: NSEvent) {
        guard let window = window else { return }

        let initialPosition = convert(initialEvent.locationInWindow, from: nil)

        let clickedItem = item(at: initialPosition)

        TooltipManager.shared.hideTooltip()

        switch clickedItem {
        case .moreButton(let line),
             .item(let line, _) where blocks[line].supportsDirectDragging:
            var isDragging: Bool = false

            let tableViewRect = convert(tableView.frame, from: tableView)

            trackingLoop: while true {
                let event = window.nextEvent(matching: [.leftMouseUp, .leftMouseDragged])!
                let position = convert(event.locationInWindow, from: nil)

                switch event.type {
                case .leftMouseDragged:
                    if !isDragging && initialPosition.distance(to: position) > 5 {
                        isDragging = true

                        switch selection {
                        case .blocks(let range, anchor: _):
                            if !range.contains(line) {
                                selection = .blocks(.init(location: line, length: 1))
                            }
                        default:
                            selection = .blocks(.init(location: line, length: 1))
                        }
                    }

                    if isDragging {
                        let normalizedPoint = convert(NSPoint(x: tableViewRect.minX, y: position.y), to: tableView)
                        var targetRow = tableView.row(at: normalizedPoint)

                        if targetRow == -1 {
                            if normalizedPoint.y >= tableViewRect.minY {
                                targetRow = blocks.count - 1
                            }
                        } else {
                            let targetRect = tableView.rect(ofRow: targetRow)

                            if normalizedPoint.y < targetRect.midY {
                                targetRow = targetRow - 1
                            }
                        }

                        dragTargetLine = targetRow
                    }
                case .leftMouseUp:
                    if !isDragging {
                        handleClick(mouseDownEvent: initialEvent, mouseUpEvent: event)
                    }

                    if let dragTargetLine = dragTargetLine {
                        var currentSelectionRange: NSRange

                        switch selection {
                        case .blocks(let range, anchor: _):
                            currentSelectionRange = range
                        default:
                            currentSelectionRange = NSRange(location: line, length: 1)
                        }

                        let selectedId = blocks[currentSelectionRange.location].id

                        // We don't allow moving the range inside itself
                        if !currentSelectionRange.contains(dragTargetLine) {
                            _ = handleMoveBlocks(range: currentSelectionRange, insertionIndex: dragTargetLine)

                            if let selectedIndex = blocks.firstIndex(where: { $0.id == selectedId }) {
                                selection = .blocks(NSRange(location: selectedIndex, length: currentSelectionRange.length))
                            }
                        }
                    }

                    break trackingLoop
                default:
                    break
                }
            }

            dragTargetLine = nil
        default:
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

                    if isDragging && row >= 0 {

                        // If the drag covers more than a single row, switch to block selection
                        if let initialRow = initialRow, initialRow != row {
                            if initialRow < row {
                                let newRange = NSRange(location: initialRow, length: row - initialRow + 1)
                                selection = .blocks(newRange, anchor: newRange.upperBound - 1)
                            } else {
                                let newRange = NSRange(location: row, length: initialRow - row + 1)
                                selection = .blocks(newRange, anchor: newRange.lowerBound)
                            }
                        } else {
                            initialRow = row

                            // If the drag is within a text block, perform text selection
                            if let view = getView(row) as? TextBlockContainerView {
                                let characterIndex = view.characterIndexForInsertion(at: convert(position, to: view))

                                if let initialIndex = initialIndex {
                                    selection = .item(row, NSRange(between: initialIndex, and: characterIndex))
                                } else {
                                    initialIndex = characterIndex
                                    selection = .item(row, NSRange(location: characterIndex, length: 0))
                                }

                                view.focus()
                                view.insertionPointColor = .clear
                                didChangeInsertionColor = true
                            // If the drag is within another kind of block, do block selection after the dragging threshold
                            } else if isDragging {
                                selection = .blocks(.init(location: row, length: 1))
                            }
                        }
                    }

                    if initialPosition.distance(to: position) > 5 {
                        isDragging = true
                    }
                case .leftMouseUp:
                    if !isDragging {
                        handleClick(mouseDownEvent: initialEvent, mouseUpEvent: event)
                    }

                    switch selection {
                    case .item(let row, let range):
                        let view = getView(row)

                        view.focus()

                        if range.length > 0 {
                            (view as? TextBlockContainerView)?.showInlineToolbar(for: range)
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
                let view = getView(row)

                if let view = view as? TextBlockContainerView {
                    view.insertionPointColor = NSColor.textColor
                }
            }
        }
    }

    private struct Insertion {
        var time: TimeInterval = Date.distantPast.timeIntervalSinceReferenceDate
        var count: Int = 0
        var index: Int?
        var line: Int?
    }

    private var lastInsertion = Insertion()

    public func handleClick(mouseDownEvent: NSEvent, mouseUpEvent: NSEvent) {
        selection = .none

        hideChildWindows()

        let point = convert(mouseUpEvent.locationInWindow, from: nil)

        switch item(at: point) {
        case .plusButton(let line):
            handlePressPlus(line: line)
        case .moreButton(let line):
            handlePressMore(line: line)
        case .item(let line, let point):
            let view = getView(line)

            if let view = view as? TextBlockContainerView {
                let pointInView = convert(point, to: view)

                if let linkInfo = view.linkRects.first(where: { info in info.rect.contains(pointInView) }) {
                    if onClickLink?(linkInfo.url.absoluteString ?? "") == true {
                        return
                    }
                }

                let characterIndex = view.characterIndexForInsertion(at: pointInView)

                if lastInsertion.line == line, lastInsertion.index == characterIndex, Date().timeIntervalSinceReferenceDate - lastInsertion.time < 0.5 {
                    let options: NSString.EnumerationOptions = lastInsertion.count % 2 == 1 ? .byWords : .byLines
                    let string = view.textValue.string as NSString
                    var selectionRange: NSRange = .init(location: characterIndex, length: 0)
                    string.enumerateSubstrings(in: .init(location: 0, length: string.length), options: options) {
                        (word, wordRange, enclosingRange, boolPointer) in
                        if wordRange.lowerBound <= characterIndex && characterIndex <= wordRange.upperBound {
                            selectionRange = wordRange
                            boolPointer.pointee = true
                        }
                    }
                    selection = .item(line, selectionRange)

                } else {
                    selection = .item(line, NSRange(location: characterIndex, length: 0))
                    lastInsertion.count = 0
                    lastInsertion.index = characterIndex
                    lastInsertion.line = line
                }

                lastInsertion.count += 1
                lastInsertion.time = Date().timeIntervalSinceReferenceDate

                view.focus()
            } else if let superview = view.superview {
                let superviewPoint = superview.convert(mouseUpEvent.locationInWindow, from: nil)
                if let targetView = view.hitTest(superviewPoint) {
                    targetView.mouseDown(with: mouseUpEvent)
                    targetView.mouseUp(with: mouseUpEvent)
                }
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

        let tableViewPoint = convert(point, to: tableView)
        let row = tableView.row(at: tableViewPoint)

        if row >= 0 {
            return .item(row, point)
        } else {
            // Clicking anywhere below the last row behaves the same as clicking the bottom right of the last row
            if blocks.count > 0 {
                let lastRow = blocks.count - 1
                let lastRowRect = tableView.rect(ofRow: lastRow)

                // Extend the rect of the last row down vertically
                let lastRowRectExtended = NSRect(
                    origin: lastRowRect.origin,
                    size: .init(width: lastRowRect.width, height: .greatestFiniteMagnitude)
                )

                if lastRowRectExtended.contains(tableViewPoint) {
                    let boundedPoint = NSPoint(x: lastRowRect.maxX, y: lastRowRect.maxY)
                    return .item(lastRow, convert(boundedPoint, from: tableView))
                }
            }

            return .background
        }
    }
}

// MARK: - Delegate

extension BlockListView: NSTableViewDelegate {
    static let numberedListRE = try! NSRegularExpression(pattern: #"^(\d+). "#)
    static let orderedListPrefixes = ["- ", "* ", ". "]

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = BlockListRowView()

        switch selection {
        case .blocks(let range, _):
            rowView.isBlockSelected = range.contains(row)
        default:
            break
        }

        return rowView
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = blocks[row]
        let wrapperView = getWrapperView(item)

        let deleteItemTitle = "Delete"
        let duplicateItemTitle = "Duplicate"

        let standardOverflowMenu: [SuggestionListItem] = [
            .row(duplicateItemTitle, nil, false, nil, nil),
            .row(deleteItemTitle, nil, false, nil, nil),
        ]

        let standardActivateOverflowMenuItem: (Int) -> Void = { [unowned self] index in
            guard let menuItems = wrapperView.overflowMenu?() else { return }

            let menuItem = menuItems[index]

            guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

            switch menuItem.title {
            case deleteItemTitle:
                if self.handleChangeBlocks(self.blocks.removing(at: line)) {
                    self.window?.makeFirstResponder(nil)
                }
            case duplicateItemTitle:
                let original = self.blocks[line]
                let copy = EditableBlock(id: UUID(), content: original.content, listDepth: original.listDepth)
                if self.handleChangeBlocks(self.blocks.inserting(copy, at: line + 1)) {
                    self.window?.makeFirstResponder(nil)
                    self.selection = .blocks(.init(location: line + 1, length: 1))
                }
            default:
                break
            }
        }

        wrapperView.overflowMenu = { return standardOverflowMenu }

        wrapperView.onActivateOverflowMenuItem = standardActivateOverflowMenuItem

        wrapperView.onOpenOverflowMenu = {
            guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

            self.selection = .blocks(.init(location: line, length: 1))
        }

        getWrapperView(item).onDeleteBlock = {
            guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

            if self.handleChangeBlocks(self.blocks.removing(at: line)) {
                self.window?.makeFirstResponder(nil)
            }
        }

        switch item.content {
        case .tokens:
            let view = getView(item) as! LogicEditor

            view.onClickBackground = { [unowned self] in
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                self.selection = .blocks(.init(location: line, length: 1))
            }

            view.onRequestDelete = { [unowned self] in
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                _ = self.handleChangeBlocks(self.blocks.removing(at: line))
            }

            view.onChangeRootNode = { [unowned self] newRootNode in
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return false }

                let newBlock: BlockEditor.Block = .init(id: item.id, content: .tokens(newRootNode), listDepth: .none)

                _ = self.handleChangeBlocks(self.blocks.replacing(elementAt: line, with: newBlock))

                return true
            }

            view.onFocusNextView = { [unowned self] in
                if self.blocks.count > row {
                    self.getView(row + 1).focus()
                }
            }
        case .text(let textValue, let sizeLevel):
            let view = getView(item) as! TextBlockContainerView

//            Swift.print("Row", row, view)

            view.textValue = textValue
            view.sizeLevel = sizeLevel
            view.onChangeTextValue = { [unowned self] newValue in
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                // Automatically create headings
                for heading in TextBlockView.SizeLevel.prefixShortcutSizes {
                    if let prefix = heading.prefix, newValue.string.starts(with: prefix + " ") && !textValue.string.starts(with: prefix + " ") {
                        let prefixLength = prefix.count + 1
                        let remainder = newValue.attributedSubstring(from: .init(location: prefixLength, length: newValue.length - prefixLength))

                        var clone = self.blocks
                        clone[row] = .init(id: item.id, content: .text(heading.apply(to: remainder), heading), listDepth: item.listDepth)

                        _ = self.handleChangeBlocks(clone)

                        return
                    }
                }

                // Automatically create unordered lists
                for prefix in BlockListView.orderedListPrefixes {
                    if newValue.string.starts(with: prefix) && !textValue.string.starts(with: prefix) {
                        let prefixLength = prefix.count
                        let remainder = newValue.attributedSubstring(from: .init(location: prefixLength, length: newValue.length - prefixLength))

                        let newBlock: EditableBlock = .init(id: UUID(), content: .text(remainder, .paragraph), listDepth: .unordered(depth: 1))
                        if self.handleChangeBlocks(self.blocks.replacing(elementAt: row, with: newBlock)) {
                            self.getView(newBlock).focus()
                        }

                        return
                    }
                }

                // Automatically create ordered lists
                if let match = BlockListView.numberedListRE.firstMatch(in: newValue.string, range: .init(location: 0, length: newValue.length)),
                    BlockListView.numberedListRE.firstMatch(in: textValue.string, range: .init(location: 0, length: textValue.length)) == nil {
                    let prefixLength = match.range.length
                    let remainder = newValue.attributedSubstring(from: .init(location: prefixLength, length: newValue.length - prefixLength))

                    let newBlock: EditableBlock = .init(id: UUID(), content: .text(remainder, .paragraph), listDepth: .ordered(depth: 1, index: 1))
                    if self.handleChangeBlocks(self.blocks.replacing(elementAt: row, with: newBlock)) {
                        self.getView(newBlock).focus()
                    }

                    return
                }

                // Update the text
                var clone = self.blocks
                clone[row] = .init(id: item.id, content: .text(newValue, view.sizeLevel), listDepth: item.listDepth)

                _ = self.handleChangeBlocks(clone)
            }

            // If the string has changed, check if we want to open the command palette
            view.onDidChangeText = { [unowned self] in
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                let range = view.selectedRange
                let string = view.textValue.string
                let location = range.location
                let prefix = string.prefix(location)

                if prefix.last == "/" {
                    let rect = view.firstRect(forCharacterRange: NSRange(location: prefix.count - 1, length: 1))
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

            view.onChangeSelectedRange = { [unowned self] range in
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                self.selection = .item(row, range)

                if let view = self.getView(row) as? TextBlockContainerView {
                    if range.length > 0 {
                        view.showInlineToolbar(for: range)
                        self.hideReplaceWithTextMenu()
                    } else {
                        self.hideInlineToolbarWindow()
                        self.hideReplaceWithTextMenu()
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
                    if let nextLine = self.blocks.prefix(upTo: line).lastIndex(where: { $0.supportsInlineFocus }),
                        let nextView = self.getView(nextLine) as? TextBlockContainerView {
                        let lineRect = nextView.lineRects.last!
                        let windowRect = self.window!.convertFromScreen(rect)
                        let convertedRect = nextView.convert(windowRect, from: nil)

                        let characterIndex = nextView.characterIndexForInsertion(at: NSPoint(x: convertedRect.origin.x, y: lineRect.midY))

                        self.selection = .item(nextLine, .init(location: characterIndex, length: 0))

                        nextView.focus()
                    } else {
                        self.selection = .item(line, .empty)
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
                    if let nextLine = self.blocks.suffix(from: line + 1).firstIndex(where: { $0.supportsInlineFocus }),
                        let nextView = self.getView(nextLine) as? TextBlockContainerView {
                        let lineRect = nextView.lineRects.first!
                        let windowRect = self.window!.convertFromScreen(rect)
                        let convertedRect = nextView.convert(windowRect, from: nil)

                        let characterIndex = nextView.characterIndexForInsertion(at: NSPoint(x: convertedRect.origin.x, y: lineRect.midY))

                        self.selection = .item(nextLine, .init(location: characterIndex, length: 0))

                        nextView.focus()
                    } else {
                        self.selection = .item(line, self.blocks[line].lastSelectionRange)
                    }
                case .none:
                    break
                }
            }

            view.onIndent = {
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                let newBlock = self.blocks[row].indented

                let oldSelection = self.selection

                if self.handleChangeBlocks(self.blocks.replacing(elementAt: row, with: newBlock)) {
                    // Reapply selection/focus
                    self.updateSelection(from: oldSelection, to: self.selection)
                    self.getView(newBlock).focus()
                }
            }

            view.onOutdent = {
                guard let row = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                let newBlock = self.blocks[row].outdented

                let oldSelection = self.selection

                if self.handleChangeBlocks(self.blocks.replacing(elementAt: row, with: newBlock)) {
                    // Reapply selection/focus
                    self.updateSelection(from: oldSelection, to: self.selection)
                    self.getView(newBlock).focus()
                }
            }

            view.onMoveToBeginningOfDocument = {
                if BlockListView.commandPaletteVisible { return }

                switch self.selection {
                case .blocks:
                    fatalError("Invalid selection when inside text block")
                    break
                case .item:
                    if let nextLine = self.blocks.firstIndex(where: { $0.supportsInlineFocus }),
                        let nextView = self.getView(nextLine) as? TextBlockContainerView {

                        self.selection = .item(nextLine, .init(location: 0, length: 0))

                        nextView.focus()
                    }
                case .none:
                    break
                }
            }

            view.onMoveToEndOfDocument = {
                if BlockListView.commandPaletteVisible { return }

                switch self.selection {
                case .blocks:
                    fatalError("Invalid selection when inside text block")
                    break
                case .item:
                    if let nextLine = self.blocks.lastIndex(where: { $0.supportsInlineFocus }),
                        let nextView = self.getView(nextLine) as? TextBlockContainerView {

                        let characterIndex = nextView.characterIndexForInsertion(at: NSPoint(x: nextView.bounds.maxX, y: nextView.bounds.maxY))

                        self.selection = .item(nextLine, .init(location: characterIndex, length: 0))

                        nextView.focus()
                    }
                case .none:
                    break
                }
            }

            let handleSelect: (TextSelectionType, Bool) -> Void = { [unowned self] selectionType, isDown in
                switch self.selection {
                case .blocks:
                    fatalError("Invalid selection when inside text block")
                    break
                case .item(let line, _):
                    if self.acceptsFirstResponder {
                        self.window?.makeFirstResponder(self)
                    }

                    switch selectionType {
                    case .line:
                        self.selection = .blocks(.init(location: line, length: 1), anchor: line)
                    case .all:
                        if (isDown) {
                            let range: NSRange = .init(between: line, and: self.blocks.count)
                            self.selection = .blocks(range, anchor: self.blocks.count)
                        } else {
                            let range: NSRange = .init(between: 0, and: line + 1)
                            self.selection = .blocks(range, anchor: 0)
                        }
                    }
                case .none:
                    break
                }
            }

            view.onSelectUp = { type in handleSelect(type, false) }
            view.onSelectDown = { type in handleSelect(type, true) }

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

                // Determine which node keeps the sizeLevel
                let prefixKeepsSizeLevel = prefix.length > 0

                var clone = self.blocks
                clone[line] = .init(id: item.id, content: .text(prefix, prefixKeepsSizeLevel ? view.sizeLevel : .paragraph), listDepth: item.listDepth)

                let nextBlock: EditableBlock = .init(id: UUID(), content: .text(suffix, prefixKeepsSizeLevel ? .paragraph : view.sizeLevel),
                                                     listDepth: item.listDepth)
                clone.insert(nextBlock, at: line + 1)

                if self.handleChangeBlocks(clone) {
                    self.focus(id: nextBlock.id)
                }
            }

            view.onOpenReplacementPalette = { [unowned self] rect in
                self.showReplaceWithTextMenu(rect: rect)
            }

            view.onOpenLinkEditor = { [unowned self] rect in
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                let textValue = view.textValue
                let selectedRange = view.selectedRange

                let link = textValue.attribute(.link, at: selectedRange.location, effectiveRange: nil) as? NSURL

                if let _ = link {
                    var longestRange: NSRange = .empty
                    textValue.attribute(
                        .link,
                        at: view.selectedRange.location,
                        longestEffectiveRange: &longestRange,
                        in: .init(between: 0, and: textValue.length)
                    )
                    self.selection = .item(line, longestRange)
                }

                let initialValue = link?.absoluteString ?? ""

                BlockListView.linkEditor.showsOverflowMenu = !initialValue.isEmpty

                BlockListView.linkEditor.onPressOverflowMenu = { rect in
                    let items: [(SuggestionListItem, () -> Void)] = [
                        (.row("Open link", nil, false, nil, nil), {
                            _ = self.onClickLink?(initialValue)

                            self.hideChildWindows()
                        }),
                        (.row("Unlink", nil, false, nil, nil), {
                            guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                            let newTextValue = view.textValue.removingAttribute(.link, range: view.selectedRange)

                            let id = UUID()
                            let clone = self.blocks.replacing(
                                elementAt: line,
                                with: .init(id: id, content: .text(newTextValue, view.sizeLevel), listDepth: self.blocks[line].listDepth)
                            )

                            self.hideChildWindows()

                            if self.handleChangeBlocks(clone) {
                                self.focus(id: id)
                            }
                        })
                    ]
                    SuggestionWindow.contextMenu.suggestionItems = items.map { $0.0 }

                    self.window?.addChildWindow(SuggestionWindow.contextMenu, ordered: .above)

                    SuggestionWindow.contextMenu.anchorTo(rect: rect)
//                    SuggestionWindow.contextMenu.makeMain()

                    SuggestionWindow.contextMenu.onSubmit = { index in
                        items[index].1()
                    }
                }

                self.showLinkEditor(rect: rect, initialValue: initialValue)

                BlockListView.linkEditor.onPressEnter = { [unowned self] in
                    guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                    guard let url = NSURL(string: BlockListView.linkEditor.suggestionText) else { return }

                    let newTextValue = view.textValue.addingAttribute(.link, value: url, range: view.selectedRange)

                    let id = UUID()
                    let clone = self.blocks.replacing(
                        elementAt: line,
                        with: .init(id: id, content: .text(newTextValue, view.sizeLevel), listDepth: self.blocks[line].listDepth)
                    )

                    self.hideLinkEditor()

                    if self.handleChangeBlocks(clone) {
                        self.focus(id: id)
                    }
                }

                BlockListView.linkEditor.onPressEscapeKey = { [unowned self] in
                    self.hideLinkEditor()
                }
            }

            view.onPasteBlocks = { [unowned self] in
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }
                guard let pastedBlocks = NSPasteboard.general.blocks else { return }

                let isEmpty = self.blocks[line].isEmpty

                if self.replaceBlocks(in: .init(location: isEmpty ? line : line + 1, length: isEmpty ? 1 : 0), with: pastedBlocks) {
                    self.selection = .none
                }
            }

            view.onRequestDeleteEditor = { [unowned self] in
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                var clone = self.blocks
                let textValue = view.textValue

                if view.sizeLevel != .paragraph {
                    let id = UUID()

                    clone = clone.replacing(
                        elementAt: line,
                        with: .init(id: id, content: .text(textValue, .paragraph), listDepth: self.blocks[line].listDepth)
                    )

                    if self.handleChangeBlocks(clone) {
                        self.focus(id: id)

                        // Selection doesn't change, but we still want the side effects
                        self.updateSelection(from: self.selection, to: .item(line, .empty))
                    }

                    return
                }

                if self.blocks[line].listDepth != .none {
                    let id = UUID()

                    func newListDepth(_ listDepth: EditableBlockListDepth) -> EditableBlockListDepth {
                        switch (listDepth) {
                        case .indented:
                            return listDepth.outdented
                        case .ordered, .unordered:
                            return .indented(depth: listDepth.depth)
                        }
                    }

                    clone = clone.replacing(
                        elementAt: line,
                        with: .init(id: id, content: .text(textValue, .paragraph), listDepth: newListDepth(self.blocks[line].listDepth))
                    )

                    if self.handleChangeBlocks(clone) {
                        self.focus(id: id)

                        // Selection doesn't change, but we still want the side effects
                        self.updateSelection(from: self.selection, to: .item(line, .empty))
                    }

                    return
                }

                if line == 0 { return }

                if let previousLine = self.blocks.prefix(upTo: line).lastIndex(where: { $0.supportsMergingText }),
                    let nextView = self.getView(previousLine) as? TextBlockContainerView {

                    let previousBlock = self.blocks[previousLine]
                    let previousTextValue = nextView.textValue
                    let previousSizeLevel = nextView.sizeLevel

                    let mergedTextValue = [previousTextValue, textValue].joined()

                    clone.remove(at: line)
                    clone[previousLine] = .init(
                        id: previousBlock.id,
                        content: .text(mergedTextValue, previousSizeLevel),
                        listDepth: self.blocks[previousLine].listDepth
                    )

                    if self.handleChangeBlocks(clone) {
                        self.focus(id: previousBlock.id)
                        self.selection = .item(previousLine, .init(location: previousTextValue.length, length: 0))
                    }

                    nextView.focus()
                } else {
                    self.selection = .item(line, .empty)
                }
            }

            view.onPressEscape = { [unowned self] in
                self.hideInlineToolbarWindow()
                self.hideCommandPalette()
                self.hideLinkEditor()
            }
        case .divider:
            break
        case .page(_, let target):
            let view = getView(item) as! PageBlock

            view.onPressBlock = { [unowned self] in
                _ = self.onClickPageLink?(target)
            }
        case .image(let url):
            let view = getView(item) as! ImageBackground

            let replaceImageTitle = "Replace image..."

            let handleReplaceImage: () -> Void = {
                guard let window = self.window else { return }

                let windowRect = view.convert(view.frame, to: nil)
                let screenRect = window.convertToScreen(windowRect)
                let adjustedRect = NSRect(
                    x: screenRect.midX - BlockListView.linkEditor.defaultContentWidth / 2,
                    y: screenRect.maxY,
                    width: 0,
                    height: 0
                )

                self.showLinkEditor(rect: adjustedRect, initialValue: url?.absoluteString ?? "")

                BlockListView.linkEditor.onPressEnter = { [unowned self] in
                    guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                    guard let url = URL(string: BlockListView.linkEditor.suggestionText) else { return }

                    let id = UUID()
                    let clone = self.blocks.replacing(
                        elementAt: line,
                        with: .init(id: id, content: .image(url), listDepth: self.blocks[line].listDepth)
                    )

                    self.hideLinkEditor()

                    if self.handleChangeBlocks(clone) {
                        self.focus(id: id)
                    }
                }

                BlockListView.linkEditor.onPressEscapeKey = { [unowned self] in
                    self.hideLinkEditor()
                }

                BlockListView.linkEditor.onDeleteEmptyInput = { [unowned self] in
                    guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                    if self.handleChangeBlocks(self.blocks.removing(at: line)) {
                        self.hideLinkEditor()
                        self.window?.makeFirstResponder(nil)
                    }
                }
            }

            view.onPressImage = {
                guard let line = self.blocks.firstIndex(where: { $0.id == item.id }) else { return }

                self.selection = .blocks(.init(location: line, length: 1))

                // Open the link editor if there's no image
                if url == nil {
                    handleReplaceImage()
                }
            }

            getWrapperView(item).overflowMenu = {
                return [.row(replaceImageTitle, nil, false, nil, nil)] + standardOverflowMenu
            }

            getWrapperView(item).onActivateOverflowMenuItem = { index in
                standardActivateOverflowMenuItem(index)

                guard let menuItems = self.getWrapperView(item).overflowMenu?() else { return }

                let menuItem = menuItems[index]

                switch menuItem.title {
                case replaceImageTitle:
                    handleReplaceImage()
                default:
                    break
                }
            }
        }

        viewFactory.updateViewWidth(block: item, tableView.bounds.width)

        return getWrapperView(item)
    }

    func showLinkEditor(rect: NSRect, initialValue: String) {
        guard let window = self.window else { return }

        let subwindow = BlockListView.linkEditor
        subwindow.suggestionText = initialValue

        window.addChildWindow(subwindow, ordered: .above)

        subwindow.anchorTo(rect: rect, verticalOffset: 4)
        subwindow.focusSearchField()
    }

    func hideLinkEditor() {
        BlockListView.linkEditor.orderOut(nil)
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

    enum Suggestion {
        static var documentationSectionHeader = SuggestionListItem.sectionHeader("MARKDOWN")
        static var tokensSectionHeader = SuggestionListItem.sectionHeader("TOKENS")

        static var text = SuggestionListItem.row("Text", "Write plain text", false, nil, MenuThumbnailImage.paragraph)
        static var heading1 = SuggestionListItem.row("Heading 1", "Large section heading", false, nil, MenuThumbnailImage.h1)
        static var heading2 = SuggestionListItem.row("Heading 2", "Medium section heading", false, nil, MenuThumbnailImage.h2)
        static var heading3 = SuggestionListItem.row("Heading 3", "Small section heading", false, nil, MenuThumbnailImage.h3)
        static var quote = SuggestionListItem.row("Quote", "Display a quote", false, nil, MenuThumbnailImage.quote)
        static var divider = SuggestionListItem.row("Divider", "Horizontal divider", false, nil, MenuThumbnailImage.divider)
        static var image = SuggestionListItem.row("Image", "Display an image", false, nil, MenuThumbnailImage.image)

        static var bulletedList = SuggestionListItem.row("Bulleted List", "Create a bulleted list", false, nil, MenuThumbnailImage.unorderedList)
        static var numberedList = SuggestionListItem.row("Numbered List", "Create a numbered list", false, nil, MenuThumbnailImage.orderedList)
        static var page = SuggestionListItem.row("Page", "Create a sub-page of this page", false, nil, MenuThumbnailImage.page)
    }

    func showCommandPalette(line: Int, query: String, rect: NSRect) {
        guard let window = self.window else { return }

        BlockListView.commandPaletteVisible = true

        let menuItems: [(SuggestionListItem, EditableBlock)] = [
            (Suggestion.documentationSectionHeader, EditableBlock.makeDefaultEmptyBlock()),
            (Suggestion.text, EditableBlock(id: UUID(), content: .text(.init(), .paragraph), listDepth: .none)),
            (Suggestion.heading1, EditableBlock(id: UUID(), content: .text(.init(), .h1), listDepth: .none)),
            (Suggestion.heading2, EditableBlock(id: UUID(), content: .text(.init(), .h2), listDepth: .none)),
            (Suggestion.heading3, EditableBlock(id: UUID(), content: .text(.init(), .h3), listDepth: .none)),
            (Suggestion.quote, EditableBlock(id: UUID(), content: .text(.init(), .quote), listDepth: .none)),
            (Suggestion.divider, EditableBlock(id: UUID(), content: .divider, listDepth: .none)),
            (Suggestion.image, EditableBlock(id: UUID(), content: .image(nil), listDepth: .none)),
            (Suggestion.bulletedList, EditableBlock(id: UUID(), content: .text(.init(), .paragraph), listDepth: .unordered(depth: 1))),
            (Suggestion.numberedList, EditableBlock(id: UUID(), content: .text(.init(), .paragraph), listDepth: .ordered(depth: 1, index: 1))),
            (Suggestion.tokensSectionHeader, EditableBlock.makeDefaultEmptyBlock()),
            (Suggestion.page, EditableBlock(id: UUID(), content: .page(title: "", target: ""), listDepth: .none)),
            (
                SuggestionListItem.row("Color token", "Define a color variable", false, nil, MenuThumbnailImage.tokens),
                EditableBlock(
                    id: UUID(),
                    content: .tokens(
                        LGCSyntaxNode.declaration(
                            .variable(
                                id: UUID(),
                                name: .init(id: UUID(), name: "colorToken1"),
                                annotation: .typeIdentifier(id: UUID(), identifier: .init(id: UUID(), string: "Color"), genericArguments: .empty),
                                initializer: .identifierExpression(id: UUID(), identifier: .init(id: UUID(), string: "placeholder", isPlaceholder: true)),
                                comment: nil
                            )
                        )
                    ),
                    listDepth: .none
                )
            ),
            (
                SuggestionListItem.row("Text style token", "Define a text style variable", false, nil, MenuThumbnailImage.tokens),
                EditableBlock(
                    id: UUID(),
                    content: .tokens(
                        LGCSyntaxNode.declaration(
                            .variable(
                                id: UUID(),
                                name: .init(id: UUID(), name: "textStyleToken1"),
                                annotation: .typeIdentifier(id: UUID(), identifier: .init(id: UUID(), string: "TextStyle"), genericArguments: .empty),
                                initializer: .identifierExpression(id: UUID(), identifier: .init(id: UUID(), string: "placeholder", isPlaceholder: true)),
                                comment: nil
                            )
                        )
                    ),
                    listDepth: .none
                )
            ),
            (
                SuggestionListItem.row("Shadow token", "Define a shadow variable", false, nil, MenuThumbnailImage.tokens),
                EditableBlock(
                    id: UUID(),
                    content: .tokens(
                        LGCSyntaxNode.declaration(
                            .variable(
                                id: UUID(),
                                name: .init(id: UUID(), name: "shadowToken1"),
                                annotation: .typeIdentifier(id: UUID(), identifier: .init(id: UUID(), string: "Shadow"), genericArguments: .empty),
                                initializer: .identifierExpression(id: UUID(), identifier: .init(id: UUID(), string: "placeholder", isPlaceholder: true)),
                                comment: nil
                            )
                        )
                    ),
                    listDepth: .none
                )
            ),
            (
                SuggestionListItem.row("Variable token", "Define a variable", false, nil, MenuThumbnailImage.variable),
                EditableBlock(
                    id: UUID(),
                    content: .tokens(
                        LGCSyntaxNode.declaration(
                            .variable(
                                id: UUID(),
                                name: .init(id: UUID(), name: "variable1"),
                                annotation: .typeIdentifier(
                                    id: UUID(),
                                    identifier: LGCIdentifier(id: UUID(), string: "type", isPlaceholder: true),
                                    genericArguments: .empty
                                ),
                                initializer: .identifierExpression(
                                    id: UUID(),
                                    identifier: LGCIdentifier(id: UUID(), string: "value", isPlaceholder: true)
                                ),
                                comment: nil
                            )
                        )
                    ),
                    listDepth: .none
                )
            )
        ]

        let subwindow = BlockListView.commandPalette

        let suggestionItems: [SuggestionListItem] = menuItems.map { $0.0 }

        subwindow.defaultContentWidth = 260 - 24

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

        // If there are no selectable results, hide the command palette
        if subwindow.selectedIndex == nil {
            hideCommandPalette()
            return
        }

        subwindow.onSelectIndex = { [unowned subwindow] index in
            subwindow.selectedIndex = index
        }

        subwindow.anchorTo(rect: rect, verticalOffset: 4)
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

            if case .page = menuItems[originalIndex].1.content {
                self.hideCommandPalette()

                self.onRequestCreatePage?(line, true)

                return
            }

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
                    replacementBlock = .init(id: self.blocks[line].id, content: .text(mutable, sizeLevel), listDepth: .none)
                }
            case .tokens, .divider, .image, .page:
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
                    switch newBlock.content {
                    case .tokens(.declaration(.variable(_, let pattern, _, _, _))):
                        let view = self.getView(newBlock) as! LogicEditor

                        // This is a workaround to solve the window appearing at the wrong x position.
                        // I think we need to force a layout pass for the window to appear in the correct location.
                        DispatchQueue.main.async {
                            view.showSuggestionWindow(for: pattern.uuid)
                        }
                    default:
                        self.focus(id: newBlock.id)
                    }
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

// MARK: - Copy & Paste

extension BlockListView {
    @IBAction public func copy(_ sender: Any?) {
        switch selection {
        case .none:
            return
        case .item:
            return
        case .blocks(let range, _):
            let selectedBlocks = Array(blocks[range.location..<range.upperBound])

            let data = MarkdownFile.makeMarkdownData(selectedBlocks)

            NSPasteboard.general.declareTypes([.blocks], owner: self)
            NSPasteboard.general.setData(data, forType: .blocks)
        }
    }

    @IBAction public func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    @IBAction public func pasteAsPlainText(_ sender: Any?) {
        guard let pastedBlocks = NSPasteboard.general.blocks else { return }

        handlePasteBlocks(pastedBlocks)
    }

    @IBAction public func pasteAsMdxText(_ sender: Any?) {
        guard let pastedString = NSPasteboard.general.string(forType: .string),
            let data = pastedString.data(using: .utf8),
            let pastedBlocks = MarkdownFile.makeBlocks(data) else { return }

        handlePasteBlocks(pastedBlocks)
    }

    private func handlePasteBlocks(_ pastedBlocks: [EditableBlock]) {
        switch selection {
        case .none:
            break
        case .item(let line, _):
            if replaceBlocks(in: .init(location: line + 1, length: 0), with: pastedBlocks) {
                selection = .none
            }
        case .blocks(let range, _):
            if replaceBlocks(in: range, with: pastedBlocks) {
                selection = .none
            }
        }
    }
}

// MARK: - BlockListTableView

class BlockListTableView: NSTableView {

    public var blocks: [BlockEditor.Block] = []

    override var acceptsFirstResponder: Bool {
        return false
    }

    // Allows clicking into NSTextFields directly (otherwise the NSTableView captures the first click)
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return true
    }
}

// MARK: - Table View Helpers

extension NSTableView {

    var availableRows: [(NSTableRowView, Int)] {
        var rows: [(NSTableRowView, Int)] = []

        enumerateAvailableRowViews { rowView, row in
            rows.append((rowView, row))
        }

        return rows
    }
}
