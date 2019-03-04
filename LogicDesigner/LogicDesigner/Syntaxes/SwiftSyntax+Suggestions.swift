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
    var category: String
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
    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "bar",
                category: "Variables".uppercased(),
                node: SwiftSyntaxNode.identifier(SwiftIdentifier(id: NSUUID().uuidString, string: "bar"))
            ),
            LogicSuggestionItem(
                title: "foo",
                category: "Variables".uppercased(),
                node: SwiftSyntaxNode.identifier(SwiftIdentifier(id: NSUUID().uuidString, string: "foo"))
            )
        ]

        return items
    }
}

extension SwiftPattern {
    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "Variable name: \(prefix)",
                category: "Pattern".uppercased(),
                node: SwiftSyntaxNode.pattern(SwiftPattern(id: NSUUID().uuidString, name: prefix))
            )
        ]

        return items
    }
}

extension SwiftBinaryOperator {
    var displayText: String {
        switch self {
        case .isEqualTo:
            return "is equal to"
        case .isGreaterThan:
            return "is greater than"
        case .isGreaterThanOrEqualTo:
            return "is greater than or equal to"
        case .isLessThan:
            return "is less than"
        case .isLessThanOrEqualTo:
            return "is less than or equal to"
        case .isNotEqualTo:
            return "is not equal to"
        case .setEqualTo:
            return "now equals"
        }
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let operatorNodes = [
            SwiftBinaryOperator.isEqualTo(SwiftIsEqualTo(id: NSUUID().uuidString)),
            SwiftBinaryOperator.isNotEqualTo(SwiftIsNotEqualTo(id: NSUUID().uuidString)),
            SwiftBinaryOperator.isGreaterThan(SwiftIsGreaterThan(id: NSUUID().uuidString)),
            SwiftBinaryOperator.isGreaterThanOrEqualTo(SwiftIsGreaterThanOrEqualTo(id: NSUUID().uuidString)),
            SwiftBinaryOperator.isLessThan(SwiftIsLessThan(id: NSUUID().uuidString)),
            SwiftBinaryOperator.isLessThanOrEqualTo(SwiftIsLessThanOrEqualTo(id: NSUUID().uuidString)),
        ]

        return operatorNodes.map { node in
            LogicSuggestionItem(
                title: node.displayText,
                category: "Operators".uppercased(),
                node: SwiftSyntaxNode.binaryOperator(node)
            )
        }
    }
}

extension SwiftExpression {
    static var assignmentSuggestionItem: LogicSuggestionItem {
        return LogicSuggestionItem(
            title: "Assignment",
            category: "Expressions".uppercased(),
            node: SwiftSyntaxNode.expression(
                SwiftExpression.binaryExpression(
                    SwiftBinaryExpression(
                        left: SwiftExpression.identifierExpression(
                            SwiftIdentifierExpression(id: NSUUID().uuidString, identifier: id("variable"))),
                        right: SwiftExpression.identifierExpression(
                            SwiftIdentifierExpression(id: NSUUID().uuidString, identifier: id("value"))),
                        op: .setEqualTo(SwiftSetEqualTo(id: NSUUID().uuidString)),
                        id: NSUUID().uuidString))))
    }

    static var comparisonSuggestionItem: LogicSuggestionItem {
        return LogicSuggestionItem(
            title: "Comparison",
            category: "Expressions".uppercased(),
            node: SwiftSyntaxNode.expression(
                SwiftExpression.binaryExpression(
                    SwiftBinaryExpression(
                        left: SwiftExpression.identifierExpression(
                            SwiftIdentifierExpression(id: NSUUID().uuidString, identifier: id("left"))),
                        right: SwiftExpression.identifierExpression(
                            SwiftIdentifierExpression(id: NSUUID().uuidString, identifier: id("right"))),
                        op: .isEqualTo(SwiftIsEqualTo(id: NSUUID().uuidString)),
                        id: NSUUID().uuidString))))
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            comparisonSuggestionItem,
            assignmentSuggestionItem
        ]

        return items + SwiftIdentifier.suggestions(for: prefix)
    }
}

extension SwiftStatement {
    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let ifCondition = SwiftSyntaxNode.statement(
            SwiftStatement.branch(
                SwiftBranch(
                    id: NSUUID().uuidString,
                    condition: idExpression("condition"),
                    block: SwiftList<SwiftStatement>.next(
                        SwiftStatement.placeholderStatement(
                            SwiftPlaceholderStatement(id: NSUUID().uuidString)
                        ),
                        .empty
                    )
                )
            )
        )

        let forLoop = SwiftSyntaxNode.statement(
            SwiftStatement.loop(
                SwiftLoop(
                    pattern: SwiftPattern(id: NSUUID().uuidString, name: "item"),
                    expression: idExpression("array"),
                    block: SwiftList<SwiftStatement>.empty,
                    id: NSUUID().uuidString)))

        let items = [
            LogicSuggestionItem(
                title: "If condition",
                category: "Statements".uppercased(),
                node: ifCondition
            ),
            LogicSuggestionItem(
                title: "For loop",
                category: "Statements".uppercased(),
                node: forLoop
            ),
            SwiftExpression.assignmentSuggestionItem
        ]

        return items
    }
}

extension SwiftSyntaxNode {
    func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        switch self {
        case .statement:
            return SwiftStatement.suggestions(for: prefix)
        case .declaration:
            return []
        case .identifier:
            return SwiftIdentifier.suggestions(for: prefix)
        case .pattern:
            return SwiftPattern.suggestions(for: prefix)
        case .expression:
            return SwiftExpression.suggestions(for: prefix)
        case .binaryOperator:
            return SwiftBinaryOperator.suggestions(for: prefix)
        }
    }
}


