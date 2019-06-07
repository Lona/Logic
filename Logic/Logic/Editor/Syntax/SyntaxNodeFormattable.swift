//
//  SyntaxNodeFormattable.swift
//  Logic
//
//  Created by Devin Abbott on 6/4/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

protocol SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> { get }
}

fileprivate extension FormatterCommand where Element == LogicElement {
    var stringContents: String {
        return elements.reduce("", { (result, element) -> String in
            return result + element.value
        })
    }
}

extension LGCIdentifier: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        if isPlaceholder {
            return .element(LogicElement.dropdown(id, string, .placeholder))
        }

        return .element(LogicElement.dropdown(id, string, .variable))
    }
}

extension LGCPattern: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(id, name, .variable))
    }
}

extension LGCBinaryOperator: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(uuid, displayText, .source))
    }
}

extension LGCLiteral: SyntaxNodeFormattable {
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
        case .array(let value):
            return .concat(
                [
                    .element(.dropdown(value.id, "[", .variable)),
                    .indent(
                        .join(with: .concat([.element(.text(",")), .line])) {
                            value.value.map { $0.formatted }
                        }
                    ),
                    .element(.text("]")),
                ]
            )
        }
    }
}

extension LGCFunctionCallArgument: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        if let label = self.label {
            return .concat(
                [
                    .element(.text(label + " :")),
                    self.expression.formatted
                ]
            )
        } else {
            return self.expression.formatted
        }
    }
}

extension LGCFunctionParameterDefaultValue: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .value(let value):
            return .concat(
                [
                    .element(LogicElement.dropdown(value.id, "default value", .source)),
                    value.expression.formatted
                ]
            )
        case .none(let value):
            return .element(LogicElement.dropdown(value, "no default", .source))
        }
    }
}

extension LGCFunctionParameter: SyntaxNodeFormattable {
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

            return .concat(
                [
                    // Always select the parent node instead of the name
                    .element(LogicElement.dropdown(value.id, value.localName.name, .variable)),
                    //                    value.localName.formatted,
                    .element(.text("of type")),
                    value.annotation.formatted,
                    .element(.text("with")),
                    defaultValue()
                ]
            )
        }
    }
}

extension LGCGenericParameter: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        case .parameter(let value):
            return value.name.formatted
        }
    }
}

extension LGCEnumerationCase: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        case .enumerationCase(let value):
            return .concat(
                [
                    // Always select the parent node instead of the name
                    .element(LogicElement.dropdown(value.id, value.name.name, .variable)),
                    .element(.text("with data")),
                    .join(with: .concat([.element(.text(",")), .line])) {
                        value.associatedValueTypes.map { $0.formatted }
                    }
                ]
            )
        }
    }
}

extension LGCTypeAnnotation: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .typeIdentifier(let value):
            switch value.genericArguments {
            case .empty:
                return value.identifier.formatted
            case .next(.placeholder, _):
                return value.identifier.formatted
            case .next:
                return .concat(
                    [
                        value.identifier.formatted,
                        .element(.text("(")),
                        .join(with: .concat([.element(.text(",")), .line])) {
                            value.genericArguments.map { $0.formatted }
                        },
                        .element(.text(")")),
                    ]
                )
            }
        case .functionType(let value):
            return .concat(
                [
                    .join(with: .concat([.element(.text(",")), .line])) {
                        value.argumentTypes.map { $0.formatted }
                    },
                    .element(.text("→")),
                    value.returnType.formatted
                ]
            )
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        }
    }
}

extension LGCExpression: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .identifierExpression(let value):
            return value.identifier.formatted
        case .binaryExpression(let value):
            switch value.op {
            case .setEqualTo:
                return .concat(
                    [
                        value.left.formatted,
                        .element(.text("=")),
                        value.right.formatted
                    ]
                )
            default:
                return .concat(
                    [
                        value.left.formatted,
                        value.op.formatted,
                        value.right.formatted
                    ]
                )
            }
        case .functionCallExpression(let value):
            if value.expression.flattenedMemberExpression?.map({ $0.string }) == ["Optional", "value"] {
                return .concat(
                    [
                        .join(with: .concat([.element(.text(",")), .line])) {
                            value.arguments.map { $0.formatted }
                        }
                    ]
                )
            }

            if value.arguments.isEmpty {
                // TODO: We should still show () on non-enum calls, but right now we can't distinguish easily
                return value.expression.formatted

//                return .concat {
//                    [
//                        value.expression.formatted,
//                        .element(.text("()"))
//                    ]
//                }
            }

            return .concat(
                [
                    value.expression.formatted,
                    .element(.text("(")),
                    .indent(
                        .concat(
                            [
                                //                                .line,
                                .join(with: .concat([.element(.text(",")), .line])) {
                                    value.arguments.map { $0.formatted }
                                }
                            ]
                        )
                    ),
                    .element(.text(")"))
                ]
            )
        case .literalExpression(let value):
            return value.literal.formatted
        case .memberExpression(let value):
            //            let joined = FormatterCommand<LogicElement>.concat {
            //                [value.expression.formatted, .element(.text(".")), value.memberName.formatted]
            //            }

            let joined = value.memberName.formatted

            return .element(.dropdown(value.id, joined.stringContents, .variable))
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        }
    }
}

extension LGCStatement: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        switch self {
        case .loop(let loop):
            return .concat(
                [
                    .element(LogicElement.dropdown(loop.id, "For each", .source)),
                    loop.pattern.formatted,
                    .element(LogicElement.text("in")),
                    loop.expression.formatted,
                ]
            )
        case .branch(let branch):
            return .concat(
                [
                    .element(LogicElement.dropdown(branch.id, "If", .source)),
                    branch.condition.formatted,
                    .indent(
                        .concat(
                            [
                                .hardLine,
                                .join(with: .hardLine) {
                                    branch.block.map { $0.formatted }
                                }
                            ]
                        )
                    )
                ]
            )
        case .placeholderStatement(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        case .expressionStatement(let value):
            return value.expression.formatted
        case .declaration(let value):
            return value.content.formatted
        }
    }
}

