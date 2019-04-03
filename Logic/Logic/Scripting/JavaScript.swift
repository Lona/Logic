//
//  JavaScript.swift
//  LonaStudio
//
//  Created by Devin Abbott on 3/11/19.
//  Copyright © 2019 Devin Abbott. All rights reserved.
//

import Foundation
import JavaScriptCore

private extension Data {
    func utf8String() -> String? {
        guard let string = NSString(data: self, encoding: String.Encoding.utf8.rawValue) else { return nil }
        return string as String
    }
}

public enum JavaScript {
    @objc private class BundleHelper: NSObject {
        @objc static func getBundle() -> Bundle {
            return Bundle(for: self)
        }
    }

    private static let context: JSContext = {
        let bundle = BundleHelper.getBundle()

        guard
            let libraryPath = bundle.path(forResource: "convert-encoding.umd.js", ofType: nil),
            let libraryScript = FileManager.default.contents(atPath: libraryPath)?.utf8String(),
            let context = JSContext()
            else { fatalError("Failed to initialize JSContext") }

        context.exceptionHandler = { _, exception in
            guard let exception = exception else {
                Swift.print("Unknown JS exception")
                return
            }
            Swift.print("JS exception", exception.toString() ?? "")
        }

        // The library assigns its export, `convertEncoding`, to `this`.
        // Window is necessary also, since we generate a web bundle to mock node deps (e.g. Buffer).
        context.evaluateScript("global = this; window = this;")
        context.evaluateScript(libraryScript)
        context.evaluateScript("""
function convert(contents, targetEncoding) {
    return global.convertEncoding.convertTypes(contents, targetEncoding);
}
""")

        return context
    }()

    public static func convert(contents: String, to targetEncoding: FileEncoding) -> String? {
        let script = "convert(`\(contents)`, '\(targetEncoding.rawValue)')"
        return context.evaluateScript(script)?.toString()
    }

    public enum FileEncoding: String {
        case xml, json
    }
}
