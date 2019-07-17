//
//  SwiftNativeTypes.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public enum Movement {
    case none, next, node(UUID)
}

public protocol SyntaxNodeProtocol {
    var uuid: UUID { get }
    var node: LGCSyntaxNode { get }
    var nodeTypeDescription: String { get }
    var subnodes: [LGCSyntaxNode] { get }
    var children: [LGCSyntaxNode] { get }
    var isSelectable: Bool { get }

    func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool
    func acceptsNode(rootNode: LGCSyntaxNode, childNode: LGCSyntaxNode) -> Bool
    func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement

    func find(id: UUID) -> LGCSyntaxNode?
    func pathTo(id: UUID, includeTopLevel: Bool) -> [LGCSyntaxNode]?
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> Self
    func delete(id: UUID) -> Self
    func insert(childNode: LGCSyntaxNode, atIndex: Int) -> Self
    func copy(deep: Bool) -> Self

    func comment(within root: LGCSyntaxNode) -> String?
    func documentation(within root: LGCSyntaxNode, for prefix: String) -> NSView
    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem]
}

public extension SyntaxNodeProtocol {
    var children: [LGCSyntaxNode] {
        return []
    }

    func comment(within root: LGCSyntaxNode) -> String? {
        return nil
    }

    var isSelectable: Bool { return true }

    func documentation(within root: LGCSyntaxNode, for prefix: String) -> NSView {
        return NSView()
    }

    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
        return []
    }

    func find(id: UUID) -> LGCSyntaxNode? {
        return pathTo(id: id, includeTopLevel: true)?.last
    }

    func pathTo(id: UUID, includeTopLevel: Bool) -> [LGCSyntaxNode]? {
        let shouldInclude = isSelectable || includeTopLevel

        if id == uuid && shouldInclude { return [node] }

        for subnode in subnodes {
            if let found = subnode.pathTo(id: id) {
                return shouldInclude ? [node] + found : found
            }
        }

        return nil
    }

    func delete(id: UUID) -> Self {
        return self
    }

    func insert(childNode: LGCSyntaxNode, atIndex: Int) -> Self {
        return self
    }

    func acceptsNode(rootNode: LGCSyntaxNode, childNode: LGCSyntaxNode) -> Bool {
        return false
    }
}

// Utility, not part of the protocol
extension SyntaxNodeProtocol {
    func parentOf(target id: UUID, includeTopLevel: Bool) -> LGCSyntaxNode? {
        return pathTo(id: id, includeTopLevel: includeTopLevel)?.dropLast().last
    }
}

extension LGCIdentifier: SyntaxNodeProtocol {
    public func copy(deep: Bool) -> LGCIdentifier {
        return .init(id: UUID(), string: string, isPlaceholder: isPlaceholder)
    }

    public var subnodes: [LGCSyntaxNode] {
        return []
    }

    public var nodeTypeDescription: String {
        return "Identifier"
    }

    public var node: LGCSyntaxNode {
        return .identifier(self)
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCIdentifier {
        switch syntaxNode {
        case .identifier(let newNode) where id == uuid:
            return newNode
        default:
            return self
        }
    }

    public var uuid: UUID { return id }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }
}

extension LGCPattern: SyntaxNodeProtocol {
    public func copy(deep: Bool) -> LGCPattern {
        return .init(id: UUID(), name: name)
    }

    public var subnodes: [LGCSyntaxNode] {
        return []
    }

    public var nodeTypeDescription: String {
        return "Pattern"
    }

    public var node: LGCSyntaxNode {
        return .pattern(self)
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCPattern {
        switch syntaxNode {
        case .pattern(let newNode) where id == uuid:
            return newNode
        default:
            return self
        }
    }
    
    public var uuid: UUID { return id }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }

    public func comment(within root: LGCSyntaxNode) -> String? {
        guard let path = root.pathTo(id: uuid), let parent = path.dropLast().last else { return nil }

        return parent.comment(within: root)
    }
}

