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
        // Values in namespaces are accessible to all scopes, regardless of their order in the code
        public var namespace = Namespace()
        public var typeNamespace = Namespace()

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

        fileprivate func setInCurrentNamespace(key: String, value: UUID) {
            namespace.set(currentNamespacePath + [key], setTo: value)
        }

        fileprivate func setTypeInCurrentNamespace(key: String, value: UUID) {
            typeNamespace.set(currentNamespacePath + [key], setTo: value)
        }

        fileprivate func pushScope() {
            patternNames = patternNames.push()
            typeNames = typeNames.push()
        }

        fileprivate func popScope() {
            patternNames = patternNames.pop()
            typeNames = typeNames.pop()
        }

        fileprivate func pushNamespace(name: String) {
            pushScope()
            currentNamespacePath = currentNamespacePath + [name]
        }

        fileprivate func popNamespace() {
            popScope()
            currentNamespacePath = currentNamespacePath.dropLast()
        }

        fileprivate func addToScope(pattern: LGCPattern) {
            patternToName[pattern.id] = pattern.name
            patternNames.set(pattern, for: pattern.name)
        }

        fileprivate func addTypeToScope(pattern: LGCPattern) {
            patternToTypeName[pattern.id] = pattern.name
            typeNames.set(pattern, for: pattern.name)
        }

        func qualifiedTypeName(id: UUID) -> [String]? {
            let found = typeNamespace.pairs.first(where: { (pair) -> Bool in
                pair.value == id
            })

            return found?.key
        }
    }

    private static var builtInTypeConstructorNames: Set<String> = ["Boolean", "Number", "String", "Array", "Color"]

    static func scopeContext(
        _ node: LGCSyntaxNode,
        targetId: UUID? = nil,
        initialContext: ScopeContext = ScopeContext()
        ) -> ScopeContext {
        var traversalConfig = LGCSyntaxNode.TraversalConfig(order: .pre)

        func namespaceDeclarations(_ context: ScopeContext, _ node: LGCSyntaxNode, config: inout LGCSyntaxNode.TraversalConfig) -> ScopeContext {
            config.needsRevisitAfterTraversingChildren = true

            switch (config.isRevisit, node) {
            case (true, .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: _, _))):
                context.setInCurrentNamespace(key: pattern.name, value: pattern.id)
            case (true, .declaration(.function(id: _, name: let functionName, returnType: _, genericParameters: _, parameters: _, block: _, _))):
                context.setInCurrentNamespace(key: functionName.name, value: functionName.id)
            case (false, .declaration(.record(id: _, name: let pattern, genericParameters: _, declarations: _, _))):
                context.setTypeInCurrentNamespace(key: pattern.name, value: pattern.id)

                // Avoid introducing member variables into the namespace
                config.ignoreChildren = true
            case (true, .declaration(.record(id: _, name: let pattern, genericParameters: _, declarations: _, _))):
                // Built-ins should be constructed using literals
                if builtInTypeConstructorNames.contains(pattern.name) { return context }

                // Create constructor function
                context.setInCurrentNamespace(key: pattern.name, value: pattern.id)
            case (true, .declaration(.enumeration(id: _, name: let pattern, genericParameters: _, cases: let cases, _))):
                context.setTypeInCurrentNamespace(key: pattern.name, value: pattern.id)

                context.pushNamespace(name: pattern.name)

                // Add initializers for each case into the namespace
                cases.forEach { enumCase in
                    switch enumCase {
                    case .placeholder:
                        break
                    case .enumerationCase(id: _, name: let caseName, associatedValueTypes: _, _):
                        context.setInCurrentNamespace(key: caseName.name, value: caseName.id)
                    }
                }

                context.popNamespace()

                return context
            case (false, .declaration(.namespace(id: _, name: let pattern, declarations: _))):
                context.pushNamespace(name: pattern.name)
            case (true, .declaration(.namespace(id: _, name: _, declarations: _))):
                context.popNamespace()
            default:
                break
            }

            return context
        }

        let contextWithNamespaceDeclarations = node.reduce(config: &traversalConfig, initialResult: initialContext, f: namespaceDeclarations)

        traversalConfig = LGCSyntaxNode.TraversalConfig(order: .pre)

        func walk(_ context: ScopeContext, _ node: LGCSyntaxNode, config: inout LGCSyntaxNode.TraversalConfig) -> ScopeContext {
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
                    _ = arguments.map { $0.node }.reduce(config: &config, initialResult: context, f: walk)
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
                } else if let patternId = context.namespace.get([identifier.string]) {
                    context.identifierToPattern[identifier.uuid] = patternId
                } else if let patternId = context.namespace.get(context.currentNamespacePath + [identifier.string]) {
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

                    if let patternId = context.namespace.get(keyPath) {
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
                    case .parameter(id: _, externalName: _, localName: let pattern, annotation: _, defaultValue: _, _):
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

                // Handle variable initializers manually so we don't introduce their names into scope
                declarations.forEach { declaration in
                    switch declaration {
                    case .variable(_, _, _, initializer: .some(let initializer), _):
                        _ = LGCSyntaxNode.expression(initializer).reduce(config: &config, initialResult: context, f: walk)
                    default:
                        break
                    }
                }

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

        return node.reduce(config: &traversalConfig, initialResult: contextWithNamespaceDeclarations, f: walk)
    }
}
