//
//  SwiftSyntax+Suggestions.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

struct LogicSuggestionItem {
    var title: String
    var node: SwiftSyntaxNode
}

struct LogicSuggestionCategory {
    var title: String
    var items: [LogicSuggestionItem]

    var suggestionListItems: [SuggestionListItem] {
        let sectionHeader = SuggestionListItem.sectionHeader(title)
        let rows = items.map { SuggestionListItem.row($0.title) }
        return Array([[sectionHeader], rows].joined())
    }
}

private func id(_ string: String) -> SwiftIdentifier {
    return SwiftIdentifier(id: NSUUID().uuidString, string: string)
}

private func idExpression(_ string: String) -> SwiftExpression {
    return SwiftExpression.identifierExpression(
        SwiftIdentifierExpression(
            id: NSUUID().uuidString,
            identifier: SwiftIdentifier(id: NSUUID().uuidString, string: string)))
}

extension SwiftIdentifier {
    static var suggestionCategories: [LogicSuggestionCategory] {
        let variables = LogicSuggestionCategory(
            title: "Variables".uppercased(),
            items: [
                LogicSuggestionItem(
                    title: "bar",
                    node: SwiftSyntaxNode.identifier(SwiftIdentifier(id: NSUUID().uuidString, string: "bar"))),
                LogicSuggestionItem(
                    title: "foo",
                    node: SwiftSyntaxNode.identifier(SwiftIdentifier(id: NSUUID().uuidString, string: "foo"))),
                ])

        return [variables]
    }
}

extension SwiftExpression {
    static var suggestionCategories: [LogicSuggestionCategory] {
        let comparison = SwiftSyntaxNode.expression(
            SwiftExpression.binaryExpression(
                SwiftBinaryExpression(
                    left: SwiftExpression.identifierExpression(
                        SwiftIdentifierExpression(id: NSUUID().uuidString, identifier: id("left"))),
                    right: SwiftExpression.identifierExpression(
                        SwiftIdentifierExpression(id: NSUUID().uuidString, identifier: id("right"))),
                    op: ">",
                    id: NSUUID().uuidString)))

        let assignment = SwiftSyntaxNode.expression(
            SwiftExpression.binaryExpression(
                SwiftBinaryExpression(
                    left: SwiftExpression.identifierExpression(
                        SwiftIdentifierExpression(id: NSUUID().uuidString, identifier: id("variable"))),
                    right: SwiftExpression.identifierExpression(
                        SwiftIdentifierExpression(id: NSUUID().uuidString, identifier: id("value"))),
                    op: "=",
                    id: NSUUID().uuidString)))

        let expressions = LogicSuggestionCategory(
            title: "Expressions".uppercased(),
            items: [
                LogicSuggestionItem(title: "Comparison", node: comparison),
                LogicSuggestionItem(title: "Assignment", node: assignment)
            ]
        )

        return Array([[expressions], SwiftIdentifier.suggestionCategories].joined())
    }
}

extension SwiftStatement {
    static var suggestionCategories: [LogicSuggestionCategory] {
        let ifCondition = SwiftSyntaxNode.statement(
            SwiftStatement.branch(
                SwiftBranch(
                    id: NSUUID().uuidString,
                    condition: idExpression("condition"),
                    block: SwiftList<SwiftStatement>.empty)))

        let forLoop = SwiftSyntaxNode.statement(
            SwiftStatement.loop(
                SwiftLoop(
                    pattern: id("item"),
                    expression: idExpression("array"),
                    block: SwiftList<SwiftStatement>.empty,
                    id: NSUUID().uuidString)))

        let statements = LogicSuggestionCategory(
            title: "Statements".uppercased(),
            items: [
                LogicSuggestionItem(title: "If condition", node: ifCondition),
                LogicSuggestionItem(title: "For loop", node: forLoop)
            ]
        )

        return Array([[statements], SwiftExpression.suggestionCategories].joined())
    }
}

extension SwiftSyntaxNode {
    var suggestionCategories: [LogicSuggestionCategory] {
        switch self {
        case .statement:
            return SwiftStatement.suggestionCategories
        case .declaration:
            return []
        case .identifier:
            return SwiftIdentifier.suggestionCategories
        case .expression:
            return SwiftExpression.suggestionCategories
        }
    }
}