extension LGCTypeAnnotation: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .typeIdentifier(let value):
            return [value.identifier.node] + value.genericArguments.map { $0.node }
        case .functionType(let value):
            return [value.returnType.node] + value.argumentTypes.map { $0.node }
        case .placeholder:
            return []
        }
    }

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
                id: value.id,
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
                    id: value.id,
                    identifier: value.identifier.replace(id: id, with: syntaxNode),
                    genericArguments: value.genericArguments.replace(id: id, with: syntaxNode)
                )
            case .functionType(let value):
                return LGCTypeAnnotation.functionType(
                    id: value.id,
                    returnType: value.returnType.replace(id: id, with: syntaxNode),
                    argumentTypes: value.argumentTypes.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            case .placeholder(let value):
                return LGCTypeAnnotation.placeholder(id: value)
            }
        }
    }

    public func copy(deep: Bool) -> LGCTypeAnnotation {
        switch self {
        case .typeIdentifier(let value):
            return LGCTypeAnnotation.typeIdentifier(
                id: value.id,
                identifier: value.identifier.copy(deep: deep),
                genericArguments: value.genericArguments.copy(deep: deep)
            )
        case .functionType(let value):
            return LGCTypeAnnotation.functionType(
                id: value.id,
                returnType: value.returnType.copy(deep: deep),
                argumentTypes: value.argumentTypes.copy(deep: deep).normalizedPlaceholders
            )
        case .placeholder(let value):
            return LGCTypeAnnotation.placeholder(id: value)
        }
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

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        switch self {
        case .typeIdentifier:
            return .next
        case .functionType:
            return .none
        case .placeholder:
            return .next
        }
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }
}

extension LGCLiteral: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .array(let value):
            return value.value.map { $0.node }
        case .none, .boolean, .color, .number, .string:
            return []
        }
    }

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
                    id: value.id,
                    value: value.value
                )
            case .number(let value):
                return LGCLiteral.number(
                    id: value.id,
                    value: value.value
                )
            case .string(let value):
                return LGCLiteral.string(
                    id: value.id,
                    value: value.value
                )
            case .color(let value):
                return LGCLiteral.color(
                    id: value.id,
                    value: value.value
                )
            case .array(let value):
                return LGCLiteral.array(
                    id: value.id,
                    value: value.value.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            case .none(let value):
                return LGCLiteral.none(id: value)
            }
        }
    }

    public func copy(deep: Bool) -> LGCLiteral {
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
        case .array(let value):
            return LGCLiteral.array(
                id: UUID(),
                value: value.value.copy(deep: deep).normalizedPlaceholders
            )
        case .none:
            return LGCLiteral.none(id: UUID())
        }
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
        case .array(let value):
            return value.id
        case .none(let value):
            return value
        }
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }
}

extension LGCFunctionParameterDefaultValue: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .none:
            return []
        case .value(let value):
            return [value.expression.node]
        }
    }

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
            case .none(let value):
                return LGCFunctionParameterDefaultValue.none(id: value)
            case .value(let value):
                return LGCFunctionParameterDefaultValue.value(
                    id: value.id,
                    expression: value.expression.replace(id: id, with: syntaxNode)
                )
            }
        }
    }

    public func copy(deep: Bool) -> LGCFunctionParameterDefaultValue {
        switch self {
        case .none:
            return LGCFunctionParameterDefaultValue.none(id: UUID())
        case .value(let value):
            return LGCFunctionParameterDefaultValue.value(
                id: value.id,
                expression: value.expression.copy(deep: deep)
            )
        }
    }

    public var uuid: UUID {
        switch self {
        case .none(let value):
            return value
        case .value(let value):
            return value.id
        }
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }
}

