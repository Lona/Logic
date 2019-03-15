//
//  SwiftSyntax+Suggestions.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public struct LogicSuggestionItem {
    public init(title: String, category: String, node: LGCSyntaxNode, disabled: Bool = false) {
        self.title = title
        self.category = category
        self.node = node
        self.disabled = disabled
    }

    public var title: String
    public var category: String
    public var node: LGCSyntaxNode
    public var disabled: Bool

    func titleContains(prefix: String) -> Bool {
        if prefix.isEmpty { return true }

        return title.lowercased().contains(prefix.lowercased())
    }
}

extension Array where Element == LogicSuggestionItem {
    func titleContains(prefix: String) -> [Element] {
        return self.filter { item in item.titleContains(prefix: prefix) }
    }
}

public struct LogicSuggestionCategory {
    public var title: String
    public var items: [LogicSuggestionItem]

    public var suggestionListItems: [SuggestionListItem] {
        let sectionHeader = SuggestionListItem.sectionHeader(title)
        let rows = items.map { SuggestionListItem.row($0.title, $0.disabled) }
        return Array([[sectionHeader], rows].joined())
    }
}

private func id(_ string: String) -> LGCIdentifier {
    return LGCIdentifier(id: NSUUID().uuidString, string: string)
}

private func idExpression(_ string: String) -> LGCExpression {
    return LGCExpression.identifierExpression(
        LGCIdentifierExpression(
            id: NSUUID().uuidString,
            identifier: LGCIdentifier(id: NSUUID().uuidString, string: string)))
}

public extension LGCIdentifier {
    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "bar",
                category: "Variables".uppercased(),
                node: LGCSyntaxNode.identifier(LGCIdentifier(id: NSUUID().uuidString, string: "bar"))
            ),
            LogicSuggestionItem(
                title: "foo",
                category: "Variables".uppercased(),
                node: LGCSyntaxNode.identifier(LGCIdentifier(id: NSUUID().uuidString, string: "foo"))
            )
        ]

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCPattern {
    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "Variable name: \(prefix)",
                category: "Pattern".uppercased(),
                node: LGCSyntaxNode.pattern(LGCPattern(id: NSUUID().uuidString, name: prefix)),
                disabled: prefix.isEmpty
            )
        ]

        return items
    }
}

public extension LGCBinaryOperator {
    public var displayText: String {
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

    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let operatorNodes = [
            LGCBinaryOperator.isEqualTo(LGCIsEqualTo(id: NSUUID().uuidString)),
            LGCBinaryOperator.isNotEqualTo(LGCIsNotEqualTo(id: NSUUID().uuidString)),
            LGCBinaryOperator.isGreaterThan(LGCIsGreaterThan(id: NSUUID().uuidString)),
            LGCBinaryOperator.isGreaterThanOrEqualTo(LGCIsGreaterThanOrEqualTo(id: NSUUID().uuidString)),
            LGCBinaryOperator.isLessThan(LGCIsLessThan(id: NSUUID().uuidString)),
            LGCBinaryOperator.isLessThanOrEqualTo(LGCIsLessThanOrEqualTo(id: NSUUID().uuidString)),
        ]

        return operatorNodes.map { node in
            LogicSuggestionItem(
                title: node.displayText,
                category: "Operators".uppercased(),
                node: LGCSyntaxNode.binaryOperator(node)
            )
        }.titleContains(prefix: prefix)
    }
}

public extension LGCExpression {
    static var assignmentSuggestionItem: LogicSuggestionItem {
        return LogicSuggestionItem(
            title: "Assignment",
            category: "Expressions".uppercased(),
            node: LGCSyntaxNode.expression(
                LGCExpression.binaryExpression(
                    LGCBinaryExpression(
                        left: LGCExpression.identifierExpression(
                            LGCIdentifierExpression(id: NSUUID().uuidString, identifier: id("variable"))),
                        right: LGCExpression.identifierExpression(
                            LGCIdentifierExpression(id: NSUUID().uuidString, identifier: id("value"))),
                        op: .setEqualTo(LGCSetEqualTo(id: NSUUID().uuidString)),
                        id: NSUUID().uuidString))))
    }

    static var comparisonSuggestionItem: LogicSuggestionItem {
        return LogicSuggestionItem(
            title: "Comparison",
            category: "Expressions".uppercased(),
            node: LGCSyntaxNode.expression(
                LGCExpression.binaryExpression(
                    LGCBinaryExpression(
                        left: LGCExpression.identifierExpression(
                            LGCIdentifierExpression(id: NSUUID().uuidString, identifier: id("left"))),
                        right: LGCExpression.identifierExpression(
                            LGCIdentifierExpression(id: NSUUID().uuidString, identifier: id("right"))),
                        op: .isEqualTo(LGCIsEqualTo(id: NSUUID().uuidString)),
                        id: NSUUID().uuidString))))
    }

    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            comparisonSuggestionItem,
            assignmentSuggestionItem
        ]

        return items.titleContains(prefix: prefix) + LGCIdentifier.suggestions(for: prefix)
    }
}

public extension LGCStatement {
    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let ifCondition = LGCSyntaxNode.statement(
            LGCStatement.branch(
                LGCBranch(
                    id: NSUUID().uuidString,
                    condition: idExpression("condition"),
                    block: LGCList<LGCStatement>.next(
                        LGCStatement.placeholderStatement(
                            LGCPlaceholderStatement(id: NSUUID().uuidString)
                        ),
                        .empty
                    )
                )
            )
        )

        let forLoop = LGCSyntaxNode.statement(
            LGCStatement.loop(
                LGCLoop(
                    pattern: LGCPattern(id: NSUUID().uuidString, name: "item"),
                    expression: idExpression("array"),
                    block: LGCList<LGCStatement>.empty,
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
            LGCExpression.assignmentSuggestionItem
        ]

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCProgram {
    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        return LGCStatement.suggestions(for: prefix)
    }
}

public extension LGCSyntaxNode {
    public func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        switch self {
        case .statement:
            return LGCStatement.suggestions(for: prefix)
        case .declaration:
            return []
        case .identifier:
            return LGCIdentifier.suggestions(for: prefix)
        case .pattern:
            return LGCPattern.suggestions(for: prefix)
        case .expression:
            return LGCExpression.suggestions(for: prefix)
        case .binaryOperator:
            return LGCBinaryOperator.suggestions(for: prefix)
        case .program:
            return LGCProgram.suggestions(for: prefix)
        }
    }
}

