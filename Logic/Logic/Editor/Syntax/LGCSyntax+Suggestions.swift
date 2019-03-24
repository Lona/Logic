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
    return LGCIdentifier(id: UUID(), string: string)
}

private func idExpression(_ string: String) -> LGCExpression {
    return LGCExpression.identifierExpression(
        id: UUID(),
        identifier: LGCIdentifier(id: UUID(), string: string)
    )
}

public extension LGCIdentifier {
    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "bar",
                category: "Variables".uppercased(),
                node: LGCSyntaxNode.identifier(LGCIdentifier(id: UUID(), string: "bar"))
            ),
            LogicSuggestionItem(
                title: "foo",
                category: "Variables".uppercased(),
                node: LGCSyntaxNode.identifier(LGCIdentifier(id: UUID(), string: "foo"))
            )
        ]

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCTypeAnnotation {
    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "Boolean",
                category: "Types".uppercased(),
                node: LGCSyntaxNode.typeAnnotation(
                    LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "Boolean")
                    )
                )
            ),
            LogicSuggestionItem(
                title: "Number",
                category: "Types".uppercased(),
                node: LGCSyntaxNode.typeAnnotation(
                    LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "Number")
                    )
                )
            ),
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
                node: LGCSyntaxNode.pattern(LGCPattern(id: UUID(), name: prefix)),
                disabled: prefix.isEmpty
            )
        ]

        return items
    }
}

public extension LGCFunctionParameter {
    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "Parameter name: \(prefix)",
                category: "Function Parameter".uppercased(),
                node: LGCSyntaxNode.functionParameter(
                    LGCFunctionParameter.parameter(
                        id: UUID(),
                        externalName: nil,
                        localName: LGCPattern(id: UUID(), name: prefix),
                        annotation: LGCTypeAnnotation.typeIdentifier(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "type")
                        ),
                        defaultValue: nil
                    )
                ),
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
            LGCBinaryOperator.isEqualTo(id: UUID()),
            LGCBinaryOperator.isNotEqualTo(id: UUID()),
            LGCBinaryOperator.isGreaterThan(id: UUID()),
            LGCBinaryOperator.isGreaterThanOrEqualTo(id: UUID()),
            LGCBinaryOperator.isLessThan(id: UUID()),
            LGCBinaryOperator.isLessThanOrEqualTo(id: UUID())
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
                    left: LGCExpression.identifierExpression(id: UUID(), identifier: id("variable")),
                    right: LGCExpression.identifierExpression(id: UUID(), identifier: id("value")),
                    op: .setEqualTo(id: UUID()),
                    id: UUID()
                )
            )
        )
    }

    static var comparisonSuggestionItem: LogicSuggestionItem {
        return LogicSuggestionItem(
            title: "Comparison",
            category: "Expressions".uppercased(),
            node: LGCSyntaxNode.expression(
                LGCExpression.binaryExpression(
                    left: LGCExpression.identifierExpression(id: UUID(), identifier: id("left")),
                    right: LGCExpression.identifierExpression(id: UUID(), identifier: id("right")),
                    op: .isEqualTo(id: UUID()),
                    id: UUID()
                )
            )
        )
    }

    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            comparisonSuggestionItem,
            assignmentSuggestionItem
        ]

        return items.titleContains(prefix: prefix) + LGCIdentifier.suggestions(for: prefix)
    }
}

public extension LGCDeclaration {
    static var functionSuggestionItem: LogicSuggestionItem {
        return LogicSuggestionItem(
            title: "Function",
            category: "Declarations".uppercased(),
            node: LGCSyntaxNode.declaration(
                LGCDeclaration.function(
                    id: UUID(),
                    name: LGCPattern(id: UUID(), name: "name"),
                    returnType: LGCTypeAnnotation.typeIdentifier(id: UUID(), identifier: LGCIdentifier(id: UUID(), string: "Void")),
                    parameters: .next(LGCFunctionParameter.placeholder(id: UUID()), .empty),
                    block: .empty
                )
            )
        )
    }

    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            functionSuggestionItem
        ]

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCStatement {
    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let ifCondition = LGCSyntaxNode.statement(
            LGCStatement.branch(
                id: UUID(),
                condition: idExpression("condition"),
                block: LGCList<LGCStatement>.next(
                    LGCStatement.placeholderStatement(id: UUID()),
                    .empty
                )
            )
        )

        let forLoop = LGCSyntaxNode.statement(
            LGCStatement.loop(
                pattern: LGCPattern(id: UUID(), name: "item"),
                expression: idExpression("array"),
                block: LGCList<LGCStatement>.empty,
                id: UUID()
            )
        )

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
            LGCExpression.assignmentSuggestionItem,
            LGCDeclaration.functionSuggestionItem
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
            return LGCDeclaration.suggestions(for: prefix)
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
        case .functionParameter:
            return LGCFunctionParameter.suggestions(for: prefix)
        case .typeAnnotation:
            return LGCTypeAnnotation.suggestions(for: prefix)
        }
    }
}