extension LGCFunctionParameter: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .placeholder:
            return []
        case .parameter(let value):
            return [value.localName.node, value.annotation.node, value.defaultValue.node]
        }
    }

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
                id: value.id,
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
            case .placeholder(let value):
                return LGCFunctionParameter.placeholder(id: value)
            case .parameter(let value):
                return LGCFunctionParameter.parameter(
                    id: value.id,
                    externalName: value.externalName,
                    localName: value.localName.replace(id: id, with: syntaxNode),
                    annotation: value.annotation.replace(id: id, with: syntaxNode),
                    defaultValue: value.defaultValue.replace(id: id, with: syntaxNode)
                )
            }
        }
    }

    public func copy(deep: Bool) -> LGCFunctionParameter {
        switch self {
        case .placeholder:
            return LGCFunctionParameter.placeholder(id: UUID())
        case .parameter(let value):
            return LGCFunctionParameter.parameter(
                id: UUID(),
                externalName: value.externalName,
                localName: value.localName.copy(deep: deep),
                annotation: value.annotation.copy(deep: deep),
                defaultValue: value.defaultValue.copy(deep: deep)
            )
        }
    }

    public var uuid: UUID {
        switch self {
        case .parameter(let value):
            return value.id
        case .placeholder(let value):
            return value
        }
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return true
    }
}

extension LGCGenericParameter: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .placeholder:
            return []
        case .parameter(let value):
            return [value.name.node]
        }
    }

    public var nodeTypeDescription: String {
        return "Generic Parameter"
    }

    public var node: LGCSyntaxNode {
        return .genericParameter(self)
    }

    public func delete(id: UUID) -> LGCGenericParameter {
        switch self {
        case .placeholder:
            return self
        case .parameter(let value):
            return .parameter(
                id: value.id,
                name: value.name.delete(id: id)
            )
        }
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCGenericParameter {
        switch syntaxNode {
        case .genericParameter(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .placeholder(let value):
                return .placeholder(id: value)
            case .parameter(let value):
                return .parameter(
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode)
                )
            }
        }
    }

    public func copy(deep: Bool) -> LGCGenericParameter {
        switch self {
        case .placeholder:
            return .placeholder(id: UUID())
        case .parameter(let value):
            return .parameter(
                id: UUID(),
                name: value.name.copy(deep: deep)
            )
        }
    }

    public var uuid: UUID {
        switch self {
        case .parameter(let value):
            return value.id
        case .placeholder(let value):
            return value
        }
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }
}

extension LGCEnumerationCase: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .placeholder:
            return []
        case .enumerationCase(let value):
            return [value.name.node, value.comment?.node].compactMap { $0 } + value.associatedValueTypes.map { $0.node }
        }
    }

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
                id: value.id,
                name: value.name.delete(id: id),
                associatedValueTypes: LGCList(updated),
                comment: value.comment?.delete(id: id)
            )
        }
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCEnumerationCase {
        switch syntaxNode {
        case .enumerationCase(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .placeholder(let value):
                return LGCEnumerationCase.placeholder(id: value)
            case .enumerationCase(let value):
                return LGCEnumerationCase.enumerationCase(
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode),
                    associatedValueTypes: value.associatedValueTypes.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    comment: value.comment?.replace(id: id, with: syntaxNode)
                )
            }
        }
    }

    public func copy(deep: Bool) -> LGCEnumerationCase {
        switch self {
        case .placeholder:
            return LGCEnumerationCase.placeholder(id: UUID())
        case .enumerationCase(let value):
            return LGCEnumerationCase.enumerationCase(
                id: UUID(),
                name: value.name.copy(deep: deep),
                associatedValueTypes: value.associatedValueTypes.copy(deep: deep).normalizedPlaceholders,
                comment: value.comment?.copy(deep: deep)
            )
        }
    }

    public var uuid: UUID {
        switch self {
        case .enumerationCase(let value):
            return value.id
        case .placeholder(let value):
            return value
        }
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return true
    }

    public func comment(within root: LGCSyntaxNode) -> String? {
        switch self {
        case .enumerationCase(let value):
            let comment = value.comment?.string

            switch root.contents.parentOf(target: uuid, includeTopLevel: false) {
            case .some(.declaration(.enumeration(let enumValue))):
                let base = "This is a case of the enumeration: `\(enumValue.name.name)`"
                if let comment = comment {
                    return "\(comment)\n\n---\n\n\(base)"
                } else {
                    return base
                }
            default:
                return comment
            }
        case .placeholder:
            return nil
        }
    }
}

