//
//  TypeEntity+Unification.swift
//  Logic
//
//  Created by Devin Abbott on 5/22/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension TypeEntity {
    private static var currentIndex: Int = 0

    static func makeTypeName() -> String {
        currentIndex += 1
        let name = String(currentIndex, radix: 36, uppercase: true)
        return "~\(name)"
    }

    func makeUnificationType() -> (type: Unification.T, nameMapping: [String: Unification.T]) {
        switch self {
        case .enumType(let value):
            var mapping: [String: Unification.T] = [:]
            var evars: [Unification.T] = []

            value.genericParameterNames.forEach { original in
                let new = Unification.T.evar(TypeEntity.makeTypeName())
                mapping[original] = new
                evars.append(new)
            }

            let type: Unification.T = .cons(name: value.name, parameters: evars)
            
            return (type, mapping)
        case .nativeType(let value):
            var mapping: [String: Unification.T] = [:]
            var evars: [Unification.T] = []

            value.genericParameterNames.forEach { original in
                let new = Unification.T.evar(TypeEntity.makeTypeName())
                mapping[original] = new
                evars.append(new)
            }

            let type: Unification.T = .cons(name: value.name, parameters: evars)

            return (type, mapping)
        case .functionType(_):
            fatalError("Not handled")
        }
    }
}
