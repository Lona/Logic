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

protocol LogicTextEditable {
    var uuid: SwiftUUID { get }
    var textElements: [LogicEditorText] { get }
    func find(id: SwiftUUID) -> SwiftSyntaxNode?
}

extension SwiftIdentifier: LogicTextEditable {
    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return id == uuid ? SwiftSyntaxNode.identifier(self) : nil
    }

    var uuid: SwiftUUID { return id }

    var textElements: [LogicEditorText] {
        return [LogicEditorText.dropdown(id, string, Colors.editableText)]
    }
}

extension SwiftStatement: LogicTextEditable {
    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        if id == uuid {
            return SwiftSyntaxNode.statement(self)
        }

        switch self {
        case .branch(let branch):
            return nil
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
        default:
            return []
        }
    }
}

extension SwiftSyntaxNode {
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
}