extension LGCBinaryOperator: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        return []
    }

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
            case .isEqualTo(let value):
                return LGCBinaryOperator.isEqualTo(id: value)
            case .isNotEqualTo(let value):
                return LGCBinaryOperator.isNotEqualTo(id: value)
            case .isLessThan(let value):
                return LGCBinaryOperator.isLessThan(id: value)
            case .isGreaterThan(let value):
                return LGCBinaryOperator.isGreaterThan(id: value)
            case .isLessThanOrEqualTo(let value):
                return LGCBinaryOperator.isLessThanOrEqualTo(id: value)
            case .isGreaterThanOrEqualTo(let value):
                return LGCBinaryOperator.isGreaterThanOrEqualTo(id: value)
            case .setEqualTo(let value):
                return LGCBinaryOperator.setEqualTo(id: value)
            }
        }
    }

    public func copy(deep: Bool) -> LGCBinaryOperator {
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

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }
}

extension LGCExpression: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .binaryExpression(let value):
            return [value.left.node, value.op.node, value.right.node]
        case .identifierExpression(let value):
            return [value.identifier.node]
        case .functionCallExpression(let value):
            return [value.expression.node] + value.arguments.map { $0.expression.node }
        case .literalExpression(let value):
            return [value.literal.node]
        case .memberExpression(let value):
            return [value.expression.node, value.memberName.node]
        case .placeholder:
            return []
        }
    }

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
                id: value.id
            )
        case (_, .identifierExpression(let value)):
            return .identifierExpression(
                id: value.id,
                identifier: value.identifier.replace(id: id, with: syntaxNode)
            )
        case (_, .functionCallExpression(let value)):
            return .functionCallExpression(
                id: value.id,
                expression: value.expression.replace(id: id, with: syntaxNode),
                arguments: value.arguments.replace(id: id, with: syntaxNode)
            )
        case (_, .literalExpression(let value)):
            return .literalExpression(
                id: value.id,
                literal: value.literal.replace(id: id, with: syntaxNode)
            )
        case (_, .memberExpression(let value)):
            return .memberExpression(
                id: value.id,
                expression: value.expression.replace(id: id, with: syntaxNode),
                memberName: value.memberName.replace(id: id, with: syntaxNode)
            )
        case (_, .placeholder):
            return .makePlaceholder()
        }
    }

    public func copy(deep: Bool) -> LGCExpression {
        switch self {
        case .binaryExpression(let value):
            return .binaryExpression(
                left: value.left.copy(deep: deep),
                right: value.right.copy(deep: deep),
                op: value.op.copy(deep: deep),
                id: value.id
            )
        case .identifierExpression(let value):
            return .identifierExpression(
                id: value.id,
                identifier: value.identifier.copy(deep: deep)
            )
        case .functionCallExpression(let value):
            return .functionCallExpression(
                id: value.id,
                expression: value.expression.copy(deep: deep),
                arguments: value.arguments.copy(deep: deep)
            )
        case .literalExpression(let value):
            return .literalExpression(
                id: value.id,
                literal: value.literal.copy(deep: deep)
            )
        case .memberExpression(let value):
            return .memberExpression(
                id: value.id,
                expression: value.expression.copy(deep: deep),
                memberName: value.memberName.copy(deep: deep)
            )
        case .placeholder:
            return .makePlaceholder()
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
        case .placeholder(let value):
            return value
        }
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
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
        case .placeholder:
            return .next
        }
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }
}

