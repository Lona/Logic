import AppKit

// MARK: - LogicEditor

open class LogicEditor: NSBox {

    public struct MenuItem {
        public var row: SuggestionListItem
        public var action: () -> Void

        public init(row: SuggestionListItem, action: @escaping () -> Void) {
            self.row = row
            self.action = action
        }
    }

    public struct ElementError {
        public var uuid: UUID
        public var message: String

        public init(uuid: UUID, message: String) {
            self.uuid = uuid
            self.message = message
        }
    }

    public enum FocusControl {
        case manual
        case automatic
    }

    // MARK: Lifecycle

    public init(
        rootNode: LGCSyntaxNode = defaultRootNode,
        formattingOptions: LogicFormattingOptions = LogicFormattingOptions.normal
        ) {
        self.context = .init(rootNode, options: formattingOptions)

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

    public var supportsLineSelection = false {
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

    public var onRequestDelete: (() -> Void)?

    public var onClickBackground: (() -> Void)? {
        get { return canvasView.onClickBackground }
        set { canvasView.onClickBackground = newValue }
    }

    public var decorationForNodeID: ((UUID) -> LogicElement.Decoration?)? {
        get { return canvasView.getElementDecoration }
        set { canvasView.getElementDecoration = newValue }
    }

    public var context: SyntaxNodeContext {
        didSet {
            canvasView.formattedContent = .init(rootNode.formatted(using: formattingOptions))

            if showsMinimap {
                minimapScroller.setNeedsDisplay()
            }
        }
    }

    public var rootNode: LGCSyntaxNode {
        get { return context.syntaxNode }
        set {
            context = .init(newValue, options: formattingOptions)
        }
    }

    public var formattingOptions: LogicFormattingOptions {
        get { return context.formattingOptions }
        set {
            context = .init(rootNode, options: newValue)
        }
    }

    public var elementErrors: [ElementError] = [] {
        didSet {
            let rows = context.formatted.logicalRows

            canvasView.errorLines = rows.map({ row in row.compactMap({ $0.syntaxNodeID }) }).enumerated().compactMap { line, ids in
                if elementErrors.contains(where: { ids.contains($0.uuid) }) {
                    return line
                } else {
                    return nil
                }
            }

            canvasView.errorRanges = elementErrors.compactMap { error in
                //                let topNode = self.rootNode.topNodeWithEqualElements(as: error.uuid, options: formattingOptions, includeTopLevel: false)

                if let selectedRange = context.elementRange(for: error.uuid, includeTopLevel: false) {
                    return selectedRange
                } else {
                    return nil
                }
            }
        }
    }

    public var suggestionFilter: SuggestionView.SuggestionFilter = .recommended {
        didSet {
            childWindow.suggestionFilter = suggestionFilter
        }
    }

    public var onChangeSuggestionFilter: ((SuggestionView.SuggestionFilter) -> Void)?

    public var defaultSuggestionWindowSize = CGSize(width: 610 - 24, height: 380 - 24)

    public var defaultDetailWindowWidth: CGFloat = 400 - 24

    public var showsDropdown: Bool = false

    public var placeholderText: String? = nil

    public var focusControl: FocusControl = .automatic

    public var showsFilterBar: Bool = false

    public var showsLineButtons: Bool {
        get { return canvasView.showsLineButtons }
        set { canvasView.showsLineButtons = newValue }
    }


    public var plusButtonTooltip: String {
        get { return canvasView.plusButtonTooltip }
        set { canvasView.plusButtonTooltip = newValue }
    }

    public var moreButtonTooltip: String {
        get { return canvasView.moreButtonTooltip }
        set { canvasView.moreButtonTooltip = newValue }
    }

    public var showsMinimap: Bool = false {
        didSet {
            if showsMinimap {
                minimapScroller.drawKnobSlot = canvasView.drawScrollerBackground

                scrollView.autohidesScrollers = false
                scrollView.verticalScroller = minimapScroller
            } else {
                minimapScroller.drawKnobSlot = nil

                scrollView.autohidesScrollers = true
                scrollView.verticalScroller = NSScroller()
            }
        }
    }

    public var onInsertBelow: ((LGCSyntaxNode, LGCSyntaxNode) -> Void)?

    public var contextMenuForNode: ((LGCSyntaxNode, LGCSyntaxNode) -> [MenuItem]?) = {_, _ in nil}

    public var suggestionsForNode: ((LGCSyntaxNode, LGCSyntaxNode, String) -> [LogicSuggestionItem]) = LogicEditor.defaultSuggestionsForNode

    public var documentationForSuggestion: (
        LGCSyntaxNode,
        LogicSuggestionItem,
        String,
        LogicFormattingOptions,
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
        LogicFormattingOptions,
        LogicSuggestionItem.DynamicSuggestionBuilder
        ) -> NSView = { rootNode, suggestion, query, formattingOptions, builder in
            return suggestion.documentation?(builder) ?? suggestion.node.documentation(within: rootNode, for: query, formattingOptions: formattingOptions)
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

    private lazy var subwindow = SuggestionWindow()

    // TODO: Make private when we know how we use it in the blockeditor
    public let canvasView = LogicCanvasView()
    private let scrollView = NSScrollView()
    private let minimapScroller = MinimapScroller(frame: .zero)

    private var emptyTextField = LNATextField(labelWithString: "")

    private var emptyDetailView: NSView {
        let container = NSView()
        let textField = emptyTextField

        container.addSubview(textField)

        container.translatesAutoresizingMaskIntoConstraints = false

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        textField.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        textField.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 30).isActive = true
        textField.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: 30).isActive = true
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.lineBreakMode = .byCharWrapping

        return container
    }

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

        canvasView.formattedContent = context.formatted
        canvasView.onActivate = handleActivateElement
        canvasView.onActivateLine = handleActivateLine
        canvasView.onClickLineMore = handleClickMore
        canvasView.onClickLinePlus = handleClickPlus
        canvasView.onPressTabKey = nextNode
        canvasView.onPressShiftTabKey = previousNode
        canvasView.onPressDeleteKey = handleDelete
        canvasView.onDuplicateCommand = handleDuplicateCommand
        canvasView.onMoveLine = handleMoveLine
        canvasView.onBlur = handleBlur
        canvasView.onFocus = handleFocus
        canvasView.getLineShowsButtons = handleLineShowsButtons
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
        if let firstIndex = context.formatted.elements.firstIndex(where: { $0.isActivatable }) {
            canvasView.selectedRange = firstIndex..<firstIndex + 1
        }
    }

