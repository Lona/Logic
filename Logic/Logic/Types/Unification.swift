//
//  Unify.swift
//  Logic
//
//  Created by Devin Abbott on 5/21/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum Unification {
    public enum T: Equatable, CustomDebugStringConvertible {
        case evar(String)
        case cons(name: String, parameters: [T])

        public static func cons(name: String) -> T {
            return .cons(name: name, parameters: [])
        }

        public var isEvar: Bool {
            switch self {
            case .evar:
                return true
            case .cons:
                return false
            }
        }

        public var name: String {
            switch self {
            case .evar(let name):
                return name
            case .cons(name: let name, parameters: _):
                return name
            }
        }

        public var debugDescription: String {
            switch self {
            case .evar(let name):
                return name
            case .cons(name: let name, parameters: let parameters):
                if parameters.isEmpty {
                    return name
                } else {
                    return "\(name)<\(parameters.map { $0.debugDescription }.joined(separator: ", "))>"
                }
            }
        }
    }

    public enum UnificationError: Error {
        case nameMismatch(T, T)
        case genericArgumentsCountMismatch(T, T)
    }

    public typealias Substitution = KeyValueList<T, T>

    public struct Constraint: Equatable, CustomDebugStringConvertible {
        var head: T
        var tail: T

        public init(_ head: T, _ tail: T) {
            self.head = head
            self.tail = tail
        }

        func substituting(_ substitution: Substitution) -> Constraint {
            return Constraint(substitution[head] ?? head, substitution[tail] ?? tail)
        }

        public var debugDescription: String {
            return "\(head) == \(tail)"
        }
    }

    private static func update(constraints: [Constraint], using substitution: Substitution) -> [Constraint] {
        return constraints.map { $0.substituting(substitution) }
    }

    public static func unify(constraints: [Constraint], substitution: Substitution = Substitution()) -> Result<Substitution, UnificationError> {
        var substitution = substitution
        var constraints = constraints

//        Swift.print("INITIAL CONSTRAINTS", constraints)

        while let constraint = constraints.popLast() {
//            Swift.print("CURRENT", constraint)

            let head = constraint.head
            let tail = constraint.tail

            if head == tail { continue }

            switch (head, tail) {
            case (.cons(_, let headParameters), .cons(_, let tailParameters)):
                if head.name != tail.name {
                    return .failure(UnificationError.nameMismatch(head, tail))
                }

                if headParameters.count != tailParameters.count {
                    return .failure(UnificationError.genericArgumentsCountMismatch(head, tail))
                }

                zip(headParameters, tailParameters).forEach { a, b in
                    constraints.append(Constraint(a, b))
                }
            case (.evar, _):
                substitution = substitution.with(tail, for: head)
            case (_, .evar):
                substitution = substitution.with(head, for: tail)
            }

//            Swift.print("SUBS", substitution)

            constraints = update(constraints: constraints, using: substitution)

//            Swift.print("CONSTRAINTS", constraints)
        }

        return .success(substitution)
    }

    public static func substitute(_ substitution: Unification.Substitution, in type: Unification.T) -> Unification.T {
        var type = type

        while let newType = substitution[type] {
            type = newType
        }

        return type
    }
}
