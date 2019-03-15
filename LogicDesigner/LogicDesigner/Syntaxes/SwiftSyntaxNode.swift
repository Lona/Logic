//
//  SwiftNativeTypes.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit
import Logic

enum Movement {
    case none, next
}

protocol SyntaxNodeProtocol {
    var uuid: SwiftUUID { get }
    var lastNode: SwiftSyntaxNode { get }
    var movementAfterInsertion: Movement { get }
    var node: SwiftSyntaxNode { get }
    var nodeTypeDescription: String { get }

    func find(id: SwiftUUID) -> SwiftSyntaxNode?
    func pathTo(id: SwiftUUID) -> [SwiftSyntaxNode]?
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> Self

    func documentation(for prefix: String) -> RichText

    //    static var suggestionCategories: [LogicSuggestionCategory] { get }
}

extension SyntaxNodeProtocol {
    func documentation(for prefix: String) -> RichText {
        return RichText(blocks: [])
    }
}

extension SwiftIdentifier: SyntaxNodeProtocol {
    var nodeTypeDescription: String {
        return "Identifier"
    }

    var node: SwiftSyntaxNode {
        return .identifier(self)
    }

    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftIdentifier {
        switch syntaxNode {
        case .identifier(let newNode) where id == uuid:
            return SwiftIdentifier(id: NSUUID().uuidString, string: newNode.string)
        default:
            return SwiftIdentifier(id: NSUUID().uuidString, string: string)
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return id == uuid ? node : nil
    }

    func pathTo(id: SwiftUUID) -> [SwiftSyntaxNode]? {
        return id == uuid ? [node] : nil
    }

    var lastNode: SwiftSyntaxNode {
        return node
    }

    var uuid: SwiftUUID { return id }

    var movementAfterInsertion: Movement {
        return .next
    }
}

extension SwiftPattern: SyntaxNodeProtocol {
    var nodeTypeDescription: String {
        return "Pattern"
    }

    var node: SwiftSyntaxNode {
        return .pattern(self)
    }

    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftPattern {
        switch syntaxNode {
        case .pattern(let newNode) where id == uuid:
            return SwiftPattern(id: NSUUID().uuidString, name: newNode.name)
        default:
            return SwiftPattern(id: NSUUID().uuidString, name: name)
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return id == uuid ? node : nil
    }

    func pathTo(id: SwiftUUID) -> [SwiftSyntaxNode]? {
        return id == uuid ? [node] : nil
    }

    var lastNode: SwiftSyntaxNode {
        return node
    }

    var uuid: SwiftUUID { return id }

    var movementAfterInsertion: Movement {
        return .next
    }
}

extension SwiftBinaryOperator: SyntaxNodeProtocol {
    var nodeTypeDescription: String {
        return "Binary Operator"
    }

