import AppKit

// MARK: - LogicEditor

public class LogicEditor: NSBox {

    // MARK: Lifecycle

    public init(rootNode: LGCSyntaxNode = defaultRootNode) {
        self.rootNode = rootNode

        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()
        setScroll(enabled: true)

        update()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var supportsLineSelection = true {
        didSet {
            if !supportsLineSelection, let _ = canvasView.selectedLine {
                canvasView.selectedLine = nil
            }
        }
    }

    public var scrollsVertically = true {
        didSet { setScroll(enabled: scrollsVertically) }
    }

    public var canvasStyle = LogicCanvasView.Style() {
        didSet {
            canvasView.style = canvasStyle
        }
    }

    public var willSelectNode: ((LGCSyntaxNode, UUID?) -> UUID?)? = LogicEditor.defaultWillSelectNode

    public var onChangeRootNode: ((LGCSyntaxNode) -> Bool)?

    public var decorationForNodeID: ((UUID) -> LogicElement.Decoration?)? {
        get { return canvasView.getElementDecoration }
        set { canvasView.getElementDecoration = newValue }
    }

    public var rootNode: LGCSyntaxNode {
        didSet {
            canvasView.formattedContent = rootNode.formatted(using: formattingOptions)
        }
    }

    public var formattingOptions = LogicFormattingOptions.normal {
        didSet {
            canvasView.formattedContent = rootNode.formatted(using: formattingOptions)
        }
    }

    public var underlinedId: UUID? {
        didSet {
            guard let underlinedId = underlinedId else {
                canvasView.underlinedRange = nil
                return
            }

            let topNode = self.rootNode.topNodeWithEqualElements(as: underlinedId, options: formattingOptions, includeTopLevel: false)

            if let selectedRange = self.rootNode.elementRange(for: topNode.uuid, options: formattingOptions, includeTopLevel: false) {
                self.canvasView.underlinedRange = selectedRange
            } else {
                self.canvasView.underlinedRange = nil
            }
        }
    }

    public var suggestionFilter: SuggestionView.SuggestionFilter = .recommended {
        didSet {
            childWindow.suggestionFilter = suggestionFilter
        }
    }

    public var onChangeSuggestionFilter: ((SuggestionView.SuggestionFilter) -> Void)?

    public var showsDropdown: Bool = true

    public var showsFilterBar: Bool = false

    public var contextMenuForNode: ((LGCSyntaxNode, LGCSyntaxNode) -> NSMenu?) = {_, _ in nil}

    public var suggestionsForNode: ((LGCSyntaxNode, LGCSyntaxNode, String) -> [LogicSuggestionItem]) = LogicEditor.defaultSuggestionsForNode

    public var documentationForSuggestion: (
        LGCSyntaxNode,
        LogicSuggestionItem,
        String,
        LogicSuggestionItem.DynamicSuggestionBuilder
        ) -> NSView = LogicEditor.defaultDocumentationForSuggestion

    public static let defaultRootNode = LGCSyntaxNode.program(
        LGCProgram(
            id: UUID(),
            block: LGCList<LGCStatement>.next(
                LGCStatement.placeholder(id: UUID()),
                .empty
            )
        )
    )

    public static let defaultSuggestionsForNode: (
        LGCSyntaxNode,
        LGCSyntaxNode,
        String) -> [LogicSuggestionItem] = { rootNode, node, query in
        return node.suggestions(within: rootNode, for: query)
    }

    public static let defaultDocumentationForSuggestion: (
        LGCSyntaxNode,
        LogicSuggestionItem,
        String,
        LogicSuggestionItem.DynamicSuggestionBuilder
        ) -> NSView = { rootNode, suggestion, query, builder in
        return suggestion.documentation?(builder) ?? suggestion.node.documentation(within: rootNode, for: query)
    }

    public static let defaultWillSelectNode: (LGCSyntaxNode, UUID?) -> UUID? = { (rootNode: LGCSyntaxNode, nodeId: UUID?) in
        guard let nodeId = nodeId else { return nil }

        return rootNode.redirectSelection(nodeId)
    }

    public func forceUpdate() {
        canvasView.forceUpdate()
    }

    // MARK: Private

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

    private var childWindow: SuggestionWindow {
        return SuggestionWindow.shared
    }

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
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        addSubview(scrollView)

        canvasView.formattedContent = rootNode.formatted(using: formattingOptions)
        canvasView.onActivate = handleActivateElement
        canvasView.onActivateLine = handleActivateLine
        canvasView.onRightClick = handleRightClick
        canvasView.onPressTabKey = nextNode
        canvasView.onPressShiftTabKey = previousNode
        canvasView.onPressDeleteKey = handleDelete
        canvasView.onMoveLine = handleMoveLine
        canvasView.onBlur = handleBlur
        canvasView.onFocus = handleFocus
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

    private func handleFocus() {
        if let firstIndex = rootNode.formatted(using: formattingOptions).elements.firstIndex(where: { $0.isActivatable }) {
            canvasView.selectedRange = firstIndex..<firstIndex + 1
        }
    }

    private func handleBlur() {
        handleActivateElement(nil)
    }

    private func handleDelete() {
        let formattedContent = rootNode.formatted(using: formattingOptions)
        let elements = formattedContent.elements

        func range() -> Range<Int>? {
            if let selectedLine = canvasView.selectedLine {
                return formattedContent.elementIndexRange(for: selectedLine)
            } else {
                return canvasView.selectedRange
            }
        }

        if let selectedRange = range(),
            let selectedNode = self.rootNode.topNodeWithEqualRange(as: selectedRange, options: formattingOptions, includeTopLevel: false) {
            let shouldActivate = onChangeRootNode?(rootNode.delete(id: selectedNode.uuid))
            if shouldActivate == true {
                handleActivateElement(nil)
            }
        }
    }

    private func handleMoveLine(_ sourceLineIndex: Int, _ destinationLineIndex: Int) {
//        Swift.print(sourceLineIndex, "=>", destinationLineIndex)

        // Find the smallest node that accepts a line drag
        func findDragSource(node: LGCSyntaxNode) -> LGCSyntaxNode? {
            guard var path = rootNode.pathTo(id: node.uuid) else { return nil }

            while let current = path.last {
                if current.contents.acceptsLineDrag(rootNode: rootNode) {
                    return current
                }

                path = path.dropLast()
            }

            return nil
        }

        // Find the smallest node that accepts a drop
        func findDropTarget(relativeTo node: LGCSyntaxNode, accepting sourceNode: LGCSyntaxNode) -> LGCSyntaxNode? {
            guard var path = rootNode.pathTo(id: node.uuid, includeTopLevel: true) else { return nil }

            while let parent = path.dropLast().last {
                if parent.contents.acceptsNode(rootNode: rootNode, childNode: sourceNode) {
                    return parent
                }

                path = path.dropLast()
            }

            return nil
        }

        // Determine the index of the target within its parent, since we'll be inserting the source node relative to it
        func findDropIndex(relativeTo node: LGCSyntaxNode, within parent: LGCSyntaxNode, index: Int) -> Int? {
            let childRanges = parent.contents.children.map {
                rootNode.elementRange(for: $0.uuid, options: formattingOptions, includeTopLevel: false, useOwnerId: true)
                }.compactMap { $0 }

            return childRanges.firstIndex(where: { $0.contains(index) })
        }

        let formattedContent = rootNode.formatted(using: formattingOptions)

        if let sourceRange = formattedContent.elementIndexRange(for: sourceLineIndex),
            let destinationRange = formattedContent.elementIndexRange(for: destinationLineIndex),
            let originalSourceNode = rootNode.topNodeWithEqualRange(as: sourceRange, options: formattingOptions, includeTopLevel: false, useOwnerId: true),
            let sourceNode = findDragSource(node: originalSourceNode),
            let targetNode = rootNode.topNodeWithEqualRange(as: destinationRange, options: formattingOptions, includeTopLevel: true, useOwnerId: true) {

            // Target is within source
            if let _ = sourceNode.find(id: targetNode.uuid) { return }

            var initialParent = targetNode
            while let targetParent = findDropTarget(relativeTo: initialParent, accepting: sourceNode) {
                initialParent = targetParent

                if let targetIndex = findDropIndex(relativeTo: targetNode, within: targetParent, index: destinationRange.lowerBound) {
                    let newParent = targetParent.contents
                        .insert(childNode: sourceNode.copy(), atIndex: targetIndex)
                        .node

                    let newRoot = rootNode
                        .replace(id: targetParent.uuid, with: newParent)
                        .delete(id: sourceNode.uuid)

                    _ = onChangeRootNode?(newRoot.copy(deep: true))

                    break
                }
            }
        }
    }

    private func nextNode() {
        if let index = rootNode.formatted(using: formattingOptions).nextActivatableElementIndex(after: self.canvasView.selectedRange?.lowerBound),
            let id = self.rootNode.formatted(using: formattingOptions).elements[index].syntaxNodeID {

            select(nodeByID: id)
        } else {
            self.hideSuggestionWindow()

            if let nextKeyView = nextKeyView {
                window?.makeFirstResponder(nextKeyView)
            }
        }
    }

    private func previousNode() {
        if let index = rootNode.formatted(using: formattingOptions).previousActivatableElementIndex(before: self.canvasView.selectedRange?.lowerBound),
            let id = self.rootNode.formatted(using: formattingOptions).elements[index].syntaxNodeID {

            select(nodeByID: id)
        } else {
            self.hideSuggestionWindow()

            if let previousKeyView = previousKeyView {
                window?.makeFirstResponder(previousKeyView)
            }
        }
    }

    private func select(nodeByID originalId: UUID?) {
        let syntaxNodeId = willSelectNode?(rootNode, originalId) ?? originalId

        self.canvasView.selectedLine = nil
        self.suggestionText = ""

        if let syntaxNodeId = syntaxNodeId {
            let topNode = self.rootNode.topNodeWithEqualElements(as: syntaxNodeId, options: formattingOptions, includeTopLevel: false)

            if let selectedRange = self.rootNode.elementRange(for: topNode.uuid, options: formattingOptions, includeTopLevel: false) {
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
            let elements = self.rootNode.formatted(using: formattingOptions).elements

            if activatedIndex < elements.count {
                self.select(nodeByID: elements[activatedIndex].syntaxNodeID)
                return
            }
        }

        self.select(nodeByID: nil)
    }

    private func handleActivateLine(_ activatedLineIndex: Int) {
        handleActivateElement(nil)

        if supportsLineSelection {
            canvasView.selectedLine = activatedLineIndex
        }
    }

    private func handleRightClick(_ item: LogicCanvasView.Item?, _ point: NSPoint) {
        guard let item = item else { return }

        switch item {
        case .line:
            break
        case .range(let range):
            guard let selectedNode = rootNode.topNodeWithEqualRange(
                as: range,
                options: formattingOptions,
                includeTopLevel: false
                ) else { return }

            guard let menu = contextMenuForNode(rootNode, selectedNode),
                let firstItem = menu.items.first else { return }

            hideSuggestionWindow()

            canvasView.outlinedRange = rootNode.elementRange(for: selectedNode.uuid, options: formattingOptions, includeTopLevel: false)

            menu.delegate = self
            menu.popUp(positioning: firstItem, at: convert(point, from: canvasView), in: self)
        }
    }
}

// MARK: - Menu

extension LogicEditor: NSMenuDelegate {
    public func menuDidClose(_ menu: NSMenu) {
        canvasView.outlinedRange = nil
        canvasView.selectedRange = nil
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
                    suggestionListItems.append((logicItem.offset, .row(logicItem.item.title, logicItem.item.disabled, logicItem.item.badge)))
                case .colorPreview(code: let code, let color):
                    suggestionListItems.append(
                        (
                            logicItem.offset,
                            .colorRow(name: logicItem.item.title, code: code, color, logicItem.item.disabled)
                        )
                    )
                case .textStylePreview(let style):
                    suggestionListItems.append(
                        (
                            logicItem.offset,
                            .textStyleRow(logicItem.item.title, style, logicItem.item.disabled)
                        )
                    )
                }
            }
        }

