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

    public static func url(for name: String) -> URL? {
        let bundle = BundleLocator.getBundle()

        guard let libraryUrl = bundle.url(forResource: name, withExtension: "logic") else {
            Swift.print("Failed to find Logic library file for: \(name)")
            return nil
        }

        return libraryUrl
    }

    public static func load(name: String) -> LGCSyntaxNode? {
        if let cached = cache[name] {
            return cached
        }

        guard
            let libraryUrl = url(for: name),
            let libraryScript = try? Data(contentsOf: libraryUrl)
        else {
            Swift.print("Failed to read Logic library file for: \(name)")
            return nil
        }

        let decoded: LGCSyntaxNode

        do {
            decoded = try JSONDecoder().decode(LGCSyntaxNode.self, from: libraryScript)
        } catch {
            Swift.print("Invalid Logic JSON:", error)
            return nil
        }

        cache[name] = decoded

        return decoded
    }

    public static func clearCache() {
        cache.removeAll()
    }
}
