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

extension SwiftPattern {
    var formatted: LogicEditorFormatCommand {
        return .element(LogicEditorElement.dropdown(id, name, Colors.editableText))
    }
}

extension SwiftBinaryOperator {
    var formatted: LogicEditorFormatCommand {
        switch self {
        case .isEqualTo(let value):
            return .element(LogicEditorElement.dropdown(value.id, "is equal to", Colors.text))
        case .isNotEqualTo(let value):
            return .element(LogicEditorElement.dropdown(value.id, "is not equal to", Colors.text))
        default:
            return .element(LogicEditorElement.text("placeholder"))
        }
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
                    value.op.formatted,
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
        case .expressionStatement(let value):
            return value.expression.formatted
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
        case .pattern(let value):
            return value.formatted
        case .binaryOperator(let value):
            return value.formatted
        case .expression(let value):
            return value.formatted
        }
    }

    func elementRange(for targetID: SwiftUUID) -> Range<Int>? {
        let topNode = topNodeWithEqualElement(as: targetID)
        let topNodeFormattedElements = topNode.formatted.elements

        guard let topFirstFocusableIndex = topNodeFormattedElements.firstIndex(where: { $0.syntaxNodeID != nil }) else { return nil }

        guard let firstIndex = formatted.elements.firstIndex(where: { formattedElement in
            guard let id = formattedElement.syntaxNodeID else { return false }
            return id == topNodeFormattedElements[topFirstFocusableIndex].syntaxNodeID
        }) else { return nil }

        let lastIndex = firstIndex + (topNodeFormattedElements.count - topFirstFocusableIndex - 1)

        return firstIndex..<lastIndex
    }

    func topNodeWithEqualElement(as targetID: SwiftUUID) -> SwiftSyntaxNode {
        guard let pathToTarget = pathTo(id: targetID) else {
            fatalError("Node not found")
        }

        let allFormattedElements = pathToTarget.map({ $0.formatted.elements })
        guard let minimumElementCount = allFormattedElements.map({ $0.count }).min(),
            let topIndex = allFormattedElements.firstIndex(where: { $0.count == minimumElementCount })
            else { fatalError("Bad index logic") }

        return pathToTarget[topIndex]
    }
}
