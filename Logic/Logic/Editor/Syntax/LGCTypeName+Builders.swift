//
//  LGCTypeName+Builders.swift
//  Logic
//
//  Created by Devin Abbott on 8/26/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension LGCTypeName {
    public var flattenedTypeName: [LGCIdentifier] {
        switch self {
        case .placeholder:
            return []
        case .typeName(let value):
            return [value.identifier] + (value.nestedName?.flattenedTypeName.compactMap { $0 } ?? [])
        }
    }
}