extension LGCDeclaration: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        func genericParameters() -> FormatterCommand<LogicElement> {
            switch self {
            case .function(id: _, name: _, returnType: _, genericParameters: let genericParameters, parameters: _, block: _),
                 .enumeration(id: _, name: _, genericParameters: let genericParameters, cases: _),
                 .record(id: _, name: _, genericParameters: let genericParameters, declarations: _):
                if genericParameters.isEmpty {
                    return .empty
                } else {
                    return .concat(
                        [
                            .hardLine,
                            .element(.text("Generic type parameters:")),
                            .join(with: .concat([.element(.text(",")), .line])) {
                                genericParameters.map { param in param.formatted }
                            }
                        ]
                    )
                }
            case .variable, .namespace, .placeholder, .importDeclaration:
                fatalError("TODO")
            }
        }

        func parameters() -> FormatterCommand<LogicElement> {
            switch self {
            case .function(let value):
                switch value.parameters {
                case .next(.placeholder(let inner), _):
                    return .concat(
                        [
                            .element(.text("Parameters:")),
                            .element(LogicElement.dropdown(inner, "", .variable)),
                        ]
                    )
                default:
                    return .concat(
                        [
                            .element(.text("Parameters:")),
                            .indent(
                                .concat(
                                    [
                                        .hardLine,
                                        .join(with: .concat([.hardLine])) {
                                            value.parameters.map { param in param.formatted }
                                        }
                                    ]
                                )
                            )
                        ]
                    )
                }

            case .variable, .enumeration, .namespace, .placeholder:
                fatalError("TODO")
            }
        }

        switch self {
        case .variable(let value):
            var contents: [FormatterCommand<LogicElement>] = [
                .element(LogicElement.dropdown(value.id, "Let", .source)),
                value.name.formatted
            ]

            if let annotation = value.annotation {
                contents.append(.element(.text(":")))
                contents.append(annotation.formatted)

                if let initializer = value.initializer {
                    switch annotation {
                    case .typeIdentifier(id: _, identifier: let identifier, genericArguments: .empty) where identifier.isPlaceholder:
                        break
                    default:
                        contents.append(.element(.text("=")))
                        contents.append(initializer.formatted)
                    }
                }
            }

            return .concat(contents)
        case .function(let value):
            return .concat(
                [
                    .element(LogicElement.dropdown(value.id, "Function", .source)),
                    value.name.formatted,
                    .indent(
                        .concat(
                            [
                                genericParameters(),
                                .hardLine,
                                parameters(),
                                .hardLine,
                                .element(.text("Returning")),
                                .line,
                                value.returnType.formatted,
                                .hardLine,
                                .element(.text("Body:")),
                                .indent(
                                    .concat(
                                        [
                                            .hardLine,
                                            .join(with: .hardLine) {
                                                value.block.map { $0.formatted }
                                            }
                                        ]
                                    )
                                )
                            ]
                        )
                    )
                ]
            )
        case .enumeration(let value):
            let contents: FormatterCommand<LogicElement> = .concat(
                [
                    .element(.text("with cases:")),
                    .indent(
                        .concat(
                            [
                                .hardLine,
                                .join(with: .hardLine) {
                                    value.cases.map { $0.formatted }
                                }
                            ]
                        )
                    )
                ]
            )

            return .concat(
                [
                    .element(LogicElement.dropdown(value.id, "Enumeration", .source)),
                    value.name.formatted,
                    (value.genericParameters.isEmpty ? contents : .indent(
                        .concat(
                            [
                                genericParameters(),
                                .hardLine,
                                contents
                            ]
                        )
                    ))
                ]
            )
        case .record(let value):
            let contents: FormatterCommand<LogicElement> = .concat(
                [
                    .element(.text("with properties:")),
                    .indent(
                        .concat(
                            [
                                .hardLine,
                                .join(with: .hardLine) {
                                    value.declarations.map { $0.formatted }
                                }
                            ]
                        )
                    )
                ]
            )

            return .concat(
                [
                    .element(LogicElement.dropdown(value.id, "Record", .source)),
                    value.name.formatted,
                    (value.genericParameters.isEmpty ? contents : .indent(
                        .concat(
                            [
                                genericParameters(),
                                .hardLine,
                                contents
                            ]
                        )
                    ))
                ]
            )
        case .namespace(let value):
            return .concat(
                [
                    .element(LogicElement.dropdown(value.id, "Namespace", .source)),
                    value.name.formatted,
                    .indent(
                        .concat(
                            [
                                .hardLine,
                                .join(with: .hardLine) {
                                    value.declarations.map { $0.formatted }
                                }
                            ]
                        )
                    )
                ]
            )
        case .importDeclaration(let value):
            return .concat(
                [
                    .element(LogicElement.dropdown(value.id, "Import", .source)),
                    value.name.formatted
                ]
            )
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        }
    }
}

extension LGCTopLevelParameters: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        return .join(with: .hardLine) {
            self.parameters.map { $0.formatted }
        }
    }
}


extension LGCProgram: SyntaxNodeFormattable {
    var formatted: FormatterCommand<LogicElement> {
        return .join(with: .hardLine) {
            self.block.map { $0.formatted }
        }
    }
}

public extension LGCSyntaxNode {
    var formatted: FormatterCommand<LogicElement> {
        guard let contents = contents as? SyntaxNodeFormattable else {
            fatalError("No formatting rules for selected \(nodeTypeDescription)")
        }
        return contents.formatted
    }
}
