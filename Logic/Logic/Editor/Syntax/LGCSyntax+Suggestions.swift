//
//  SwiftSyntax+Suggestions.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public struct LogicSuggestionItem {
    public enum Style {
        case normal
        case colorPreview(code: String, NSColor)
        case textStylePreview(TextStyle)
    }

    public init(
        title: String,
        badge: String? = nil,
        category: String,
        node: LGCSyntaxNode,
        nextFocusId: UUID? = nil,
        disabled: Bool = false,
        style: Style = .normal) {
        self.title = title
        self.badge = badge
        self.category = category
        self.node = node
        self.nextFocusId = nextFocusId
        self.disabled = disabled
        self.style = style
    }

    public var title: String
    public var badge: String?
    public var category: String
    public var node: LGCSyntaxNode
    public var nextFocusId: UUID?
    public var disabled: Bool
    public var style: Style

    public func titleContains(prefix: String) -> Bool {
        if prefix.isEmpty { return true }

        return title.lowercased().contains(prefix.lowercased())
    }
}

public extension Array where Element == LogicSuggestionItem {
    func titleContains(prefix: String) -> [Element] {
        return self.filter { item in item.titleContains(prefix: prefix) }
    }

    func sortedByPrefix() -> [Element] {
        return self.sorted { left, right in
            return left.title < right.title
        }
    }
}

public struct LogicSuggestionCategory {
    public var title: String
    public var items: [LogicSuggestionItem]

    public var suggestionListItems: [SuggestionListItem] {
        let sectionHeader = SuggestionListItem.sectionHeader(title)
        let rows = items.map { SuggestionListItem.row($0.title, $0.disabled, $0.badge) }
        return Array([[sectionHeader], rows].joined())
    }
}

public extension LGCIdentifier {
    enum Suggestion {
        public static func name(_ string: String) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: string,
                category: "Variables".uppercased(),
                node: LGCSyntaxNode.identifier(.init(id: UUID(), string: string))
            )
        }

        public static let categoryTitle = "Identifiers".uppercased()
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            Suggestion.name("bar"),
            Suggestion.name("foo")
        ]

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCLiteral {
    enum Suggestion {
        public static var `true`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "true",
                badge: "Boolean",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(.boolean(id: UUID(), value: true))
            )
        }

        public static var `false`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "false",
                badge: "Boolean",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(.boolean(id: UUID(), value: false))
            )
        }

        public static func rationalNumber(for prefix: String) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: prefix.isEmpty ? "Number" : prefix,
                badge: "Number",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(.number(id: UUID(), value: CGFloat(Double(prefix) ?? 0))),
                disabled: Double(prefix) == nil
            )
        }

        public static func string(for prefix: String) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: prefix.isEmpty ? "Empty" : "\"\(prefix)\"",
                badge: "String",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(.string(id: UUID(), value: prefix))
            )
        }

        public static func array(for prefix: String) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Array",
                badge: "Array",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(
                    .array(
                        id: UUID(),
                        value: .next(.makePlaceholder(), .empty)
                    )
                )
            )
        }

        public static func color(for prefix: String) -> LogicSuggestionItem {
            let color = NSColor.parse(css: prefix)

            return LogicSuggestionItem(
                title: "Color",
                badge: "Color",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(.color(id: UUID(), value: prefix.starts(with: "#") ? prefix.uppercased() : prefix)),
                disabled: color == nil,
                style: color == nil ? .normal : .colorPreview(code: prefix, color ?? NSColor.black)
            )
        }

        public static let categoryTitle = "Literals".uppercased()
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            Suggestion.true,
            Suggestion.false,
            LogicSuggestionItem(
                title: "red",
                category: "Colors".uppercased(),
                node: LGCSyntaxNode.literal(.color(id: UUID(), value: "red")),
                style: .colorPreview(code: "#FF0000", .red)
            )
        ]

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCFunctionParameterDefaultValue {
    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
//        let inferredType = inferType(
//            within: root,
//            context: [
//                TypeEntity.nativeType(NativeType(name: "Boolean")),
//                TypeEntity.nativeType(NativeType(name: "Number")),
//                TypeEntity.nativeType(NativeType(name: "String")),
//            ]
//        )

        let items = [
            LogicSuggestionItem(
                title: "No default",
                category: "Default Value".uppercased(),
                node: LGCSyntaxNode.functionParameterDefaultValue(.none(id: UUID()))
            )
        ]

        let expressions: [LogicSuggestionItem] = LGCExpression
            .suggestions(for: prefix)
            .compactMap({ item in
                switch item.node {
                case .expression(let expression):
                    return LogicSuggestionItem(
                        title: item.title,
                        category: item.category,
                        node: .functionParameterDefaultValue(
                            LGCFunctionParameterDefaultValue.value(id: UUID(), expression: expression)
                        ),
                        disabled: item.disabled,
                        style: item.style
                    )
                default:
                    return nil
                }
            })

        return items.titleContains(prefix: prefix) + expressions
    }
}

