//
//  SwiftSyntax+TextElements.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public extension LGCIdentifier {
    var formatted: FormatterCommand<LogicElement> {
        if isPlaceholder {
            return .element(LogicElement.dropdown(id, string, .placeholder))
        }

        return .element(LogicElement.dropdown(id, string, .variable))
    }
}

public extension LGCPattern {
    var formatted: FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(id, name, .variable))
    }
}

public extension LGCBinaryOperator {
    var formatted: FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(uuid, displayText, .source))
    }
}

public extension LGCLiteral {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .none:
            return .element(.text("none"))
        case .boolean(let value):
            return .element(LogicElement.dropdown(value.id, value.value.description, .variable))
        case .number(let value):
            let formatted = value.value.description.replacingOccurrences(of: ".0", with: "")
            return .element(LogicElement.dropdown(value.id, formatted, .variable))
        case .string(let value):
            return .element(LogicElement.dropdown(value.id, "\"" + value.value + "\"", .variable))
        case .color(let value):
            return .element(LogicElement.dropdown(value.id, value.value.description, .variable))
        }
    }
}

public extension LGCFunctionCallArgument {
    var formatted: FormatterCommand<LogicElement> {
        return .concat {
            [
                .element(.text(self.label + " :")),
                self.expression.formatted
            ]
        }
    }
}

public extension LGCFunctionParameterDefaultValue {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .value(let value):
            return .concat {
                [
                    .element(LogicElement.dropdown(value.id, "default value", .source)),
                    value.expression.formatted
                ]
            }
        case .none(let value):
            return .element(LogicElement.dropdown(value, "no default", .source))
        }
    }
}

public extension LGCFunctionParameter {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        case .parameter(let value):
            func defaultValue() -> FormatterCommand<LogicElement> {
                switch value.annotation {
                case .typeIdentifier(let annotation):
                    if annotation.identifier.isPlaceholder {
                        return .element(.text("no default"))
                    }
                    return value.defaultValue.formatted
                case .functionType:
                    return value.defaultValue.formatted
                case .placeholder:
                    return .element(.text("no default"))
                }
            }

            return .concat {
                [
                    // Always select the parent node instead of the name
                    .element(LogicElement.dropdown(value.id, value.localName.name, .variable)),
//                    value.localName.formatted,
                    .element(.text("of type")),
                    value.annotation.formatted,
                    .element(.text("with")),
                    defaultValue()
                ]
            }
        }
    }
}

public extension LGCEnumerationCase {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        case .enumerationCase(let value):
            return .concat {
                [
                    // Always select the parent node instead of the name
                    .element(LogicElement.dropdown(value.id, value.name.name, .variable)),
                    .element(.text("with data")),
                    .join(with: .concat {[.element(.text(",")), .line]}) {
                        value.associatedValueTypes.map { $0.formatted }
                    }
                ]
            }
        }
    }
}

public extension LGCTypeAnnotation {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .typeIdentifier(let value):
            switch value.genericArguments {
            case .empty:
                return value.identifier.formatted
            case .next(.placeholder, _):
                return value.identifier.formatted
            case .next:
                return .concat {
                    [
                        value.identifier.formatted,
                        .element(.text("(")),
                        .join(with: .concat {[.element(.text(",")), .line]}) {
                            value.genericArguments.map { $0.formatted }
                        },
                        .element(.text(")")),
                    ]
                }
            }
        case .functionType(let value):
            return .concat {
                [
                    .join(with: .concat {[.element(.text(",")), .line]}) {
                        value.argumentTypes.map { $0.formatted }
                    },
                    .element(.text("→")),
                    value.returnType.formatted
                ]
            }
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        }
    }
}

public extension LGCExpression {
    var formatted: FormatterCommand<LogicElement> {
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
        case .literalExpression(let value):
            return value.literal.formatted
        }
    }
}

public extension LGCStatement {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .loop(let loop):
            return .concat {
                [
                    .element(LogicElement.dropdown(loop.id, "For", .source)),
                    loop.pattern.formatted,
                    .element(LogicElement.text("in")),
                    loop.expression.formatted,
                ]
            }
        case .branch(let branch):
            return .concat {
                [
                    .element(LogicElement.dropdown(branch.id, "If", .source)),
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
            return .element(LogicElement.dropdown(value, "", .variable))
        case .expressionStatement(let value):
            return value.expression.formatted
        case .declaration(let value):
            return value.content.formatted
        }
    }
}

