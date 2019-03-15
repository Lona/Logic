//
//  SwiftSyntax+TextElements.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public extension LGCIdentifier {
    public var formatted: FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(id, string, Colors.editableText))
    }
}

public extension LGCPattern {
    public var formatted: FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(id, name, Colors.editableText))
    }
}

public extension LGCBinaryOperator {
    public var formatted: FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(uuid, displayText, Colors.text))
    }
}

public extension LGCFunctionCallArgument {
    public var formatted: FormatterCommand<LogicElement> {
        return .concat {
            [
                .element(.text(self.label + " :")),
                self.expression.formatted
            ]
        }
    }
}

public extension LGCExpression {
    public var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .identifierExpression(let value):
            return value.identifier.formatted
        case .binaryExpression(let value):
            switch value.op {
            case .setEqualTo:
                return .concat {
                    [
                        value.left.formatted,
                        .element(.text("=")),
                        value.right.formatted
                    ]
                }
            default:
                return .concat {
                    [
                        value.left.formatted,
                        value.op.formatted,
                        value.right.formatted
                    ]
                }
            }
        case .functionCallExpression(let value):
            return .concat {
                [
                    value.expression.formatted,
                    .element(.text("(")),
                    .indent {
                        .concat {
                            [
                                .line,
                                .join(with: .concat {[.element(.text(",")), .line]}) {
                                    value.arguments.map { $0.formatted }
                                }
                            ]
                        }
                    },
                    .element(.text(")"))
                ]
            }
        }
    }
}

public extension LGCStatement {
    public var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .loop(let loop):
            return .concat {
                [
                    .element(LogicElement.dropdown(loop.id, "For", NSColor.black)),
                    loop.pattern.formatted,
                    .element(LogicElement.text("in")),
                    loop.expression.formatted,
                ]
            }
        case .branch(let branch):
            return .concat {
                [
                    .element(LogicElement.dropdown(branch.id, "If", NSColor.black)),
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
            return .element(LogicElement.dropdown(value, "", Colors.editableText))
        case .expressionStatement(let value):
            return value.expression.formatted
        default:
            return .hardLine
        }
    }
}


public extension LGCProgram {
    public var formatted: FormatterCommand<LogicElement> {
        return .join(with: .hardLine) {
            self.block.map { $0.formatted }
        }
    }
}


public extension LGCSyntaxNode {
    public var formatted: FormatterCommand<LogicElement> {
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
        case .program(let value):
            return value.formatted
        }
    }

    public func elementRange(for targetID: UUID) -> Range<Int>? {
        let topNode = topNodeWithEqualElements(as: targetID)
        let topNodeFormattedElements = topNode.formatted.elements

        guard let topFirstFocusableIndex = topNodeFormattedElements.firstIndex(where: { $0.syntaxNodeID != nil }) else { return nil }

        guard let firstIndex = formatted.elements.firstIndex(where: { formattedElement in
            guard let id = formattedElement.syntaxNodeID else { return false }
            return id == topNodeFormattedElements[topFirstFocusableIndex].syntaxNodeID
        }) else { return nil }

        let lastIndex = firstIndex + (topNodeFormattedElements.count - topFirstFocusableIndex - 1)

        return firstIndex..<lastIndex
    }

    public func topNodeWithEqualElements(as targetID: UUID) -> LGCSyntaxNode {
        let elementPath = uniqueElementPathTo(id: targetID)

        return elementPath[elementPath.count - 1]
    }

    public func uniqueElementPathTo(id targetID: UUID) -> [LGCSyntaxNode] {
        guard let pathToTarget = pathTo(id: targetID), pathToTarget.count > 0 else {
            fatalError("Node not found")
        }

        let (_, uniquePath): (min: Int, path: [LGCSyntaxNode]) = pathToTarget
            .reduce((min: Int.max, path: []), { result, next in
                let formattedElements = next.formatted.elements
                if formattedElements.count < result.min {
                    return (formattedElements.count, result.path + [next])
                } else {
                    return result
                }
            })

        return uniquePath
    }
}
