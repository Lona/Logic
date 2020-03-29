//
//  ScopeContext.swift
//  Logic
//
//  Created by Devin Abbott on 5/28/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension Compiler {

    class ScopeContext {
        public var namespace = Namespace()

        var currentNamespacePath: [String] = []

        // Values in these are never removed, even if a variable is out of scope
        public var patternToName: [UUID: String] = [:]
        public var identifierToPattern: [UUID: UUID] = [:]
        public var patternToTypeName: [UUID: String] = [:]
        public var undefinedIdentifiers = Set<UUID>()
        public var undefinedMemberExpressions = Set<UUID>()

        // This keeps track of the current scope
        fileprivate var patternNames = ScopeStack<String, LGCPattern>()
        fileprivate var typeNames = ScopeStack<String, LGCPattern>()

        public var namesInScope: [String] {
            return patternNames.flattened.map { $0.key }
        }

        public var patternsInScope: [LGCPattern] {
            return patternNames.flattened.map { $0.value }
        }

        public var typesInScope: [LGCPattern] {
            return typeNames.flattened.map { $0.value }
        }

        public init() {}

        public func copy() -> ScopeContext {
            let other = ScopeContext()
            other.namespace = namespace.copy()
            other.currentNamespacePath = currentNamespacePath
            other.patternToName = patternToName
            other.identifierToPattern = identifierToPattern
            other.patternToTypeName = patternToTypeName
            other.undefinedIdentifiers = undefinedIdentifiers
            other.undefinedMemberExpressions = undefinedMemberExpressions
            other.patternNames = patternNames
            other.typeNames = typeNames
            return other
        }

        func pushScope() {
            patternNames = patternNames.push()
            typeNames = typeNames.push()
        }

        func popScope() {
            patternNames = patternNames.pop()
            typeNames = typeNames.pop()
        }

        func pushNamespace(name: String) {
            pushScope()
            currentNamespacePath = currentNamespacePath + [name]
        }

        func popNamespace() {
            popScope()
            currentNamespacePath = currentNamespacePath.dropLast()
        }

        func addToScope(pattern: LGCPattern) {
            patternToName[pattern.id] = pattern.name
            patternNames.set(pattern, for: pattern.name)
        }

        func addTypeToScope(pattern: LGCPattern) {
            patternToTypeName[pattern.id] = pattern.name
            typeNames.set(pattern, for: pattern.name)
        }

        func qualifiedTypeName(id: UUID) -> [String]? {
            let found = namespace.types.first(where: { (pair) -> Bool in
                pair.value == id
            })

            return found?.key
        }
    }

    static var builtInTypeConstructorNames: Set<String> = ["Boolean", "Number", "String", "Array", "Color"]

    static func scopeContext(
        _ node: LGCSyntaxNode,
        targetId: UUID? = nil,
        initialContext: ScopeContext = ScopeContext()
    ) -> Result<ScopeContext, NamespaceError> {

        switch Compiler.namespace(node: node) {
        case .success(let namespace):
            initialContext.namespace = namespace
        case .failure(let error):
            return .failure(error)
        }

        var traversalConfig =  TraversalConfig(order: .pre)

        func walk(_ context: ScopeContext, _ node: LGCSyntaxNode, config:  TraversalConfig) -> ScopeContext {
            if node.uuid == targetId {
                config.stopTraversal = true
                return context
            }

            config.needsRevisitAfterTraversingChildren = true

            switch (config.isRevisit, node) {
            case (false, .typeAnnotation(let typeAnnotation)):

                // Handle the generic arguments manually, since type annotations contain identifiers
                // and we don't want to look them up as names in scope
                switch typeAnnotation {
                case .typeIdentifier(_, _, genericArguments: let arguments):
                    _ = arguments.map { $0.node }.reduce(config: config, initialResult: context, f: walk)
                default:
                    break
                }

                config.ignoreChildren = true
                config.needsRevisitAfterTraversingChildren = false
            case (true, .identifier(let identifier)):
                if identifier.isPlaceholder { return context }

                // First, lookup identifier in scope
                if let pattern = context.patternNames.value(for: identifier.string) {
                    context.identifierToPattern[identifier.uuid] = pattern.uuid
                // Next, lookup identifier in namespace
                } else if let patternId = context.namespace.values[[identifier.string]] {
                    context.identifierToPattern[identifier.uuid] = patternId
                // TODO: Recurse
                } else if let patternId = context.namespace.values[context.currentNamespacePath + [identifier.string]] {
                    context.identifierToPattern[identifier.uuid] = patternId
                } else {
                    Swift.print("No identifier: \(identifier.string)", context.patternNames)
                    context.undefinedIdentifiers.insert(identifier.uuid)
                }
            case (false, .expression(.memberExpression)):
                config.ignoreChildren = true

                switch node {
                case .expression(let expression):
                    guard let identifiers = expression.flattenedMemberExpression else { return context }

                    let keyPath = identifiers.map { $0.string }

                    if let patternId = context.namespace.values[keyPath] {
                        context.identifierToPattern[expression.uuid] = patternId
                    } else {
                        Swift.print("No identifier path: \(keyPath)", context.patternNames)
                        context.undefinedMemberExpressions.insert(expression.uuid)
                    }
                default:
                    assertionFailure("Only expressions here")
                }
            case (true, .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: _, _))):
                context.addToScope(pattern: pattern)
            case (false, .declaration(.function(id: _, name: let functionName, returnType: _, genericParameters: let genericParameters, parameters: let parameters, block: _, _))):
                context.addToScope(pattern: functionName)

                context.pushScope()

                parameters.forEach { parameter in
                    switch parameter {
                    case .placeholder:
                        break
                    case .parameter(id: _, localName: let pattern, annotation: _, defaultValue: _, _):
                        context.addToScope(pattern: pattern)
                    }
                }

                genericParameters.forEach { param in
                    switch param {
                    case .placeholder:
                        break
                    case .parameter(id: _, name: let paramName):
                        context.addTypeToScope(pattern: paramName)
                    }
                }
            case (true, .declaration(.function(id: _, name: _, returnType: _, genericParameters: _, parameters: _, block: _, _))):
                context.popScope()
            case (false, .declaration(.record(id: _, name: let pattern, genericParameters: let genericParameters, declarations: let declarations, _))):
                context.pushNamespace(name: pattern.name)

                genericParameters.forEach { param in
                    switch param {
                    case .placeholder:
                        break
                    case .parameter(id: _, name: let paramName):
                        context.addTypeToScope(pattern: paramName)
                    }
                }

                // Handle variable initializers manually
                declarations.forEach { declaration in
                    switch declaration {
                    case .variable(_, let variableName, _, initializer: .some(let initializer), _):
                        _ = LGCSyntaxNode.expression(initializer).reduce(config: config, initialResult: context, f: walk)

                        context.addToScope(pattern: variableName)
                    default:
                        break
                    }
                }

                // Don't introduce variables names into scope
                config.ignoreChildren = true
            case (true, .declaration(.record)):
                context.popNamespace()
            case (false, .declaration(.enumeration(id: _, name: let pattern, genericParameters: let genericParameters, cases: _, _))):
                context.pushNamespace(name: pattern.name)

                genericParameters.forEach { param in
                    switch param {
                    case .placeholder:
                        break
                    case .parameter(id: _, name: let paramName):
                        context.addTypeToScope(pattern: paramName)
                    }
                }
            case (true, .declaration(.enumeration(_, _, _, _, _))):
                context.popNamespace()
            case (false, .declaration(.namespace(id: _, name: let pattern, declarations: _))):
                context.pushNamespace(name: pattern.name)
            case (true, .declaration(.namespace(id: _, name: _, declarations: _))):
                context.popNamespace()
            default:
                break
            }

            return context
        }

        return .success(node.reduce(config: traversalConfig, initialResult: initialContext, f: walk))
    }
}
