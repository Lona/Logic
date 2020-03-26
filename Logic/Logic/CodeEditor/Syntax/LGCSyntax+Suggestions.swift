//
//  SwiftSyntax+Suggestions.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

private func makeTitle(label: String, query: String) -> String {
    return label + (query.isEmpty ? "" : ": \(query)")
}

public struct LogicSuggestionItem {
    public enum Style {
        case normal
        case colorPreview(code: String, NSColor)
        case textStylePreview(TextStyle)
    }

    public struct DynamicSuggestionBuilder {
        public var initialValue: Data?
        public var onChangeValue: (Data?) -> Void
        public var onSubmit: () -> Void
        public var setNodeBuilder: (@escaping (Data?) -> LGCSyntaxNode) -> Void
        public var setListItem: ((SuggestionListItem?) -> Void)
        public var formattingOptions: LogicFormattingOptions

        public init(
            initialValue: Data?,
            onChangeValue: @escaping (Data?) -> Void,
            onSubmit: @escaping () -> Void,
            setListItem: @escaping ((SuggestionListItem?) -> Void),
            setNodeBuilder: @escaping (@escaping (Data?) -> LGCSyntaxNode) -> Void,
            formattingOptions: LogicFormattingOptions) {
            self.initialValue = initialValue
            self.onChangeValue = onChangeValue
            self.onSubmit = onSubmit
            self.setListItem = setListItem
            self.setNodeBuilder = setNodeBuilder
            self.formattingOptions = formattingOptions
        }
    }

    public init(
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        image: NSImage? = nil,
        category: String,
        node: LGCSyntaxNode,
        suggestionFilters: [SuggestionView.SuggestionFilter] = [.all],
        nextFocusId: UUID? = nil,
        disabled: Bool = false,
        style: Style = .normal,
        documentation: ((DynamicSuggestionBuilder) -> NSView)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.image = image
        self.category = category
        self.node = node
        self.suggestionFilters = suggestionFilters
        self.nextFocusId = nextFocusId
        self.disabled = disabled
        self.style = style
        self.documentation = documentation
    }

    public var title: String
    public var subtitle: String?
    public var badge: String?
    public var image: NSImage?
    public var category: String
    public var node: LGCSyntaxNode
    public var suggestionFilters: [SuggestionView.SuggestionFilter]
    public var nextFocusId: UUID?
    public var disabled: Bool
    public var style: Style
    public var documentation: ((DynamicSuggestionBuilder) -> NSView)?

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
        let rows = items.map { SuggestionListItem.row($0.title, $0.subtitle, $0.disabled, $0.badge, nil) }
        return Array([[sectionHeader], rows].joined())
    }
}

public extension LGCIdentifier {
    enum Suggestion {
        public static func name(_ string: String) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: string,
                category: LGCExpression.Suggestion.variablesCategoryTitle,
                node: LGCSyntaxNode.identifier(.init(id: UUID(), string: string))
            )
        }

        public static let categoryTitle = "Identifiers".uppercased()
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        return []
    }
}

public extension LGCLiteral {
    enum Suggestion {
        public static var `true`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "true",
                badge: "Boolean",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(.boolean(id: UUID(), value: true)),
                documentation: ({ builder in
                    return LightMark.makeScrollView(markdown: """
# Boolean Literal

A boolean is either `true` or `false` - this one is `true`.
""", renderingOptions: .init(formattingOptions: builder.formattingOptions))
                })
            )
        }

        public static var `false`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "false",
                badge: "Boolean",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(.boolean(id: UUID(), value: false)),
                documentation: ({ builder in
                    return LightMark.makeScrollView(markdown: """
# Boolean Literal

A boolean is either `true` or `false` - this one is `false`.
""", renderingOptions: .init(formattingOptions: builder.formattingOptions))
                })
            )
        }

        public static func rationalNumber(for prefix: String) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: prefix.isEmpty ? "Number" : prefix,
                badge: "Number",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(.number(id: UUID(), value: CGFloat(Double(prefix) ?? 0))),
                disabled: Double(prefix) == nil,
                documentation: ({ builder in
                    let alert = prefix.isEmpty
                        ? "I> Type any number.\n\n"
                        : Double(prefix) == nil
                        ? "E> That's not a valid number!\n\n"
                        : ""

                    return LightMark.makeScrollView(markdown: """
\(alert)# Number Literal

Create a new `Number`: **\(prefix)**
""", renderingOptions: .init(formattingOptions: builder.formattingOptions))
                })
            )
        }

        public static func string(for prefix: String) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: prefix.isEmpty ? "Empty" : "\"\(prefix)\"",
                badge: "String",
                category: categoryTitle,
                node: LGCSyntaxNode.literal(.string(id: UUID(), value: prefix)),
                documentation: ({ builder in
                    let alert = prefix.isEmpty ? "I> Type anything to create a string containing those characters, or press enter to create an empty string.\n\n" : ""

                    return LightMark.makeScrollView(markdown: """
\(alert)# String Literal

Create a new `String`: **"\(prefix)"**

## Escaping

There's no need to escape characters in string literals. This will be done automatically by the compiler when converting to code.
""", renderingOptions: .init(formattingOptions: builder.formattingOptions))
                })
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
            let result = NSColor.parseAndNormalize(css: prefix)
            let color = result?.color
            let prefix = result?.css ?? prefix

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
        return []
    }
}

