//
//  Library.swift
//  Logic
//
//  Created by Devin Abbott on 5/29/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum Library {
    public typealias Loader = (String) -> LGCSyntaxNode?

    private static var cache: [String: LGCSyntaxNode] = [:]

    public static func load(name: String) -> LGCSyntaxNode? {
        if let cached = cache[name] {
            return cached
        }

        let bundle = BundleLocator.getBundle()

        guard let libraryUrl = bundle.url(forResource: name, withExtension: "logic"),
            let libraryScript = try? Data(contentsOf: libraryUrl),
            let decoded = try? JSONDecoder().decode(LGCSyntaxNode.self, from: libraryScript)
        else {
            return nil
        }

        cache[name] = decoded

        return decoded
    }

    public static func clearCache() {
        cache.removeAll()
    }
}