        return suggestionListItems
    }

    private func logicSuggestionItems(for syntaxNode: LGCSyntaxNode, prefix: String) -> [LogicSuggestionItem] {
        guard let range = rootNode.elementRange(for: syntaxNode.uuid, options: formattingOptions, includeTopLevel: false),
            let elementPath = rootNode.pathTo(id: syntaxNode.uuid) else { return [] }

        let highestMatch = elementPath.first(where: { rootNode.elementRange(for: $0.uuid, options: formattingOptions, includeTopLevel: false) == range }) ?? syntaxNode

        return suggestionsForNode(rootNode, highestMatch, prefix).filter {
            !showsFilterBar || ($0.suggestionFilters.isEmpty || $0.suggestionFilters.contains(suggestionFilter))
        }
    }
}

// MARK: - Suggestion Window

extension LogicEditor {

    private func makeDetailView(
        for suggestion: LogicSuggestionItem?,
        query: String,
        builder: LogicSuggestionItem.DynamicSuggestionBuilder) -> NSView? {
        guard let suggestion = suggestion else { return nil }

        return documentationForSuggestion(rootNode, suggestion, query, builder)
    }

    // The suggestion window is shared between all logic editors, so we need to assign every parameter
    // to it each time we show it. Otherwise, we may be showing parameters set by another logic editor.
    private func showSuggestionWindow(for nodeIndex: Int, syntaxNode: LGCSyntaxNode) {
        guard let window = self.window else { return }

        let syntaxNodePath = self.rootNode.uniqueElementPathTo(id: syntaxNode.uuid, options: formattingOptions, includeTopLevel: false)
        let dropdownNodes = Array(syntaxNodePath)

        var logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: suggestionText)

