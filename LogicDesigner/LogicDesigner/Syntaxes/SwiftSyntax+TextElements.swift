//
//  SwiftSyntax+TextElements.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension SwiftIdentifier {
    var textElements: [LogicEditorTextElement] {
        return [LogicEditorTextElement.dropdown(id, string, Colors.editableText)]
    }
}

extension SwiftExpression {
    var textElements: [LogicEditorTextElement] {
        switch self {
        case .identifierExpression(let value):
            return value.identifier.textElements
        case .binaryExpression(let value):
            return Array([
                value.left.textElements,
                [LogicEditorTextElement.unstyled(value.op)],
                value.right.textElements
                ].joined())
        }
    }
}

extension SwiftStatement {
    var textElements: [LogicEditorTextElement] {
        switch self {
        case .loop(let loop):
            return Array([
                [LogicEditorTextElement.dropdown(loop.id, "For", NSColor.black)],
                loop.pattern.textElements,
                [LogicEditorTextElement.unstyled("in")],
                loop.expression.textElements
                ].joined())
        case .branch(let branch):
            return Array([
                [LogicEditorTextElement.dropdown(branch.id, "If", NSColor.black)],
                branch.condition.textElements,
                [LogicEditorTextElement.dropdown("???", "", NSColor.systemGray)]
                ].joined())
        default:
            return []
        }
    }
}

extension SwiftSyntaxNode /*: LogicTextEditable */ {
    var textElements: [LogicEditorTextElement] {
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
}
