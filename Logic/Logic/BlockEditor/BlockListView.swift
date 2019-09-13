//
//  BlockListView.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

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

    public var blocks: [BlockEditor.Block] = [] {
        didSet {
            update()
        }
    }

    public var selectedIndex: Int? {
        didSet {
            if let selectedIndex = selectedIndex {
                tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)

                // Check that the view is currently visible, otherwise it will scroll to the bottom
                if visibleRect != .zero {
                    tableView.scrollRowToVisible(selectedIndex)
                }

                var reloadIndexSet = IndexSet(integer: selectedIndex)

                if let oldValue = oldValue {
                    reloadIndexSet.insert(oldValue)
                }

                tableView.reloadData(forRowIndexes: reloadIndexSet, columnIndexes: IndexSet(integer: 0))
            } else {
                tableView.selectRowIndexes(IndexSet(), byExtendingSelection: false)
            }
        }
    }

    public var onSelectIndex: ((Int?) -> Void)?
    public var onActivateIndex: ((Int) -> Void)?

    // MARK: Private

    private var tableView = BlockListTableView()
    private let scrollView = NSScrollView()
    private let tableColumn = NSTableColumn(title: "Suggestions", minWidth: 100)

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
        //        tableView.action = #selector(handleDoubleAction)
        tableView.backgroundColor = .clear

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = tableView

        addSubview(scrollView)

        tableView.reloadData()
        tableView.sizeToFit()
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
        tableView.reloadData()
        tableView.sizeToFit()
    }

    override public var acceptsFirstResponder: Bool {
        return false
    }
}

// MARK: - Target

//extension BlockListView {
//    @objc func handleDoubleAction(_ sender: AnyObject) {
//        guard tableView.clickedRow > 0 else { return }
//
//        let item = self.items[tableView.clickedRow]
//        if item.isSelectable {
//            self.onActivateIndex?(tableView.clickedRow)
//        }
//    }
//}

// MARK: - Delegate

extension BlockListView: NSTableViewDelegate {
    //    public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    //        return items[row].isSelectable
    //    }
    //
    //    public func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
    //        return items[row].isGroupRow
    //    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = blocks[row]

        //        var disabledBackgroundColor = Colors.greyBackground
        //
        //        if #available(OSX 10.14, *) {
        //            disabledBackgroundColor = NSColor.unemphasizedSelectedContentBackgroundColor
        //        }
        //
        //        func fillColor(disabled: Bool) -> NSColor {
        //            return row != selectedIndex
        //                ? NSColor.clear
        //                : disabled
        //                ? disabledBackgroundColor
        //                : NSColor.selectedMenuItemColor
        //        }

        switch item {
        case .text(let value):
            let initialValue = value.map { $0.editableString }.joined()

            let view = InlineBlockEditor(frame: .zero)
            view.textValue = initialValue
            view.onChangeTextValue = { [unowned self] newValue in
                view.textValue = newValue
//                self.tableView.noteHeightOfRows(withIndexesChanged: .init(integer: row))
            }
            return view
        }
    }

//    public override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
//        return true
//    }

    //    public func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
    //        DispatchQueue.main.async { [weak self] in
    //            guard let self = self else { return }
    //
    //            if let proposedIndex = proposedSelectionIndexes.first {
    //                let item = self.items[proposedIndex]
    //                if item.isSelectable {
    //                    self.onSelectIndex?(proposedIndex)
    //                }
    //            } else {
    //                self.onSelectIndex?(nil)
    //            }
    //        }
    //
    //        return tableView.selectedRowIndexes
    //    }
}

// MARK: - Data source

extension BlockListView: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return blocks.count
    }

    //    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    //        return items[row].height
    //    }
}

class BlockListTableView: NSTableView {
    override var acceptsFirstResponder: Bool {
        return false
    }

    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return true
    }

//    public override func hitTest(_ point: NSPoint) -> NSView? {
//        let position = convert(point, from: nil)
//
//        let rows = self.rows(in: bounds)
//
//        //        Swift.print("rows", rows)
//
//        guard let range = Range(rows) else { return nil }
//
//        for index in range {
//            let rect = self.rect(ofRow: index)
//
//            Swift.print(rect, position)
//
//            if rect.contains(position) {
//                return self.rowView(atRow: index, makeIfNecessary: true)
//            }
//        }
//
//        return nil
//    }
}