extension LGCStatement: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .branch(let value):
            return [value.condition.node] + value.block.map { $0.node }
        case .declaration(let value):
            return [value.content.node]
        case .loop(let value):
            return [value.expression.node, value.pattern.node]
        case .expressionStatement(let value):
            return [value.expression.node]
        case .placeholder:
            return []
        }
    }

    public var nodeTypeDescription: String {
        return "Statement"
    }

    public var node: LGCSyntaxNode {
        return .statement(self)
    }

    public func delete(id: UUID) -> LGCStatement {
        switch self {
        case .declaration(let value):
            return .declaration(id: value.id, content: value.content.delete(id: id))
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
                    id: value.id,
                    condition: value.condition.replace(id: id, with: syntaxNode),
                    block: value.block.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            case .declaration(let value):
                return LGCStatement.declaration(
                    id: value.id,
                    content: value.content.replace(id: id, with: syntaxNode)
                )
            case .loop(let value):
                return LGCStatement.loop(
                    pattern: value.pattern.replace(id: id, with: syntaxNode),
                    expression: value.expression.replace(id: id, with: syntaxNode),
                    block: LGCList<LGCStatement>.empty,
                    id: value.id
                )
            case .expressionStatement(let value):
                return LGCStatement.expressionStatement(
                    id: value.id,
                    expression: value.expression.replace(id: id, with: syntaxNode)
                )
            case .placeholder(_):
                return self
            }
        }
    }

    public func copy(deep: Bool) -> LGCStatement {
        switch self {
        case .branch(let value):
            return .branch(
                id: UUID(),
                condition: value.condition.copy(deep: deep),
                block: value.block.copy(deep: deep).normalizedPlaceholders
            )
        case .declaration(let value):
            return LGCStatement.declaration(
                id: UUID(),
                content: value.content.copy(deep: deep)
            )
        case .loop(let value):
            return LGCStatement.loop(
                pattern: value.pattern.copy(deep: deep),
                expression: value.expression.copy(deep: deep),
                block: LGCList<LGCStatement>.empty,
                id: UUID()
            )
        case .expressionStatement(let value):
            return LGCStatement.expressionStatement(
                id: UUID(),
                expression: value.expression.copy(deep: deep)
            )
        case .placeholder:
            return .makePlaceholder()
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
        case .placeholder(let value):
            return value
        }
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return true
    }
}

