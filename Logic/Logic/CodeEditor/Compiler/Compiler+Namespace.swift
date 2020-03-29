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

extension Compiler {
    public static func namespace(node topLevelNode: LGCSyntaxNode) -> Result<Compiler.Namespace, Compiler.NamespaceError> {
        let context = Compiler.Namespace()

        var currentNamespacePath: [String] = []

        func pushNamespacePath(name: String) {
            currentNamespacePath = currentNamespacePath + [name]
        }

        func popNamespacePath() {
            currentNamespacePath = currentNamespacePath.dropLast()
        }

        func declareValue(name: String, value: UUID) throws {
            try context.declareValue(name: currentNamespacePath + [name], value: value)
        }

        func declareType(name: String, type: UUID) throws {
            try context.declareType(name: currentNamespacePath + [name], type: type)
        }

        do {
            var config: LGCSyntaxNode.TraversalConfig = .init(order: .pre)

            try topLevelNode.forEachDescendant(config: config) { (node, config) in
                config.needsRevisitAfterTraversingChildren = true

                switch (config.isRevisit, node) {
                case (true, .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: _, _))):
                    try declareValue(name: pattern.name, value: pattern.id)
                case (true, .declaration(.function(id: _, name: let functionName, returnType: _, genericParameters: _, parameters: _, block: _, _))):
                    try declareValue(name: functionName.name, value: functionName.id)
                case (false, .declaration(.record(id: _, name: let pattern, genericParameters: _, declarations: _, _))):
                    try declareType(name: pattern.name, type: pattern.id)

                    // We push to the namespace path and traverse into children.
                    // Variable declarations will be added to the namespace - we will then turn these into
                    // getter functions for each member variable.
                    pushNamespacePath(name: pattern.name)
                case (true, .declaration(.record(id: _, name: let pattern, genericParameters: _, declarations: _, _))):
                    popNamespacePath()

                    // Built-ins should be constructed using literals
                    if Compiler.builtInTypeConstructorNames.contains(pattern.name) { return }

                    // Create constructor function
                    try declareValue(name: pattern.name, value: pattern.id)
                case (true, .declaration(.enumeration(id: _, name: let pattern, genericParameters: _, cases: let cases, _))):
                    try declareType(name: pattern.name, type: pattern.id)

                    pushNamespacePath(name: pattern.name)

                    // Add initializers for each case into the namespace
                    try cases.forEach { enumCase in
                        switch enumCase {
                        case .placeholder:
                            break
                        case .enumerationCase(id: _, name: let caseName, associatedValueTypes: _, _):
                            try declareValue(name: caseName.name, value: caseName.id)
                        }
                    }

                    popNamespacePath()
                case (false, .declaration(.namespace(id: _, name: let pattern, declarations: _))):
                    pushNamespacePath(name: pattern.name)
                case (true, .declaration(.namespace(id: _, name: _, declarations: _))):
                    popNamespacePath()
                default:
                    break
                }
            }
        } catch {
            if let error = error as? Compiler.NamespaceError {
                return .failure(error)
            }

            fatalError("\(error)")
        }

        return .success(context)
    }
}
