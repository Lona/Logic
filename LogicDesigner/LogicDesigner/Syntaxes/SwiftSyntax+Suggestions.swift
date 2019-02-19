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

extension SwiftIdentifier {
    static var suggestionCategories: [LogicSuggestionCategory] {
        let variables = LogicSuggestionCategory(
            title: "Variables",
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

extension SwiftStatement {
    static var suggestionCategories: [LogicSuggestionCategory] {
        let ifCondition = SwiftSyntaxNode.statement(
            SwiftStatement.branch(
                SwiftBranch(
                    id: NSUUID().uuidString,
                    condition: id("value"),
                    block: SwiftList<SwiftStatement>.empty)))

        let forLoop = SwiftSyntaxNode.statement(
            SwiftStatement.loop(
                SwiftLoop(
                    pattern: id("item"),
                    expression: id("array"),
                    block: SwiftList<SwiftStatement>.empty,
                    id: NSUUID().uuidString)))

        let statements = LogicSuggestionCategory(
            title: "Statements",
            items: [
                LogicSuggestionItem(title: "Condition (If)", node: ifCondition),
                LogicSuggestionItem(title: "Loop (For)", node: forLoop)
            ]
        )

        return Array([[statements], SwiftIdentifier.suggestionCategories].joined())
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
        }
    }
}


