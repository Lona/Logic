//
//  Document.swift
//  TypeDesigner
//
//  Created by Devin Abbott on 9/25/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import AppKit
import Logic
import XMLCoder

struct Content: Codable {
    var types: [TypeEntity]
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
        let testConstraints: [Unification.Constraint] = [
            .init(Unification.T.evar("b"), Unification.T.evar("a")),
            .init(Unification.T.evar("a"), Unification.T.cons(name: "Boolean")),
            .init(Unification.T.evar("c"), Unification.T.cons(name: "Array", parameters: [.cons(name: "Boolean")])),
            .init(Unification.T.cons(name: "Array", parameters: [.evar("e")]), Unification.T.cons(name: "Array", parameters: [.cons(name: "Boolean")])),
            .init(Unification.T.evar("d"), Unification.T.cons(name: "Array", parameters: [.evar("Boolean")])),
            .init(Unification.T.evar("d"), Unification.T.evar("c")),
        ]

        let results = Unification.unify(constraints: testConstraints)

        Swift.print("Unification", results)

        typeListEditor.fillColor = Colors.suggestionWindowBackground

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
            case .enumType(let genericType):
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
            case .nativeType(let nativeType):
                return nativeType.parameters.map { $0.name }
            case .functionType:
                return [] // TODO
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
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(content)

        guard let xmlData = LogicFile.convert(jsonData, to: .xml) else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil)
        }

        return xmlData
    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard let jsonData = LogicFile.convert(data, to: .json) else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil)
        }

        content = try JSONDecoder().decode(Content.self, from: jsonData)
        typeListEditor.list = content.types
    }
}

