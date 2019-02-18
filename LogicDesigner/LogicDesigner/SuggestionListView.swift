import AppKit
import Foundation

public enum SuggestionListItem {
    case sectionHeader(String)
    case row(String)

    public var isSelectable: Bool {
        switch self {
        case .row:
            return true
        case .sectionHeader:
            return false
        }
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
                tableView.scrollRowToVisible(selectedIndex)

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

    // MARK: Private

    private var tableView = SuggestionListTableView()
    private let scrollView = NSScrollView()
    private let tableColumn = NSTableColumn(title: "Suggestions", minWidth: 100)

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero

        tableView.addTableColumn(tableColumn)
        tableView.intercellSpacing = NSSize.zero
        tableView.headerView = nil
        tableView.dataSource = self
        tableView.delegate = self

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
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

// MARK: - Delegate

extension SuggestionListView: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return items[row].isSelectable
    }

    public func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        let item = items[row]

        switch item {
        case .row:
            return false
        case .sectionHeader:
            return true
        }
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]

        switch item {
        case .row(let value):
            let rowView = ResultRow(titleText: value, selected: row == selectedIndex)
            rowView.fillColor = row == selectedIndex ? NSColor.selectedMenuItemColor : NSColor.clear
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
        let item = items[row]

        switch item {
        case .row:
            return 26
        case .sectionHeader:
            return 18
        }
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
