//
//  SwiftSyntax+Documentation.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 3/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension SwiftExpression {
    func documentation(for prefix: String) -> RichText {
        switch self {
        case .binaryExpression(let value):
            switch value.op {
            case .setEqualTo:
                let blocks: [RichText.BlockElement] = [
                    .heading(.title) { "Assignment" },
                    .paragraph(
                        [
                            .text(.none) { "Use an assignment expression to update the value of an existing variable." }
                        ]
                    )
                ]

                return RichText(blocks: blocks)
            default:
                let blocks: [RichText.BlockElement] = [
                    .heading(.title) { "Comparison" },
                    .paragraph(
                        [
                            .text(.none) { "Compare two variables." }
                        ]
                    )
                ]

                return RichText(blocks: blocks)
            }
        default:
            return RichText(blocks: [])
        }
    }
}

extension SwiftStatement {
    func documentation(for prefix: String) -> RichText {
        switch self {
        case .branch:
            let blocks: [RichText.BlockElement] = [
                .heading(.title) { "If condition" },
                .paragraph(
                    [
                        .text(.none) { "Conditions let you run different code depending on the current state of your app." }
                    ]
                ),
                .heading(.section) { "Example" },
                .paragraph(
                    [
                        .text(.none) { "Suppose our program has a variable " },
                        .text(.bold) { "age" },
                        .text(.none) { ", representing the current user's age. We might want to print a specific message depending on the value of age. We could use an " },
                        .text(.bold) { "if condition " },
                        .text(.none) { "to accomplish this:" }
                    ]
                ),
                .code(
                    SwiftSyntaxNode.statement(
                        SwiftStatement.branch(
                            SwiftBranch(
                                id: NSUUID().uuidString,
                                condition: SwiftExpression.identifierExpression(
                                    SwiftIdentifierExpression(
                                        id: NSUUID().uuidString,
                                        identifier: SwiftIdentifier(id: NSUUID().uuidString, string: "age")
                                    )
                                ),
                                block: SwiftList<SwiftStatement>.next(
                                    SwiftStatement.placeholderStatement(
                                        SwiftPlaceholderStatement(id: NSUUID().uuidString)
                                    ),
                                    .empty
                                )
                            )
                        )
                    )
                ),
                .paragraph(
                    [
                        .text(.none) { "If we also wanted to print a message for users under 18, we might be better off using an " },
                        .text(.link) { "if else statement" },
                        .text(.none) { "." }
                    ]
                )
            ]

            return RichText(blocks: blocks)
        case .loop:
            let blocks: [RichText.BlockElement] = [
                .heading(.title) { "For loop" },
                .paragraph(
                    [
                        .text(.none) { "Loops let you run the same code multiple times, once for each item in a sequence of items." }
                    ]
                )
            ]

            return RichText(blocks: blocks)
        default:
            return RichText(blocks: [])
        }
    }
}

extension SwiftSyntaxNode {
    func documentation(for prefix: String) -> RichText {
        return contents.documentation(for: prefix)
    }
}

