//
//  NameGenerator.swift
//  Logic
//
//  Created by Devin Abbott on 5/22/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public class NameGenerator {

    // MARK: Lifecycle

    public init(prefix: String = "") {
        self.prefix = prefix
    }

    // MARK: Public

    public func next() -> String {
        currentIndex += 1
        let name = String(currentIndex, radix: 36, uppercase: true)
        return "\(prefix)\(name)"
    }

    // MARK: Private

    private var prefix: String

    private var currentIndex: Int = 0
}
