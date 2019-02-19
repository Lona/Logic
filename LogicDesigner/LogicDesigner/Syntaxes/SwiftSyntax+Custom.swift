//
//  SwiftNativeTypes.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public typealias SwiftString = String
public typealias SwiftUUID = String

private func id(_ string: String) -> SwiftIdentifier {
    return SwiftIdentifier(id: NSUUID().uuidString, string: string)
}

protocol LogicTextEditable {
    var uuid: SwiftUUID { get }
    var textElements: [LogicEditorText] { get }
    func find(id: SwiftUUID) -> SwiftSyntaxNode?
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> Self
    static var suggestionCategories: [LogicSuggestionCategory] { get }
}

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

    var textElements: [LogicEditorText] {
        return [LogicEditorText.dropdown(id, string, Colors.editableText)]
    }

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

extension SwiftStatement: LogicTextEditable {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftStatement {
        switch syntaxNode {
        case .statement(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .branch(let branch):
                return .branch(SwiftBranch(
                    id: NSUUID().uuidString,
                    condition: branch.condition.replace(id: id, with: syntaxNode),
                    block: SwiftList<SwiftStatement>.empty))
            case .decl(let decl):
                return self
            case .loop(let loop):
                return SwiftStatement.loop(
                    SwiftLoop(
                        pattern: loop.pattern.replace(id: id, with: syntaxNode),
                        expression: loop.expression.replace(id: id, with: syntaxNode),
                        block: SwiftList<SwiftStatement>.empty,
                        id: NSUUID().uuidString))
            }
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        if id == uuid {
            return SwiftSyntaxNode.statement(self)
        }

        switch self {
        case .branch(let branch):
            return branch.condition.find(id: id)
        case .decl(let decl):
            return nil
        case .loop(let loop):
            return loop.expression.find(id: id) ?? loop.pattern.find(id: id)
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
        }
    }

    var textElements: [LogicEditorText] {
        switch self {
        case .loop(let loop):
            return Array([
                [LogicEditorText.dropdown(loop.id, "For", NSColor.black)],
                loop.pattern.textElements,
                [LogicEditorText.unstyled("in")],
                loop.expression.textElements
            ].joined())
        case .branch(let branch):
            return Array([
                [LogicEditorText.dropdown(branch.id, "If", NSColor.black)],
                branch.condition.textElements
                ].joined())
        default:
            return []
        }
    }

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

extension SwiftSyntaxNode /*: LogicTextEditable */ {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftSyntaxNode {
        switch self {
        case .statement(let statement):
            return .statement(statement.replace(id: id, with: syntaxNode))
        case .declaration(let declaration):
            return self
        case .identifier(let identifier):
            return .identifier(identifier.replace(id: id, with: syntaxNode))
        }
    }

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

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        switch self {
        case .statement(let statement):
            return statement.find(id: id)
        case .declaration(let declaration):
            return nil
        case .identifier(let identifier):
            return identifier.find(id: id)
        }
    }

    var textElements: [LogicEditorText] {
        switch self {
        case .statement(let statement):
            return statement.textElements
        case .declaration(let declaration):
            return []
        case .identifier(let identifier):
            return identifier.textElements
        }
    }
}
