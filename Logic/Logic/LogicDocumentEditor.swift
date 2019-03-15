import AppKit

public let defaultRootNode = SwiftSyntaxNode.program(
    SwiftProgram(
        id: NSUUID().uuidString,
        block: SwiftList<SwiftStatement>.next(
            SwiftStatement.placeholderStatement(
                SwiftPlaceholderStatement(id: NSUUID().uuidString)
            ),
            .empty
        )
    )
)

// MARK: - LogicDocumentEditor

public class LogicDocumentEditor: NSBox {

    // MARK: Lifecycle

    public init(rootNode: SwiftSyntaxNode = defaultRootNode) {
        self.rootNode = rootNode

        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var rootNode: SwiftSyntaxNode {
        didSet {
            logicEditor.formattedContent = rootNode.formatted
        }
    }

    var childWindow: SuggestionWindow? = SuggestionWindow()

    var suggestionText: String = "" {
        didSet {
            childWindow?.suggestionText = suggestionText
        }
    }

    var selectedSuggestionIndex: Int? {
        didSet {
            childWindow?.selectedIndex = selectedSuggestionIndex
        }
    }

    func indexedSuggestionListItems(for logicSuggestionItems: [LogicSuggestionItem]) -> [(offset: Int, item: SuggestionListItem)] {
        var categories: [(name: String, list: [(offset: Int, item: LogicSuggestionItem)])] = []

        logicSuggestionItems.enumerated().forEach { offset, item in
            if let categoryIndex = categories.firstIndex(where: { $0.name == item.category }) {
                let category = categories[categoryIndex]
                categories[categoryIndex] = (category.name, category.list + [(offset, item)])
            } else {
                categories.append((item.category, [(offset, item)]))
            }
        }

        var suggestionListItems: [(Int, SuggestionListItem)] = []

        categories.forEach { category in
            suggestionListItems.append((0, .sectionHeader(category.name)))

            category.list.forEach { logicItem in
                suggestionListItems.append((logicItem.offset, .row(logicItem.item.title, logicItem.item.disabled)))
            }
        }

        return suggestionListItems
    }

    func logicSuggestionItems(for syntaxNode: SwiftSyntaxNode, prefix: String) -> [LogicSuggestionItem] {
        guard let range = rootNode.elementRange(for: syntaxNode.uuid),
            let elementPath = rootNode.pathTo(id: syntaxNode.uuid) else { return [] }

        let highestMatch = elementPath.first(where: { rootNode.elementRange(for: $0.uuid) == range }) ?? syntaxNode

        return highestMatch.suggestions(for: prefix)
    }

    func nextNode() {
        if let index = self.logicEditor.nextActivatableIndex(after: self.logicEditor.selectedRange?.lowerBound),
            let id = self.rootNode.formatted.elements[index].syntaxNodeID {

            self.logicEditor.selectedRange = self.rootNode.elementRange(for: id)
            self.suggestionText = ""

            let nextSyntaxNode = self.rootNode.topNodeWithEqualElements(as: id)
            self.showSuggestionWindow(for: index, syntaxNode: nextSyntaxNode)
        } else {
            Swift.print("No next node to activate")

            self.hideSuggestionWindow()
        }
    }

    func previousNode() {
        if let index = self.logicEditor.previousActivatableIndex(before: self.logicEditor.selectedRange?.lowerBound),
            let id = self.rootNode.formatted.elements[index].syntaxNodeID {

            self.logicEditor.selectedRange = self.rootNode.elementRange(for: id)
            self.suggestionText = ""

            let nextSyntaxNode = self.rootNode.topNodeWithEqualElements(as: id)
            self.showSuggestionWindow(for: index, syntaxNode: nextSyntaxNode)
        } else {
            Swift.print("No previous node to activate")

            self.hideSuggestionWindow()
        }
    }

    func showSuggestionWindow(for nodeIndex: Int, syntaxNode: SwiftSyntaxNode) {
        guard let window = self.window, let childWindow = self.childWindow else { return }

        let syntaxNodePath = self.rootNode.uniqueElementPathTo(id: syntaxNode.uuid)
        let dropdownNodes = Array(syntaxNodePath)

        var logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: suggestionText)

        let originalIndexedSuggestions = indexedSuggestionListItems(for: logicSuggestions)
        childWindow.detailView = logicSuggestions.first?.node.documentation(for: suggestionText).makeScrollView()
        childWindow.suggestionItems = originalIndexedSuggestions.map { $0.item }
        childWindow.selectedIndex = originalIndexedSuggestions.firstIndex { $0.item.isSelectable }
        childWindow.dropdownValues = dropdownNodes.map { $0.nodeTypeDescription }
        childWindow.dropdownIndex = dropdownNodes.count - 1

        childWindow.onSelectIndex = { index in
            self.selectedSuggestionIndex = index

            if let index = index {
                let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
                let suggestedNode = logicSuggestions[indexedSuggestions[index].offset].node

                childWindow.detailView = suggestedNode.documentation(for: self.suggestionText).makeScrollView()
            } else {
                childWindow.detailView = nil
            }
        }

        childWindow.onPressEscapeKey = {
            self.hideSuggestionWindow()
        }

        childWindow.onPressTabKey = self.nextNode

        childWindow.onPressShiftTabKey = self.previousNode

        childWindow.onHighlightDropdownIndex = { highlightedIndex in
            if let highlightedIndex = highlightedIndex {
                let selected = dropdownNodes[highlightedIndex]
                let range = self.rootNode.elementRange(for: selected.uuid)

                self.logicEditor.outlinedRange = range
            } else {
                self.logicEditor.outlinedRange = nil
            }
        }

        childWindow.onSelectDropdownIndex = { selectedIndex in
            self.logicEditor.outlinedRange = nil
            self.select(nodeByID: dropdownNodes[selectedIndex].uuid)
        }

        childWindow.onSubmit = { index in
            let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
            let logicSuggestionItem = logicSuggestions[indexedSuggestions[index].offset]

            if logicSuggestionItem.disabled { return }

            let suggestedNode = logicSuggestionItem.node

            Swift.print("Chose suggestion", suggestedNode)

            let replacement = self.rootNode.replace(id: syntaxNode.uuid, with: suggestedNode)

            self.rootNode = replacement

            self.logicEditor.formattedContent = self.rootNode.formatted

            if suggestedNode.movementAfterInsertion == .next {
                self.nextNode()
            } else {
                self.handleActivateElement(self.logicEditor.selectedRange?.lowerBound)
            }
        }

        childWindow.onChangeSuggestionText = { value in
            self.suggestionText = value

            // Update logicSuggestions
            logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: value)

            let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
            childWindow.suggestionItems = indexedSuggestions.map { $0.item }
            childWindow.selectedIndex = indexedSuggestions.firstIndex(where: { $0.item.isSelectable })
        }

