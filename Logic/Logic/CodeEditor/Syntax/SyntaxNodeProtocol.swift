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
    var isSelectable: Bool { get }

    func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool
    func acceptsNode(rootNode: LGCSyntaxNode, childNode: LGCSyntaxNode) -> Bool
    func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement

    func find(id: UUID) -> LGCSyntaxNode?
    func pathTo(id: UUID, includeTopLevel: Bool) -> [LGCSyntaxNode]?
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> Self
    func delete(id: UUID) -> Self?
    func insert(childNode: LGCSyntaxNode, atIndex: Int) -> Self
    func copy(deep: Bool) -> Self
    func childrenInSameCollection(as node: LGCSyntaxNode) -> [LGCSyntaxNode]

    func comment(within root: LGCSyntaxNode) -> String?
    func documentation(within root: LGCSyntaxNode, for prefix: String, formattingOptions: LogicFormattingOptions) -> NSView
    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem]
}

public extension SyntaxNodeProtocol {
    func childrenInSameCollection(as node: LGCSyntaxNode) -> [LGCSyntaxNode] {
        return []
    }

    func comment(within root: LGCSyntaxNode) -> String? {
        return nil
    }

    var isSelectable: Bool { return true }

    func documentation(within root: LGCSyntaxNode, for prefix: String, formattingOptions: LogicFormattingOptions) -> NSView {
        return NSView()
    }

    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
        return []
    }

    func find(id: UUID) -> LGCSyntaxNode? {
        if id == uuid { return node }

        for subnode in subnodes {
            if let found = subnode.find(id: id) {
                return found
            }
        }

        return nil
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

    func delete(id: UUID) -> Self? {
        return uuid == id ? nil : self
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
    public func parentOf(target id: UUID, includeTopLevel: Bool) -> LGCSyntaxNode? {
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

    public func delete(id: UUID) -> LGCTypeAnnotation? {
        if id == uuid { return nil }

        switch self {
        case .typeIdentifier, .placeholder:
            return self
        case .functionType(let value):
            let updatedArguments = value.argumentTypes.compactMap { $0.delete(id: id) }

            return LGCTypeAnnotation.functionType(
                id: value.id,
                returnType: value.returnType.delete(id: id) ?? LGCTypeAnnotation.makePlaceholder(),
                argumentTypes: LGCList(updatedArguments).normalizedPlaceholders
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

    public func childrenInSameCollection(as node: LGCSyntaxNode) -> [LGCSyntaxNode] {
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

    public func delete(id: UUID) -> LGCLiteral? {
        if id == uuid { return nil }

        switch self {
        case .array(let value):
            return .array(
                id: value.id,
                value: LGCList(value.value.compactMap { $0.delete(id: id) }).normalizedPlaceholders
            )
        case .boolean, .number, .string, .color, .none:
            return self
        }
    }

    public func insert(childNode: LGCSyntaxNode, atIndex: Int) -> LGCLiteral {
        guard case .expression(let child) = childNode,
            case .array(let value) = self else { return self }

        var updated = value.value.normalizedPlaceholders.map { $0 }
        updated.insert(child, at: atIndex)

        return .array(id: uuid, value: .init(updated))
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

    public func acceptsNode(rootNode: LGCSyntaxNode, childNode: LGCSyntaxNode) -> Bool {
        switch (self, childNode) {
        case (.array, .expression):
            return true
        default:
            return false
        }
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
            return [value.localName.node, value.annotation.node, value.defaultValue.node, value.comment?.node].compactMap { $0 }
        }
    }

    public var nodeTypeDescription: String {
        return "Parameter"
    }

    public var node: LGCSyntaxNode {
        return .functionParameter(self)
    }

    public func delete(id: UUID) -> LGCFunctionParameter? {
        if id == uuid { return nil }

        switch self {
        case .placeholder:
            return self
        case .parameter(let value):
            guard let name = value.localName.delete(id: id) else { return nil }

            return LGCFunctionParameter.parameter(
                id: value.id,
                localName: name,
                annotation: value.annotation.delete(id: id) ?? LGCTypeAnnotation.makePlaceholder(),
                defaultValue: value.defaultValue.delete(id: id) ?? LGCFunctionParameterDefaultValue.none(id: UUID()),
                comment: value.comment?.delete(id: id)
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
                    localName: value.localName.replace(id: id, with: syntaxNode),
                    annotation: value.annotation.replace(id: id, with: syntaxNode),
                    defaultValue: value.defaultValue.replace(id: id, with: syntaxNode),
                    comment: value.comment?.replace(id: id, with: syntaxNode)
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
                localName: value.localName.copy(deep: deep),
                annotation: value.annotation.copy(deep: deep),
                defaultValue: value.defaultValue.copy(deep: deep),
                comment: value.comment?.copy(deep: deep)
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

    public func comment(within root: LGCSyntaxNode) -> String? {
        switch self {
        case .parameter(let value):
            return value.comment?.string
        default:
            return nil
        }
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

    public func delete(id: UUID) -> LGCGenericParameter? {
        if id == uuid { return nil }

        switch self {
        case .placeholder:
            return self
        case .parameter(let value):
            guard let name = value.name.delete(id: id) else { return nil }

            return .parameter(
                id: value.id,
                name: name
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

    public func delete(id: UUID) -> LGCEnumerationCase? {
        if id == uuid { return nil }

        switch self {
        case .placeholder:
            return self
        case .enumerationCase(let value):
            let updated = value.associatedValueTypes.compactMap { $0.delete(id: id) }

            guard let name = value.name.delete(id: id) else { return nil }

            return LGCEnumerationCase.enumerationCase(
                id: value.id,
                name: name,
                associatedValueTypes: LGCList(updated).normalizedPlaceholders,
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

extension LGCExpression: SyntaxNodeProtocol {
    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .assignmentExpression(let value):
            return [value.left.node, value.right.node]
        case .identifierExpression(let value):
            return [value.identifier.node]
        case .functionCallExpression(let value):
            return [value.expression.node] + value.arguments.map { $0.node }
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
        case (_, .assignmentExpression(let value)):
            return .assignmentExpression(
                left: value.left.replace(id: id, with: syntaxNode),
                right: value.right.replace(id: id, with: syntaxNode),
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
                arguments: value.arguments.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true)
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
        case .assignmentExpression(let value):
            return .assignmentExpression(
                left: value.left.copy(deep: deep),
                right: value.right.copy(deep: deep),
                id: UUID()
            )
        case .identifierExpression(let value):
            return .identifierExpression(
                id: UUID(),
                identifier: value.identifier.copy(deep: deep)
            )
        case .functionCallExpression(let value):
            return .functionCallExpression(
                id: UUID(),
                expression: value.expression.copy(deep: deep),
                arguments: value.arguments.copy(deep: deep)
            )
        case .literalExpression(let value):
            return .literalExpression(
                id: UUID(),
                literal: value.literal.copy(deep: deep)
            )
        case .memberExpression(let value):
            return .memberExpression(
                id: UUID(),
                expression: value.expression.copy(deep: deep),
                memberName: value.memberName.copy(deep: deep)
            )
        case .placeholder:
            return .makePlaceholder()
        }
    }

    public func insert(childNode: LGCSyntaxNode, atIndex: Int) -> LGCExpression {
        guard case .functionCallArgument(let child) = childNode,
            case .functionCallExpression(let value) = self else { return self }

        var updated = value.arguments.normalizedPlaceholders.map { $0 }
        updated.insert(child, at: atIndex)

        return LGCExpression.functionCallExpression(
            id: value.id,
            expression: value.expression,
            arguments: .init(updated)
        )
    }

    public func delete(id: UUID) -> LGCExpression? {
        if id == uuid { return nil }

        switch self {
        case .functionCallExpression(let value):
            guard let expression = value.expression.delete(id: id) else { return nil }

            return .functionCallExpression(
                id: value.id,
                expression: expression,
                arguments: LGCList(value.arguments.compactMap { $0.delete(id: id) }).normalizedPlaceholders
            )
        case .literalExpression(let value):
            guard let literal = value.literal.delete(id: id) else { return nil }

            return .literalExpression(id: value.id, literal: literal)
        case .assignmentExpression, .identifierExpression, .memberExpression, .placeholder:
            return self
        }
    }

    public var uuid: UUID {
        switch self {
        case .assignmentExpression(let value):
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
        case .assignmentExpression:
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
        guard let parent = rootNode.contents.parentOf(target: uuid, includeTopLevel: false) else { return false }

        switch parent {
        case .literal(.array):
            return true
        default:
            return false
        }
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
        case .returnStatement(let value):
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

    public func delete(id: UUID) -> LGCStatement? {
        if id == uuid { return nil }

        switch self {
        case .declaration(let value):
            guard let content = value.content.delete(id: id) else { return nil }
            return .declaration(id: value.id, content: content)
        case .returnStatement(let value):
            return .returnStatement(id: value.id, expression: value.expression.delete(id: id) ?? LGCExpression.makePlaceholder())
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
            case .returnStatement(let value):
                return LGCStatement.returnStatement(
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
        case .returnStatement(let value):
            return LGCStatement.returnStatement(
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
        case .returnStatement(let value):
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

    public func childrenInSameCollection(as node: LGCSyntaxNode) -> [LGCSyntaxNode] {
        switch self {
        case .enumeration(let value):
            return value.cases.map { $0.node }
        case .record(let value):
            return value.declarations.map { $0.node }
        case .namespace(let value):
            return value.declarations.map { $0.node }
        case .function(let value):
            switch node {
            case .functionParameter:
                return value.parameters.map { $0.node }
            case .statement:
                return value.block.map { $0.node }
            default:
                return []
            }
        default:
            return []
        }
    }

    public var nodeTypeDescription: String {
        return "Declaration"
    }

    public var node: LGCSyntaxNode {
        return .declaration(self)
    }

    public var namePattern: LGCPattern? {
        switch self {
        case .variable(let value):
            return value.name
        case .enumeration(let value):
            return value.name
        case .record(let value):
            return value.name
        case .namespace(let value):
            return value.name
        case .function(let value):
            return value.name
        case .importDeclaration(let value):
            return value.name
        case .placeholder:
            return nil
        }
    }

    public func delete(id: UUID) -> LGCDeclaration? {
        if id == uuid { return nil }

        switch self {
        case .variable(let value):
            guard let name = value.name.delete(id: id) else { return nil }

            let shouldDeleteAnnotation = value.annotation?.uuid == id
            let shouldDeleteInitializer = value.initializer?.uuid == id

            return .variable(
                id: value.id,
                name: name,
                annotation: shouldDeleteAnnotation
                    ? LGCTypeAnnotation.typeIdentifier(id: UUID(), identifier: LGCIdentifier(id: UUID(), string: "type", isPlaceholder: true), genericArguments: .empty)
                    : value.annotation?.delete(id: id),
                initializer: shouldDeleteAnnotation || shouldDeleteInitializer
                    ? LGCExpression.identifierExpression(id: UUID(), identifier: LGCIdentifier(id: UUID(), string: "value", isPlaceholder: true))
                    : value.initializer?.delete(id: id),
                comment: value.comment?.delete(id: id)
            )
        case .enumeration(let value):
            guard let name = value.name.delete(id: id) else { return nil }

            return .enumeration(
                id: value.id,
                name: name,
                genericParameters: value.genericParameters.delete(id: id),
                cases: LGCList(value.cases.compactMap { $0.delete(id: id) }).normalizedPlaceholders,
                comment: value.comment?.delete(id: id)
            )
        case .record(let value):
            guard let name = value.name.delete(id: id) else { return nil }

            return .record(
                id: value.id,
                name: name,
                genericParameters: value.genericParameters.delete(id: id),
                declarations: LGCList(value.declarations.compactMap { $0.delete(id: id) }).normalizedPlaceholders,
                comment: value.comment?.delete(id: id)
            )
        case .namespace(let value):
            guard let name = value.name.delete(id: id) else { return nil }

            return .namespace(
                id: value.id,
                name: name,
                declarations: LGCList(value.declarations.compactMap { $0.delete(id: id) }).normalizedPlaceholders
            )
        case .function(let value):
            guard let name = value.name.delete(id: id) else { return nil }

            return .function(
                id: value.id,
                name: name,
                returnType: value.returnType.delete(id: id) ?? LGCTypeAnnotation.makePlaceholder(),
                genericParameters: value.genericParameters.delete(id: id),
                parameters: value.parameters.delete(id: id).normalizedPlaceholders,
                block: value.block.delete(id: id).normalizedPlaceholders,
                comment: value.comment?.delete(id: id)
            )
        case .importDeclaration(let value):
            guard let name = value.name.delete(id: id) else { return nil }

            return .importDeclaration(id: value.id, name: name)
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
                    genericParameters: value.genericParameters.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    parameters: value.parameters.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    block: value.block.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    comment: value.comment?.replace(id: id, with: syntaxNode)
                )
            case .enumeration(let value):
                return LGCDeclaration.enumeration(
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode),
                    genericParameters: value.genericParameters.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    cases: value.cases.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
                    comment: value.comment?.replace(id: id, with: syntaxNode)
                )
            case .record(let value):
                return LGCDeclaration.record(
                    id: value.id,
                    name: value.name.replace(id: id, with: syntaxNode),
                    genericParameters: value.genericParameters.replace(id: id, with: syntaxNode, preservingEndingPlaceholder: true),
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
        case .enumeration(let value):
            guard case .enumerationCase(let child) = childNode else { return self }

            var updated = value.cases.normalizedPlaceholders.map { $0 }
            updated.insert(child, at: atIndex)

            return .enumeration(
                id: value.id,
                name: value.name,
                genericParameters: value.genericParameters,
                cases: .init(updated),
                comment: value.comment
            )
        case .record(let value):
            guard case .declaration(let child) = childNode else { return self }

            var updated = value.declarations.normalizedPlaceholders.map { $0 }
            updated.insert(child, at: atIndex)

            return .record(
                id: value.id,
                name: value.name,
                genericParameters: value.genericParameters,
                declarations: .init(updated),
                comment: value.comment
            )
        case .namespace(let value):
            guard case .declaration(let child) = childNode else { return self }

            var updated = value.declarations.normalizedPlaceholders.map { $0 }
            updated.insert(child, at: atIndex)

            return .namespace(
                id: value.id,
                name: value.name,
                declarations: .init(updated)
            )
        case .function(let value):
            switch childNode {
            case .functionParameter(let child):
                var updated = value.parameters.normalizedPlaceholders.map { $0 }
                updated.insert(child, at: atIndex)

                return .function(
                    id: value.id,
                    name: value.name,
                    returnType: value.returnType,
                    genericParameters: value.genericParameters,
                    parameters: .init(updated),
                    block: value.block,
                    comment: value.comment
                )
            case .statement(let child):
                var updated = value.block.normalizedPlaceholders.map { $0 }
                updated.insert(child, at: atIndex)

                return .function(
                    id: value.id,
                    name: value.name,
                    returnType: value.returnType,
                    genericParameters: value.genericParameters,
                    parameters: value.parameters,
                    block: .init(updated),
                    comment: value.comment
                )
            default:
                return self
            }
        default:
            return self
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
        case (.record, .declaration):
            return true
        case (.enumeration, .enumerationCase):
            return true
        case (.function, .functionParameter):
            return true
        case (.function, .statement):
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
        case .function(let value):
            return value.comment?.string
        case .namespace, .importDeclaration, .placeholder:
            return nil
        }
    }
}

extension LGCProgram: SyntaxNodeProtocol {
    public var isSelectable: Bool { return false }

    public var subnodes: [LGCSyntaxNode] {
        return block.map { $0.node }
    }

    public func childrenInSameCollection(as node: LGCSyntaxNode) -> [LGCSyntaxNode] {
        return block.map { $0.node }
    }

    public var nodeTypeDescription: String {
        return "Program"
    }

    public var node: LGCSyntaxNode {
        return .program(self)
    }

    public func delete(id: UUID) -> LGCProgram? {
        if id == uuid { return nil }

        let updated = block.compactMap { $0.delete(id: id) }

        return LGCProgram(
            id: self.uuid,
            block: LGCList(updated).normalizedPlaceholders
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

    public func childrenInSameCollection(as node: LGCSyntaxNode) -> [LGCSyntaxNode] {
        return parameters.map { $0.node }
    }

    public var nodeTypeDescription: String {
        return "Top-level Parameters"
    }

    public var node: LGCSyntaxNode {
        return .topLevelParameters(self)
    }

    public func delete(id: UUID) -> LGCTopLevelParameters? {
        if id == uuid { return nil }
        
        let updated = parameters.compactMap { $0.delete(id: id) }

        return LGCTopLevelParameters(
            id: self.uuid,
            parameters: LGCList(updated).normalizedPlaceholders
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

    public func childrenInSameCollection(as node: LGCSyntaxNode) -> [LGCSyntaxNode] {
        return declarations.map { $0.node }
    }

    public var nodeTypeDescription: String {
        return "Top-level Declarations"
    }

    public var node: LGCSyntaxNode {
        return .topLevelDeclarations(self)
    }

    public func delete(id: UUID) -> LGCTopLevelDeclarations? {
        if id == uuid { return nil }

        let updated = declarations.compactMap { $0.delete(id: id) }

        return LGCTopLevelDeclarations(
            id: self.uuid,
            declarations: LGCList(updated).normalizedPlaceholders
        )
    }

    public func insert(childNode: LGCSyntaxNode, atIndex: Int) -> LGCTopLevelDeclarations {
        guard case .declaration(let child) = childNode else { return self }

        var updated = declarations.map { $0 }
        updated.insert(child, at: min(atIndex, updated.count))

        return LGCTopLevelDeclarations(
            id: uuid,
            declarations: LGCList(updated).normalizedPlaceholders
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

extension LGCFunctionCallArgument: SyntaxNodeProtocol {
    public func acceptsLineDrag(rootNode: LGCSyntaxNode) -> Bool {
        return false
    }

    public var uuid: UUID {
        switch self {
        case .argument(let value):
            return value.id
        case .placeholder(let value):
            return value
        }
    }

    public var node: LGCSyntaxNode {
        return .functionCallArgument(self)
    }

    public var nodeTypeDescription: String {
        return "Argument"
    }

    public var subnodes: [LGCSyntaxNode] {
        switch self {
        case .argument(let value):
            return [value.expression.node]
        case .placeholder:
            return []
        }
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCFunctionCallArgument {
        switch syntaxNode {
        case .functionCallArgument(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .argument(let value):
                return .argument(
                    id: UUID(),
                    label: value.label,
                    expression: value.expression.replace(id: id, with: syntaxNode)
                )
            case .placeholder:
                return .placeholder(id: UUID())
            }
        }
    }

    public func delete(id: UUID) -> LGCFunctionCallArgument? {
        if id == uuid { return nil }

        switch self {
        case .argument(let value):
            guard let expression = value.expression.delete(id: id) else { return nil }

            return .argument(id: value.id, label: value.label, expression: expression)
        case .placeholder(let id):
            return .placeholder(id: id)
        }
    }

    public func copy(deep: Bool) -> LGCFunctionCallArgument {
        switch self {
        case .argument(let value):
            return .argument(
                id: UUID(),
                label: value.label,
                expression: value.expression.copy(deep: deep)
            )
        case .placeholder(let value):
            return .placeholder(id: value)
        }
    }

    public func movementAfterInsertion(rootNode: LGCSyntaxNode) -> Movement {
        switch self {
        case .placeholder:
            return .none
        case .argument:
            return .next
        }
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
        case .functionCallArgument(let value):
            return value
        }
    }

    func insert(childNode: LGCSyntaxNode, atIndex: Int) -> LGCSyntaxNode {
        LGCSyntaxNode.lookupCache.remove(key: self.uuid)
        return contents.insert(childNode: childNode, atIndex: atIndex).node
    }

    public func delete(id: UUID) -> LGCSyntaxNode? {
        LGCSyntaxNode.lookupCache.remove(key: self.uuid)
        return contents.delete(id: id)?.node
    }

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCSyntaxNode {
        LGCSyntaxNode.lookupCache.remove(key: self.uuid)
        return contents.replace(id: id, with: syntaxNode).node
    }

    public func copy(deep: Bool = true) -> LGCSyntaxNode {
        return contents.copy(deep: deep).node
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        if let found = LGCSyntaxNode.lookup(rootNode: self, nodeId: id) {
            return found
        }

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

extension LGCSyntaxNode {
    static func makeLookupMap(from rootNode: LGCSyntaxNode) -> [UUID: LGCSyntaxNode] {
        var map: [UUID: LGCSyntaxNode] = [:]

        var nodes: [LGCSyntaxNode] = [rootNode]

        while let next = nodes.popLast() {
            map[next.uuid] = next
            nodes.append(contentsOf: next.subnodes)
        }

        return map
    }

    fileprivate static var lookupCache: LRUCache<UUID, [UUID: LGCSyntaxNode]> = .init()

    fileprivate static func lookup(rootNode: LGCSyntaxNode, nodeId: UUID) -> LGCSyntaxNode? {
        if let map = lookupCache.item(for: rootNode.uuid) {
            return map[nodeId]
        } else {
            let map = makeLookupMap(from: rootNode)
            lookupCache.add(item: map, for: rootNode.uuid)
            return map[nodeId]
        }
    }
}

extension LGCSyntaxNode {
    public func hierarchyDescription(indent: Int = 2, initialIndent: Int = 0) -> String {
        let childrenDescription = self.subnodes.map {
           String(repeating: " ", count: initialIndent + indent) + $0.hierarchyDescription(indent: indent, initialIndent: initialIndent + indent)
        }
        let description = "\(nodeTypeDescription)(\(uuid))"
        return ([description] + childrenDescription).joined(separator: "\n")
    }
}
