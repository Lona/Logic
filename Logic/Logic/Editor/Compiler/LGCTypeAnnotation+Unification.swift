//
//  LGCTypeAnnotation+Unification.swift
//  Logic
//
//  Created by Devin Abbott on 5/28/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCTypeName {
    func unificationType(genericsInScope: [String: String], getName: () -> String) -> Unification.T {
        switch self {
        case .typeName(_, identifier: let identifier, nestedName: nil, genericArguments: let arguments):
            if identifier.isPlaceholder { return .evar(getName()) }

            if let renamed = genericsInScope[identifier.string] {
                return .gen(renamed)
            }

            let parameters = arguments.map { $0.unificationType(genericsInScope: genericsInScope, getName: getName) }

            return .cons(name: identifier.string, parameters: parameters)
        default:
            fatalError("Not supported")
        }
    }
}

public extension LGCTypeAnnotation {
    func unificationType(genericsInScope: [String: String], getName: () -> String) -> Unification.T {
        switch self {
        case .typeIdentifier(id: _, name: let name):
            return name.unificationType(genericsInScope: genericsInScope, getName: getName)
        case .placeholder(id: _):
            return .evar(getName())
        default:
            fatalError("Not supported")
        }
    }
}