    private func handleBlur() {
        handleActivateElement(nil)
    }

    private func handleDuplicateCommand() {
        let formattedContent = context.formatted
        let elements = formattedContent.elements

        func range() -> Range<Int>? {
            if let selectedLine = canvasView.selectedLine {
                return formattedContent.elementIndexRange(for: selectedLine)
            } else {
                return canvasView.selectedRange
            }
        }

        if let selectedRange = range(),
            let selectedNode = context.topNodeWithEqualRange(as: selectedRange, includeTopLevel: false) {
            let targetNode = canvasView.selectedLine != nil ? rootNode.findDragSource(id: selectedNode.uuid) ?? selectedNode : selectedNode
            if let newRootNode = rootNode.duplicate(id: targetNode.uuid) {
                let shouldActivate = onChangeRootNode?(newRootNode.rootNode)
                if shouldActivate == true {
                    handleActivateElement(nil)
                }
            }
        }
    }

    private func handleDelete() {
        let formattedContent = context.formatted
        let elements = formattedContent.elements

        func range() -> Range<Int>? {
            if let selectedLine = canvasView.selectedLine {
                return formattedContent.elementIndexRange(for: selectedLine)
            } else {
                return canvasView.selectedRange
            }
        }

        if let selectedRange = range(),
            let selectedNode = context.topNodeWithEqualRange(as: selectedRange, includeTopLevel: false) {
            let targetNode = canvasView.selectedLine != nil ? rootNode.findDragSource(id: selectedNode.uuid) ?? selectedNode : selectedNode
            let shouldActivate = onChangeRootNode?(rootNode.delete(id: targetNode.uuid))
            if shouldActivate == true {
                handleActivateElement(nil)
            }
        }
    }

