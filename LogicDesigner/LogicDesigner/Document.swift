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
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    var body: [[LogicEditorText]] = [
        [
            .unstyled("if"),
            .dropdown("index", NSColor.systemPurple),
            .colored(">", NSColor.systemGray),
            .colored("10", NSColor.systemBlue),
        ],
        [
            .indent,
            .dropdown("", NSColor.systemGray)
        ],
        [
            .dropdown("", NSColor.systemGray)
        ]
    ]

    var selectedTextIndex: Int?

    var suggestionText: String = "" {
        didSet {
            childWindow?.suggestionText = suggestionText
        }
    }

    func setUpViews() -> NSView {
        let logicEditor = LogicEditor()

        logicEditor.lines = body

        logicEditor.underlinedRange = NSRange(location: 1, length: 2)

        logicEditor.onClickIndexPath = { indexPath in
            logicEditor.selectedIndexPath = indexPath

            if let window = self.window, let childWindow = self.childWindow {
                if let indexPath = indexPath {
                    self.suggestionText = self.body[indexPath.section][indexPath.item].value

                    window.addChildWindow(childWindow, ordered: .above)

                    if let rect = logicEditor.getBoundingRect(for: indexPath) {
                        let screenRect = window.convertToScreen(rect)
                        childWindow.anchorTo(rect: screenRect)
                        childWindow.focusSearchField()
                    }
                } else {
                    window.removeChildWindow(childWindow)
                    childWindow.setIsVisible(false)
                }
            }
//
            Swift.print("Clicked \(indexPath)")
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

