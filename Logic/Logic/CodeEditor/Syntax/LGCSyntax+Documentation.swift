//
//  SwiftSyntax+Documentation.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 3/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public extension LGCExpression {
    func documentation(within root: LGCSyntaxNode, for prefix: String, formattingOptions: LogicFormattingOptions) -> NSView {
        switch self {
        case .assignmentExpression:
            return LightMark.makeScrollView(markdown: """
# Assignment

Use an assignment expression to update the value of an existing variable.
""", renderingOptions: .init(formattingOptions: formattingOptions))
        default:
            return NSView()
        }
    }
}

public extension LGCFunctionParameter {
    func documentation(within root: LGCSyntaxNode, for prefix: String, formattingOptions: LogicFormattingOptions) -> NSView {
        return LightMark.makeScrollView(markdown: """
I> Info message

# Title
""", renderingOptions: .init(formattingOptions: formattingOptions))
    }
}

public extension LGCPattern {
    func documentation(within root: LGCSyntaxNode, for prefix: String, formattingOptions: LogicFormattingOptions) -> NSView {
//        let parent = root.contents.parentOf(target: uuid, includeTopLevel: false)
//
//        let prefersCamelCase: Bool
//
//        switch parent {
//        case .some(.declaration(.record)), .some(.declaration(.namespace)):
//            prefersCamelCase = false
//        default:
//            prefersCamelCase = true
//        }

        let alert = prefix.isEmpty
            ? "I> Type a variable name!\n\n"
            : prefix.contains(" ")
            ? "E> Variable names can't contain spaces!\n\n"
            : prefix.first?.isNumber == true
            ? "E> Variable names can't start with numbers!\n\n"
//            : (prefix.first?.isUppercase == true && prefersCamelCase)
//            ? "W> This variable name should use **camelCase** (start with a lowercase character)\n\n"
//            : (prefix.first?.isLowercase == true && !prefersCamelCase)
//            ? "W> This variable name should use **UpperCamelCase** (start with an uppercase character)\n\n"
            : ""

        return LightMark.makeScrollView(markdown: """
\(alert)# Name

A valid name starts with an uppercase or lowercase letter (a through z, A through Z) or an underscore character. After the first character, numbers are also allowed.

Examples include: `myVariable`, `MyRecord`, `_private`, `ipv6`

## Naming Conventions

Variable, function, and function parameter names should use **camelCase** (also known as **lowerCamelCase**). These should start with a lowercase letter, and use uppercase at the start of every word.

Record, enumeration, and namespaces names should use **UpperCamelCase** (also known as **PascalCase**. These should start with an uppercase letter, and use uppercase at the start of every word.
""", renderingOptions: .init(formattingOptions: formattingOptions))
    }
}

public extension LGCStatement {
    func documentation(within root: LGCSyntaxNode, for prefix: String, formattingOptions: LogicFormattingOptions) -> NSView {
        switch self {
        case .branch:
//            let example = LGCSyntaxNode.statement(
//                LGCStatement.branch(
//                    id: UUID(),
//                    condition: LGCExpression.binaryExpression(
//                        left: LGCExpression.identifierExpression(
//                            id: UUID(),
//                            identifier: LGCIdentifier(id: UUID(), string: "age")
//                        ),
//                        right: LGCExpression.identifierExpression(
//                            id: UUID(),
//                            identifier: LGCIdentifier(id: UUID(), string: "17")
//                        ),
//                        op: .isGreaterThan(id: UUID()),
//                        id: UUID()
//                    ),
//                    block: LGCList<LGCStatement>.next(
//                        LGCStatement.expressionStatement(
//                            id: UUID(),
//                            expression: LGCExpression.binaryExpression(
//                                left: LGCExpression.identifierExpression(
//                                    id: UUID(),
//                                    identifier: LGCIdentifier(id: UUID(), string: "layers.Text.text")
//                                ),
//                                right: LGCExpression.identifierExpression(
//                                    id: UUID(),
//                                    identifier: LGCIdentifier(id: UUID(), string: "\"Congrats, you're an adult!\"")
//                                ),
//                                op: .setEqualTo(id: UUID()),
//                                id: UUID()
//                            )
//                        ),
//                        .empty
//                    )
//                )
//            )

            return LightMark.makeScrollView(markdown: """
# If condition

Conditions let you run different code depending on the current state of your app.

## Example

Suppose our program has a variable `age` representing the current user's age. We might want to display a specific message depending on the value of age. We could use an **if condition** to accomplish this:

TODO: Add code block
""", renderingOptions: .init(formattingOptions: formattingOptions))
        case .loop:
            return LightMark.makeScrollView(markdown: """
# For loop

Loops let you run the same code multiple times, once for each item in a sequence of items.
""", renderingOptions: .init(formattingOptions: formattingOptions))
        default:
            return NSView()
        }
    }
}

public extension LGCSyntaxNode {
    func documentation(within root: LGCSyntaxNode, for prefix: String, formattingOptions: LogicFormattingOptions) -> NSView {
        return contents.documentation(within: root, for: prefix, formattingOptions: formattingOptions)
    }

    func makeCodeView(using options: LogicFormattingOptions) -> NSView {
        let container = NSBox()
        container.boxType = .custom
        container.borderType = .lineBorder
        container.borderWidth = 1
        container.borderColor = NSColor(red: 0.59, green: 0.59, blue: 0.59, alpha: 0.26)
        container.fillColor = Colors.background
        container.cornerRadius = 4

        let editor = LogicCanvasView()
        editor.formattedContent = .init(formatted(using: options))

        container.addSubview(editor)

        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        editor.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        editor.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        editor.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true

        return container
    }

    init?(data: Data) {
        guard let jsonData = LogicFile.convert(data, kind: .logic, to: .json) else {
            Swift.print("Failed to convert LGCSyntaxNode data to json")
            return nil
        }

        guard let node = try? JSONDecoder().decode(LGCSyntaxNode.self, from: jsonData) else {
            Swift.print("Failed to deserialize JSON")
            return nil
        }

        self = node
    }
}

