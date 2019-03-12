//
//  Document.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/16/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Cocoa

class Document: NSDocument {

    override init() {
        super.init()
//        testFormatter()
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    var rootNode: SwiftSyntaxNode = SwiftSyntaxNode.statement(
        SwiftStatement.placeholderStatement(
            SwiftPlaceholderStatement(id: NSUUID().uuidString)
        )
    )

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
                suggestionListItems.append((logicItem.offset, .row(logicItem.item.title)))
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

        childWindow.detailView = logicSuggestions.first?.node.documentation(for: suggestionText).makeScrollView()
        childWindow.suggestionItems = indexedSuggestionListItems(for: logicSuggestions).map { $0.item }
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
            let suggestedNode = logicSuggestions[indexedSuggestions[index].offset].node

            Swift.print("Chose suggestion", suggestedNode)

            let replacement = self.rootNode.replace(id: syntaxNode.uuid, with: suggestedNode)

            self.rootNode = replacement

            self.logicEditor.formattedContent = self.rootNode.formatted

            if suggestedNode.movementAfterInsertion == .next {
                self.nextNode()
            } else {
                self.logicEditor.reactivate()
            }
        }

        childWindow.onChangeSuggestionText = { value in
            self.suggestionText = value

            // Update logicSuggestions
            logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: value)

            childWindow.suggestionItems = self.indexedSuggestionListItems(for: logicSuggestions).map { $0.item }
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

    private let logicEditor = LogicEditor()

    func setUpViews() -> NSView {

        logicEditor.formattedContent = rootNode.formatted
        logicEditor.onActivate = { activatedIndex in
            if let activatedIndex = activatedIndex {
                let id = self.rootNode.formatted.elements[activatedIndex].syntaxNodeID
                self.select(nodeByID: id)
            } else {
                self.select(nodeByID: nil)
            }
        }

        return logicEditor
    }

    var childWindow: SuggestionWindow?
    var window: NSWindow?

    override func makeWindowControllers() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)

        window.backgroundColor = NSColor.white

        window.center()

        window.contentView = setUpViews()

        let windowController = NSWindowController(window: window)

        windowController.showWindow(nil)

        addWindowController(windowController)

        self.window = window

        let childWindow = SuggestionWindow()

        self.childWindow = childWindow
    }

    override var windowNibName: NSNib.Name? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return NSNib.Name("Document")
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.
        // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }


}