    var node: SwiftSyntaxNode {
        return .binaryOperator(self)
    }

    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftBinaryOperator {
        switch syntaxNode {
        case .binaryOperator(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .isEqualTo:
                return SwiftBinaryOperator.isEqualTo(SwiftIsEqualTo(id: NSUUID().uuidString))
            case .isNotEqualTo:
                return SwiftBinaryOperator.isNotEqualTo(SwiftIsNotEqualTo(id: NSUUID().uuidString))
            case .isLessThan:
                return SwiftBinaryOperator.isLessThan(SwiftIsLessThan(id: NSUUID().uuidString))
            case .isGreaterThan:
                return SwiftBinaryOperator.isGreaterThan(SwiftIsGreaterThan(id: NSUUID().uuidString))
            case .isLessThanOrEqualTo:
                return SwiftBinaryOperator.isLessThanOrEqualTo(SwiftIsLessThanOrEqualTo(id: NSUUID().uuidString))
            case .isGreaterThanOrEqualTo:
                return SwiftBinaryOperator.isGreaterThanOrEqualTo(SwiftIsGreaterThanOrEqualTo(id: NSUUID().uuidString))
            case .setEqualTo:
                return SwiftBinaryOperator.setEqualTo(SwiftSetEqualTo(id: NSUUID().uuidString))
            }
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return id == uuid ? node : nil
    }

    func pathTo(id: SwiftUUID) -> [SwiftSyntaxNode]? {
        return id == uuid ? [node] : nil
    }

    var lastNode: SwiftSyntaxNode {
        return node
    }

    var uuid: SwiftUUID {
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

    var movementAfterInsertion: Movement {
        return .next
    }
}

extension SwiftExpression: SyntaxNodeProtocol {
    var nodeTypeDescription: String {
        return "Expression"
    }

    var node: SwiftSyntaxNode {
        return .expression(self)
    }

    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftExpression {
        switch (syntaxNode, self) {
        case (.expression(let newNode), _) where id == uuid:
            return newNode
        // Identifier can become an IdentifierExpression and replace an expression
        case (.identifier(let newNode), _) where id == uuid:
            return .identifierExpression(SwiftIdentifierExpression(
                id: NSUUID().uuidString,
                identifier: newNode))
        case (_, .binaryExpression(let value)):
            return .binaryExpression(SwiftBinaryExpression(
                left: value.left.replace(id: id, with: syntaxNode),
                right: value.right.replace(id: id, with: syntaxNode),
                op: value.op.replace(id: id, with: syntaxNode),
                id: NSUUID().uuidString))
        case (_, .identifierExpression(let value)):
            return .identifierExpression(SwiftIdentifierExpression(
                id: NSUUID().uuidString,
                identifier: value.identifier.replace(id: id, with: syntaxNode)))
        case (_, .functionCallExpression(let value)):
            return .functionCallExpression(
                SwiftFunctionCallExpression(
                    id: NSUUID().uuidString,
                    expression: value.expression.replace(id: id, with: syntaxNode),
                    arguments: value.arguments.replace(id: id, with: syntaxNode)
                )
            )
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        if id == uuid {
            return SwiftSyntaxNode.expression(self)
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

    func pathTo(id: SwiftUUID) -> [SwiftSyntaxNode]? {
        if id == uuid {
            return [.expression(self)]
        }

        var found: [SwiftSyntaxNode]?

        switch self {
        case .binaryExpression(let value):
            found = value.left.pathTo(id: id) ?? value.op.pathTo(id: id) ?? value.right.pathTo(id: id)
        case .identifierExpression(let value):
            found = value.identifier.pathTo(id: id)
        case .functionCallExpression(let value):
            let foundInArguments: [SwiftSyntaxNode]? = value.arguments.reduce(nil, { result, node in
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

    var lastNode: SwiftSyntaxNode {
        switch self {
        case .binaryExpression(let value):
            return value.right.lastNode
        case .identifierExpression(let value):
            return value.identifier.lastNode
        case .functionCallExpression(let value):
            return value.arguments.isEmpty ? value.expression.lastNode : value.arguments[value.arguments.count - 1].lastNode
        }
    }

    var uuid: SwiftUUID {
        switch self {
        case .binaryExpression(let value):
            return value.id
        case .identifierExpression(let value):
            return value.id
        case .functionCallExpression(let value):
            return value.id
        }
    }

    var movementAfterInsertion: Movement {
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

extension SwiftStatement: SyntaxNodeProtocol {
    var nodeTypeDescription: String {
        return "Statement"
    }

    var node: SwiftSyntaxNode {
        return .statement(self)
    }

    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftStatement {
        switch syntaxNode {
        case .statement(let newNode) where id == uuid:
            return newNode
        case .expression(let newNode) where id == uuid:
            return .expressionStatement(
                SwiftExpressionStatement(
                    id: NSUUID().uuidString,
                    expression: newNode
                )
            )
        case .declaration(let newNode) where id == uuid:
            return .decl(
                SwiftDecl(
                    content: newNode,
                    id: NSUUID().uuidString
                )
            )
        default:
            switch self {
            case .branch(let value):
                return .branch(
                    SwiftBranch(
                        id: NSUUID().uuidString,
                        condition: value.condition.replace(id: id, with: syntaxNode),
                        block: value.block.replace(id: id, with: syntaxNode)
                    )
                )
            case .decl:
                return self
            case .loop(let value):
                return SwiftStatement.loop(
                    SwiftLoop(
                        pattern: value.pattern.replace(id: id, with: syntaxNode),
                        expression: value.expression.replace(id: id, with: syntaxNode),
                        block: SwiftList<SwiftStatement>.empty,
                        id: NSUUID().uuidString))
            case .expressionStatement(let value):
                return SwiftStatement.expressionStatement(
                    SwiftExpressionStatement(
                        id: NSUUID().uuidString,
                        expression: value.expression.replace(id: id, with: syntaxNode)
                    )
                )
            case .placeholderStatement(_):
                return self
            }
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        if id == uuid {
            return SwiftSyntaxNode.statement(self)
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

    func pathTo(id: SwiftUUID) -> [SwiftSyntaxNode]? {
        if id == uuid {
            return [.statement(self)]
        }

        var found: [SwiftSyntaxNode]?

        switch self {
        case .branch(let value):
            let foundInBlock: [SwiftSyntaxNode]? = value.block.reduce(nil, { result, node in
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

    var lastNode: SwiftSyntaxNode {
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

    var uuid: SwiftUUID {
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

    var movementAfterInsertion: Movement {
        return .next
    }
}

extension SwiftProgram: SyntaxNodeProtocol {
    var nodeTypeDescription: String {
        return "Program"
    }

    var node: SwiftSyntaxNode {
        return .program(self)
    }

    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftProgram {
        return SwiftProgram(
            id: NSUUID().uuidString,
            block: block.replace(id: id, with: syntaxNode)
        )
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        if id == uuid { return node }

        return block.find(id: id)
    }

    func pathTo(id: SwiftUUID) -> [SwiftSyntaxNode]? {
        if id == uuid { return [node] }

        let found: [SwiftSyntaxNode]? = block.reduce(nil, { result, node in
            if result != nil { return result }
            return node.pathTo(id: id)
        })

        // We don't include the Program node in the path, since we never want
        // to directly select it or show it in any menus
        return found
    }

    var lastNode: SwiftSyntaxNode {
        return block.map { $0 }.last?.lastNode ?? node
    }

    var uuid: SwiftUUID {
        return id
    }

    var movementAfterInsertion: Movement {
        return .next
    }
}


extension SwiftFunctionCallArgument {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftFunctionCallArgument {
        return SwiftFunctionCallArgument(
            id: NSUUID().uuidString,
            label: label,
            expression: expression.replace(id: id, with: syntaxNode)
        )
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return expression.find(id: id)
    }

    func pathTo(id: SwiftUUID) -> [SwiftSyntaxNode]? {
        return expression.pathTo(id: id)
    }

    var lastNode: SwiftSyntaxNode {
        return expression.lastNode
    }

    var uuid: SwiftUUID {
        return id
    }

    var movementAfterInsertion: Movement {
        return .next
    }
}

extension SwiftSyntaxNode {
    var contents: SyntaxNodeProtocol {
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

    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftSyntaxNode {
        return contents.replace(id: id, with: syntaxNode).node
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return contents.find(id: id)
    }

    func pathTo(id: SwiftUUID) -> [SwiftSyntaxNode]? {
        return contents.pathTo(id: id)
    }

    var lastNode: SwiftSyntaxNode {
        return contents.lastNode
    }

    var uuid: SwiftUUID {
        return contents.uuid
    }

    var movementAfterInsertion: Movement {
        return contents.movementAfterInsertion
    }

    var nodeTypeDescription: String {
        return contents.nodeTypeDescription
    }
}

extension SwiftList where T == SwiftStatement {
    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return self.reduce(nil, { result, item in
            return result ?? item.find(id: id)
        })
    }

    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftList {
        // Reverse list so we can easily prepend to the front
        let result = self.map { statement in statement.replace(id: id, with: syntaxNode) }.reversed()

        var resultIterator = result.makeIterator()
        var output = SwiftList<T>.empty

        if let first = result.first, case .placeholderStatement = first {

        } else {
            output = .next(.placeholderStatement(SwiftPlaceholderStatement(id: NSUUID().uuidString)), output)
        }

        while let current = resultIterator.next() {
            output = .next(current, output)
        }

        return output
    }
}

extension SwiftList where T == SwiftFunctionCallArgument {
    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return self.reduce(nil, { result, item in
            return result ?? item.find(id: id)
        })
    }

    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftList {
        // Reverse list so we can easily prepend to the front
        let result = self.map { statement in statement.replace(id: id, with: syntaxNode) }.reversed()

        var resultIterator = result.makeIterator()
        var output = SwiftList<T>.empty

        while let current = resultIterator.next() {
            output = .next(current, output)
        }

        return output
    }
}
