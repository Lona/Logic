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

        testFormatter()
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    var syntax: SwiftSyntaxNode = SwiftSyntaxNode.statement(
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
        let items: [SuggestionListItem] = Array(syntaxNode.suggestionCategories.map { $0.suggestionListItems }.joined())
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
        if let (offset, element) = self.logicEditor.nextActivatable(after: self.logicEditor.selectedIndex),
            let nextNodeID = element.syntaxNodeID,
            let nextSyntaxNode = self.syntax.find(id: nextNodeID) {

            self.logicEditor.selectedIndex = offset
            self.suggestionText = element.value

            self.showSuggestionWindow(for: offset, syntaxNode: nextSyntaxNode)
        } else {
            Swift.print("No next node to activate")

            self.hideSuggestionWindow()
        }
    }

    func showSuggestionWindow(for nodeIndex: Int, syntaxNode: SwiftSyntaxNode) {
        guard let window = self.window, let childWindow = self.childWindow else { return }

        childWindow.suggestionItems = self.suggestions(for: syntaxNode)

        childWindow.onPressEscapeKey = {
            self.hideSuggestionWindow()
        }

        childWindow.onPressTabKey = self.nextNode

        childWindow.onSubmit = { index in
            if let suggestedNode = self.suggestedSyntaxNode(for: syntaxNode, at: index) {
                Swift.print("Chose suggestion", suggestedNode)

                let replacement = self.syntax.replace(id: syntaxNode.uuid, with: suggestedNode)

                self.syntax = replacement

                self.logicEditor.formattedContent = self.syntax.formatted

                self.nextNode()
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

    private let logicEditor = LogicEditor()

    func setUpViews() -> NSView {

        // TODO Determine index of clicked item
        logicEditor.formattedContent = syntax.formatted

        logicEditor.underlinedRange = NSRange(location: 1, length: 2)

        logicEditor.onActivate = { activatedIndex, element in
            self.logicEditor.selectedIndex = activatedIndex
            self.suggestionText = element?.value ?? ""

            if let activatedIndex = activatedIndex,
                let id = element?.syntaxNodeID,
                let syntaxNode = self.syntax.find(id: id) {
                self.showSuggestionWindow(for: activatedIndex, syntaxNode: syntaxNode)
            } else {
                self.hideSuggestionWindow()
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