public extension LGCTypeAnnotation {
    enum Suggestion {
        public static func from(type: Unification.T) -> LogicSuggestionItem {
            func makeTypeAnnotation(type: Unification.T) -> LGCTypeAnnotation {
                switch type {
                case .cons(name: let name, parameters: let parameters):
                    return LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: name),
                        genericArguments: .init(parameters.map(makeTypeAnnotation(type:)))
                    )
                case .evar(let name), .gen(let name):
                    return LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: name),
                        genericArguments: .empty
                    )
                case .fun:
                    fatalError("Not supported")
                }
            }

            return LogicSuggestionItem(
                title: type.name,
                badge: "Type",
                category: "Types".uppercased(),
                node: LGCSyntaxNode.typeAnnotation(makeTypeAnnotation(type: type))
            )
        }
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "Boolean",
                category: "Types".uppercased(),
                node: LGCSyntaxNode.typeAnnotation(
                    LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "Boolean"),
                        genericArguments: .empty
                    )
                )
            ),
            LogicSuggestionItem(
                title: "Number",
                category: "Types".uppercased(),
                node: LGCSyntaxNode.typeAnnotation(
                    LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "Number"),
                        genericArguments: .empty
                    )
                )
            ),
            LogicSuggestionItem(
                title: "Optional",
                category: "Generic Types".uppercased(),
                node: LGCSyntaxNode.typeAnnotation(
                    LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "Optional"),
                        genericArguments: .next(
                            LGCTypeAnnotation.typeIdentifier(
                                id: UUID(),
                                identifier: LGCIdentifier(id: UUID(), string: "Void"),
                                genericArguments: .empty
                            ),
                            .empty
                        )
                    )
                )
            ),
            LogicSuggestionItem(
                title: "Array",
                category: "Generic Types".uppercased(),
                node: LGCSyntaxNode.typeAnnotation(
                    LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "Array"),
                        genericArguments: .next(
                            LGCTypeAnnotation.typeIdentifier(
                                id: UUID(),
                                identifier: LGCIdentifier(id: UUID(), string: "Void"),
                                genericArguments: .empty
                            ),
                            .empty
                        )
                    )
                )
            ),
            LogicSuggestionItem(
                title: "Function",
                category: "Function Types".uppercased(),
                node: LGCSyntaxNode.typeAnnotation(
                    LGCTypeAnnotation.functionType(
                        id: UUID(),
                        returnType: LGCTypeAnnotation.typeIdentifier(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "Void"),
                            genericArguments: .empty
                        ),
                        argumentTypes: .next(
                            LGCTypeAnnotation.placeholder(id: UUID()),
                            .empty
                        )
                    )
                )
            )
        ]

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCPattern {
    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "Variable name: \(prefix)",
                category: "Pattern".uppercased(),
                node: LGCSyntaxNode.pattern(LGCPattern(id: UUID(), name: prefix)),
                disabled: prefix.isEmpty
            )
        ]

        return items
    }
}

public extension LGCGenericParameter {
    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            LogicSuggestionItem(
                title: "Type name: \(prefix)",
                category: "Generic Parameter".uppercased(),
                node: .genericParameter(.parameter(id: UUID(), name: .init(id: UUID(), name: prefix))),
                disabled: prefix.isEmpty
            )
        ]

        return items
    }
}

