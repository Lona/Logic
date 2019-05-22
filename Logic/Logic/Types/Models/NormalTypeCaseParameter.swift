//
//  NormalTypeCaseParameter.swift
//  Logic
//
//  Created by Devin Abbott on 9/26/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct NormalTypeCaseParameter: Codable & Equatable {
    public init(value: TypeParameter) {
        self.value = value
    }

    public var value: TypeParameter

    public var children: [TypeListItem] {
        return value.children
    }

    func replacing(itemAtPath path: [Int], with item: TypeListItem) -> TypeListItem {
        if path.count > 0 {
            switch value {
            case .type(let name, var substitution):
                if path.count > 0 {
                    substitution = substitution.enumerated().map { index, x in
                        if index == path[0] {
                            return item.genericTypeParameterSubstitution!
                        } else {
                            return x
                        }
                    }
                    return TypeListItem.normalTypeCaseParameter(
                        NormalTypeCaseParameter(value:
                            TypeParameter.type(name, substitution)))
                } else {
                    return item
                }
            case .generic:
                return TypeListItem.normalTypeCaseParameter(self)
            }
        } else {
            return item
        }
    }
}
