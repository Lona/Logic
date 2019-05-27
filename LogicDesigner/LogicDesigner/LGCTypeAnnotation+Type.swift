//
//  LGCTypeAnnotation+Type.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/22/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

extension LGCTypeAnnotation {
    public func unificationType(getName: () -> String) -> Unification.T {
        switch self {
        case .typeIdentifier(id: _, identifier: let identifier, genericArguments: let arguments):
            if identifier.isPlaceholder { return .evar(getName()) }

            let parameters = arguments.map { $0.unificationType(getName: getName) }

            return .cons(name: identifier.string, parameters: parameters)
        case .placeholder(id: _):
            return .evar(getName())
        default:
            fatalError("Not supported")
        }
    }
}