        window.addChildWindow(childWindow, ordered: .above)

        if let rect = self.logicEditor.getBoundingRect(for: nodeIndex) {
            let screenRect = window.convertToScreen(rect)
            childWindow.anchorTo(rect: screenRect)
            childWindow.focusSearchField()
        }
    }

    func hideSuggestionWindow() {
        guard let window = self.window, let childWindow = self.childWindow else { return }

        window.removeChildWindow(childWindow)
        childWindow.setIsVisible(false)
    }

    func select(nodeByID syntaxNodeId: SwiftUUID?) {
        self.logicEditor.selectedLine = nil
        self.suggestionText = ""

        if let syntaxNodeId = syntaxNodeId {
            let topNode = self.rootNode.topNodeWithEqualElements(as: syntaxNodeId)

            if let selectedRange = self.rootNode.elementRange(for: topNode.uuid) {
                self.logicEditor.selectedRange = selectedRange
                self.showSuggestionWindow(for: selectedRange.lowerBound, syntaxNode: topNode)
            } else {
                self.logicEditor.selectedRange = nil
                self.hideSuggestionWindow()
            }
        } else {
            self.logicEditor.selectedRange = nil
            self.hideSuggestionWindow()
        }
    }

    // MARK: Private

    private let logicEditor = LogicElementEditor()

    func handleActivateElement(_ activatedIndex: Int?) {
        if let activatedIndex = activatedIndex {
            let id = self.rootNode.formatted.elements[activatedIndex].syntaxNodeID
            self.select(nodeByID: id)
        } else {
            self.select(nodeByID: nil)
        }
    }

    func handleActivateLine(_ activatedLineIndex: Int) {
        handleActivateElement(nil)

        Swift.print("Activate line \(activatedLineIndex)")

        logicEditor.selectedLine = activatedLineIndex
    }

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero

        addSubview(logicEditor)

        logicEditor.formattedContent = rootNode.formatted
        logicEditor.onActivate = handleActivateElement
        logicEditor.onActivateLine = handleActivateLine
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        logicEditor.translatesAutoresizingMaskIntoConstraints = false
        
        logicEditor.topAnchor.constraint(equalTo: topAnchor).isActive = true
        logicEditor.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        logicEditor.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        logicEditor.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func update() {}
}
