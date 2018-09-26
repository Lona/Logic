//
//  Document.swift
//  TypeDesigner
//
//  Created by Devin Abbott on 9/25/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import AppKit
import Logic

struct Content: Codable {
    var types: [Entity]
}

class Document: NSDocument {

    override init() {
        super.init()
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    var content = Content(types: [])

    var typeListEditor = TypeList()

    func setUpViews() -> NSView {
        typeListEditor.fillColor = .white

        typeListEditor.onChange = { list in
            self.content.types = list
            self.typeListEditor.list = list
        }

        typeListEditor.getTypeList = {
            let types = self.content.types.map({ $0.name })
            return types
        }

        typeListEditor.getGenericParametersForType = { name in
            guard let entity = self.content.types.first(where: { $0.name == name }) else { return [] }

            switch entity {
            case .genericType(let genericType):
                let all = genericType.cases.map({ genericCase -> [String] in
                    switch genericCase {
                    case .normal(_, let parameters):
                        let all = parameters.map({ parameter -> [String] in
                            switch parameter.value {
                            case .generic(let name):
                                return [name]
                            case .type:
                                return []
                            }
                        })
                        return Array(all.joined())
                    case .record(_, let parameters):
                        let all = parameters.map({ parameter -> [String] in
                            switch parameter.value {
                            case .generic(let name):
                                return [name]
                            case .type:
                                return []
                            }
                        })
                        return Array(all.joined())
                    }
                })
                return Array(all.joined())
            default:
                return []
            }
        }

        return typeListEditor
    }

    override func makeWindowControllers() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)

        window.center()

        window.contentView = setUpViews()

        let windowController = NSWindowController(window: window)

        windowController.showWindow(nil)

        addWindowController(windowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        do {
            let encoder = JSONEncoder()
            if #available(OSX 10.13, *) {
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            } else {
                encoder.outputFormatting = [.prettyPrinted]
            }
            return try encoder.encode(content)
        } catch let error {
            Swift.print(error)
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }

    override func read(from data: Data, ofType typeName: String) throws {
        do {
            content = try JSONDecoder().decode(Content.self, from: data)
            typeListEditor.list = content.types
        } catch let error {
            Swift.print(error)
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }
}