extension LGCDeclaration: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .variable(let value):
            return [value.name.node, value.comment?.node, value.annotation?.node, value.initializer?.node].compactMap { $0 }
        case .function(let value):
            return [value.name.node, value.comment?.node].compactMap { $0 } + value.genericParameters.map { $0.node } + [value.returnType.node] +
                value.parameters.map { $0.node } + value.block.map { $0.node }
        case .enumeration(let value):
            return [value.name.node, value.comment?.node].compactMap { $0 } + value.genericParameters.map { $0.node } + value.cases.map { $0.node }
        case .record(let value):
            return [value.name.node, value.comment?.node].compactMap { $0 } + value.genericParameters.map { $0.node } + value.declarations.map { $0.node }
        case .namespace(let value):
            return [value.name.node] + value.declarations.map { $0.node }
        case .placeholder:
            return []
        case .importDeclaration(let value):
            return [value.name.node]
        }
    }

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
                id: value.id,
                name: value.name.delete(id: id),
                genericParameters: value.genericParameters.delete(id: id),
                cases: LGCList(value.cases.filter({
                    switch $0 {
                    case .placeholder:
                        return true
                    case .enumerationCase(let value):
                        return value.id != id
                    }
                }).map { $0.delete(id: id) }),
                comment: value.comment?.delete(id: id)
            )
        case .record(let value):
            return .record(
                id: value.id,
                name: value.name.delete(id: id),
                genericParameters: value.genericParameters.delete(id: id),
                declarations: LGCList(value.declarations.filter({
                    switch $0 {
                    case .placeholder:
                        return true
                    default:
                        return $0.uuid != id
                    }
                }).map { $0.delete(id: id) }),
                comment: value.comment?.delete(id: id)
            )
        case .namespace(let value):
            return .namespace(
                id: value.id,
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
                id: value.id,
                name: value.name.delete(id: id),
                returnType: value.returnType.delete(id: id),
                genericParameters: value.genericParameters.delete(id: id),
                parameters: value.parameters.delete(id: id),
                block: value.block.delete(id: id),
                comment: value.comment?.delete(id: id)
            )
        case .importDeclaration(let value):
            return .importDeclaration(id: value.id, name: value.name.delete(id: id))
        case .placeholder(let value):
            return .placeholder(id: value)
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
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode),
                    annotation: value.annotation?.replace(id: id, with: syntaxNode),
                    initializer: value.initializer?.replace(id: id, with: syntaxNode),
                    comment: value.comment?.replace(id: id, with: syntaxNode)
                )
            case .function(let value):
                return LGCDeclaration.function(
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode),
                    returnType: value.returnType.replace(id: id, with: syntaxNode),
                    genericParameters: value.genericParameters.replace(id: id, with: syntaxNode),
                    parameters: value.parameters.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    block: value.block.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    comment: value.comment?.replace(id: id, with: syntaxNode)
                )
            case .enumeration(let value):
                return LGCDeclaration.enumeration(
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode),
                    genericParameters: value.genericParameters.replace(id: id, with: syntaxNode),
                    cases: value.cases.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    comment: value.comment?.replace(id: id, with: syntaxNode)
                )
            case .record(let value):
                return LGCDeclaration.record(
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode),
                    genericParameters: value.genericParameters.replace(id: id, with: syntaxNode),
                    declarations: value.declarations.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    comment: value.comment?.replace(id: id, with: syntaxNode)
                )
            case .namespace(let value):
                return LGCDeclaration.namespace(
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode),
                    declarations: value.declarations.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
                )
            case .importDeclaration(let value):
                return .importDeclaration(
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode)
                )
            case .placeholder(let value):
                return LGCDeclaration.placeholder(id: value)
            }
        }
    }

    public func copy(deep: Bool) -> LGCDeclaration {
        switch self {
        case .variable(let value):
            return LGCDeclaration.variable(
                id: UUID(),
                name: value.name.copy(deep: deep),
                annotation: value.annotation?.copy(deep: deep),
                initializer: value.initializer?.copy(deep: deep),
                comment: value.comment?.copy(deep: deep)
            )
        case .function(let value):
            return LGCDeclaration.function(
                id: UUID(),
                name: value.name.copy(deep: deep),
                returnType: value.returnType.copy(deep: deep),
                genericParameters: value.genericParameters.copy(deep: deep),
                parameters: value.parameters.copy(deep: deep).normalizedPlaceholders,
                block: value.block.copy(deep: deep).normalizedPlaceholders,
                comment: value.comment?.copy(deep: deep)
            )
        case .enumeration(let value):
            return LGCDeclaration.enumeration(
                id: UUID(),
                name: value.name.copy(deep: deep),
                genericParameters: value.genericParameters.copy(deep: deep),
                cases: value.cases.copy(deep: deep).normalizedPlaceholders,
                comment: value.comment?.copy(deep: deep)
            )
        case .record(let value):
            return LGCDeclaration.record(
                id: UUID(),
                name: value.name.copy(deep: deep),
                genericParameters: value.genericParameters.copy(deep: deep),
                declarations: value.declarations.copy(deep: deep).normalizedPlaceholders,
                comment: value.comment?.copy(deep: deep)
            )
        case .namespace(let value):
            return LGCDeclaration.namespace(
                id: UUID(),
                name: value.name.copy(deep: deep),
                declarations: value.declarations.copy(deep: deep).normalizedPlaceholders
            )
        case .importDeclaration(let value):
            return .importDeclaration(
                id: UUID(),
                name: value.name.copy(deep: deep)
            )
        case .placeholder:
            return .makePlaceholder()
        }
    }

    public func insert(childNode: LGCSyntaxNode, atIndex: Int) -> LGCDeclaration {
        switch self {
        case .namespace(let value):
            guard case .declaration(let child) = childNode else { return self }

            var updated = value.declarations.normalizedPlaceholders.map { $0 }
            updated.insert(child, at: atIndex)

            return .namespace(id: value.id, name: value.name, declarations: .init(updated))
        default:
            return self
        }
    }

    public var children: [LGCSyntaxNode] {
        switch self {
        case .namespace(let value):
            return value.declarations.map { $0.node }
        default:
            return []
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
        case .record(let value):
            return value.id
        case .namespace(let value):
            return value.id
        case .importDeclaration(let value):
            return value.id
        case .placeholder(let value):
            return value
        }
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return true
    }

    public func acceptsNode(rootNode: LGCSyntaxNode, childNode: LGCSyntaxNode) -> Bool {
        switch (self, childNode) {
        case (.namespace, .declaration):
            return true
        default:
            return false
        }
    }

    public func comment(within root: LGCSyntaxNode) -> String? {
        switch self {
        case .variable(let value):
            return value.comment?.string
        case .enumeration(let value):
            return value.comment?.string
        case .record(let value):
            return value.comment?.string
        default:
            break
        }
        return nil
    }
}

