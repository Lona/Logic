//
//  SwiftNativeTypes.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

protocol LogicTextEditable {
//    var uuid: SwiftUUID { get }
//    var textElements: [LogicEditorText] { get }
//    func find(id: SwiftUUID) -> SwiftSyntaxNode?
//    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> Self
//    static var suggestionCategories: [LogicSuggestionCategory] { get }
}

extension SwiftIdentifier: LogicTextEditable {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftIdentifier {
        switch syntaxNode {
        case .identifier(let newNode) where id == uuid:
            return SwiftIdentifier(id: NSUUID().uuidString, string: newNode.string)
        default:
            return self
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return id == uuid ? SwiftSyntaxNode.identifier(self) : nil
    }

    var uuid: SwiftUUID { return id }
}

extension SwiftExpression: LogicTextEditable {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftExpression {
        switch (syntaxNode, self) {
        case (.expression(let newNode), _) where id == uuid:
            return newNode
        case (_, .binaryExpression(let value)):
            return .binaryExpression(SwiftBinaryExpression(
                left: value.left.replace(id: id, with: syntaxNode),
                right: value.right.replace(id: id, with: syntaxNode),
                op: value.op,
                id: NSUUID().uuidString))
        // Identifier can replace IdentifierExpression
        case (.identifier(let newNode), .identifierExpression) where id == uuid:
            return .identifierExpression(SwiftIdentifierExpression(
                id: NSUUID().uuidString,
                identifier: newNode))
        case (_, .identifierExpression(let value)):
            return .identifierExpression(SwiftIdentifierExpression(
                id: NSUUID().uuidString,
                identifier: value.identifier.replace(id: id, with: syntaxNode)))
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        if id == uuid {
            return SwiftSyntaxNode.expression(self)
        }

        switch self {
        case .binaryExpression(let value):
            return value.left.find(id: id) ?? value.right.find(id: id)
        case .identifierExpression(let value):
            if id == value.identifier.uuid {
                return SwiftSyntaxNode.expression(self)
            }

            return value.identifier.find(id: id)
        }
    }

    var uuid: SwiftUUID {
        switch self {
        case .binaryExpression(let value):
            return value.id
        case .identifierExpression(let value):
            return value.id
        }
    }
}

extension SwiftStatement: LogicTextEditable {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftStatement {
        switch syntaxNode {
        case .statement(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .branch(let value):
                return .branch(SwiftBranch(
                    id: NSUUID().uuidString,
                    condition: value.condition.replace(id: id, with: syntaxNode),
                    block: SwiftList<SwiftStatement>.empty))
            case .decl:
                return self
            case .loop(let value):
                return SwiftStatement.loop(
                    SwiftLoop(
                        pattern: value.pattern.replace(id: id, with: syntaxNode),
                        expression: value.expression.replace(id: id, with: syntaxNode),
                        block: SwiftList<SwiftStatement>.empty,
                        id: NSUUID().uuidString))
            case .expressionStatement(_):
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
            return value.condition.find(id: id)
        case .decl:
            return nil
        case .loop(let value):
            return value.expression.find(id: id) ?? value.pattern.find(id: id)
        case .expressionStatement(let value):
            return value.expression.find(id: id)
        }
    }

    var uuid: SwiftUUID {
        switch self {
        case .branch(let branch):
            return branch.id
        case .decl(let decl):
            return decl.id
        case .loop(let loop):
            return loop.id
        case .expressionStatement(let expr):
            return expr.id
        }
    }
}

extension SwiftSyntaxNode {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftSyntaxNode {
        switch self {
        case .statement(let statement):
            return .statement(statement.replace(id: id, with: syntaxNode))
        case .declaration:
            return self
        case .identifier(let identifier):
            return .identifier(identifier.replace(id: id, with: syntaxNode))
        case .expression(let value):
            return .expression(value.replace(id: id, with: syntaxNode))
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        switch self {
        case .statement(let value):
            return value.find(id: id)
        case .declaration:
            return nil
        case .identifier(let value):
            return value.find(id: id)
        case .expression(let value):
            return value.find(id: id)
        }
    }

    var uuid: SwiftUUID {
        switch self {
        case .statement(let value):
            return value.uuid
        case .declaration(let value):
            return ""
        case .identifier(let value):
            return value.uuid
        case .expression(let value):
            return value.uuid
        }
    }
}