public extension LGCFunctionParameterDefaultValue {
    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
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
    enum Suggestion {
        public static var `preludeImport`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Prelude",
                category: "LIBRARIES",
                node: LGCSyntaxNode.pattern(LGCPattern(id: UUID(), name: "Prelude")),
                documentation: ({ builder in
                    return LightMark.makeScrollView(markdown: """
# Prelude

The Logic type system.

> This is automatically imported in all Lona files.
""", renderingOptions: .init(formattingOptions: builder.formattingOptions))
                })
            )
        }

        public static var `colorImport`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Color",
                category: "LIBRARIES",
                node: LGCSyntaxNode.pattern(LGCPattern(id: UUID(), name: "Color")),
                documentation: ({ builder in
                    return LightMark.makeScrollView(markdown: """
# Color

The Lona Color library. This contains functions for creating and manipulating cross-platform color definitions.
""", renderingOptions: .init(formattingOptions: builder.formattingOptions))
                })
            )
        }

        public static var `textStyleImport`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "TextStyle",
                category: "LIBRARIES",
                node: LGCSyntaxNode.pattern(LGCPattern(id: UUID(), name: "TextStyle")),
                documentation: ({ builder in
                    return LightMark.makeScrollView(markdown: """
# TextStyle

The Lona Text Style library. This contains functions for creating and manipulating cross-platform text style definitions.
""", renderingOptions: .init(formattingOptions: builder.formattingOptions))
                })
            )
        }

        public static var `shadowImport`: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Shadow",
                category: "LIBRARIES",
                node: LGCSyntaxNode.pattern(LGCPattern(id: UUID(), name: "Shadow")),
                documentation: ({ builder in
                    return LightMark.makeScrollView(markdown: """
# Shadow

The Lona Shadow library. This contains functions for creating and manipulating cross-platform shadow definitions.
""", renderingOptions: .init(formattingOptions: builder.formattingOptions))
                })
            )
        }
    }

    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
        let parent = root.contents.parentOf(target: uuid, includeTopLevel: false)

        switch parent {
        case .some(.declaration(.importDeclaration)):
            return [
                Suggestion.colorImport,
                Suggestion.textStyleImport,
                Suggestion.shadowImport,
                Suggestion.preludeImport
            ].titleContains(prefix: prefix).sortedByPrefix()
        default:
            break
        }

        let items = [
            LogicSuggestionItem(
                title: "Name: \(prefix)",
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
                    localName: LGCPattern(id: UUID(), name: prefix),
                    annotation: LGCTypeAnnotation.typeIdentifier(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "type", isPlaceholder: true),
                        genericArguments: .empty
                    ),
                    defaultValue: .none(id: UUID()),
                    comment: nil
                )
            case .parameter(let value):
                return LGCFunctionParameter.parameter(
                    id: UUID(),
                    localName: LGCPattern(id: UUID(), name: prefix),
                    annotation: value.annotation, // TODO: new id?
                    defaultValue: value.defaultValue, // TODO: new id?
                    comment: nil
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
                    associatedValueTypes: .next(LGCTypeAnnotation.makePlaceholder(), .empty),
                    comment: nil
                )
            case .enumerationCase(let value):
                return LGCEnumerationCase.enumerationCase(
                    id: UUID(),
                    name: LGCPattern(id: UUID(), name: prefix),
                    associatedValueTypes: value.associatedValueTypes,
                    comment: nil
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

        public static func memberExpression(names: [String]) -> LogicSuggestionItem {
            return memberExpression(identifiers: names.map { LGCIdentifier(id: UUID(), string: $0) })
        }

        public static func memberExpression(identifiers: [LGCIdentifier]) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: identifiers.last?.string ?? "",
                subtitle: identifiers.count > 1 ? identifiers.dropLast().map { $0.string }.joined(separator: ".") : nil,
                category: variablesCategoryTitle,
                node: .expression(LGCExpression.makeMemberExpression(identifiers: identifiers))
            )
        }

        public static func identifier(name: String) -> LogicSuggestionItem {
            return from(identifierSuggestion: LGCIdentifier.Suggestion.name(name))!
        }

        public static func functionCall(keyPath: [String], title: String? = nil, arguments: [LGCFunctionCallArgument]) -> LogicSuggestionItem {
            let title = title ?? keyPath.last ?? ""

            return LogicSuggestionItem(
                title: title,
                subtitle: keyPath.count > 1 ? keyPath.dropLast().joined(separator: ".") : nil,
                badge: "ƒ",
                category: functionCallCategoryTitle,
                node: .expression(
                    .functionCallExpression(
                        id: UUID(),
                        expression: LGCExpression.makeMemberExpression(names: keyPath),
                        arguments: .init(arguments)
                    )
                )
            )
        }

        public static let functionCallCategoryTitle = "Functions".uppercased()

        public static let categoryTitle = "Expressions".uppercased()

        public static let variablesCategoryTitle = "Variables".uppercased()
    }

    static var assignmentSuggestionItem: LogicSuggestionItem {
        return LogicSuggestionItem(
            title: "Assignment",
            category: "Expressions".uppercased(),
            node: LGCSyntaxNode.expression(
                LGCExpression.assignmentExpression(
                    left: LGCExpression.identifierExpression(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "variable", isPlaceholder: true)
                    ),
                    right: LGCExpression.identifierExpression(
                        id: UUID(),
                        identifier: LGCIdentifier(id: UUID(), string: "value", isPlaceholder: true)
                    ),
                    id: UUID()
                )
            )
        )
    }

    static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
