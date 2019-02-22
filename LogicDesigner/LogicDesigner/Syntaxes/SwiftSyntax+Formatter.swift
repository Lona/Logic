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
            return .concat {
                [
                    .element(LogicEditorElement.dropdown(branch.id, "If", NSColor.black)),
                    branch.condition.formatted,
                    .indent {
                        .concat {
                            [
                                .hardLine,
                                .join(with: .hardLine) {
                                    branch.block.map { $0.formatted }
                                }
                            ]
                        }
                    }
                ]
            }
        case .placeholderStatement(let value):
            return .element(LogicEditorElement.dropdown(value.id, "", Colors.editableText))
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
            fatalError("Handle declarations")
        case .identifier(let value):
            return value.formatted
        case .expression(let value):
            return value.formatted
        }
    }

    var formattedElementRange: Range<Int>? {
        let startId = self.uuid
        let endId = self.lastNode.uuid

        let elements = formatted.elements

        if let startIndex = elements.firstIndex(where: { $0.syntaxNodeID == startId }),
            let endIndex = elements.firstIndex(where: { $0.syntaxNodeID == endId }) {
            return Range(startIndex...endIndex)
        }

        return nil
    }

    func node(atFormattedElementIndex index: Int) -> SwiftSyntaxNode? {
        let elements = formatted.elements

//        guard index < elements.count else { return nil }

        if let id = elements[index].syntaxNodeID {
            return find(id: id)
        } else {
            return nil
        }
    }
}
