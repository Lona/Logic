//
//  Environment+Scope.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

public extension Environment {

    struct Namespace: CustomDebugStringConvertible {
        public var debugDescription: String {
            return pairs.debugDescription
        }

        public indirect enum Value: CustomDebugStringConvertible {
            public var debugDescription: String {
                switch self {
                case .pattern(let uuid):
                    return uuid.debugDescription
                case .namespace(let namespace):
                    return namespace.debugDescription
                }
            }

            case namespace(Namespace)
            case pattern(UUID)
        }

        public var pairs: [String: Value] = [:]

        public func get(_ keyPath: [String]) -> Value? {
            guard let key = keyPath.first, let value = pairs[key] else { return nil }

            let rest = keyPath.dropFirst()

            if rest.isEmpty {
                return value
            } else {
                switch value {
                case .namespace(let sub):
                    return sub.get(Array(rest))
                case .pattern:
                    fatalError("Invalid namespace keypath")
                }
            }
        }

        public mutating func with(_ keyPath: [String], setTo value: Value) -> Namespace {
            guard let key = keyPath.first else { return self }

            let rest = keyPath.dropFirst()

            if rest.isEmpty {
                self.pairs[key] = value
            } else {
                guard let current = self.pairs[key] else { return self }

                switch current {
                case .namespace(var sub):
                    self.pairs[key] = .namespace(sub.with(Array(rest), setTo: value))
                case .pattern:
                    fatalError("Invalid namespace keypath")
                }
            }

            return self
        }

        public mutating func set(_ keyPath: [String], setTo value: Value) {
            self = with(keyPath, setTo: value)
        }

        public var flattened: [(keyPath: [String], pattern: UUID)] {
            let all: [[(keyPath: [String], UUID)]] = pairs.map { key, value in
                switch value {
                case .pattern(let uuid):
                    return [([key], uuid)]
                case .namespace(let sub):
                    return sub.flattened.map { keyPath, nestedValue in
                        return ([key] + keyPath, nestedValue)
                    }
                }
            }

            return Array(all.joined())
        }
    }

    class ScopeContext {
        var namespace = Namespace()

        var currentNamespacePath: [String] = []

        // Values in these are never removed, even if a variable is out of scope
        var patternToName: [UUID: String] = [:]
        var identifierToPattern: [UUID: UUID] = [:]
        var patternToTypeName: [UUID: String] = [:]

        // This keeps track of the current scope
        fileprivate var patternNames = ScopeStack<String, LGCPattern>()

        var namesInScope: [String] {
            return patternNames.flattened.map { $0.key }
        }

        var patternsInScope: [LGCPattern] {
            return patternNames.flattened.map { $0.value }
        }

        public init() {}

        fileprivate func setInCurrentNamespace(key: String, value: Namespace.Value) {
            namespace.set(currentNamespacePath + [key], setTo: value)
        }
    }

    static func scopeContext(
        _ node: LGCSyntaxNode,
        targetId: UUID? = nil,
        initialContext: ScopeContext = ScopeContext()
        ) -> ScopeContext {
        var traversalConfig = LGCSyntaxNode.TraversalConfig(order: .pre)

        return node.reduce(config: &traversalConfig, initialResult: initialContext) {
            (context, node, config) -> ScopeContext in
            if node.uuid == targetId {
                config.stopTraversal = true
                return context
            }

            config.needsRevisitAfterTraversingChildren = true

            switch (config.isRevisit, node) {
            case (true, .identifier(let identifier)):
                if identifier.isPlaceholder { return context }

                if context.patternNames.value(for: identifier.string) == nil {
                    Swift.print("No \(identifier.string)", context.patternNames)
                }

                context.identifierToPattern[identifier.uuid] = context.patternNames.value(for: identifier.string)!.uuid

                return context
            case (false, .expression(.memberExpression)):
                config.ignoreChildren = true

                switch node {
                case .expression(let expression):
                    guard let identifiers = expression.flattenedMemberExpression else { return context }

                    let keyPath = identifiers.map { $0.string }

                    guard let value = context.namespace.get(keyPath) else { return context }

                    guard case .pattern(let patternId) = value else { return context }

                    context.identifierToPattern[expression.uuid] = patternId
                default:
                    assertionFailure("Only expressions here")
                }

                return context
            case (true, .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: _))):
                context.patternToName[pattern.uuid] = pattern.name
                context.patternNames.set(pattern, for: pattern.name)

                context.setInCurrentNamespace(key: pattern.name, value: .pattern(pattern.id))

                return context
            case (false, .declaration(.function(id: _, name: let functionName, returnType: _, genericParameters: _, parameters: let parameters, block: _))):
                context.patternToName[functionName.uuid] = functionName.name
                context.patternNames.set(functionName, for: functionName.name)

                context.patternNames = context.patternNames.push()

                context.setInCurrentNamespace(key: functionName.name, value: .pattern(functionName.id))

                parameters.forEach { parameter in
                    switch parameter {
                    case .parameter(id: _, externalName: _, localName: let pattern, annotation: _, defaultValue: _):
                        context.patternToName[pattern.uuid] = pattern.name
                        context.patternNames.set(pattern, for: pattern.name)
                    default:
                        break
                    }
                }

                return context
            case (true, .declaration(.function(id: _, name: _, returnType: _, genericParameters: _, parameters: _, block: _))):
                context.patternNames = context.patternNames.pop()

                return context
            case (false, .declaration(.record(id: _, name: let pattern, declarations: _))):
                context.patternToTypeName[pattern.id] = pattern.name

                // We don't want to introduce the record's member variables into scope
                config.ignoreChildren = true

                return context
            case (true, .declaration(.record(id: _, name: let pattern, declarations: _))):
                // Built-ins should be constructed using literals
                if ["Boolean", "Number", "String"].contains(pattern.name) { return context }

                // Create constructor function
                context.patternToName[pattern.uuid] = pattern.name
                context.patternNames.set(pattern, for: pattern.name)

                context.setInCurrentNamespace(key: pattern.name, value: .pattern(pattern.id))
            case (false, .declaration(.enumeration(id: _, name: let pattern, genericParameters: _, cases: _))):
                context.patternToTypeName[pattern.id] = pattern.name

                return context
            case (false, .declaration(.namespace(id: _, name: let pattern, declarations: _))):
                context.patternNames = context.patternNames.push()

                context.currentNamespacePath = context.currentNamespacePath + [pattern.name]
                context.namespace = context.namespace.with(context.currentNamespacePath, setTo: .namespace(Namespace()))

                return context
            case (true, .declaration(.namespace(id: _, name: _, declarations: _))):
                context.patternNames = context.patternNames.pop()

                context.currentNamespacePath = context.currentNamespacePath.dropLast()

                return context
            default:
                break
            }

            return context
        }
    }
}
