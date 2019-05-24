//
//  NativeType.swift
//  Logic
//
//  Created by Devin Abbott on 5/24/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct NativeTypeParameter: Codable & Equatable {
    public var name: String

    public init(name: String) {
        self.name = name
    }

    func replacing(itemAtPath path: [Int], with item: TypeListItem) -> TypeListItem {
        if path.count > 0 {
            fatalError("Nothing to replace")
        } else {
            return TypeListItem.nativeTypeParameter(item.nativeTypeParameter!)
        }
    }
}

public struct NativeType: Codable & Equatable, CustomDebugStringConvertible {
    public var name: String
    public var parameters: [NativeTypeParameter]

    public init(name: String, parameters: [NativeTypeParameter] = []) {
        self.name = name
        self.parameters = parameters
    }

    public var debugDescription: String {
        if genericParameterNames.isEmpty {
            return name
        } else {
            return "*\(name)<\(genericParameterNames.joined(separator: ", "))>"
        }
    }

    public var genericParameterNames: [String] {
        return parameters.map { $0.name }
    }
}