    // Determine the index of the target within its parent, since we'll be inserting the source node relative to it
    private func findDropIndex(relativeTo node: LGCSyntaxNode, within parent: LGCSyntaxNode, index: Int) -> Int? {
        let childRanges = parent.contents.children.map {
            context.elementRange(for: $0.uuid, includeTopLevel: false, useOwnerId: true)
            }.compactMap { $0 }

        return childRanges.firstIndex(where: { $0.contains(index) })
    }

    private func handleMoveLine(_ sourceLineIndex: Int, _ destinationLineIndex: Int) {
        //        Swift.print(sourceLineIndex, "=>", destinationLineIndex)

        let formattedContent = context.formatted

        if let sourceRange = formattedContent.elementIndexRange(for: sourceLineIndex),
            let destinationRange = formattedContent.elementIndexRange(for: destinationLineIndex),
            let originalSourceNode = context.topNodeWithEqualRange(as: sourceRange, includeTopLevel: false, useOwnerId: true),
            let sourceNode = rootNode.findDragSource(id: originalSourceNode.uuid),
            let targetNode = context.topNodeWithEqualRange(as: destinationRange, includeTopLevel: true, useOwnerId: true) {

            // Target is within source
            if let _ = sourceNode.find(id: targetNode.uuid) { return }

            var initialParent = targetNode
            while let targetParent = rootNode.findDropTarget(relativeTo: initialParent, accepting: sourceNode) {
                initialParent = targetParent

                if let targetIndex = findDropIndex(relativeTo: targetNode, within: targetParent, index: destinationRange.lowerBound) {
                    let newParent = targetParent.insert(childNode: sourceNode.copy(), atIndex: targetIndex)

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
        if let index = context.formatted.nextActivatableElementIndex(after: self.canvasView.selectedRange?.lowerBound),
            let id = context.formatted.elements[index].syntaxNodeID {

            select(nodeByID: id)
        } else {
            self.hideSuggestionWindow()

            if let nextKeyView = nextKeyView {
                window?.makeFirstResponder(nextKeyView)
            }
        }
    }

    private func previousNode() {
        if let index = context.formatted.previousActivatableElementIndex(before: self.canvasView.selectedRange?.lowerBound),
            let id = context.formatted.elements[index].syntaxNodeID {

            select(nodeByID: id)
        } else {
            self.hideSuggestionWindow()

            if let previousKeyView = previousKeyView {
                window?.makeFirstResponder(previousKeyView)
            }
        }
    }

    public func select(nodeByID originalId: UUID?) {
        let syntaxNodeId = willSelectNode?(rootNode, originalId) ?? originalId

        self.canvasView.selectedLine = nil
        self.suggestionText = ""

        if let syntaxNodeId = syntaxNodeId {
            let topNode = context.topNodeWithEqualElements(as: syntaxNodeId, includeTopLevel: false)

            if let selectedRange = context.elementRange(for: topNode.uuid, includeTopLevel: false) {
                self.canvasView.selectedRange = selectedRange

                self.showActionWindow(for: selectedRange.lowerBound, syntaxNode: topNode)
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
            let elements = context.formatted.elements

            if activatedIndex < elements.count {
                let element = elements[activatedIndex]
                self.select(nodeByID: element.syntaxNodeID ?? element.targetNodeId)
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

    private func draggableNode(atLine line: Int) -> LGCSyntaxNode? {
        guard let range = context.formatted.elementIndexRange(for: line),
            let originalSourceNode = context.topNodeWithEqualRange(as: range, includeTopLevel: false, useOwnerId: true),
            let sourceNode = rootNode.findDragSource(id: originalSourceNode.uuid)
            else { return nil }
        return sourceNode
    }

    private func handleLineShowsButtons(_ line: Int) -> Bool {
        guard let sourceNode = draggableNode(atLine: line) else { return false }

        // If the previous line has the same node, show line buttons on the previous line instead
        let previousLine = line - 1
        if previousLine >= 0 && draggableNode(atLine: previousLine) == sourceNode { return false }

        return contextMenuForNode(rootNode, sourceNode) != nil
    }

    private func handleClickPlus(_ line: Int, rect: NSRect) {
        guard let sourceNode = draggableNode(atLine: line) else { return }

        onInsertBelow?(rootNode, sourceNode)
    }

    private func handleClickMore(_ line: Int, rect: NSRect) {
        guard let window = self.window else { return }

        guard let range = context.formatted.elementIndexRange(for: line),
            let originalSourceNode = context.topNodeWithEqualRange(as: range, includeTopLevel: false, useOwnerId: true),
            let sourceNode = rootNode.findDragSource(id: originalSourceNode.uuid),
            let menu = contextMenuForNode(rootNode, sourceNode)
            else { return }

        let actualRange = context.elementRange(for: sourceNode.uuid, includeTopLevel: false)

        let windowRect = canvasView.convert(rect, to: nil)
        let screenRect = window.convertToScreen(windowRect)

        let suggestionItems = menu.map { $0.row }

        let suggestionListHeight = suggestionItems.map { $0.height }.reduce(0, +)

        subwindow.defaultContentWidth = 200
        subwindow.suggestionView.showsSuggestionDetails = false
        subwindow.suggestionView.suggestionListWidth = 200
        subwindow.suggestionText = ""
        subwindow.placeholderText = "Filter actions"

        subwindow.anchorHorizontallyTo(rect: screenRect, horizontalOffset: 4)
        subwindow.suggestionItems = suggestionItems

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

        subwindow.onChangeSuggestionText = { [unowned subwindow] text in
            subwindow.suggestionText = text
            subwindow.suggestionItems = filteredSuggestionItems(query: text).map { offset, item in item }
            subwindow.selectedIndex = filteredSuggestionItems(query: text).firstIndex(where: { offset, item in item.isSelectable })
        }
        subwindow.onSelectIndex = { [unowned subwindow] index in
            subwindow.selectedIndex = index
        }

        //        handleActivateElement(nil)
        canvasView.selectedRange = actualRange
        window.addChildWindow(subwindow, ordered: .above)
        subwindow.focusSearchField()

        var didHide: Bool = false

        let hideWindow = { [unowned self] in
            if didHide { return }
            didHide = true
            window.removeChildWindow(self.subwindow)
            self.subwindow.setIsVisible(false)
        }

        subwindow.onPressEscapeKey = hideWindow
        subwindow.onRequestHide = hideWindow

        subwindow.onSubmit = { [unowned self] index in
            self.canvasView.selectedRange = nil

            let originalIndex = filteredSuggestionItems(query: self.subwindow.suggestionText).map { offset, item in offset }[index]
            let item = menu[originalIndex]
            item.action()

            hideWindow()

            didHide = true

            self.update()
        }
    }

    // MARK: Action menu

    private func showActionWindow(for nodeIndex: Int, syntaxNode: LGCSyntaxNode) {
        guard let window = self.window else { return }
        guard let rect = suggestionWindowAnchorRect(for: nodeIndex) else { return }

        var menu: [LogicEditor.MenuItem] = []

        let renameItem: LogicEditor.MenuItem = .init(row: .row("Rename...", nil, false, nil, nil), action: { [unowned self] in
            self.showSuggestionWindow(for: nodeIndex, syntaxNode: syntaxNode)
        })

        switch syntaxNode {
        case .pattern:
            let deleteItem: LogicEditor.MenuItem = .init(row: .row("Delete", nil, false, nil, nil), action: { [unowned self] in
                if let parent = self.rootNode.contents.parentOf(target: syntaxNode.uuid, includeTopLevel: true),
                    case .declaration(let declaration) = parent {
                    if declaration.uuid == self.rootNode.uuid {
                        self.onRequestDelete?()
                    } else {
                        let shouldActivate = self.onChangeRootNode?(self.rootNode.delete(id: declaration.uuid))
                        if shouldActivate == true {
                            self.handleActivateElement(nil)
                        }
                    }
                }
            })

            menu = [renameItem, deleteItem]

            subwindow.placeholderText = "Filter actions"
        case .expression:
            let customValueRow: SuggestionListItem = .row("Custom value", "Define a new value", false, nil, MenuThumbnailImage.newValue)
            let variableReferenceRow: SuggestionListItem = .row("Variable reference", "Reference an existing value", false, nil, MenuThumbnailImage.variable)
            let functionCallRow: SuggestionListItem = .row("Function call", "Generate a value from a function", false, nil, MenuThumbnailImage.function)

            let customValueItem: LogicEditor.MenuItem = .init(row: customValueRow, action: { [unowned self] in
                self.showSuggestionWindow(for: nodeIndex, syntaxNode: syntaxNode, categoryFilter: LGCLiteral.Suggestion.categoryTitle)
            })

            let variableReferenceItem: LogicEditor.MenuItem = .init(row: variableReferenceRow, action: { [unowned self] in
                self.showSuggestionWindow(for: nodeIndex, syntaxNode: syntaxNode, categoryFilter: LGCExpression.Suggestion.variablesCategoryTitle)
            })

            let functionCallItem: LogicEditor.MenuItem = .init(row: functionCallRow, action: { [unowned self] in
                self.showSuggestionWindow(for: nodeIndex, syntaxNode: syntaxNode)
            })

            menu = [customValueItem, variableReferenceItem, functionCallItem]

            subwindow.placeholderText = "Filter kinds of tokens"
        default:
            showSuggestionWindow(for: nodeIndex, syntaxNode: syntaxNode)
            return
        }

        subwindow.style = .contextMenu
        subwindow.suggestionText = ""

        let suggestionItems = menu.map { $0.row }
        
        subwindow.suggestionItems = suggestionItems
        subwindow.anchorTo(rect: rect, verticalOffset: 2)

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

        subwindow.onChangeSuggestionText = { [unowned subwindow] text in
            subwindow.suggestionText = text
            subwindow.suggestionItems = filteredSuggestionItems(query: text).map { offset, item in item }
            subwindow.selectedIndex = filteredSuggestionItems(query: text).firstIndex(where: { offset, item in item.isSelectable })
        }
        subwindow.onSelectIndex = { [unowned subwindow] index in
            subwindow.selectedIndex = index
        }

        //        handleActivateElement(nil)
//        canvasView.selectedRange = actualRange
        window.addChildWindow(subwindow, ordered: .above)
        subwindow.focusSearchField()

        var didHide: Bool = false

        let hideWindow = { [unowned self] in
            if didHide { return }
            didHide = true
            window.removeChildWindow(self.subwindow)
            self.subwindow.setIsVisible(false)
        }

        subwindow.onPressEscapeKey = hideWindow
        subwindow.onRequestHide = hideWindow

        subwindow.onSubmit = { [unowned self] index in
            self.canvasView.selectedRange = nil

            let originalIndex = filteredSuggestionItems(query: self.subwindow.suggestionText).map { offset, item in offset }[index]
            let item = menu[originalIndex]
            item.action()

            hideWindow()

            didHide = true

            self.update()
        }
    }

    private func suggestionListHeight(for suggestionItems: [SuggestionListItem]) -> CGFloat {
        let suggestionListHeight = suggestionItems.map { $0.height }.reduce(0, +)
        let searchBarHeight: CGFloat = 32
        let dividerHeight: CGFloat = 1

        return min(
            searchBarHeight + dividerHeight + suggestionListHeight + OverlayWindow.shadowViewMargin * 2,
            defaultSuggestionWindowSize.height
        )
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
                    suggestionListItems.append(
                        (
                            logicItem.offset,
                            .row(logicItem.item.title, logicItem.item.subtitle, logicItem.item.disabled, logicItem.item.badge, nil)
                        )
                    )
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
        guard let range = context.elementRange(for: syntaxNode.uuid, includeTopLevel: false),
            let elementPath = rootNode.pathTo(id: syntaxNode.uuid) else { return [] }

        let highestMatch = elementPath.first(where: { context.elementRange(for: $0.uuid, includeTopLevel: false) == range }) ?? syntaxNode

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
        guard let suggestion = suggestion else {
            let text = query.isEmpty ? "No suggestions available" : "No results for \"\(query)\""
            emptyTextField.attributedStringValue = TextStyles.subtitleMuted.apply(to: text)
            return emptyDetailView
        }

        return documentationForSuggestion(rootNode, suggestion, query, formattingOptions, builder)
    }

    private func handleSubmit(
        originalNode: LGCSyntaxNode,
        logicSuggestionItem: LogicSuggestionItem,
        suggestedNode: LGCSyntaxNode) -> Void {
        let replacement = self.rootNode.replace(id: originalNode.uuid, with: suggestedNode)

        if self.onChangeRootNode?(replacement) == true {
            if focusControl == .manual {
                handleActivateElement(nil)
            } else if let nextFocusId = logicSuggestionItem.nextFocusId {
                self.select(nodeByID: nextFocusId)
            } else {
                // Handle the case where the inserted node isn't represented in the formatted output.
                // We traverse up the tree to find the nearest parent that is.
                if var path = self.rootNode.pathTo(id: suggestedNode.uuid) {
                    while let selectionNode = path.last {
                        if let range = context.elementRange(for: selectionNode.uuid, includeTopLevel: false) {
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

    public func showSuggestionWindow(for syntaxNodeId: UUID) {
        let topNode = context.topNodeWithEqualElements(as: syntaxNodeId, includeTopLevel: false)

        if let selectedRange = context.elementRange(for: topNode.uuid, includeTopLevel: false) {
            self.canvasView.selectedRange = selectedRange

            self.showSuggestionWindow(for: selectedRange.lowerBound, syntaxNode: topNode)
        }
    }

    // The suggestion window is shared between all logic editors, so we need to assign every parameter
    // to it each time we show it. Otherwise, we may be showing parameters set by another logic editor.
    private func showSuggestionWindow(for nodeIndex: Int, syntaxNode: LGCSyntaxNode, categoryFilter: String? = nil) {
        guard let window = self.window else { return }

        canvasView.hasFocus = true

        let syntaxNodePath = context.uniqueElementPathTo(id: syntaxNode.uuid, includeTopLevel: false)
        let dropdownNodes = Array(syntaxNodePath)

        var logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: suggestionText).filter {
            categoryFilter == nil || $0.category == categoryFilter
        }

        let originalIndexedSuggestions = indexedSuggestionListItems(for: logicSuggestions)
        let initialIndex = originalIndexedSuggestions.firstIndex { $0.item.isSelectable }

        // We set this function when we create a suggestion builder so that we can call it later to
        // instantiate a node with the builder's saved data
        var createDynamicNode: ((Data?) -> LGCSyntaxNode)?

        var dynamicSuggestions: [Int: Data] = [:]
        var dynamicListItems: [Int: SuggestionListItem] = [:]

        func makeSuggestionBuilder(index: Int?) -> LogicSuggestionItem.DynamicSuggestionBuilder {
            createDynamicNode = nil

            let savedValue = index != nil ? dynamicSuggestions[index!] : nil

            return LogicSuggestionItem.DynamicSuggestionBuilder(
                initialValue: savedValue,
                onChangeValue: ({ dynamicSuggestion in
                    guard let index = index else { return }
                    dynamicSuggestions[index] = dynamicSuggestion
                }),
                onSubmit: ({ [unowned self] in
                    guard let index = index else { return }
                    self.childWindow.onSubmit?(index)
                }),
                setListItem: ({ [unowned self] item in
                    guard let index = index else { return }
                    dynamicListItems[index] = item
                    self.childWindow.suggestionItems[index] = item ??
                        self.indexedSuggestionListItems(for: logicSuggestions)[index].item
                }),
                setNodeBuilder: ({ callback in
                    createDynamicNode = callback
                }),
                formattingOptions: formattingOptions
            )
        }

        switch syntaxNode {
        case .pattern:
            childWindow.placeholderText = "Type a new name and press Enter"
            childWindow.style = .textInput
        case .expression where categoryFilter == LGCLiteral.Suggestion.categoryTitle:
            childWindow.placeholderText = "Type or pick a new value and press Enter"
            childWindow.style = .detail
        case .expression where categoryFilter == LGCExpression.Suggestion.variablesCategoryTitle:
            childWindow.placeholderText = "Filter variables"
            childWindow.style = .contextMenu
        default:
            childWindow.placeholderText = placeholderText
            childWindow.style = .default
            childWindow.showsFilterBar = showsFilterBar
            childWindow.showsDropdown = showsDropdown
        }

        childWindow.onRequestHide = hideSuggestionWindow
        childWindow.selectedIndex = initialIndex
        childWindow.detailView = makeDetailView(
            for: logicSuggestions.first,
            query: suggestionText,
            builder: makeSuggestionBuilder(index: initialIndex)
        )
        childWindow.suggestionItems = originalIndexedSuggestions.map { $0.item }
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
                let range = self.context.elementRange(for: selected.uuid, includeTopLevel: false)

                self.canvasView.outlinedRange = range
            } else {
                self.canvasView.outlinedRange = nil
            }
        }

        childWindow.onSelectDropdownIndex = { selectedIndex in
            self.canvasView.outlinedRange = nil
            self.select(nodeByID: dropdownNodes[selectedIndex].uuid)
        }

        childWindow.onSubmit = { [unowned self] index in
            let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
            let logicSuggestionItem = logicSuggestions[indexedSuggestions[index].offset]

            if logicSuggestionItem.disabled && dynamicListItems[index] == nil { return }

            self.handleSubmit(
                originalNode: syntaxNode,
                logicSuggestionItem: logicSuggestionItem,
                suggestedNode: createDynamicNode?(dynamicSuggestions[index]) ?? logicSuggestionItem.node
            )
        }

        childWindow.onChangeSuggestionText = { [unowned self] value in
            self.suggestionText = value

            // Reset dynamic suggestions
            dynamicSuggestions.removeAll()
            dynamicListItems.removeAll()

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

        if let rect = suggestionWindowAnchorRect(for: nodeIndex) {
            childWindow.anchorTo(rect: rect, verticalOffset: 2)
            childWindow.focusSearchField()
        }
    }

    private func suggestionWindowAnchorRect(for nodeIndex: Int) -> NSRect? {
        guard let window = self.window else { return nil }

        if let elementRect = canvasView.getElementRect(for: nodeIndex) {
            let windowRect = canvasView.convert(elementRect, to: nil)
            let screenRect = window.convertToScreen(windowRect)

            // Adjust the window to left-align suggestions with the element's text
            let adjustedRect = NSRect(
                x: screenRect.minX - 12 + canvasStyle.textPadding.width,
                y: screenRect.minY,
                width: screenRect.width,
                height: screenRect.height)

            return adjustedRect
        }

        return nil
    }

    private func hideSuggestionWindow() {
        guard let window = self.window else { return }

        window.removeChildWindow(childWindow)
        childWindow.setIsVisible(false)
        canvasView.hasFocus = false
    }
}