extension LGCProgram: SyntaxNodeProtocol {
    public var isSelectable: Bool { return false }

    public var subnodes: [LGCSyntaxNode] {
        return block.map { $0.node }
    }

    public var children: [LGCSyntaxNode] {
        return block.map { $0.node }
    }

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
            id: self.uuid,
            block: LGCList(updated)
        )
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCProgram {
        switch syntaxNode {
        case .program(let newNode) where id == uuid:
            return newNode
        default:
            return LGCProgram(
                id: self.uuid,
                block: block.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
            )
        }
    }

    public func copy(deep: Bool) -> LGCProgram {
        return LGCProgram(
            id: UUID(),
            block: block.copy(deep: deep).normalizedPlaceholders
        )
    }

    public func insert(childNode: LGCSyntaxNode, atIndex: Int) -> LGCProgram {
        guard case .statement(let child) = childNode else { return self }

        var updated = block.normalizedPlaceholders.map { $0 }
        updated.insert(child, at: atIndex)

        return LGCProgram(
            id: self.uuid,
            block: LGCList(updated)
        )
    }

    public var uuid: UUID {
        return id
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }

    public func acceptsNode(rootNode: LGCSyntaxNode, childNode: LGCSyntaxNode) -> Bool {
        switch childNode {
        case .statement:
            return true
        default:
            return false
        }
    }
}

extension LGCTopLevelParameters: SyntaxNodeProtocol {
    public var isSelectable: Bool { return false }

    public var subnodes: [LGCSyntaxNode] {
        return parameters.map { $0.node }
    }

    public var children: [LGCSyntaxNode] {
        return parameters.map { $0.node }
    }

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
            id: self.uuid,
            parameters: LGCList(updated)
        )
    }

    public func insert(childNode: LGCSyntaxNode, atIndex: Int) -> LGCTopLevelParameters {
        guard case .functionParameter(let child) = childNode else { return self }

        var updated = parameters.normalizedPlaceholders.map { $0 }
        updated.insert(child, at: atIndex)

        return LGCTopLevelParameters(
            id: self.uuid,
            parameters: LGCList(updated)
        )
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCTopLevelParameters {
        switch syntaxNode {
        case .topLevelParameters(let newNode) where id == uuid:
            return newNode
        default:
            return LGCTopLevelParameters(
                id: self.uuid,
                parameters: parameters.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
            )
        }
    }

    public func copy(deep: Bool) -> LGCTopLevelParameters {
        return LGCTopLevelParameters(
            id: UUID(),
            parameters: parameters.copy(deep: deep).normalizedPlaceholders
        )
    }

    public var uuid: UUID {
        return id
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }

    public func acceptsNode(rootNode: LGCSyntaxNode, childNode: LGCSyntaxNode) -> Bool {
        switch childNode {
        case .functionParameter:
            return true
        default:
            return false
        }
    }
}

extension LGCTopLevelDeclarations: SyntaxNodeProtocol {
    public var isSelectable: Bool { return false }

    public var subnodes: [LGCSyntaxNode] {
        return declarations.map { $0.node }
    }

    public var children: [LGCSyntaxNode] {
        return declarations.map { $0.node }
    }

    public var nodeTypeDescription: String {
        return "Top-level Declarations"
    }

    public var node: LGCSyntaxNode {
        return .topLevelDeclarations(self)
    }