public extension LGCDeclaration {
    var formatted: FormatterCommand<LogicElement> {
        func parameters() -> FormatterCommand<LogicElement> {
            switch self {
            case .function(let value):
                switch value.parameters {
                case .next(.placeholder(let inner), _):
                    return .concat {
                        [
                            .element(.text("Parameters:")),
                            .element(LogicElement.dropdown(inner, "", .variable)),
                        ]
                    }
                default:
                    return .concat {
                        [
                            .element(.text("Parameters:")),
                            .indent {
                                .concat {
                                    [
                                        .hardLine,
                                        .join(with: .concat {[.hardLine]}) {
                                            value.parameters.map { param in param.formatted }
                                        }
                                    ]
                                }
                            }
                        ]
                    }
                }

            case .variable, .enumeration:
                fatalError("TODO")
            }
        }

        switch self {
        case .variable:
            return .element(.text("VARIABLE"))
        case .function(let value):
            return .concat {
                [
                    .element(LogicElement.dropdown(value.id, "Function", .source)),
                    value.name.formatted,
                    .indent {
                        .concat {
                            [
                                .hardLine,
                                parameters(),
                                .hardLine,
                                .element(.text("Returning")),
                                .line,
                                value.returnType.formatted,
                                .hardLine,
                                .element(.text("Body:")),
                                .indent {
                                    .concat {
                                        [
                                            .hardLine,
                                            .join(with: .hardLine) {
                                                value.block.map { $0.formatted }
                                            }
                                        ]
                                    }
                                }
                            ]
                        }
                    }
                ]
            }
        case .enumeration(let value):
            return .concat {
                [
                    .element(LogicElement.dropdown(value.id, "Enumeration", .source)),
                    value.name.formatted,
                    .element(.text("with cases:")),
                    .indent {
                        .concat {
                            [
                                .hardLine,
                                .join(with: .hardLine) {
                                    value.cases.map { $0.formatted }
                                }
                            ]
                        }
                    }
                ]
            }
        }
    }
}

public extension LGCTopLevelParameters {
    var formatted: FormatterCommand<LogicElement> {
        return .join(with: .hardLine) {
            self.parameters.map { $0.formatted }
        }
    }
}


public extension LGCProgram {
    var formatted: FormatterCommand<LogicElement> {
        return .join(with: .hardLine) {
            self.block.map { $0.formatted }
        }
    }
}

public extension LGCSyntaxNode {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .statement(let value):
            return value.formatted
        case .declaration(let value):
            return value.formatted
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
        case .functionParameter(let value):
            return value.formatted
        case .typeAnnotation(let value):
            return value.formatted
        case .functionParameterDefaultValue(let value):
            return value.formatted
        case .literal(let value):
            return value.formatted
        case .topLevelParameters(let value):
            return value.formatted
        case .enumerationCase(let value):
            return value.formatted
        }
    }

    func elementRange(for targetID: UUID) -> Range<Int>? {
        let topNode = topNodeWithEqualElements(as: targetID)
        let topNodeFormattedElements = topNode.formatted.elements

        guard let topFirstFocusableIndex = topNodeFormattedElements.firstIndex(where: { $0.syntaxNodeID != nil }) else { return nil }

        guard let firstIndex = formatted.elements.firstIndex(where: { formattedElement in
            guard let id = formattedElement.syntaxNodeID else { return false }
            return id == topNodeFormattedElements[topFirstFocusableIndex].syntaxNodeID
        }) else { return nil }

        let lastIndex = firstIndex + (topNodeFormattedElements.count - topFirstFocusableIndex - 1)

        return firstIndex..<lastIndex + 1
    }

    func topNodeWithEqualElements(as targetID: UUID) -> LGCSyntaxNode {
        let elementPath = uniqueElementPathTo(id: targetID)

        return elementPath[elementPath.count - 1]
    }

    // Returns the top-most node containing the given range.
    //
    // Returns nil if a non-focusable node selected. This is most likely due to temporarily
    // invalid selection range after a modification, e.g. after a deletion but before the selection range
    // has been updated
    func topNodeWithEqualRange(as range: Range<Int>) -> LGCSyntaxNode? {
        let elements = formatted.elements
        let clampedRange = range.clamped(to: elements.startIndex..<elements.endIndex)
        guard let firstId = elements[clampedRange].first?.syntaxNodeID else {
            return nil
        }

        let uniquePath = uniqueElementPathTo(id: firstId).reversed()

        for node in uniquePath {
            if node.formatted.elements.count >= range.count {
                return node
            }
        }

        return nil
    }

    func uniqueElementPathTo(id targetID: UUID) -> [LGCSyntaxNode] {
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
