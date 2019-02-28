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
        SwiftStatement.loop(
            SwiftLoop(
                pattern: SwiftIdentifier(id: NSUUID().uuidString, string: "item"),
                expression: SwiftExpression.identifierExpression(
                    SwiftIdentifierExpression(
                        id: NSUUID().uuidString,
                        identifier: SwiftIdentifier(id: NSUUID().uuidString, string: "array"))),
                block: SwiftList<SwiftStatement>.empty,
                id: NSUUID().uuidString)
        )
    )

    var suggestionText: String = "" {
        didSet {
            childWindow?.suggestionText = suggestionText
        }
    }

    func suggestions(for syntaxNode: SwiftSyntaxNode) -> [SuggestionListItem] {
        guard let range = rootNode.elementRange(for: syntaxNode.uuid),
            let elementPath = rootNode.pathTo(id: syntaxNode.uuid) else { return [] }

        let highestMatch = elementPath.first(where: { rootNode.elementRange(for: $0.uuid) == range }) ?? syntaxNode

        let items: [SuggestionListItem] = Array(highestMatch.suggestionCategories.map { $0.suggestionListItems }.joined())
        return items
    }

    func suggestedSyntaxNode(for syntaxNode: SwiftSyntaxNode, at selectedIndex: Int) -> SwiftSyntaxNode? {
        var found: SwiftSyntaxNode?
        var index = -1

        syntaxNode.suggestionCategories.forEach { category in

            // Category offset
            index += 1

            category.items.forEach { item in
                index += 1

                if index == selectedIndex {
                    found = item.node
                }
            }
        }

        return found
    }

    func nextNode() {
        if let (offset, element) = self.logicEditor.nextActivatable(after: self.logicEditor.selectedRange?.lowerBound),
            let nextNodeID = element.syntaxNodeID {

            self.logicEditor.selectedRange = self.rootNode.elementRange(for: nextNodeID)
            self.suggestionText = ""

            let nextSyntaxNode = self.rootNode.topNodeWithEqualElement(as: nextNodeID)
            self.showSuggestionWindow(for: offset, syntaxNode: nextSyntaxNode)
        } else {
            Swift.print("No next node to activate")

            self.hideSuggestionWindow()
        }
    }

    func showSuggestionWindow(for nodeIndex: Int, syntaxNode: SwiftSyntaxNode) {
        guard let window = self.window, let childWindow = self.childWindow else { return }

        let syntaxNodePath = self.rootNode.pathTo(id: syntaxNode.uuid) ?? []
        let dropdownNodes = Array(syntaxNodePath.reversed())

        childWindow.suggestionItems = self.suggestions(for: syntaxNode)
        childWindow.dropdownValues = dropdownNodes.map { $0.nodeTypeDescription }

        childWindow.onPressEscapeKey = {
            self.hideSuggestionWindow()
        }

        childWindow.onPressTabKey = self.nextNode

        childWindow.onHighlightDropdownIndex = { highlightedIndex in
            if let highlightedIndex = highlightedIndex {
                let selected = dropdownNodes[highlightedIndex]
                let range = self.rootNode.elementRange(for: selected.uuid)

                self.logicEditor.outlinedRange = range

//                Swift.print("Full path", self.syntax.pathTo(id: id)?.map { $0.nodeTypeDescription })
//
//                self.logicEditor.selectionEndID = syntaxNode.lastNode.uuid
//                self.showSuggestionWindow(for: activatedIndex, syntaxNode: syntaxNode)
            } else {
                self.logicEditor.outlinedRange = nil
            }
        }

        childWindow.onSelectDropdownIndex = { selectedIndex in
            self.logicEditor.outlinedRange = nil
        }

        childWindow.onSubmit = { index in
            if let suggestedNode = self.suggestedSyntaxNode(for: syntaxNode, at: index) {
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

    func select(index activatedIndex: Int?) {
        self.suggestionText = ""

        if let activatedIndex = activatedIndex,
            let syntaxNodeId = self.rootNode.formatted.elements[activatedIndex].syntaxNodeID {

            let topNode = self.rootNode.topNodeWithEqualElement(as: syntaxNodeId)

            self.logicEditor.selectedRange = self.rootNode.elementRange(for: syntaxNodeId)
            self.showSuggestionWindow(for: activatedIndex, syntaxNode: topNode)
        } else {
            self.logicEditor.selectedRange = nil
            self.hideSuggestionWindow()
        }
    }

    private let logicEditor = LogicEditor()

    func setUpViews() -> NSView {

        logicEditor.formattedContent = rootNode.formatted
        logicEditor.onActivate = { activatedIndex, element in self.select(index: activatedIndex) }

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

        childWindow.onChangeSuggestionText = { value in
            self.suggestionText = value
        }

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