    public func delete(id: UUID) -> LGCTopLevelDeclarations {
        let updated = declarations.filter { param in
            switch param {
            case .placeholder:
                return true
            default:
                return param.uuid != id
            }
            }.map { $0.delete(id: id) }

        return LGCTopLevelDeclarations(
            id: self.uuid,
            declarations: LGCList(updated)
        )
    }

    public func insert(childNode: LGCSyntaxNode, atIndex: Int) -> LGCTopLevelDeclarations {
        guard case .declaration(let child) = childNode else { return self }

        var updated = declarations.normalizedPlaceholders.map { $0 }
        updated.insert(child, at: atIndex)

        return LGCTopLevelDeclarations(
            id: uuid,
            declarations: LGCList(updated)
        )
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCTopLevelDeclarations {
        switch syntaxNode {
        case .topLevelDeclarations(let newNode) where id == uuid:
            return newNode
        default:
            return LGCTopLevelDeclarations(
                id: uuid,
                declarations: declarations.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
            )
        }
    }

    public func copy(deep: Bool) -> LGCTopLevelDeclarations {
        return LGCTopLevelDeclarations(
            id: UUID(),
            declarations: declarations.copy(deep: deep).normalizedPlaceholders
        )
    }

    public var uuid: UUID {
        return id
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }

    public func acceptsNode(rootNode: LGCSyntaxNode, childNode: LGCSyntaxNode) -> Bool {
        switch childNode {
        case .declaration:
            return true
        default:
            return false
        }
    }
}

extension LGCFunctionCallArgument {
    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCFunctionCallArgument {
        return LGCFunctionCallArgument(
            id: self.uuid,
            label: label,
            expression: expression.replace(id: id, with: syntaxNode)
        )
    }

    func copy(deep: Bool) -> LGCFunctionCallArgument {
        return LGCFunctionCallArgument(
            id: UUID(),
            label: label,
            expression: expression.copy(deep: deep)
        )
    }

    // Implementation needed, since we don't conform to SyntaxNodeProtocol
    public func find(id: UUID) -> LGCSyntaxNode? {
        return expression.find(id: id)
    }

    public func pathTo(id: UUID, includeTopLevel: Bool) -> [LGCSyntaxNode]? {
        return expression.pathTo(id: id, includeTopLevel: includeTopLevel)
    }

    public var uuid: UUID {
        return id
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }
}

extension LGCComment: SyntaxNodeProtocol {
    public var uuid: UUID {
        return id
    }

    public var node: LGCSyntaxNode {
        return .comment(self)
    }

    public var nodeTypeDescription: String {
        return "Comment"
    }

    public var subnodes: [LGCSyntaxNode] {
        return []
    }

    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return .next
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCComment {
        switch syntaxNode {
        case .comment(let newNode) where id == uuid:
            return newNode
        default:
            return self
        }
    }

    public func copy(deep: Bool) -> LGCComment {
        return .init(id: UUID(), string: string)
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
        case .genericParameter(let value):
            return value
        case .topLevelDeclarations(let value):
            return value
        case .comment(let value):
            return value
        }
    }

    public func delete(id: UUID) -> LGCSyntaxNode {
        return contents.delete(id: id).node
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCSyntaxNode {
        return contents.replace(id: id, with: syntaxNode).node
    }

    public func copy(deep: Bool = true) -> LGCSyntaxNode {
        return contents.copy(deep: deep).node
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        return contents.find(id: id)
    }

    public func pathTo(id: UUID, includeTopLevel: Bool = false) -> [LGCSyntaxNode]? {
        return contents.pathTo(id: id, includeTopLevel: includeTopLevel)
    }

    public var subnodes: [LGCSyntaxNode] {
        return contents.subnodes
    }

    public var uuid: UUID {
        return contents.uuid
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        return contents.movementAfterInsertion(rootNode: rootNode)
    }

    public var nodeTypeDescription: String {
        return contents.nodeTypeDescription
    }

    public func isDraggable(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }

    func comment(within root: LGCSyntaxNode) -> String? {
        return contents.comment(within: root)
    }
}
