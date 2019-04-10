import AppKit

// MARK: - LogicEditor

public class LogicEditor: NSBox {

    // MARK: Lifecycle

    public init(rootNode: LGCSyntaxNode = defaultRootNode) {
        self.rootNode = rootNode

        super.init(frame: .zero)

        self.suggestionsForNode = { [unowned self] node, query in
            return LogicEditor.defaultSuggestionsForNode(node, self.rootNode, query)
        }

        self.documentationForNode = { [unowned self] node, query in
            return LogicEditor.defaultDocumentationForNode(node, self.rootNode, query)
        }

        setUpViews()
        setUpConstraints()
        setScroll(enabled: true)

        update()

        let notificationTokens = [
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: self.childWindow,
                queue: nil,
                using: { [weak self] notification in self?.hideSuggestionWindow() }
            ),
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignMainNotification,
                object: self.childWindow,
                queue: nil,
                using: { [weak self] notification in self?.hideSuggestionWindow() }
            )
        ]

        subscriptions.append({
            notificationTokens.forEach {
                NotificationCenter.default.removeObserver($0)
            }
        })
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        subscriptions.forEach { subscription in subscription() }
    }

    // MARK: Public

    public var scrollsVertically = true {
        didSet { setScroll(enabled: scrollsVertically) }
    }

    public var canvasStyle = LogicCanvasView.Style() {
        didSet {
            canvasView.style = canvasStyle
        }
    }

    public var onChangeRootNode: ((LGCSyntaxNode) -> Bool)?

    public var getDecorationForNodeID: ((UUID) -> LogicElement.Decoration?)? {
        get { return canvasView.getElementDecoration }
        set { canvasView.getElementDecoration = newValue }
    }

    public var rootNode: LGCSyntaxNode {
        didSet {
            canvasView.formattedContent = rootNode.formatted
        }
    }

    public var showsDropdown: Bool {
        get { return childWindow.showsDropdown }
        set { childWindow.showsDropdown = newValue }
    }

    public var suggestionsForNode: ((LGCSyntaxNode, String) -> [LogicSuggestionItem]) = { _, _
        in return []
    }

    public var documentationForNode: ((LGCSyntaxNode, String) -> RichText) = { _, _ in
        return RichText(blocks: [])
    }

    public static let defaultRootNode = LGCSyntaxNode.program(
        LGCProgram(
            id: UUID(),
            block: LGCList<LGCStatement>.next(
                LGCStatement.placeholderStatement(id: UUID()),
                .empty
            )
        )
    )

    public static let defaultSuggestionsForNode: (
        LGCSyntaxNode,
        LGCSyntaxNode,
        String) -> [LogicSuggestionItem] = { node, rootNode, query in
        return node.suggestions(within: rootNode, for: query)
    }

    public static let defaultDocumentationForNode: (
        LGCSyntaxNode,
        LGCSyntaxNode,
        String) -> RichText = { node, rootNode, query in
            return node.documentation(within: rootNode, for: query)
    }

    public func forceUpdate() {
        canvasView.forceUpdate()
    }

    // MARK: Private

    private var subscriptions: [() -> Void] = []

    private var suggestionText: String = "" {
        didSet {
            childWindow.suggestionText = suggestionText
        }
    }

    private var selectedSuggestionIndex: Int? {
        didSet {
            childWindow.selectedIndex = selectedSuggestionIndex
        }
    }

    private lazy var childWindow: SuggestionWindow = SuggestionWindow()

    private let canvasView = LogicCanvasView()
    private let scrollView = NSScrollView()

    private func setScroll(enabled: Bool) {
        if enabled {
            canvasView.removeFromSuperview()

            scrollView.documentView = canvasView
            scrollView.isHidden = false

            canvasView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor).isActive = true
            canvasView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor).isActive = true
            canvasView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor).isActive = true
        } else {
            addSubview(canvasView)

            scrollView.documentView = nil
            scrollView.isHidden = true

            canvasView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            canvasView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            canvasView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            canvasView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
    }

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        addSubview(scrollView)

        canvasView.formattedContent = rootNode.formatted
        canvasView.onActivate = handleActivateElement
        canvasView.onActivateLine = handleActivateLine
        canvasView.onPressTabKey = nextNode
        canvasView.onPressShiftTabKey = previousNode
        canvasView.onPressDeleteKey = handleDelete
        canvasView.onMoveLine = handleMoveLine
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func update() {}
}

// MARK: - Selection

extension LogicEditor {

