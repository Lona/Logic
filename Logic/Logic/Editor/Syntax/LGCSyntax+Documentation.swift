//
//  SwiftSyntax+Documentation.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 3/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public extension LGCExpression {
    func documentation(within rootNode: LGCSyntaxNode, for prefix: String, formattingOptions: LightMark.RenderingOptions) -> NSView {
        switch self {
        case .binaryExpression(let value):
            switch value.op {
            case .setEqualTo:
                return LightMark.makeScrollView(markdown: """
# Assignment

Use an assignment expression to update the value of an existing variable.
""", renderingOptions: formattingOptions)
            default:
                return LightMark.makeScrollView(markdown: """
# Comparison

Compare two variables.
""", renderingOptions: formattingOptions)
            }
        default:
            return NSView()
        }
    }
}

public extension LGCFunctionParameter {
    func documentation(within rootNode: LGCSyntaxNode, for prefix: String, formattingOptions: LightMark.RenderingOptions) -> NSView {
        return LightMark.makeScrollView(markdown: """
I> Info message

# Title
""", renderingOptions: formattingOptions)
    }
}

public extension LGCStatement {
    func documentation(within rootNode: LGCSyntaxNode, for prefix: String, formattingOptions: LightMark.RenderingOptions) -> NSView {
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
""", renderingOptions: formattingOptions)
        case .loop:
            return LightMark.makeScrollView(markdown: """
# For loop

Loops let you run the same code multiple times, once for each item in a sequence of items.
""", renderingOptions: formattingOptions)
        default:
            return NSView()
        }
    }
}

public extension LGCSyntaxNode {
    func documentation(within rootNode: LGCSyntaxNode, for prefix: String, formattingOptions: LogicFormattingOptions) -> NSView {
        return contents.documentation(within: rootNode, for: prefix, formattingOptions: formattingOptions)
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
        editor.formattedContent = formatted(using: options)

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

