//
//  SwiftSyntax+Documentation.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 3/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

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