    private func handleDelete() {
        let formattedContent = rootNode.formatted
        let elements = formattedContent.elements

        func range() -> Range<Int>? {
            if let selectedLine = canvasView.selectedLine {
                return formattedContent.elementIndexRange(for: selectedLine)
            } else {
                return canvasView.selectedRange
            }
        }

        if let selectedRange = range(), let selectedNode = self.rootNode.topNodeWithEqualRange(as: selectedRange) {
            let shouldActivate = onChangeRootNode?(rootNode.delete(id: selectedNode.uuid))
            if shouldActivate == true {
                handleActivateElement(nil)
            }
        }
    }

    private func handleMoveLine(_ sourceLineIndex: Int, _ destinationLineIndex: Int) {
        Swift.print(sourceLineIndex, "=>", destinationLineIndex)

        let formattedContent = rootNode.formatted
        let elements = formattedContent.elements

        if let sourceRange = formattedContent.elementIndexRange(for: sourceLineIndex),
            let destinationRange = formattedContent.elementIndexRange(for: destinationLineIndex),
            let sourceId = elements[sourceRange].first?.syntaxNodeID,
            let targetId = elements[destinationRange].first?.syntaxNodeID {

            _ = onChangeRootNode?(rootNode.swap(sourceId: sourceId, targetId: targetId))
        }
    }

    private func nextNode() {
        if let index = rootNode.formatted.nextActivatableElementIndex(after: self.canvasView.selectedRange?.lowerBound),
            let id = self.rootNode.formatted.elements[index].syntaxNodeID {

            self.canvasView.selectedRange = self.rootNode.elementRange(for: id)
            self.suggestionText = ""

            let nextSyntaxNode = self.rootNode.topNodeWithEqualElements(as: id)
            self.showSuggestionWindow(for: index, syntaxNode: nextSyntaxNode)
        } else {
            Swift.print("No next node to activate")

            self.hideSuggestionWindow()
        }
    }

    private func previousNode() {
        if let index = rootNode.formatted.previousActivatableElementIndex(before: self.canvasView.selectedRange?.lowerBound),
            let id = self.rootNode.formatted.elements[index].syntaxNodeID {

            self.canvasView.selectedRange = self.rootNode.elementRange(for: id)
            self.suggestionText = ""

            let nextSyntaxNode = self.rootNode.topNodeWithEqualElements(as: id)
            self.showSuggestionWindow(for: index, syntaxNode: nextSyntaxNode)
        } else {
            Swift.print("No previous node to activate")

            self.hideSuggestionWindow()
        }
    }

    private func select(nodeByID syntaxNodeId: UUID?) {
        self.canvasView.selectedLine = nil
        self.suggestionText = ""

        if let syntaxNodeId = syntaxNodeId {
            let topNode = self.rootNode.topNodeWithEqualElements(as: syntaxNodeId)

            if let selectedRange = self.rootNode.elementRange(for: topNode.uuid) {
                self.canvasView.selectedRange = selectedRange
                self.showSuggestionWindow(for: selectedRange.lowerBound, syntaxNode: topNode)
            } else {
                self.canvasView.selectedRange = nil
                self.hideSuggestionWindow()
            }
        } else {
            self.canvasView.selectedRange = nil
            self.hideSuggestionWindow()
        }
    }

    private func handleActivateElement(_ activatedIndex: Int?) {
        if let activatedIndex = activatedIndex {
            let elements = self.rootNode.formatted.elements

            if activatedIndex < elements.count {
                self.select(nodeByID: elements[activatedIndex].syntaxNodeID)
                return
            }
        }

        self.select(nodeByID: nil)
    }

    private func handleActivateLine(_ activatedLineIndex: Int) {
        handleActivateElement(nil)

        canvasView.selectedLine = activatedLineIndex
    }
}

// MARK: - Suggestions

extension LogicEditor {

    private func indexedSuggestionListItems(for logicSuggestionItems: [LogicSuggestionItem]) -> [(offset: Int, item: SuggestionListItem)] {
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
                switch logicItem.item.style {
                case .normal:
                    suggestionListItems.append((logicItem.offset, .row(logicItem.item.title, logicItem.item.disabled)))
                case .colorPreview(code: let code, let color):
                    suggestionListItems.append(
                        (
                            logicItem.offset,
                            .colorRow(name: logicItem.item.title, code: code, color, logicItem.item.disabled)
                        )
                    )
                }
            }
        }

        return suggestionListItems
    }

    private func logicSuggestionItems(for syntaxNode: LGCSyntaxNode, prefix: String) -> [LogicSuggestionItem] {
        guard let range = rootNode.elementRange(for: syntaxNode.uuid),
            let elementPath = rootNode.pathTo(id: syntaxNode.uuid) else { return [] }

        let highestMatch = elementPath.first(where: { rootNode.elementRange(for: $0.uuid) == range }) ?? syntaxNode

        return suggestionsForNode(highestMatch, prefix)
    }
}