public extension LGCFunctionParameter {
    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
        func parameter() -> LGCFunctionParameter {
            switch self {
            case .placeholder:
                return LGCFunctionParameter.parameter(
                    id: UUID(),
                    externalName: nil,
                    localName: LGCPattern(id: UUID(), name: prefix),
                    annotation: LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "type", isPlaceholder: true),
                        genericArguments: .empty
                    ),
                    defaultValue: .none(id: UUID())
                )
            case .parameter(let value):
                return LGCFunctionParameter.parameter(
                    id: UUID(),
                    externalName: value.externalName,
                    localName: LGCPattern(id: UUID(), name: prefix),
                    annotation: value.annotation, // TODO: new id?
                    defaultValue: value.defaultValue // TODO: new id?
                )
            }
        }

        return [
            LogicSuggestionItem(
                title: "Parameter name: \(prefix)",
                category: "Function Parameter".uppercased(),
                node: LGCSyntaxNode.functionParameter(parameter()),
                disabled: prefix.isEmpty
            )
        ]
    }
}

public extension LGCEnumerationCase {
    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
        func parameter() -> LGCEnumerationCase {
            switch self {
            case .placeholder:
                return LGCEnumerationCase.enumerationCase(
                    id: UUID(),
                    name: LGCPattern(id: UUID(), name: prefix),
                    associatedValueTypes: .next(LGCTypeAnnotation.makePlaceholder(), .empty)
                )
            case .enumerationCase(let value):
                return LGCEnumerationCase.enumerationCase(
                    id: UUID(),
                    name: LGCPattern(id: UUID(), name: prefix),
                    associatedValueTypes: value.associatedValueTypes
                )
            }
        }

        return [
            LogicSuggestionItem(
                title: "Case name: \(prefix)",
                category: "Enumeration Case".uppercased(),
                node: LGCSyntaxNode.enumerationCase(parameter()),
                disabled: prefix.isEmpty
            )
        ]
    }
}

public extension LGCBinaryOperator {
    var displayText: String {
        switch self {
        case .isEqualTo:
            return "is equal to"
        case .isGreaterThan:
            return "is greater than"
        case .isGreaterThanOrEqualTo:
            return "is greater than or equal to"
        case .isLessThan:
            return "is less than"
        case .isLessThanOrEqualTo:
            return "is less than or equal to"
        case .isNotEqualTo:
            return "is not equal to"
        case .setEqualTo:
            return "now equals"
        }
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let operatorNodes = [
            LGCBinaryOperator.isEqualTo(id: UUID()),
            LGCBinaryOperator.isNotEqualTo(id: UUID()),
            LGCBinaryOperator.isGreaterThan(id: UUID()),
            LGCBinaryOperator.isGreaterThanOrEqualTo(id: UUID()),
            LGCBinaryOperator.isLessThan(id: UUID()),
            LGCBinaryOperator.isLessThanOrEqualTo(id: UUID())
        ]

        return operatorNodes.map { node in
            LogicSuggestionItem(
                title: node.displayText,
                category: "Operators".uppercased(),
                node: LGCSyntaxNode.binaryOperator(node)
            )
        }.titleContains(prefix: prefix)
    }
}

public extension LGCExpression {
    enum Suggestion {
        public static func from(literalSuggestion suggestion: LogicSuggestionItem) -> LogicSuggestionItem? {
            switch suggestion.node {
            case .literal(let literal):
                var copy = suggestion
                copy.node = .expression(.literalExpression(id: UUID(), literal: literal))
                return copy
            default:
                return nil
            }
        }

        public static func from(identifierSuggestion suggestion: LogicSuggestionItem) -> LogicSuggestionItem? {
            switch suggestion.node {
            case .identifier(let identifier):
                var copy = suggestion
                copy.node = .expression(.identifierExpression(id: UUID(), identifier: identifier))
                return copy
            default:
                return nil
            }
        }

