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

    func documentation(for prefix: String) -> RichText

    //    static var suggestionCategories: [LogicSuggestionCategory] { get }
}

extension SyntaxNodeProtocol {
    public func documentation(for prefix: String) -> RichText {
        return RichText(blocks: [])
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
            return LGCIdentifier(id: UUID(), string: newNode.string)
        default:
            return LGCIdentifier(id: UUID(), string: string)
        }
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        return id == uuid ? node : nil
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

    public func find(id: UUID) -> LGCSyntaxNode? {
        return id == uuid ? node : nil
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
                return LGCBinaryOperator.isEqualTo(LGCIsEqualTo(id: UUID()))
            case .isNotEqualTo:
                return LGCBinaryOperator.isNotEqualTo(LGCIsNotEqualTo(id: UUID()))
            case .isLessThan:
                return LGCBinaryOperator.isLessThan(LGCIsLessThan(id: UUID()))
            case .isGreaterThan:
                return LGCBinaryOperator.isGreaterThan(LGCIsGreaterThan(id: UUID()))
            case .isLessThanOrEqualTo:
                return LGCBinaryOperator.isLessThanOrEqualTo(LGCIsLessThanOrEqualTo(id: UUID()))
            case .isGreaterThanOrEqualTo:
                return LGCBinaryOperator.isGreaterThanOrEqualTo(LGCIsGreaterThanOrEqualTo(id: UUID()))
            case .setEqualTo:
                return LGCBinaryOperator.setEqualTo(LGCSetEqualTo(id: UUID()))
            }
        }
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        return id == uuid ? node : nil
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
            return value.id
        case .isNotEqualTo(let value):
            return value.id
        case .isLessThan(let value):
            return value.id
        case .isGreaterThan(let value):
            return value.id
        case .isLessThanOrEqualTo(let value):
            return value.id
        case .isGreaterThanOrEqualTo(let value):
            return value.id
        case .setEqualTo(let value):
            return value.id
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
            return .identifierExpression(LGCIdentifierExpression(
                id: UUID(),
                identifier: newNode))
        case (_, .binaryExpression(let value)):
            return .binaryExpression(LGCBinaryExpression(
                left: value.left.replace(id: id, with: syntaxNode),
                right: value.right.replace(id: id, with: syntaxNode),
                op: value.op.replace(id: id, with: syntaxNode),
                id: UUID()))
        case (_, .identifierExpression(let value)):
            return .identifierExpression(LGCIdentifierExpression(
                id: UUID(),
                identifier: value.identifier.replace(id: id, with: syntaxNode)))
        case (_, .functionCallExpression(let value)):
            return .functionCallExpression(
                LGCFunctionCallExpression(
                    id: UUID(),
                    expression: value.expression.replace(id: id, with: syntaxNode),
                    arguments: value.arguments.replace(id: id, with: syntaxNode)
                )
            )
        }
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        if id == uuid {
            return LGCSyntaxNode.expression(self)
        }

        switch self {
        case .binaryExpression(let value):
            return value.left.find(id: id) ?? value.op.find(id: id) ?? value.right.find(id: id)
        case .identifierExpression(let value):
            return value.identifier.find(id: id)
        case .functionCallExpression(let value):
            return value.expression.find(id: id) ?? value.arguments.find(id: id)
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
            let foundInArguments: [LGCSyntaxNode]? = value.arguments.reduce(nil, { result, node in
                if result != nil { return result }
                return node.pathTo(id: id)
            })
            found = value.expression.pathTo(id: id) ?? foundInArguments
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

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCStatement {
        switch syntaxNode {
        case .statement(let newNode) where id == uuid:
            return newNode
        case .expression(let newNode) where id == uuid:
            return .expressionStatement(
                LGCExpressionStatement(
                    id: UUID(),
                    expression: newNode
                )
            )
        case .declaration(let newNode) where id == uuid:
            return .decl(
                LGCDecl(
                    content: newNode,
                    id: UUID()
                )
            )
        default:
            switch self {
            case .branch(let value):
                return .branch(
                    LGCBranch(
                        id: UUID(),
                        condition: value.condition.replace(id: id, with: syntaxNode),
                        block: value.block.replace(id: id, with: syntaxNode)
                    )
                )
            case .decl:
                return self
            case .loop(let value):
                return LGCStatement.loop(
                    LGCLoop(
                        pattern: value.pattern.replace(id: id, with: syntaxNode),
                        expression: value.expression.replace(id: id, with: syntaxNode),
                        block: LGCList<LGCStatement>.empty,
                        id: UUID()))
            case .expressionStatement(let value):
                return LGCStatement.expressionStatement(
                    LGCExpressionStatement(
                        id: UUID(),
                        expression: value.expression.replace(id: id, with: syntaxNode)
                    )
                )
            case .placeholderStatement(_):
                return self
            }
        }
    }

    public func find(id: UUID) -> LGCSyntaxNode? {
        if id == uuid {
            return LGCSyntaxNode.statement(self)
        }

        switch self {
        case .branch(let value):
            return value.condition.find(id: id) ?? value.block.find(id: id)
        case .decl:
            return nil
        case .loop(let value):
            return value.expression.find(id: id) ?? value.pattern.find(id: id)
        case .expressionStatement(let value):
            return value.expression.find(id: id)
        case .placeholderStatement:
            return nil
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
        case .decl:
            return nil
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
        case .decl:
            return .statement(self)
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
        case .decl(let value):
            return value.id
        case .loop(let value):
            return value.id
        case .expressionStatement(let value):
            return value.id
        case .placeholderStatement(let value):
            return value.id
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

    public func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCProgram {
        return LGCProgram(
            id: UUID(),
            block: block.replace(id: id, with: syntaxNode)
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


extension LGCFunctionCallArgument {
    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCFunctionCallArgument {
        return LGCFunctionCallArgument(
            id: UUID(),
            label: label,
            expression: expression.replace(id: id, with: syntaxNode)
        )
    }

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
        case .declaration:
            fatalError("Declarations not implemented")
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
        }
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

extension LGCList where T == LGCStatement {
    func find(id: UUID) -> LGCSyntaxNode? {
        return self.reduce(nil, { result, item in
            return result ?? item.find(id: id)
        })
    }

    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCList {
        // Reverse list so we can easily prepend to the front
        let result = self.map { statement in statement.replace(id: id, with: syntaxNode) }.reversed()

        var resultIterator = result.makeIterator()
        var output = LGCList<T>.empty

        if let first = result.first, case .placeholderStatement = first {

        } else {
            output = .next(.placeholderStatement(LGCPlaceholderStatement(id: UUID())), output)
        }

        while let current = resultIterator.next() {
            output = .next(current, output)
        }

        return output
    }
}

extension LGCList where T == LGCFunctionCallArgument {
    func find(id: UUID) -> LGCSyntaxNode? {
        return self.reduce(nil, { result, item in
            return result ?? item.find(id: id)
        })
    }

    func replace(id: UUID, with syntaxNode: LGCSyntaxNode) -> LGCList {
        // Reverse list so we can easily prepend to the front
        let result = self.map { statement in statement.replace(id: id, with: syntaxNode) }.reversed()

        var resultIterator = result.makeIterator()
        var output = LGCList<T>.empty

        while let current = resultIterator.next() {
            output = .next(current, output)
        }

        return output
    }
}