// MARK: - Suggestion Window

extension LogicEditor {

    private func makeDetailView(for syntaxNode: LGCSyntaxNode?, query: String) -> NSView? {
        if let syntaxNode = syntaxNode {
            return documentationForNode(syntaxNode, query).makeScrollView()
        } else {
            return nil
        }
    }

    private func showSuggestionWindow(for nodeIndex: Int, syntaxNode: LGCSyntaxNode) {
        guard let window = self.window else { return }

        let syntaxNodePath = self.rootNode.uniqueElementPathTo(id: syntaxNode.uuid)
        let dropdownNodes = Array(syntaxNodePath)

        var logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: suggestionText)

        let originalIndexedSuggestions = indexedSuggestionListItems(for: logicSuggestions)
        childWindow.detailView = makeDetailView(for: logicSuggestions.first?.node, query: suggestionText)
        childWindow.suggestionItems = originalIndexedSuggestions.map { $0.item }
        childWindow.selectedIndex = originalIndexedSuggestions.firstIndex { $0.item.isSelectable }
        childWindow.dropdownValues = dropdownNodes.map { $0.nodeTypeDescription }
        childWindow.dropdownIndex = dropdownNodes.count - 1

        childWindow.onSelectIndex = { index in
            self.selectedSuggestionIndex = index

            if let index = index {
                let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
                let suggestedNode = logicSuggestions[indexedSuggestions[index].offset].node

                self.childWindow.detailView = self.makeDetailView(for: suggestedNode, query: self.suggestionText)
            } else {
                self.childWindow.detailView = nil
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

                self.canvasView.outlinedRange = range
            } else {
                self.canvasView.outlinedRange = nil
            }
        }

        childWindow.onSelectDropdownIndex = { selectedIndex in
            self.canvasView.outlinedRange = nil
            self.select(nodeByID: dropdownNodes[selectedIndex].uuid)
        }

        childWindow.onSubmit = { index in
            let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
            let logicSuggestionItem = logicSuggestions[indexedSuggestions[index].offset]

            if logicSuggestionItem.disabled { return }

            let suggestedNode = logicSuggestionItem.node

//            Swift.print("Chose suggestion", suggestedNode)

            let replacement = self.rootNode.replace(id: syntaxNode.uuid, with: suggestedNode)

            if self.onChangeRootNode?(replacement) == true {
                if let nextFocusId = logicSuggestionItem.nextFocusId {
                    self.select(nodeByID: nextFocusId)
                } else if suggestedNode.movementAfterInsertion == .next {
                    self.nextNode()
                } else {
                    self.handleActivateElement(self.canvasView.selectedRange?.lowerBound)
                }
            }
        }

        childWindow.onChangeSuggestionText = { value in
            self.suggestionText = value

            // Update logicSuggestions
            logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: value)

            let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)

            self.childWindow.suggestionItems = indexedSuggestions.map { $0.item }
            self.childWindow.selectedIndex = indexedSuggestions.firstIndex(where: { $0.item.isSelectable })
            if let selectedItem = logicSuggestions.first {
                self.childWindow.detailView = self.makeDetailView(for: selectedItem.node, query: self.suggestionText)
            }
        }

        window.addChildWindow(childWindow, ordered: .above)

        if let elementRect = canvasView.getElementRect(for: nodeIndex) {
            let windowRect = canvasView.convert(elementRect, to: nil)
            let screenRect = window.convertToScreen(windowRect)

            // Adjust the window to left-align suggestions with the element's text
            let adjustedRect = NSRect(
                x: screenRect.minX - 12 + canvasStyle.textPadding.width,
                y: screenRect.minY - 2,
                width: screenRect.width,
                height: screenRect.height)

            childWindow.anchorTo(rect: adjustedRect)
            childWindow.focusSearchField()
        }
    }

    private func hideSuggestionWindow() {
        guard let window = self.window else { return }

        window.removeChildWindow(childWindow)
        childWindow.setIsVisible(false)
    }
}