        let originalIndexedSuggestions = indexedSuggestionListItems(for: logicSuggestions)

        var dynamicSuggestions: [Int: LogicSuggestionItem.DynamicSuggestion] = [:]

        func makeSuggestionBuilder(index: Int?) -> LogicSuggestionItem.DynamicSuggestionBuilder {

            let savedValue = index != nil ? dynamicSuggestions[index!] : nil

            return LogicSuggestionItem.DynamicSuggestionBuilder(
                initialValue: savedValue,
                onSave: ({ dynamicSuggestion in
                    guard let index = index else { return }
                    dynamicSuggestions[index] = dynamicSuggestion
                }),
                onSubmit: ({ [unowned self] in
                    guard let index = index else { return }
                    self.childWindow.onSubmit?(index)
                })
            )
        }

        childWindow.showsDropdown = showsDropdown
        childWindow.showsFilterBar = showsFilterBar
        childWindow.onRequestHide = hideSuggestionWindow
        childWindow.detailView = makeDetailView(
            for: logicSuggestions.first,
            query: suggestionText,
            builder: makeSuggestionBuilder(index: self.childWindow.selectedIndex)
        )
        childWindow.suggestionItems = originalIndexedSuggestions.map { $0.item }
        childWindow.selectedIndex = originalIndexedSuggestions.firstIndex { $0.item.isSelectable }
        childWindow.dropdownValues = dropdownNodes.map { $0.nodeTypeDescription }
        childWindow.dropdownIndex = dropdownNodes.count - 1
        childWindow.suggestionFilter = suggestionFilter
        childWindow.onChangeSuggestionFilter = { value in
            self.onChangeSuggestionFilter?(value)
            self.showSuggestionWindow(for: nodeIndex, syntaxNode: syntaxNode)
        }