        public static var comparison: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Comparison",
                category: categoryTitle,
                node: LGCSyntaxNode.expression(
                    LGCExpression.binaryExpression(
                        left: LGCExpression.identifierExpression(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "left", isPlaceholder: true)
                        ),
                        right: LGCExpression.identifierExpression(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "right", isPlaceholder: true)
                        ),
                        op: .isEqualTo(id: UUID()),
                        id: UUID()
                    )
                )
            )
        }

        public static func memberExpression(names: [String]) -> LogicSuggestionItem {
            return memberExpression(identifiers: names.map { LGCIdentifier(id: UUID(), string: $0) })
        }

        public static func memberExpression(identifiers: [LGCIdentifier]) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: identifiers.map { $0.string }.joined(separator: "."),
                category: "Variables".uppercased(),
                node: .expression(LGCExpression.makeMemberExpression(identifiers: identifiers))
            )
        }

        public static func identifier(name: String) -> LogicSuggestionItem {
            return from(identifierSuggestion: LGCIdentifier.Suggestion.name(name))!
        }

        public static func functionCall(keyPath: [String], title: String? = nil, arguments: [LGCFunctionCallArgument]) -> LogicSuggestionItem {
            let title = title ?? keyPath.joined(separator: ".")

            return LogicSuggestionItem(
                title: title,
                badge: "ƒ",
                category: "FUNCTIONS",
                node: .expression(
                    .functionCallExpression(
                        id: UUID(),
                        expression: LGCExpression.makeMemberExpression(names: keyPath),
                        arguments: .init(arguments)
                    )
                )
            )
        }

        public static let categoryTitle = "Expressions".uppercased()
    }

    static var assignmentSuggestionItem: LogicSuggestionItem {
        return LogicSuggestionItem(
            title: "Assignment",
            category: "Expressions".uppercased(),
            node: LGCSyntaxNode.expression(
                LGCExpression.binaryExpression(
                    left: LGCExpression.identifierExpression(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "variable", isPlaceholder: true)
                    ),
                    right: LGCExpression.identifierExpression(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "value", isPlaceholder: true)
                    ),
                    op: .setEqualTo(id: UUID()),
                    id: UUID()
                )
            )
        )
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            Suggestion.comparison,
            assignmentSuggestionItem
        ]

        let literalExpressions: [LogicSuggestionItem] = LGCLiteral
            .suggestions(for: prefix)
            .compactMap(Suggestion.from(literalSuggestion:))

//        let textStyleExample = LogicSuggestionItem(
//            title: "Title Muted",
//            category: "Text Styles".uppercased(),
//            node: LGCSyntaxNode.identifier(LGCIdentifier(id: UUID(), string: "TextStyles.title")),
//            style: .textStylePreview(TextStyle(weight: .bold, size: 18, color: NSColor.purple))
//        )

        return items.titleContains(prefix: prefix) +
            LGCIdentifier.suggestions(for: prefix) +
//            [textStyleExample].titleContains(prefix: prefix) +
            literalExpressions
    }
}

