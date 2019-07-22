//
//  SyntaxNodeFormattable.swift
//  Logic
//
//  Created by Devin Abbott on 6/4/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

protocol SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement>
}

public class LogicFormattingOptions {
    public enum Style: String {
        case natural, visual, js

        public var displayName: String {
            switch self {
            case .natural:
                return "Natural language"
            case .visual:
                return "Visual language"
            case .js:
                return "JavaScript-like"
            }
        }
    }

    public enum Locale {
        case en_US, es_ES

        public var `true`: String {
            switch self {
            case .en_US:
                return "true"
            case .es_ES:
                return "cierto"
            }
        }

        public var `false`: String {
            switch self {
            case .en_US:
                return "false"
            case .es_ES:
                return "falso"
            }
        }

        public var `if`: String {
            switch self {
            case .en_US:
                return "If"
            case .es_ES:
                return "Si"
            }
        }

        public var `in`: String {
            switch self {
            case .en_US:
                return "in"
            case .es_ES:
                return "en"
            }
        }

        public var `forEach`: String {
            switch self {
            case .en_US:
                return "For each"
            case .es_ES:
                return "Por cada"
            }
        }
    }

    public init(
        style: Style = .natural,
        locale: Locale = .en_US,
        getColor: @escaping (UUID) -> (String, NSColor)? = {_ in nil}
        ) {
        self.style = style
        self.locale = locale
        self.getColor = getColor
    }

    public var style: Style
    public var locale: Locale
    public var getColor: (UUID) -> (String, NSColor)?

    public static var normal = LogicFormattingOptions()
    public static var visual = LogicFormattingOptions(style: .visual)
}

fileprivate extension FormatterCommand where Element == LogicElement {
    var stringContents: String {
        return elements.reduce("", { (result, element) -> String in
            return result + element.value
        })
    }
}

extension LGCComment: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(id, string, .comment))
    }
}

extension LGCIdentifier: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        if isPlaceholder {
            return .element(LogicElement.dropdown(id, string, .placeholder))
        }

        return .element(LogicElement.dropdown(id, string, .variable))
    }
}

extension LGCPattern: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(id, name, .variable))
    }

    var formattedAsTitle: FormatterCommand<LogicElement> {
        return .element(.title(id, name))
    }
}

extension LGCBinaryOperator: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        return .element(LogicElement.dropdown(uuid, displayText, .source))
    }
}

extension LGCLiteral: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        switch self {
        case .none:
            return .element(.text("none"))
        case .boolean(let value):
            return .element(LogicElement.dropdown(value.id, value.value ? options.locale.true : options.locale.false, .variable))
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
                        .concat(
                            [
                                .hardLine,
                                .join(with: .concat([.element(.text(",")), .hardLine])) {
                                    value.value.map { $0.formatted(using: options) }
                                }
                            ]
                        )
                    ),
                    .hardLine,
                    .element(.text("]")),
                ]
            )
        }
    }
}

extension LGCFunctionCallArgument: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        if let label = self.label {
            return .concat(
                [
                    .element(.text(label + ":")),
                    self.expression.formatted(using: options)
                ]
            )
        } else {
            return self.expression.formatted(using: options)
        }
    }
}

extension LGCFunctionParameterDefaultValue: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        switch self {
        case .value(let value):
            return .concat(
                [
                    .element(LogicElement.dropdown(value.id, "default value", .source)),
                    value.expression.formatted(using: options)
                ]
            )
        case .none(let value):
            return .element(LogicElement.dropdown(value, "no default", .source))
        }
    }
}

extension LGCFunctionParameter: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
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
                    return value.defaultValue.formatted(using: options)
                case .functionType:
                    return value.defaultValue.formatted(using: options)
                case .placeholder:
                    return .element(.text("no default"))
                }
            }

            return .concat(
                [
                    // Always select the parent node instead of the name
                    .element(LogicElement.dropdown(value.id, value.localName.name, .variable)),
                    //                    value.localName.formatted(using: options),
                    .element(.text("of type")),
                    value.annotation.formatted(using: options),
                    .element(.text("with")),
                    defaultValue()
                ]
            )
        }
    }
}