        childWindow.onSelectIndex = { index in
            self.selectedSuggestionIndex = index

            if let index = index {
                let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
                let suggestion = logicSuggestions[indexedSuggestions[index].offset]

                self.childWindow.detailView = self.makeDetailView(
                    for: suggestion,
                    query: self.suggestionText,
                    builder: makeSuggestionBuilder(index: index)
                )
            } else {
                self.childWindow.detailView = nil
            }
        }

        childWindow.onPressEscapeKey = {
            self.hideSuggestionWindow()
        }

        childWindow.onPressTabKey = self.nextNode

        childWindow.onPressShiftTabKey = self.previousNode

        childWindow.onHighlightDropdownIndex = { [unowned self] highlightedIndex in
            if let highlightedIndex = highlightedIndex {
                let selected = dropdownNodes[highlightedIndex]
                let range = self.rootNode.elementRange(for: selected.uuid, options: self.formattingOptions, includeTopLevel: false)

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

            let suggestedNode: LGCSyntaxNode

            if let dynamicSuggestion = dynamicSuggestions[index] {
                suggestedNode = dynamicSuggestion.node
            } else {
                suggestedNode = logicSuggestionItem.node
            }

//            Swift.print("Chose suggestion", suggestedNode)

            let replacement = self.rootNode.replace(id: syntaxNode.uuid, with: suggestedNode)

            if self.onChangeRootNode?(replacement) == true {
                if let nextFocusId = logicSuggestionItem.nextFocusId {
                    self.select(nodeByID: nextFocusId)
                } else {
                    // Handle the case where the inserted node isn't represented in the formatted output.
                    // We traverse up the tree to find the nearest parent that is.
                    if var path = self.rootNode.pathTo(id: suggestedNode.uuid) {
                        while let selectionNode = path.last {
                            if let range = self.rootNode.elementRange(for: selectionNode.uuid, options: self.formattingOptions, includeTopLevel: false) {
                                self.canvasView.selectedRange = range
                                break
                            }
                            path = path.dropLast()
                        }
                    }

                    switch suggestedNode.movementAfterInsertion(rootNode: replacement) {
                    case .node(let nextFocusId):
                        self.select(nodeByID: nextFocusId)
                    case .next:
                        self.nextNode()
                    case .none:
                        self.handleActivateElement(self.canvasView.selectedRange?.lowerBound)
                    }
                }
            }
        }

        childWindow.onChangeSuggestionText = { [unowned self] value in
            self.suggestionText = value

            // Update logicSuggestions
            logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: value)

            let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
            let index = indexedSuggestions.firstIndex(where: { $0.item.isSelectable })

            self.childWindow.suggestionItems = indexedSuggestions.map { $0.item }
            self.childWindow.selectedIndex = index
            self.childWindow.detailView = self.makeDetailView(
                for: logicSuggestions.first,
                query: self.suggestionText,
                builder: makeSuggestionBuilder(index: index)
            )
        }

        window.addChildWindow(childWindow, ordered: .above)

        if let elementRect = canvasView.getElementRect(for: nodeIndex) {
            let windowRect = canvasView.convert(elementRect, to: nil)
            let screenRect = window.convertToScreen(windowRect)

            // Adjust the window to left-align suggestions with the element's text
            let adjustedRect = NSRect(
                x: screenRect.minX - 12 + canvasStyle.textPadding.width,
                y: screenRect.minY,
                width: screenRect.width,
                height: screenRect.height)

            childWindow.anchorTo(rect: adjustedRect, verticalOffset: 2)
            childWindow.focusSearchField()
        }
    }

    private func hideSuggestionWindow() {
        guard let window = self.window else { return }

        window.removeChildWindow(childWindow)
        childWindow.setIsVisible(false)
    }
}
