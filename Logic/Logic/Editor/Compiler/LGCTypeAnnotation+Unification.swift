//
//  LGCTypeAnnotation+Unification.swift
//  Logic
//
//  Created by Devin Abbott on 5/28/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension LGCTypeAnnotation {
    func unificationType(genericsInScope: [String: String], getName: () -> String) -> Unification.T {
        switch self {
        case .typeIdentifier(id: _, identifier: let identifier, genericArguments: let arguments):
            if identifier.isPlaceholder { return .evar(getName()) }

            if let renamed = genericsInScope[identifier.string] {
                return .gen(renamed)
            }

            let parameters = arguments.map { $0.unificationType(genericsInScope: genericsInScope, getName: getName) }

            return .cons(name: identifier.string, parameters: parameters)
        case .placeholder(id: _):
            return .evar(getName())
        default:
            fatalError("Not supported")
        }
    }
}