extension LGCGenericParameter: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        switch self {
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        case .parameter(let value):
            return value.name.formatted(using: options)
        }
    }
}

extension LGCEnumerationCase: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        switch self {
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        case .enumerationCase(let value):
            var commentContents: [FormatterCommand<LogicElement>] = []

            if let comment = value.comment {
                commentContents.append(.spacer(12))
                commentContents.append(comment.formatted(using: options))
                commentContents.append(.hardLine)
            }

            return .concat(
                commentContents + [
                    // Always select the parent node instead of the name
                    .element(LogicElement.dropdown(value.id, value.name.name, .variable)),
                    .element(.text("with data")),
                    .join(with: .concat([.element(.text(",")), .line])) {
                        value.associatedValueTypes.map { $0.formatted(using: options) }
                    }
                ]
            )
        }
    }
}

extension LGCTypeAnnotation: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        switch self {
        case .typeIdentifier(let value):
            switch value.genericArguments {
            case .empty:
                return value.identifier.formatted(using: options)
            case .next(.placeholder, _):
                return value.identifier.formatted(using: options)
            case .next:
                return .concat(
                    [
                        value.identifier.formatted(using: options),
                        .element(.text("(")),
                        .join(with: .concat([.element(.text(",")), .line])) {
                            value.genericArguments.map { $0.formatted(using: options) }
                        },
                        .element(.text(")")),
                    ]
                )
            }
        case .functionType(let value):
            return .concat(
                [
                    .join(with: .concat([.element(.text(",")), .line])) {
                        value.argumentTypes.map { $0.formatted(using: options) }
                    },
                    .element(.text("→")),
                    value.returnType.formatted(using: options)
                ]
            )
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        }
    }
}

extension LGCExpression: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        switch self {
        case .identifierExpression(let value):
            return value.identifier.formatted(using: options)
        case .binaryExpression(let value):
            switch value.op {
            case .setEqualTo:
                return .concat(
                    [
                        value.left.formatted(using: options),
                        .element(.text("=")),
                        value.right.formatted(using: options)
                    ]
                )
            default:
                return .concat(
                    [
                        value.left.formatted(using: options),
                        value.op.formatted(using: options),
                        value.right.formatted(using: options)
                    ]
                )
            }
        case .functionCallExpression(let value):
            if value.expression.flattenedMemberExpression?.map({ $0.string }) == ["Optional", "value"] {
                return .concat(
                    [
                        .join(with: .concat([.element(.text(",")), .line])) {
                            value.arguments.map { $0.formatted(using: options) }
                        }
                    ]
                )
            }

            if value.arguments.isEmpty {
                // TODO: We should still show () on non-enum calls, but right now we can't distinguish easily
                return value.expression.formatted(using: options)

//                return .concat {
//                    [
//                        value.expression.formatted(using: options),
//                        .element(.text("()"))
//                    ]
//                }
            }

            return .concat(
                [
                    value.expression.formatted(using: options),
                    .element(.text("(")),
                    .indent(
                        .concat(
                            [
                                .hardLine,
                                .join(with: .concat([.element(.text(",")), .hardLine])) {
                                    value.arguments.map { $0.formatted(using: options) }
                                }
                            ]
                        )
                    ),
                    .hardLine,
                    .element(.text(")"))
                ]
            )
        case .literalExpression(let value):
            return value.literal.formatted(using: options)
        case .memberExpression(let value):
            //            let joined = FormatterCommand<LogicElement>.concat {
            //                [value.expression.formatted(using: options), .element(.text(".")), value.memberName.formatted(using: options)]
            //            }

            let joined = value.memberName.formatted(using: options)

            return .element(.dropdown(value.id, joined.stringContents, .variable))
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        }
    }
}