public extension LGCDeclaration {
    enum Suggestion {
        static var variable: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Variable",
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.variable(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "name"),
                        annotation: LGCTypeAnnotation.typeIdentifier(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "type", isPlaceholder: true),
                            genericArguments: .empty
                        ),
                        initializer: .identifierExpression(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "value", isPlaceholder: true)
                        )
                    )
                )
            )
        }

        static var function: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Function",
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.function(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "name"),
                        returnType: LGCTypeAnnotation.typeIdentifier(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "Void"),
                            genericArguments: .empty
                        ),
                        genericParameters: .empty,
                        parameters: .next(LGCFunctionParameter.placeholder(id: UUID()), .empty),
                        block: .next(LGCStatement.placeholder(id: UUID()), .empty)
                    )
                )
            )
        }

        static var genericFunction: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Generic Function",
                category: "GENERIC \(categoryTitle)",
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.function(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "name"),
                        returnType: LGCTypeAnnotation.typeIdentifier(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "Void"),
                            genericArguments: .empty
                        ),
                        genericParameters: .next(LGCGenericParameter.makePlaceholder(), .empty),
                        parameters: .next(LGCFunctionParameter.placeholder(id: UUID()), .empty),
                        block: .next(LGCStatement.placeholder(id: UUID()), .empty)
                    )
                )
            )
        }

        static var `enum`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Enumeration",
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.enumeration(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "name"),
                        genericParameters: .empty,
                        cases: .next(LGCEnumerationCase.makePlaceholder(), .empty)
                    )
                )
            )
        }

        static var genericEnum: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Generic Enumeration",
                category: "GENERIC \(categoryTitle)",
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.enumeration(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "name"),
                        genericParameters: .next(.makePlaceholder(), .empty),
                        cases: .next(LGCEnumerationCase.makePlaceholder(), .empty)
                    )
                )
            )
        }

        static var record: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Record",
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.record(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "name"),
                        genericParameters: .empty,
                        declarations: .next(LGCDeclaration.makePlaceholder(), .empty)
                    )
                )
            )
        }

        static var genericRecord: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Generic Record",
                category: "GENERIC \(categoryTitle)",
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.record(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "name"),
                        genericParameters: .next(.makePlaceholder(), .empty),
                        declarations: .next(LGCDeclaration.makePlaceholder(), .empty)
                    )
                )
            )
        }

        static func namespace(query: String) -> LogicSuggestionItem? {
            if let first = query.first, first.isLowercase {
                return nil
            }

            let patternId = UUID()

            return LogicSuggestionItem(
                title: "Namespace" + (query.isEmpty ? "" : " " + query),
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.namespace(
                        id: UUID(),
                        name: LGCPattern(id: patternId, name: query.isEmpty ? "name" : query),
                        declarations: .next(LGCDeclaration.makePlaceholder(), .empty)
                    )
                ),
                nextFocusId: patternId
            )
        }

        static var `import`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Import",
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.importDeclaration(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "Name")
                    )
                )
            )
        }

        static let categoryTitle = "Declarations".uppercased()
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            Suggestion.variable,
            Suggestion.function,
            Suggestion.enum,
            Suggestion.record,
            Suggestion.namespace(query: ""),
            Suggestion.genericFunction,
            Suggestion.genericEnum,
            Suggestion.genericRecord,
            Suggestion.import
            ].compactMap { $0 }

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCStatement {
    static let suggestionCategoryTitle = "Statements".uppercased()

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let ifCondition = LGCSyntaxNode.statement(
            LGCStatement.branch(
                id: UUID(),
                condition: .identifierExpression(
                    id: UUID(),
                    identifier: LGCIdentifier(id: UUID(), string: "condition", isPlaceholder: true)
                ),
                block: LGCList<LGCStatement>.next(
                    LGCStatement.placeholder(id: UUID()),
                    .empty
                )
            )
        )

        let forLoop = LGCSyntaxNode.statement(
            LGCStatement.loop(
                pattern: LGCPattern(id: UUID(), name: "item"),
                expression: LGCExpression.identifierExpression(
                    id: UUID(),
                    identifier: LGCIdentifier(id: UUID(), string: "array", isPlaceholder: true)
                ),
                block: LGCList<LGCStatement>.empty,
                id: UUID()
            )
        )

        let items = [
            LogicSuggestionItem(
                title: "If condition",
                category: suggestionCategoryTitle.uppercased(),
                node: ifCondition
            ),
            LogicSuggestionItem(
                title: "For loop",
                category: suggestionCategoryTitle.uppercased(),
                node: forLoop
            ),
            LGCExpression.assignmentSuggestionItem,
        ] + LGCDeclaration.suggestions(for: prefix)

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCSyntaxNode {
    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
        switch self {
        case .statement:
            return LGCStatement.suggestions(for: prefix)
        case .declaration:
            return LGCDeclaration.suggestions(for: prefix)
        case .identifier:
            return LGCIdentifier.suggestions(for: prefix)
        case .pattern:
            return LGCPattern.suggestions(for: prefix)
        case .expression:
            return LGCExpression.suggestions(for: prefix)
        case .binaryOperator:
            return LGCBinaryOperator.suggestions(for: prefix)
        case .program:
            return []
        case .functionParameter:
            return contents.suggestions(within: root, for: prefix)
        case .genericParameter:
            return LGCGenericParameter.suggestions(for: prefix)
        case .typeAnnotation:
            return LGCTypeAnnotation.suggestions(for: prefix)
        case .functionParameterDefaultValue:
            return contents.suggestions(within: root, for: prefix)
        case .literal:
            return LGCLiteral.suggestions(for: prefix)
        case .topLevelParameters:
            return []
        case .enumerationCase:
            return contents.suggestions(within: root, for: prefix)
        }
    }
}


