//
//  Document.swift
//  TypeDesigner
//
//  Created by Devin Abbott on 9/25/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import AppKit
import Logic

class Document: NSDocument {

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    func setUpViews() -> NSView {
        let typeListEditor = TypeList()
        typeListEditor.fillColor = .white

        typeListEditor.onChange = { list in
            typeListEditor.list = list

//            let types = list.map({ try? $0.typeInstance() }).compactMap({ $0 })
//            Swift.print("Type instances", types)
//
//            let tcs = list.map({ try? $0.typeConstructor() }).compactMap({ $0 })
//            Swift.print("Type constructors", tcs)
        }

        typeListEditor.list = [
//            Entity(LTypeConstructor.unit),
//            Entity(LTypeConstructor.boolean),
//            Entity(LTypeConstructor("Number", isNative: true)),
//            Entity(LTypeConstructor("String", isNative: true)),
//            Entity(LTypeConstructor("Optional", dataConstructors: [
//                LDataConstructor(name: "value", types: [LType.generic("T")]),
//                LDataConstructor(name: "null", types: [])
//                ])),
        ]

        typeListEditor.getTypeList = {
            let types = typeListEditor.list.map({ $0.name })
            return types
        }

        typeListEditor.getGenericParametersForType = { name in
            guard let entity = typeListEditor.list.first(where: { $0.name == name }) else { return [] }

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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)

        window.center()

        window.contentView = setUpViews()

        let windowController = NSWindowController(window: window)

        windowController.showWindow(nil)
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

