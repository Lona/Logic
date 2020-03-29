//
//  Namespace.swift
//  Logic
//
//  Created by Devin Abbott on 5/28/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Compiler {

    /**
     All Logic declaration names must be unique, and are added to a global namespace.

     Values and types share a separate namespace, e.g. `Foo` can be a type and also a function,
     which is how constructor functions are created.
     */
    public class Namespace: CustomDebugStringConvertible {
        public var values: [[String]: UUID] = [:]
        public var types: [[String]: UUID] = [:]

        public init() {}

        public func copy() -> Namespace {
            let new = Namespace()

            new.values = values
            new.types = types

            return new
        }

        public var debugDescription: String {
            return """
            Namespace:
              Values:
            \(values.map({ "    \($0.key.joined(separator: ".")) -> \($0.value)" }).joined(separator: "\n"))
              Types:
            \(values.map({ "    \($0.key.joined(separator: ".")) -> \($0.value)" }).joined(separator: "\n"))
            """
        }
    }

    public enum NamespaceError: Error {
        case valueAlreadyDeclared(name: [String], existing: UUID, new: UUID)
        case typeAlreadyDeclared(name: [String], existing: UUID, new: UUID)

        public var nodeID: UUID {
            switch self {
            case .valueAlreadyDeclared(_, let id, _), .typeAlreadyDeclared(_, let id, _):
                return id
            }
        }

        public var localizedDescription: String {
            switch self {
            case .valueAlreadyDeclared(let qualifiedName, _, _):
                return "The value name '\(qualifiedName.joined(separator: "."))' has already been declared."
            case .typeAlreadyDeclared(let qualifiedName, _, _):
                return "The type name '\(qualifiedName.joined(separator: "."))' has already been declared."
            }
        }
    }
}

extension Compiler.Namespace {
    public func declareValue(name: [String], value: UUID) throws {
        if let existing = values[name] {
            throw Compiler.NamespaceError.valueAlreadyDeclared(name: name, existing: existing, new: value)
        }

        values[name] = value
    }

    public func declareType(name: [String], type: UUID) throws {
        if let existing = types[name] {
            throw Compiler.NamespaceError.typeAlreadyDeclared(name: name, existing: existing, new: type)
        }

        types[name] = type
    }
}

extension Sequence where Iterator.Element == Compiler.Namespace {
    /**
     Merge namespaces.

     This results in an error if any duplicate names are found.
     */
    func merged() -> Result<Compiler.Namespace, Compiler.NamespaceError> {
        return Result(catching: {
            try self.reduce(into: Compiler.Namespace()) { (result, element) in
                for (name, type) in element.types {
                    try result.declareType(name: name, type: type)
                }
            }
        }).mapError({ $0 as! Compiler.NamespaceError })
    }
}

extension Compiler {
    public class NamespaceVisitor {
        public init(namespace: Compiler.Namespace) {
            self.namespace = namespace
        }

        public var namespace: Compiler.Namespace
        public var currentPath: [String] = []
        public var traversalConfig: TraversalConfig = .init(order: .pre)

        public func pushPathComponent(name: String) {
            currentPath = currentPath + [name]
        }

        public func popPathComponent() {
            currentPath = currentPath.dropLast()
        }

        public func declareValue(name: String, value: UUID) throws {
            try namespace.declareValue(name: currentPath + [name], value: value)
        }

        public func declareType(name: String, type: UUID) throws {
            try namespace.declareType(name: currentPath + [name], type: type)
        }
    }
}

public protocol NamespaceVisitable {
    func visit(_ visitor: Compiler.NamespaceVisitor) throws
}

extension Compiler {

    /**
     Build the global namespace by visiting each node.
     */
    public static func namespace<Node: Reducible & NamespaceVisitable>(
        node topLevelNode: Node
    ) -> Result<Compiler.Namespace, Compiler.NamespaceError> {
        let context = Compiler.Namespace()
        let visitor = Compiler.NamespaceVisitor(namespace: context)

        do {
            try topLevelNode.forEachDescendant(config: visitor.traversalConfig) { (node, config) in
                try node.visit(visitor)
            }
        } catch {
            return .failure(error as! Compiler.NamespaceError)
        }

        return .success(context)
    }
}
