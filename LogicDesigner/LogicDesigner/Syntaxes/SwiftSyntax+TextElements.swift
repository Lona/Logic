//
//  SwiftSyntax+TextElements.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension SwiftIdentifier {
    var textElements: [LogicEditorElement] {
        return [LogicEditorElement.dropdown(id, string, Colors.editableText)]
    }

    var formatted: LogicEditorFormatCommand {
        return .element(LogicEditorElement.dropdown(id, string, Colors.editableText))
    }
}

extension SwiftExpression {
    var textElements: [LogicEditorElement] {
        switch self {
        case .identifierExpression(let value):
            return value.identifier.textElements
        case .binaryExpression(let value):
            return Array([
                value.left.textElements,
                [LogicEditorElement.text(value.op)],
                value.right.textElements
                ].joined())
        }
    }

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
    var textElements: [LogicEditorElement] {
        switch self {
        case .loop(let loop):
            return Array([
                [LogicEditorElement.dropdown(loop.id, "For", NSColor.black)],
                loop.pattern.textElements,
                [LogicEditorElement.text("in")],
                loop.expression.textElements
                ].joined())
        case .branch(let branch):
            return Array([
                [LogicEditorElement.dropdown(branch.id, "If", NSColor.black)],
                branch.condition.textElements,
                [LogicEditorElement.dropdown("???", "", NSColor.systemGray)]
                ].joined())
        default:
            return []
        }
    }

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
            return .concat {
                [
                    .element(LogicEditorElement.dropdown(branch.id, "If", NSColor.black)),
                    branch.condition.formatted,
                    .indent {
                        .concat {
                            [
                                .hardLine,
                                .element(LogicEditorElement.dropdown("???", "", NSColor.systemGray))
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
    var textElements: [LogicEditorElement] {
        switch self {
        case .statement(let value):
            return value.textElements
        case .declaration:
            return []
        case .identifier(let value):
            return value.textElements
        case .expression(let value):
            return value.textElements
        }
    }

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
