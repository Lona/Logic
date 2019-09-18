import AppKit
import Foundation

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

// MARK: - SuggestionListView

public class SuggestionListView: NSBox {

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

    public var parameters: Parameters {
        didSet {
            if parameters != oldValue {
                update()
            }
        }
    }

    public var items: [SuggestionListItem] = [] {
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

    private var tableView = SuggestionListTableView()
    private let scrollView = NSScrollView()
    private let tableColumn = NSTableColumn(title: "Suggestions", minWidth: 100)

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero
        fillColor = Colors.suggestionListBackground

        tableView.addTableColumn(tableColumn)
        tableView.intercellSpacing = NSSize.zero
        tableView.headerView = nil
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.action = #selector(handleDoubleAction)
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
}

// MARK: - Target

extension SuggestionListView {
    @objc func handleDoubleAction(_ sender: AnyObject) {
        guard tableView.clickedRow >= 0 else { return }

        let item = self.items[tableView.clickedRow]
        if item.isSelectable {
            self.onActivateIndex?(tableView.clickedRow)
        }
    }
}

// MARK: - Delegate

extension SuggestionListView: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return items[row].isSelectable
    }

    public func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return items[row].isGroupRow
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]

        var disabledBackgroundColor = Colors.greyBackground

        if #available(OSX 10.14, *) {
            disabledBackgroundColor = NSColor.unemphasizedSelectedContentBackgroundColor
        }

        func fillColor(disabled: Bool) -> NSColor {
            return row != selectedIndex
                ? NSColor.clear
                : disabled
                ? disabledBackgroundColor
                : NSColor.selectedMenuItemColor
        }

        switch item {
        case .row(let value, let subtitle, let disabled, let badge, let image):
            let rowView = ResultRow(titleText: value, subtitleText: subtitle, selected: row == selectedIndex, disabled: disabled, badgeText: badge, image: image)
            rowView.fillColor = fillColor(disabled: disabled)
            return rowView
        case .colorRow(name: let value, code: let code, let color, let disabled):
            let rowView = ColorRow(
                titleText: value,
                subtitleText: code,
                selected: row == selectedIndex,
                disabled: disabled,
                previewColor: color)
            rowView.fillColor = fillColor(disabled: disabled)
            return rowView
        case .textStyleRow(let value, let style, let disabled):
            let rowView = TextStyleRow(
                titleText: value,
                textStyle: style,
                selected: row == selectedIndex,
                disabled: disabled)
            rowView.fillColor = fillColor(disabled: disabled)
            return rowView
        case .sectionHeader(let value):
            return ResultSectionHeader(titleText: value)
        }
    }

    public func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let proposedIndex = proposedSelectionIndexes.first {
                let item = self.items[proposedIndex]
                if item.isSelectable {
                    self.onSelectIndex?(proposedIndex)
                }
            } else {
                self.onSelectIndex?(nil)
            }
        }

        return tableView.selectedRowIndexes
    }
}

// MARK: - Data source

extension SuggestionListView: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return items[row].height
    }
}

// MARK: - Parameters

extension SuggestionListView {
    public struct Parameters: Equatable {
        public init() {}
    }
}

// MARK: - SuggestionListTableView

class SuggestionListTableView: NSTableView {
    override var acceptsFirstResponder: Bool {
        return false
    }
}
