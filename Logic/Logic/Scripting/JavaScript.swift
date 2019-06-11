//
//  JavaScript.swift
//  LonaStudio
//
//  Created by Devin Abbott on 3/11/19.
//  Copyright © 2019 Devin Abbott. All rights reserved.
//

import Foundation
import JavaScriptCore

public enum JavaScript {
    private static let context: JSContext = {
        let bundle = BundleLocator.getBundle()

        guard
            let libraryPath = bundle.path(forResource: "lona-serialization.umd.js", ofType: nil),
            let libraryScript = try? String(contentsOfFile: libraryPath),
            let context = JSContext()
            else { fatalError("Failed to initialize JSContext") }

        context.exceptionHandler = { _, exception in
            guard let exception = exception else {
                Swift.print("Unknown JS exception")
                return
            }
            Swift.print("JS exception", exception.toString() ?? "")
        }

        // The library assigns its export, `lonaSerialization`, to `this`.
        // Window is necessary also, since we generate a web bundle to mock node deps (e.g. Buffer).
        context.evaluateScript("global = this; window = this;")
        context.evaluateScript(libraryScript)

        return context
    }()

    static func convert(contents: String, kind: EncodingConversionKind, to targetEncoding: LogicFile.DataSerializationFormat) -> String? {
        switch kind {
        case .logic:
            let script = "global.lonaSerialization.convertLogic(`\(contents)`, '\(targetEncoding.rawValue)')"
            return context.evaluateScript(script)?.toString()
        case .types:
            let script = "global.lonaSerialization.convertTypes(`\(contents)`, '\(targetEncoding.rawValue)')"
            return context.evaluateScript(script)?.toString()
        }
    }
}

public enum EncodingConversionKind: String {
    case logic
    case types
}
