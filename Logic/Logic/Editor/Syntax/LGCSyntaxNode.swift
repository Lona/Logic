//
//  SwiftNativeTypes.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public enum Movement {
    case none, next
}

public protocol SyntaxNodeProtocol {
    var uuid: UUID { get }
    var lastNode: LGCSyntaxNode { get }
    var movementAfterInsertion: Movement { get }
    var node: LGCSyntaxNode { get }
    var nodeTypeDescription: String { get }

    func find(id: UUID) -> LGCSyntaxNode?
    func pathTo(id: UUID) -> [LGCSyntaxNode]?
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> Self
    func delete(id: UUID) -> Self
    func swap(sourceId: UUID, targetId: UUID) -> Self

    func documentation(within root: LGCSyntaxNode, for prefix: String) -> RichText
    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem]
}

public extension SyntaxNodeProtocol {
    func documentation(within root: LGCSyntaxNode, for prefix: String) -> RichText {
        return RichText(blocks: [])
    }

    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
        return []
    }

    func find(id: UUID) -> LGCSyntaxNode? {
        return pathTo(id: id)?.last
    }

    func delete(id: UUID) -> Self {
        return self
    }

    func swap(sourceId: UUID, targetId: UUID) -> Self {
        return self
    }
}

extension LGCIdentifier: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Identifier"
    }

    public var node: LGCSyntaxNode {
        return .identifier(self)
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCIdentifier {
        switch syntaxNode {
        case .identifier(let newNode) where id == uuid:
            return LGCIdentifier(id: UUID(), string: newNode.string, isPlaceholder: newNode.isPlaceholder)
        default:
            return LGCIdentifier(id: UUID(), string: string, isPlaceholder: isPlaceholder)
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        return id == uuid ? [node] : nil
    }

    public var lastNode: LGCSyntaxNode {
        return node
    }

    public var uuid: UUID { return id }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCPattern: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Pattern"
    }

    public var node: LGCSyntaxNode {
        return .pattern(self)
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCPattern {
        switch syntaxNode {
        case .pattern(let newNode) where id == uuid:
            return LGCPattern(id: UUID(), name: newNode.name)
        default:
            return LGCPattern(id: UUID(), name: name)
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        return id == uuid ? [node] : nil
    }

    public var lastNode: LGCSyntaxNode {
        return node
    }

    public var uuid: UUID { return id }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCTypeAnnotation: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        switch self {
        case .typeIdentifier, .placeholder:
            return "Type Annotation"
        case .functionType:
            return "Function Type Annotation"
        }
    }

    public var node: LGCSyntaxNode {
        return .typeAnnotation(self)
    }

    public func delete(id: UUID) -> LGCTypeAnnotation {
        switch self {
        case .typeIdentifier, .placeholder:
            return self
        case .functionType(let value):
            let updatedArguments = value.argumentTypes
                .filter {
                    switch $0 {
                    case .typeIdentifier(let typeIdentifier):
                        return typeIdentifier.id != id
                    case .functionType, .placeholder:
                        return true
                    }
                }
                .map { $0.delete(id: id) }

            return LGCTypeAnnotation.functionType(
                id: UUID(),
                returnType: value.returnType.delete(id: id),
                argumentTypes: LGCList(updatedArguments)
            )
        }
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCTypeAnnotation {
        switch syntaxNode {
        case .typeAnnotation(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .typeIdentifier(let value):
                return LGCTypeAnnotation.typeIdentifier(
                    id: UUID(),
                    identifier: value.identifier.replace(id: id, with: syntaxNode),
                    genericArguments: value.genericArguments.replace(id: id, with: syntaxNode)
                )
            case .functionType(let value):
                return LGCTypeAnnotation.functionType(
                    id: UUID(),
                    returnType: value.returnType.replace(id: id, with: syntaxNode),
                    argumentTypes: value.argumentTypes.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            case .placeholder:
                return LGCTypeAnnotation.placeholder(id: UUID())
            }
        }
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        if id == uuid { return node }

        switch self {
        case .functionType(let value):
            return value.argumentTypes.find(id: id) ?? value.returnType.find(id: id)
        case .typeIdentifier(let value):
            return value.identifier.find(id: id) ?? value.genericArguments.find(id: id)
        case .placeholder:
            return nil
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid { return [node] }

        var found: [LGCSyntaxNode]?

        switch self {
        case .functionType(let value):
            found = value.argumentTypes.pathTo(id: id) ?? value.returnType.pathTo(id: id)
        case .typeIdentifier(let value):
            found = value.identifier.pathTo(id: id)

            // If we match the identifier, we still want to show the picker for the whole annotation
            if let _ = found {
                return [self.node]
            }

            found = value.genericArguments.pathTo(id: id)
        case .placeholder:
            break
        }

        if let found = found {
            return [self.node] + found
        } else {
            return nil
        }
    }

    public var lastNode: LGCSyntaxNode {
        return node
    }

    public var uuid: UUID {
        switch self {
        case .typeIdentifier(let value):
            return value.id
        case .functionType(let value):
            return value.id
        case .placeholder(let value):
            return value
        }
    }

    public var movementAfterInsertion: Movement {
        switch self {
        case .typeIdentifier:
            return .next
        case .functionType:
            return .none
        case .placeholder:
            return .next
        }
    }
}

extension LGCLiteral: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Literal Value"
    }

    public var node: LGCSyntaxNode {
        return .literal(self)
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCLiteral {
        switch syntaxNode {
        case .literal(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .boolean(let value):
                return LGCLiteral.boolean(
                    id: UUID(),
                    value: value.value
                )
            case .number(let value):
                return LGCLiteral.number(
                    id: UUID(),
                    value: value.value
                )
            case .string(let value):
                return LGCLiteral.string(
                    id: UUID(),
                    value: value.value
                )
            case .color(let value):
                return LGCLiteral.color(
                    id: UUID(),
                    value: value.value
                )
            case .none:
                return LGCLiteral.none(id: UUID())
            }
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid { return [node] }

        return nil
    }

    public var lastNode: LGCSyntaxNode {
        return node
    }

    public var uuid: UUID {
        switch self {
        case .boolean(let value):
            return value.id
        case .number(let value):
            return value.id
        case .string(let value):
            return value.id
        case .color(let value):
            return value.id
        case .none(let value):
            return value
        }
    }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCFunctionParameterDefaultValue: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Default Value"
    }

    public var node: LGCSyntaxNode {
        return .functionParameterDefaultValue(self)
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCFunctionParameterDefaultValue {
        switch syntaxNode {
        case .functionParameterDefaultValue(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .none:
                return LGCFunctionParameterDefaultValue.none(id: UUID())
            case .value(let value):
                return LGCFunctionParameterDefaultValue.value(
                    id: UUID(),
                    expression: value.expression.replace(id: id, with: syntaxNode)
                )
            }
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid { return [node] }

        var found: [LGCSyntaxNode]?

        switch self {
        case .none:
            return nil
        case .value(let value):
            found = value.expression.pathTo(id: id)
        }

        if let found = found {
            return [self.node] + found
        } else {
            return nil
        }
    }

    public var lastNode: LGCSyntaxNode {
        return node
    }

    public var uuid: UUID {
        switch self {
        case .none(let value):
            return value
        case .value(let value):
            return value.id
        }
    }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCFunctionParameter: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Parameter"
    }

    public var node: LGCSyntaxNode {
        return .functionParameter(self)
    }

    public func delete(id: UUID) -> LGCFunctionParameter {
        switch self {
        case .placeholder:
            return self
        case .parameter(let value):
            return LGCFunctionParameter.parameter(
                id: UUID(),
                externalName: value.externalName,
                localName: value.localName.delete(id: id),
                annotation: value.annotation.delete(id: id),
                defaultValue: value.defaultValue.delete(id: id)
            )
        }
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCFunctionParameter {
        switch syntaxNode {
        case .functionParameter(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .placeholder:
                return LGCFunctionParameter.placeholder(id: UUID())
            case .parameter(let value):
                return LGCFunctionParameter.parameter(
                    id: UUID(),
                    externalName: value.externalName,
                    localName: value.localName.replace(id: id, with: syntaxNode),
                    annotation: value.annotation.replace(id: id, with: syntaxNode),
                    defaultValue: value.defaultValue.replace(id: id, with: syntaxNode)
                )
            }
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid { return [node] }

        let found: [LGCSyntaxNode]?

        switch self {
        case .placeholder:
            found = nil
        case .parameter(let value):
            found = value.localName.pathTo(id: id)
                ?? value.annotation.pathTo(id: id)
                ?? value.defaultValue.pathTo(id: id)
        }

        if let found = found {
            return [self.node] + found
        } else {
            return nil
        }
    }

    public var lastNode: LGCSyntaxNode {
        return node
    }

    public var uuid: UUID {
        switch self {
        case .parameter(let value):
            return value.id
        case .placeholder(let value):
            return value
        }
    }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCEnumerationCase: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Enum Case"
    }

    public var node: LGCSyntaxNode {
        return .enumerationCase(self)
    }

    public func delete(id: UUID) -> LGCEnumerationCase {
        switch self {
        case .placeholder:
            return self
        case .enumerationCase(let value):
            let updated = value.associatedValueTypes
                .filter { isPlaceholder || $0.uuid != id }
                .map { $0.delete(id: id) }

            return LGCEnumerationCase.enumerationCase(
                id: UUID(),
                name: value.name.delete(id: id),
                associatedValueTypes: LGCList(updated)
            )
        }
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCEnumerationCase {
        switch syntaxNode {
        case .enumerationCase(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .placeholder:
                return LGCEnumerationCase.placeholder(id: UUID())
            case .enumerationCase(let value):
                return LGCEnumerationCase.enumerationCase(
                    id: UUID(),
                    name: value.name.replace(id: id, with: syntaxNode),
                    associatedValueTypes: value.associatedValueTypes.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            }
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid { return [node] }

        let found: [LGCSyntaxNode]?

        switch self {
        case .placeholder:
            found = nil
        case .enumerationCase(let value):
            found = value.name.pathTo(id: id) ?? value.associatedValueTypes.pathTo(id: id)
        }

        if let found = found {
            return [self.node] + found
        } else {
            return nil
        }
    }

    public var lastNode: LGCSyntaxNode {
        return node
    }

    public var uuid: UUID {
        switch self {
        case .enumerationCase(let value):
            return value.id
        case .placeholder(let value):
            return value
        }
    }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCBinaryOperator: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Binary Operator"
    }

    public var node: LGCSyntaxNode {
        return .binaryOperator(self)
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCBinaryOperator {
        switch syntaxNode {
        case .binaryOperator(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .isEqualTo:
                return LGCBinaryOperator.isEqualTo(id: UUID())
            case .isNotEqualTo:
                return LGCBinaryOperator.isNotEqualTo(id: UUID())
            case .isLessThan:
                return LGCBinaryOperator.isLessThan(id: UUID())
            case .isGreaterThan:
                return LGCBinaryOperator.isGreaterThan(id: UUID())
            case .isLessThanOrEqualTo:
                return LGCBinaryOperator.isLessThanOrEqualTo(id: UUID())
            case .isGreaterThanOrEqualTo:
                return LGCBinaryOperator.isGreaterThanOrEqualTo(id: UUID())
            case .setEqualTo:
                return LGCBinaryOperator.setEqualTo(id: UUID())
            }
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        return id == uuid ? [node] : nil
    }

    public var lastNode: LGCSyntaxNode {
        return node
    }

    public var uuid: UUID {
        switch self {
        case .isEqualTo(let value):
            return value
        case .isNotEqualTo(let value):
            return value
        case .isLessThan(let value):
            return value
        case .isGreaterThan(let value):
            return value
        case .isLessThanOrEqualTo(let value):
            return value
        case .isGreaterThanOrEqualTo(let value):
            return value
        case .setEqualTo(let value):
            return value
        }
    }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCExpression: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Expression"
    }

    public var node: LGCSyntaxNode {
        return .expression(self)
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCExpression {
        switch (syntaxNode, self) {
        case (.expression(let newNode), _) where id == uuid:
            return newNode
        // Identifier can become an IdentifierExpression and replace an expression
        case (.identifier(let newNode), _) where id == uuid:
            return .identifierExpression(id: UUID(), identifier: newNode)
        case (_, .binaryExpression(let value)):
            return .binaryExpression(
                left: value.left.replace(id: id, with: syntaxNode),
                right: value.right.replace(id: id, with: syntaxNode),
                op: value.op.replace(id: id, with: syntaxNode),
                id: UUID()
            )
        case (_, .identifierExpression(let value)):
            return .identifierExpression(
                id: UUID(),
                identifier: value.identifier.replace(id: id, with: syntaxNode)
            )
        case (_, .functionCallExpression(let value)):
            return .functionCallExpression(
                id: UUID(),
                expression: value.expression.replace(id: id, with: syntaxNode),
                arguments: value.arguments.replace(id: id, with: syntaxNode)
            )
        case (_, .literalExpression(let value)):
            return .literalExpression(
                id: UUID(),
                literal: value.literal.replace(id: id, with: syntaxNode)
            )
        case (_, .memberExpression(let value)):
            return .memberExpression(
                id: UUID(),
                expression: value.expression.replace(id: id, with: syntaxNode),
                memberName: value.memberName.replace(id: id, with: syntaxNode)
            )
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid {
            return [.expression(self)]
        }

        var found: [LGCSyntaxNode]?

        switch self {
        case .binaryExpression(let value):
            found = value.left.pathTo(id: id) ?? value.op.pathTo(id: id) ?? value.right.pathTo(id: id)
        case .identifierExpression(let value):
            found = value.identifier.pathTo(id: id)
        case .functionCallExpression(let value):
            // TODO: Should LGCFunctionCallArgument conform to SyntaxNodeProtocol?
            let foundInArguments: [LGCSyntaxNode]? = value.arguments.reduce(nil, { result, node in
                return result ?? node.pathTo(id: id)
            })
            found = value.expression.pathTo(id: id) ?? foundInArguments
        case .literalExpression(let value):
            found = value.literal.pathTo(id: id)
        case .memberExpression(let value):
            found = value.expression.pathTo(id: id) ?? value.memberName.pathTo(id: id)
        }

        if let found = found {
            return [.expression(self)] + found
        } else {
            return nil
        }
    }

    public var lastNode: LGCSyntaxNode {
        switch self {
        case .binaryExpression(let value):
            return value.right.lastNode
        case .identifierExpression(let value):
            return value.identifier.lastNode
        case .functionCallExpression(let value):
            return value.arguments.isEmpty ? value.expression.lastNode : value.arguments[value.arguments.count - 1].lastNode
        case .literalExpression(let value):
            return value.literal.lastNode
        case .memberExpression(let value):
            return value.memberName.lastNode
        }
    }

    public var uuid: UUID {
        switch self {
        case .binaryExpression(let value):
            return value.id
        case .identifierExpression(let value):
            return value.id
        case .functionCallExpression(let value):
            return value.id
        case .literalExpression(let value):
            return value.id
        case .memberExpression(let value):
            return value.id
        }
    }

    public var movementAfterInsertion: Movement {
        switch self {
        case .binaryExpression:
            return .none
        case .identifierExpression:
            return .next
        case .functionCallExpression:
            return .next
        case .literalExpression:
            return .next
        case .memberExpression:
            return .next
        }
    }
}

extension LGCStatement: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Statement"
    }

    public var node: LGCSyntaxNode {
        return .statement(self)
    }

    public func delete(id: UUID) -> LGCStatement {
        switch self {
        case .declaration(let value):
            return .declaration(id: UUID(), content: value.content.delete(id: id))
        default:
            // TODO
            return self
        }
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCStatement {
        switch syntaxNode {
        case .statement(let newNode) where id == uuid:
            return newNode
        case .expression(let newNode) where id == uuid:
            return .expressionStatement(
                id: UUID(),
                expression: newNode
            )
        case .declaration(let newNode) where id == uuid:
            return .declaration(
                id: UUID(),
                content: newNode
            )
        default:
            switch self {
            case .branch(let value):
                return .branch(
                    id: UUID(),
                    condition: value.condition.replace(id: id, with: syntaxNode),
                    block: value.block.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            case .declaration(let value):
                return LGCStatement.declaration(
                    id: UUID(),
                    content: value.content.replace(id: id, with: syntaxNode)
                )
            case .loop(let value):
                return LGCStatement.loop(
                    pattern: value.pattern.replace(id: id, with: syntaxNode),
                    expression: value.expression.replace(id: id, with: syntaxNode),
                    block: LGCList<LGCStatement>.empty,
                    id: UUID()
                )
            case .expressionStatement(let value):
                return LGCStatement.expressionStatement(
                    id: UUID(),
                    expression: value.expression.replace(id: id, with: syntaxNode)
                )
            case .placeholderStatement(_):
                return self
            }
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid {
            return [.statement(self)]
        }

        var found: [LGCSyntaxNode]?

        switch self {
        case .branch(let value):
            let foundInBlock: [LGCSyntaxNode]? = value.block.reduce(nil, { result, node in
                if result != nil { return result }
                return node.pathTo(id: id)
            })
            found = value.condition.pathTo(id: id) ?? foundInBlock
        case .declaration(let value):
            found = value.content.pathTo(id: id)
        case .loop(let value):
            found = value.expression.pathTo(id: id) ?? value.pattern.pathTo(id: id)
        case .expressionStatement(let value):
            found = value.expression.pathTo(id: id)
        case .placeholderStatement:
            return nil
        }

        if let found = found {
            return [.statement(self)] + found
        } else {
            return nil
        }
    }

    public var lastNode: LGCSyntaxNode {
        switch self {
        case .branch(let value):
            return value.block.map { $0 }.last?.lastNode ?? value.condition.lastNode
        case .declaration:
            fatalError("Not implemented")
        case .loop(let value):
            return value.expression.lastNode
        case .expressionStatement(let value):
            return value.expression.lastNode
        case .placeholderStatement:
            return .statement(self)
        }
    }

    public var uuid: UUID {
        switch self {
        case .branch(let value):
            return value.id
        case .declaration(let value):
            return value.id
        case .loop(let value):
            return value.id
        case .expressionStatement(let value):
            return value.id
        case .placeholderStatement(let value):
            return value
        }
    }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCDeclaration: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Declaration"
    }

    public var node: LGCSyntaxNode {
        return .declaration(self)
    }

    public func delete(id: UUID) -> LGCDeclaration {
        switch self {
        case .variable:
            return self
        case .enumeration(let value):
            return .enumeration(
                id: UUID(),
                name: value.name.delete(id: id),
                cases: LGCList(value.cases.filter {
                    switch $0 {
                    case .placeholder:
                        return true
                    case .enumerationCase(let value):
                        return value.id != id
                    }
                    }.map { $0.delete(id: id) })
            )
        case .namespace(let value):
            return .namespace(
                id: UUID(),
                name: value.name.delete(id: id),
                declarations: LGCList(value.declarations.filter {
                    switch $0 {
                    case .placeholder:
                        return true
                    default:
                        return $0.uuid != id
                    }
                    }.map { $0.delete(id: id) })
            )
        case .function(let value):
            return .function(
                id: UUID(),
                name: value.name.delete(id: id),
                returnType: value.returnType.delete(id: id),
                parameters: value.parameters.delete(id: id),
                block: value.block.delete(id: id)
            )
        case .placeholder:
            return .placeholder(id: UUID())
        }
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCDeclaration {
        switch syntaxNode {
        case .declaration(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .variable(let value):
                return LGCDeclaration.variable(
                    id: UUID(),
                    name: value.name.replace(id: id, with: syntaxNode),
                    annotation: value.annotation?.replace(id: id, with: syntaxNode),
                    initializer: value.initializer?.replace(id: id, with: syntaxNode)
                )
            case .function(let value):
                return LGCDeclaration.function(
                    id: UUID(),
                    name: value.name.replace(id: id, with: syntaxNode),
                    returnType: value.returnType.replace(id: id, with: syntaxNode),
                    parameters: value.parameters.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    block: value.block.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            case .enumeration(let value):
                return LGCDeclaration.enumeration(
                    id: UUID(),
                    name: value.name.replace(id: id, with: syntaxNode),
                    cases: value.cases.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            case .namespace(let value):
                return LGCDeclaration.namespace(
                    id: UUID(),
                    name: value.name.replace(id: id, with: syntaxNode),
                    declarations: value.declarations.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            case .placeholder:
                return LGCDeclaration.placeholder(id: UUID())
            }
        }
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid { return [node] }

        let found: [LGCSyntaxNode]?

        switch self {
        case .variable(let value):
            found = value.name.pathTo(id: id)
                ?? value.annotation?.pathTo(id: id)
                ?? value.initializer?.pathTo(id: id)
        case .function(let value):
            found = value.name.pathTo(id: id)
                ?? value.returnType.pathTo(id: id)
                ?? value.parameters.pathTo(id: id)
                ?? value.block.pathTo(id: id)
        case .enumeration(let value):
            found = value.name.pathTo(id: id)
                ?? value.cases.pathTo(id: id)
        case .namespace(let value):
            found = value.name.pathTo(id: id)
                ?? value.declarations.pathTo(id: id)
        case .placeholder:
            found = nil
        }

        if let found = found {
            return [self.node] + found
        } else {
            return nil
        }
    }

    public var lastNode: LGCSyntaxNode {
        switch self {
        case .variable:
            return node
        case .function(let value):
            return value.block.map { $0 }.last?.lastNode ?? node
        case .enumeration(let value):
            return value.cases.map { $0 }.last?.lastNode ?? node
        case .namespace(let value):
            return value.declarations.map { $0 }.last?.lastNode ?? node
        case .placeholder:
            return node
        }
    }

    public var uuid: UUID {
        switch self {
        case .variable(let value):
            return value.id
        case .function(let value):
            return value.id
        case .enumeration(let value):
            return value.id
        case .namespace(let value):
            return value.id
        case .placeholder(let value):
            return value
        }
    }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCProgram: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Program"
    }

    public var node: LGCSyntaxNode {
        return .program(self)
    }

    public func delete(id: UUID) -> LGCProgram {
        let updated = block
            .filter { $0.isPlaceholder || $0.uuid != id }
            .map { $0.delete(id: id) }

        return LGCProgram(
            id: UUID(),
            block: LGCList(updated)
        )
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCProgram {
        return LGCProgram(
            id: UUID(),
            block: block.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
        )
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        if id == uuid { return node }

        return block.find(id: id)
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid { return [node] }

        let found: [LGCSyntaxNode]? = block.reduce(nil, { result, node in
            if result != nil { return result }
            return node.pathTo(id: id)
        })

        // We don't include the Program node in the path, since we never want
        // to directly select it or show it in any menus
        return found
    }

    public var lastNode: LGCSyntaxNode {
        return block.map { $0 }.last?.lastNode ?? node
    }

    public var uuid: UUID {
        return id
    }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCTopLevelParameters: SyntaxNodeProtocol {
    public var nodeTypeDescription: String {
        return "Top-level Parameters"
    }

    public var node: LGCSyntaxNode {
        return .topLevelParameters(self)
    }

    public func delete(id: UUID) -> LGCTopLevelParameters {
        let updated = parameters.filter { param in
            switch param {
            case .placeholder:
                return true
            case .parameter(let value):
                return param.uuid != id && value.localName.id != id
            }
            }.map { $0.delete(id: id) }

        return LGCTopLevelParameters(
            id: UUID(),
            parameters: LGCList(updated)
        )
    }

    public func swap(sourceId: UUID, targetId: UUID) -> LGCTopLevelParameters {
        var updated = parameters.map { $0 }

        guard let sourceIndex = updated.firstIndex(where: { param in param.uuid == sourceId }),
            let targetIndex = updated.lastIndex(where: { param in param.uuid == targetId }) else { return self }

        let sourceNode = updated[sourceIndex]

        updated.remove(at: sourceIndex)
        updated.insert(sourceNode, at: targetIndex)
        updated = updated.filter { param in
            switch param {
            case .placeholder:
                return false
            case .parameter:
                return true
            }
        }
        updated.append(LGCFunctionParameter.placeholder(id: UUID()))

        return LGCTopLevelParameters(
            id: UUID(),
            parameters: LGCList(updated)
        )
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCTopLevelParameters {
        return LGCTopLevelParameters(
            id: UUID(),
            parameters: parameters.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
        )
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        if id == uuid { return node }

        return parameters.find(id: id)
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        if id == uuid { return [node] }

        let found: [LGCSyntaxNode]? = parameters.reduce(nil, { result, node in
            if result != nil { return result }
            return node.pathTo(id: id)
        })

        // We don't include the Program node in the path, since we never want
        // to directly select it or show it in any menus
        return found
    }

    public var lastNode: LGCSyntaxNode {
        return parameters.map { $0 }.last?.lastNode ?? node
    }

    public var uuid: UUID {
        return id
    }

    public var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCFunctionCallArgument {
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCFunctionCallArgument {
        return LGCFunctionCallArgument(
            id: UUID(),
            label: label,
            expression: expression.replace(id: id, with: syntaxNode)
        )
    }

    // Implementation needed, since we don't conform to SyntaxNodeProtocol
    func find(id: UUID) -> LGCSyntaxNode? {
        return expression.find(id: id)
    }

    func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        return expression.pathTo(id: id)
    }

    var lastNode: LGCSyntaxNode {
        return expression.lastNode
    }

    var uuid: UUID {
        return id
    }

    var movementAfterInsertion: Movement {
        return .next
    }
}

extension LGCSyntaxNode {
    public var contents: SyntaxNodeProtocol {
        switch self {
        case .statement(let value):
            return value
        case .declaration(let value):
            return value
        case .expression(let value):
            return value
        case .identifier(let value):
            return value
        case .pattern(let value):
            return value
        case .binaryOperator(let value):
            return value
        case .program(let value):
            return value
        case .functionParameter(let value):
            return value
        case .typeAnnotation(let value):
            return value
        case .functionParameterDefaultValue(let value):
            return value
        case .literal(let value):
            return value
        case .topLevelParameters(let value):
            return value
        case .enumerationCase(let value):
            return value
        }
    }

    public func delete(id: UUID) -> LGCSyntaxNode {
        return contents.delete(id: id).node
    }

    public func swap(sourceId: UUID, targetId: UUID) -> LGCSyntaxNode {
        return contents.swap(sourceId: sourceId, targetId: targetId).node
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCSyntaxNode {
        return contents.replace(id: id, with: syntaxNode).node
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        return contents.find(id: id)
    }

    public func pathTo(id: UUID) -> [LGCSyntaxNode]? {
        return contents.pathTo(id: id)
    }

    public var lastNode: LGCSyntaxNode {
        return contents.lastNode
    }

    public var uuid: UUID {
        return contents.uuid
    }

    public var movementAfterInsertion: Movement {
        return contents.movementAfterInsertion
    }

    public var nodeTypeDescription: String {
        return contents.nodeTypeDescription
    }
}
