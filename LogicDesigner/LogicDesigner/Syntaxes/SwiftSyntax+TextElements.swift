//
//  SwiftSyntax+TextElements.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension SwiftIdentifier {
    var textElements: [LogicEditorText] {
        return [LogicEditorText.dropdown(id, string, Colors.editableText)]
    }
}

extension SwiftStatement {
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
}

extension SwiftSyntaxNode /*: LogicTextEditable */ {
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