//        let items = [
//            Suggestion.comparison,
//            assignmentSuggestionItem
//        ]
//
//        let literalExpressions: [LogicSuggestionItem] = LGCLiteral
//            .suggestions(for: prefix)
//            .compactMap(Suggestion.from(literalSuggestion:))
//
//        return items.titleContains(prefix: prefix) +
//            LGCIdentifier.suggestions(for: prefix) +
//            literalExpressions

        return []
    }
}

extension LGCDeclaration {
    public enum Suggestion {
        public static func variable(query: String) -> LogicSuggestionItem {
            let nameId = UUID()
            let typeId = UUID()

            return LogicSuggestionItem(
                title: makeTitle(label: "Variable", query: query),
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.variable(
                        id: UUID(),
                        name: LGCPattern(id: nameId, name: query.isEmpty ? "name" : query),
                        annotation: LGCTypeAnnotation.typeIdentifier(
                            id: UUID(),
                            identifier: LGCIdentifier(id: typeId, string: "type", isPlaceholder: true),
                            genericArguments: .empty
                        ),
                        initializer: .identifierExpression(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "value", isPlaceholder: true)
                        ),
                        comment: nil
                    )
                ),
                nextFocusId: query.isEmpty ? nameId : typeId
            )
        }

        public static func function(query: String) -> LogicSuggestionItem {
            return LogicSuggestionItem(
                title: makeTitle(label: "Function", query: query),
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.function(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: query.isEmpty ? "name" : query),
                        returnType: LGCTypeAnnotation.typeIdentifier(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "Type", isPlaceholder: true),
                            genericArguments: .empty
                        ),
                        genericParameters: .empty,
                        parameters: .next(LGCFunctionParameter.placeholder(id: UUID()), .empty),
                        block: .next(LGCStatement.placeholder(id: UUID()), .empty),
                        comment: nil
                    )
                )
            )
        }

        public static var genericFunction: LogicSuggestionItem {
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
                        genericParameters: .init(
                            [
                                .parameter(id: UUID(), name: .init(id: UUID(), name: "T")),
                                .makePlaceholder()
                            ]
                        ),
                        parameters: .next(LGCFunctionParameter.placeholder(id: UUID()), .empty),
                        block: .next(LGCStatement.placeholder(id: UUID()), .empty),
                        comment: nil
                    )
                )
            )
        }

        public static func `enum`(query: String) -> LogicSuggestionItem? {
            if let first = query.first, first.isLowercase { return nil }

            let patternId = UUID()
            let placeholderId = UUID()

            return LogicSuggestionItem(
                title: makeTitle(label: "Enumeration Type", query: query),
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.enumeration(
                        id: UUID(),
                        name: LGCPattern(id: patternId, name: query.isEmpty ? "name" : query),
                        genericParameters: .empty,
                        cases: .next(.placeholder(id: placeholderId), .empty),
                        comment: nil
                    )
                ),
                nextFocusId: query.isEmpty ? patternId : placeholderId
            )
        }

        public static var genericEnum: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Generic Enumeration Type",
                category: "GENERIC \(categoryTitle)",
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.enumeration(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "name"),
                        genericParameters: .init(
                            [
                                .parameter(id: UUID(), name: .init(id: UUID(), name: "T")),
                                .makePlaceholder()
                            ]
                        ),
                        cases: .next(LGCEnumerationCase.makePlaceholder(), .empty),
                        comment: nil
                    )
                )
            )
        }

        public static func record(query: String) -> LogicSuggestionItem? {
            if let first = query.first, first.isLowercase { return nil }

            let patternId = UUID()
            let placeholderId = UUID()

            return LogicSuggestionItem(
                title: makeTitle(label: "Record Type", query: query),
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.record(
                        id: UUID(),
                        name: LGCPattern(id: patternId, name: query.isEmpty ? "name" : query),
                        genericParameters: .empty,
                        declarations: .next(.placeholder(id: placeholderId), .empty),
                        comment: nil
                    )
                ),
                nextFocusId: query.isEmpty ? patternId : placeholderId
            )
        }

        public static var genericRecord: LogicSuggestionItem {
            return LogicSuggestionItem(
                title: "Generic Record Type",
                category: "GENERIC \(categoryTitle)",
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.record(
                        id: UUID(),
                        name: LGCPattern(id: UUID(), name: "name"),
                        genericParameters: .init(
                            [
                                .parameter(id: UUID(), name: .init(id: UUID(), name: "T")),
                                .makePlaceholder()
                            ]
                        ),
                        declarations: .next(LGCDeclaration.makePlaceholder(), .empty),
                        comment: nil
                    )
                )
            )
        }

        public static func namespace(query: String) -> LogicSuggestionItem? {
            if let first = query.first, first.isLowercase { return nil }

            let patternId = UUID()
            let placeholderId = UUID()

            return LogicSuggestionItem(
                title: makeTitle(label: "Namespace", query: query),
                category: categoryTitle,
                node: LGCSyntaxNode.declaration(
                    LGCDeclaration.namespace(
                        id: UUID(),
                        name: LGCPattern(id: patternId, name: query.isEmpty ? "name" : query),
                        declarations: .next(.placeholder(id: placeholderId), .empty)
                    )
                ),
                nextFocusId: query.isEmpty ? patternId : placeholderId
            )
        }

        public static var `import`: LogicSuggestionItem {
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

        public static let categoryTitle = "Declarations".uppercased()
    }

    public static func suggestions(for prefix: String) -> [LogicSuggestionItem] {
        let items = [
            Suggestion.variable(query: ""),
            Suggestion.function(query: ""),
            Suggestion.enum(query: ""),
            Suggestion.record(query: ""),
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

        let returnStatement = LGCSyntaxNode.statement(
            LGCStatement.returnStatement(
                id: UUID(),
                expression: .identifierExpression(
                    id: UUID(),
                    identifier: LGCIdentifier(id: UUID(), string: "value", isPlaceholder: true)
                )
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
            LogicSuggestionItem(
                title: "Return statement",
                category: suggestionCategoryTitle.uppercased(),
                node: returnStatement
            ),
            LGCExpression.assignmentSuggestionItem,
        ] + LGCDeclaration.suggestions(for: prefix)

        return items.titleContains(prefix: prefix)
    }
}

public extension LGCComment {
    enum Suggestion {
        static let categoryTitle = "Declarations".uppercased()
    }

    func suggestions(within root: LGCSyntaxNode, for prefix: String) -> [LogicSuggestionItem] {
        let suggestion = LogicSuggestionItem(
            title: "Comment",
            category: Suggestion.categoryTitle,
            node: .comment(LGCComment(id: UUID(), string: prefix)),
            documentation: ({ builder in
                let textView = ControlledSearchInput()

                let decodeValue: (Data?) -> String = { data in
                    if let data = data, let title = String(data: data, encoding: .utf8) {
                        return title
                    } else {
                        return self.string
                    }
                }

                textView.textValue = decodeValue(builder.initialValue)
                textView.usesSingleLineMode = false
                textView.isBordered = false

                textView.translatesAutoresizingMaskIntoConstraints = false
                textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
                textView.setContentHuggingPriority(.defaultLow, for: .vertical)
                textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

                textView.onChangeTextValue = { value in
                    textView.textValue = value

                    guard let data = value.data(using: .utf8) else { return }

                    builder.onChangeValue(data)
                }

                textView.onSubmit = {
                    builder.onSubmit()
                }

                builder.setNodeBuilder({ data in
                    let value = decodeValue(data)
                    return .comment(.init(id: UUID(), string: value))
                })

                return textView
            })
        )

        return [suggestion]
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
            return contents.suggestions(within: root, for: prefix)
        case .expression:
            return LGCExpression.suggestions(for: prefix)
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
        case .topLevelDeclarations:
            return []
        case .comment:
            return contents.suggestions(within: root, for: prefix)
        case .functionCallArgument:
            return [
                .init(title: "TODO", category: "TODO", node: .identifier(.init(id: UUID(), string: "TODO")))
            ]
        }
    }
}