extension LGCStatement: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        switch self {
        case .loop(let loop):
            return .concat(
                [
                    .element(LogicElement.dropdown(loop.id, options.locale.forEach, .source)),
                    loop.pattern.formatted(using: options),
                    .element(LogicElement.text(options.locale.in)),
                    loop.expression.formatted(using: options),
                ]
            )
        case .branch(let branch):
            return .concat(
                [
                    .element(LogicElement.dropdown(branch.id, options.locale.if, .source)),
                    branch.condition.formatted(using: options),
                    .indent(
                        .concat(
                            [
                                .hardLine,
                                .join(with: .hardLine) {
                                    branch.block.map { $0.formatted(using: options) }
                                }
                            ]
                        )
                    )
                ]
            )
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        case .expressionStatement(let value):
            return value.expression.formatted(using: options)
        case .declaration(let value):
            return value.content.formatted(using: options)
        }
    }
}

extension LGCDeclaration: SyntaxNodeFormattable {
    private var shouldIndentInNamespace: Bool {
        switch self {
        case .namespace, .placeholder:
            return true
        default:
            return false
        }
    }

    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        func genericParameters() -> FormatterCommand<LogicElement> {
            switch self {
            case .function(id: _, name: _, returnType: _, genericParameters: let genericParameters, parameters: _, block: _, _),
                 .enumeration(id: _, name: _, genericParameters: let genericParameters, cases: _, _),
                 .record(id: _, name: _, genericParameters: let genericParameters, declarations: _, _):
                if genericParameters.isEmpty {
                    return .empty
                } else {
                    return .concat(
                        [
                            .hardLine,
                            .element(.text("Generic type parameters:")),
                            .join(with: .concat([.element(.text(",")), .line])) {
                                genericParameters.map { param in param.formatted(using: options) }
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
                                            value.parameters.map { param in param.formatted(using: options) }
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
            var contents: [FormatterCommand<LogicElement>] = []

            if let comment = value.comment {
                contents.append(.spacer(12))
                contents.append(comment.formatted(using: options))
                contents.append(.hardLine)
            }

            switch options.style {
            case .js:
                break
            case .natural, .visual:
                contents.append(.element(LogicElement.dropdown(value.id, "Let", .source)))
            }

            contents.append(value.name.formatted(using: options))

            if let annotation = value.annotation {
                contents.append(.element(.text(":")))
                contents.append(annotation.formatted(using: options))

                if let initializer = value.initializer {
                    switch annotation {
                    case .typeIdentifier(id: _, identifier: let identifier, genericArguments: .empty)
                        where identifier.string == Unification.T.color.name && options.style == .visual:

                        let colorInfo = options.getColor(initializer.uuid) ?? ("", NSColor.clear)
                        let decoration: LogicElement = .colorSwatch(colorInfo.0, colorInfo.1, value.id)

                        let formattedInitializer = initializer.formatted(using: options)

                        return .horizontalFloat(
                            decoration: decoration,
                            margins: NSEdgeInsets(top: 4, left: 0, bottom: 4, right: 0),
                            .concat(
                                [
                                    .element(.dropdown(value.name.uuid, value.name.name, .boldVariable)),
                                    .hardLine,
                                    formattedInitializer,
                                    .hardLine,
                                    .element(.text(formattedInitializer.stringContents == colorInfo.0 ? "" : colorInfo.0)),
                                    .spacer(4)
                                ]
                            )
                        )
                    case .typeIdentifier(id: _, identifier: let identifier, genericArguments: .empty) where identifier.isPlaceholder:
                        break
                    default:
                        contents.append(.element(.text("=")))
                        contents.append(initializer.formatted(using: options))
                    }
                }
            }

            return .concat(contents)
        case .function(let value):
            return .concat(
                [
                    .element(LogicElement.dropdown(value.id, "Function", .source)),
                    value.name.formatted(using: options),
                    .indent(
                        .concat(
                            [
                                genericParameters(),
                                .hardLine,
                                parameters(),
                                .hardLine,
                                .element(.text("Returning")),
                                .line,
                                value.returnType.formatted(using: options),
                                .hardLine,
                                .element(.text("Body:")),
                                .indent(
                                    .concat(
                                        [
                                            .hardLine,
                                            .join(with: .hardLine) {
                                                value.block.map { $0.formatted(using: options) }
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
            var commentContents: [FormatterCommand<LogicElement>] = []

            if let comment = value.comment {
                commentContents.append(.spacer(12))
                commentContents.append(comment.formatted(using: options))
                commentContents.append(.hardLine)
            }

            let contents: FormatterCommand<LogicElement> = .concat(
                [
                    .element(.text("with cases:")),
                    .indent(
                        .concat(
                            [
                                .hardLine,
                                .join(with: .hardLine) {
                                    value.cases.map { $0.formatted(using: options) }
                                }
                            ]
                        )
                    )
                ]
            )

            return .concat(
                commentContents + [
                    .element(LogicElement.dropdown(value.id, "Enumeration", .source)),
                    value.name.formatted(using: options),
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
            var commentContents: [FormatterCommand<LogicElement>] = []

            if let comment = value.comment {
                commentContents.append(.spacer(12))
                commentContents.append(comment.formatted(using: options))
                commentContents.append(.hardLine)
            }

            let contents: FormatterCommand<LogicElement> = .concat(
                [
                    .element(.text("with properties:")),
                    .indent(
                        .concat(
                            [
                                .hardLine,
                                .join(with: .hardLine) {
                                    value.declarations.map { $0.formatted(using: options) }
                                }
                            ]
                        )
                    )
                ]
            )

            return .concat(
                commentContents + [
                    .element(LogicElement.dropdown(value.id, "Record", .source)),
                    value.name.formatted(using: options),
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
            switch options.style {
            case .js:
                return .concat(
                    [
                        .element(LogicElement.dropdown(value.id, "export const", .source)),
                        value.name.formatted(using: options),
                        .element(LogicElement.text("= {")),
                        .indent(
                            .concat(
                                [
                                    .hardLine,
                                    .join(with: .hardLine) {
                                        value.declarations.map { $0.formatted(using: options) }
                                    }
                                ]
                            )
                        ),
                        .hardLine,
                        .element(LogicElement.text("}")),
                    ]
                )
            case .natural:
                return .concat(
                    [
                        .element(LogicElement.dropdown(value.id, "Namespace", .source)),
                        value.name.formatted(using: options),
                        .indent(
                            .concat(
                                [
                                    .hardLine,
                                    .join(with: .hardLine) {
                                        value.declarations.map { $0.formatted(using: options) }
                                    }
                                ]
                            )
                        )
                    ]
                )
            case .visual:
                return .concat(
                    [
                        .spacer(20),
                        .element(LogicElement.title(value.name.id, value.name.name)),
                        .horizontalFloat(
                            decoration: .indentGuide(value.id),
                            margins: NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 8),
                            .join(with: .hardLine) {
                                value.declarations.map { $0.formatted(using: options) }
                            }
                        )
                    ]
                )
            }
        case .importDeclaration(let value):
            return .concat(
                [
                    .element(LogicElement.dropdown(value.id, "Import", .source)),
                    value.name.formatted(using: options)
                ]
            )
        case .placeholder(let value):
            return .element(LogicElement.dropdown(value, "", .variable))
        }
    }
}

extension LGCTopLevelParameters: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        return .join(with: .hardLine) {
            self.parameters.map { $0.formatted(using: options) }
        }
    }
}

extension LGCTopLevelDeclarations: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        return .join(with: .hardLine) {
            self.declarations.map { $0.formatted(using: options) }
        }
    }
}

extension LGCProgram: SyntaxNodeFormattable {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        return .join(with: .hardLine) {
            self.block.map { $0.formatted(using: options) }
        }
    }
}

public extension LGCSyntaxNode {
    func formatted(using options: LogicFormattingOptions) -> FormatterCommand<LogicElement> {
        guard let contents = contents as? SyntaxNodeFormattable else {
            fatalError("No formatting rules for selected \(nodeTypeDescription)")
        }
        return contents.formatted(using: options)
    }
}
