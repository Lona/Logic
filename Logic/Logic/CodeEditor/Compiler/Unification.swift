//
//  Unify.swift
//  Logic
//
//  Created by Devin Abbott on 5/21/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum Unification {
    public struct FunctionArgument: Equatable, CustomDebugStringConvertible, Hashable {
        public var debugDescription: String {
            if let label = label {
                return "\(label): \(type)"
            } else {
                return "\(type)"
            }
        }

        public var label: String?
        public var type: T

        public init(label: String? = nil, type: T) {
            self.label = label
            self.type = type
        }
    }

    public enum T: Equatable, CustomDebugStringConvertible, Hashable {
        public func hash(into hasher: inout Hasher) {
            switch self {
            case .evar(let name):
                hasher.combine(name)
            case .cons(name: let name, parameters: let parameters):
                hasher.combine(name)
                hasher.combine(parameters.hashValue)
            case .fun(arguments: let arguments, returnType: let returnType):
                hasher.combine(arguments)
                hasher.combine(returnType)
            case .gen(let name):
                hasher.combine(name)
            }
        }

        case evar(String)
        case cons(name: String, parameters: [T])
        case gen(String)
        indirect case fun(arguments: [FunctionArgument], returnType: T)

        public static func cons(name: String) -> T {
            return .cons(name: name, parameters: [])
        }

        public var isEvar: Bool {
            switch self {
            case .evar:
                return true
            case .cons:
                return false
            case .fun:
                return false
            case .gen:
                return false
            }
        }

        public var name: String {
            switch self {
            case .evar(let name):
                return name
            case .cons(name: let name, parameters: _):
                return name
            case .gen(let name):
                return name
            case .fun:
                fatalError("Function types have no name")
            }
        }

        public var genericNames: [String] {
            switch self {
            case .evar:
                return []
            case .cons(_, parameters: let parameters):
                return Array(parameters.map { $0.genericNames }.joined())
            case .gen(let name):
                return [name]
            case .fun(let arguments, let returnType):
                return Array(arguments.map { $0.type.genericNames }.joined()) + returnType.genericNames
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
            case .fun(arguments: let arguments, returnType: let returnType):
                return "(\(arguments.map { $0.debugDescription }.joined(separator: ", "))) -> \(returnType)"
            case .gen(let generic):
                return generic
            }
        }

        public func replacingGenericsWithEvars(getName: () -> String) -> Unification.T {
            let replacedNames = Unification.Substitution(
                self.genericNames.map { name in
                    return (.gen(name), .evar(getName()))
                }
            )
            return Unification.substitute(replacedNames, in: self)
        }
    }

    public enum UnificationError: Error {
        case nameMismatch(T, T)
        case genericArgumentsCountMismatch(T, T)
        case genericArgumentsLabelMismatch([FunctionArgument], [FunctionArgument])
        case kindMismatch(T, T)
    }

    public typealias Substitution = KeyValueMap<T, T>

    public struct Constraint: Equatable, CustomDebugStringConvertible {
        var head: T
        var tail: T

        public init(_ head: T, _ tail: T) {
            self.head = head
            self.tail = tail
        }

        public var debugDescription: String {
            return "\(head) == \(tail)"
        }
    }

    public static func unify(constraints: [Constraint]) -> Result<Substitution, UnificationError> {
        let substitution = Substitution()
        var constraints = constraints

        while let constraint = constraints.popLast() {
            let head = constraint.head
            let tail = constraint.tail

            if head == tail { continue }

            switch (head, tail) {
            case (.fun(arguments: let headArguments, returnType: let headReturnType),
                  .fun(arguments: let tailArguments, returnType: let tailReturnType)):
                let headContainsLabels = headArguments.contains(where: { $0.label != nil })
                let tailContainsLabels = headArguments.contains(where: { $0.label != nil })

                if headContainsLabels && !tailContainsLabels && !tailArguments.isEmpty ||
                    tailContainsLabels && !headContainsLabels && !headArguments.isEmpty {
                    return .failure(.genericArgumentsLabelMismatch(headArguments, tailArguments))
                }

                if !headContainsLabels && !tailContainsLabels {
                    if headArguments.count != tailArguments.count {
                        return .failure(UnificationError.genericArgumentsCountMismatch(head, tail))
                    }

                    zip(headArguments, tailArguments).forEach { a, b in
                        constraints.append(Constraint(a.type, b.type))
                    }
                } else {
                    let headLabels = headArguments.compactMap { $0.label }
                    let tailLabels = tailArguments.compactMap { $0.label }

                    let common = Set(headLabels).intersection(tailLabels)
                    for label in common {
                        let headArgumentType = headArguments.first(where: { $0.label == label })!.type
                        let tailArgumentType = tailArguments.first(where: { $0.label == label })!.type

                        constraints.append(.init(headArgumentType, tailArgumentType))
                    }
                }

                constraints.append(.init(headReturnType, tailReturnType))
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
            // TODO: What about evars?
            case (.gen, _), (_, .gen):
                Swift.print("Unify generics", head, tail)
                break
            case (.evar, _):
                substitution.add(tail, for: head)
            case (_, .evar):
                substitution.add(head, for: tail)
            case (.cons, .fun), (.fun, .cons):
                return .failure(.kindMismatch(head, tail))
            }

            for (index, constraint) in constraints.enumerated() {
                switch (substitution.firstValue(for: constraint.head), substitution.firstValue(for: constraint.tail)) {
                case (.some(let head), .some(let tail)):
                    constraints[index] = Constraint(head, tail)
                case (.some(let head), .none):
                    constraints[index] = Constraint(head, constraint.tail)
                case (.none, .some(let tail)):
                    constraints[index] = Constraint(constraint.head, tail)
                case (.none, .none):
                    break
                }
            }
        }

        return .success(substitution)
    }

    public static func substitute(_ substitution: Unification.Substitution, in type: Unification.T) -> Unification.T {
        var type = type

        while let newType = substitution.firstValue(for: type) {
            type = newType
        }

        switch type {
        case .evar, .gen:
            return type
        case .cons(name: let name, parameters: let parameters):
            return .cons(name: name, parameters: parameters.map { substitute(substitution, in: $0) })
        case .fun(let arguments, let returnType):
            return .fun(
                arguments: arguments.map { FunctionArgument(label: $0.label, type: substitute(substitution, in: $0.type)) },
                returnType: substitute(substitution, in: returnType)
            )
        }
    }
}
