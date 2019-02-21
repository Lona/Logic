//
//  SwiftSyntax+TextElements.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension SwiftIdentifier {
    var formatted: LogicEditorFormatCommand {
        return .element(LogicEditorElement.dropdown(id, string, Colors.editableText))
    }
}

extension SwiftExpression {
    var formatted: LogicEditorFormatCommand {
        switch self {
        case .identifierExpression(let value):
            return value.identifier.formatted
        case .binaryExpression(let value):
            return .concat {
                [
                    value.left.formatted,
                    .element(LogicEditorElement.text(value.op)),
                    value.right.formatted
                ]
            }
        }
    }
}

extension SwiftStatement {
    var formatted: LogicEditorFormatCommand {
        switch self {
        case .loop(let loop):
            return .concat {
                [
                    .element(LogicEditorElement.dropdown(loop.id, "For", NSColor.black)),
                    loop.pattern.formatted,
                    .element(LogicEditorElement.text("in")),
                    loop.expression.formatted,
                ]
            }
        case .branch(let branch):
            var statements = branch.block.map { $0.formatted }
            statements.append(
                .element(LogicEditorElement.dropdown("???", "", NSColor.systemGray))
            )
            return .concat {
                [
                    .element(LogicEditorElement.dropdown(branch.id, "If", NSColor.black)),
                    branch.condition.formatted,
                    .indent {
                        .concat {
                            [
                                .hardLine,
                                .join(with: .hardLine) { statements }
                            ]
                        }
                    }
                ]
            }
        default:
            return .hardLine
        }
    }
}

extension SwiftSyntaxNode {
    var formatted: LogicEditorFormatCommand {
        switch self {
        case .statement(let value):
            return value.formatted
        case .declaration:
            return .hardLine
        case .identifier(let value):
            return value.formatted
        case .expression(let value):
            return value.formatted
        }
    }
}
